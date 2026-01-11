import logging
import random
from urllib.parse import quote

import httpx
from fastapi import APIRouter, HTTPException, Query
from thefuzz import fuzz

from app.core.song_picker import get_random_song
from app.core.security import create_game_token, decode_game_token
from app.core.utils import mask_text, mask_text_with_blanks
from app.schemas.game import (
    GuessRequest,
    GuessResult,
    NewRoundResponse,
    QueueResponse,
)

router = APIRouter(prefix="/game", tags=["game"])
logger = logging.getLogger(__name__)


async def _build_round(
    client: httpx.AsyncClient,
    mode: str,
    difficulty: str,
) -> NewRoundResponse:
    clean_lyrics = ""
    artist = ""
    title = ""
    album_cover = None

    for _ in range(12):
        logger.info("Selecting a new track for lyrics lookup.")
        selection = await get_random_song()
        artist = selection["artist"]
        title = selection["title"]
        album_cover = selection.get("album_cover")

        artist_path = quote(artist, safe="")
        title_path = quote(title, safe="")
        url = f"https://api.lyrics.ovh/v1/{artist_path}/{title_path}"
        for attempt in range(1, 3):
            logger.info(
                "Lyrics lookup attempt %s/2 for %s - %s (url=%s).",
                attempt,
                artist,
                title,
                url,
            )
            try:
                response = await client.get(url)
            except httpx.HTTPError:
                logger.warning(
                    "Lyrics request failed for %s - %s (attempt %s/2).",
                    artist,
                    title,
                    attempt,
                )
                continue

            if response.status_code != 200:
                logger.info(
                    "Lyrics response status %s for %s - %s (attempt %s/2).",
                    response.status_code,
                    artist,
                    title,
                    attempt,
                )
                continue

            data = response.json()
            raw_lyrics = data.get("lyrics", "")
            if not raw_lyrics:
                logger.info(
                    "Lyrics response empty for %s - %s (attempt %s/2).",
                    artist,
                    title,
                    attempt,
                )
                continue

            # Cleanup: API sometimes returns "Paroles de la chanson..." headers
            clean_lyrics = raw_lyrics.replace(f"Paroles de la chanson {title}", "").strip()
            if clean_lyrics:
                logger.info("Lyrics found for %s - %s.", artist, title)
                break
            logger.info("Lyrics cleanup produced empty text for %s - %s.", artist, title)
        if clean_lyrics:
            break

    if not clean_lyrics:
        logger.error("Lyrics provider failed after multiple tracks.")
        raise HTTPException(status_code=503, detail="Could not fetch lyrics provider.")

    blanks_metadata = []
    lyrics_answers = []
    lyrics_for_round = clean_lyrics

    if mode == "lyrics":
        if len(lyrics_for_round) > 500:
            lyrics_for_round = lyrics_for_round[:500].rsplit(" ", 1)[0]
        mask_ratio = 0.4 if difficulty == "hard" else 0.25
        masked, blanks_metadata, lyrics_answers = mask_text_with_blanks(
            lyrics_for_round,
            mask_ratio=mask_ratio,
        )
        hint_length = 0
    else:
        if difficulty == "hard":
            masked = mask_text(clean_lyrics, mask_ratio=0.4)
        else:
            masked = clean_lyrics
        hint_length = len(artist) if mode == "artist" else len(title)

    game_token = create_game_token(
        {
            "artist": artist,
            "title": title,
            "round_type": mode,
            "difficulty": difficulty,
            "lyrics_answers": lyrics_answers,
        }
    )

    masked_lyrics = masked
    if mode != "lyrics" and len(masked_lyrics) > 500:
        masked_lyrics = masked_lyrics[:500] + "..."

    return NewRoundResponse(
        game_token=game_token,
        masked_lyrics=masked_lyrics,
        hint_length=hint_length,
        round_type=mode,
        difficulty=difficulty,
        blanks_metadata=blanks_metadata,
        album_cover_url=album_cover,
    )


@router.get("/new", response_model=NewRoundResponse)
async def start_new_round(
    mode: str = Query("artist", pattern="^(artist|track|lyrics|shuffle)$"),
    difficulty: str = Query("easy", pattern="^(easy|hard|random)$"),
) -> NewRoundResponse:
    async with httpx.AsyncClient(timeout=10.0) as client:
        actual_mode = mode if mode != "shuffle" else random.choice(["artist", "track", "lyrics"])
        actual_difficulty = (
            difficulty if difficulty != "random" else random.choice(["easy", "hard"])
        )
        return await _build_round(
            client,
            mode=actual_mode,
            difficulty=actual_difficulty,
        )


@router.get("/queue", response_model=QueueResponse)
async def get_round_queue(
    count: int = Query(7, ge=5, le=10, description="Number of rounds to enqueue."),
    mode: str = Query("artist", pattern="^(artist|track|lyrics|shuffle)$"),
    difficulty: str = Query("easy", pattern="^(easy|hard|random)$"),
) -> QueueResponse:
    async with httpx.AsyncClient(timeout=10.0) as client:
        rounds = []
        attempts = 0
        max_attempts = count * 3
        while len(rounds) < count and attempts < max_attempts:
            attempts += 1
            round_mode = mode if mode != "shuffle" else random.choice(
                ["artist", "track", "lyrics"]
            )
            round_difficulty = (
                difficulty if difficulty != "random" else random.choice(["easy", "hard"])
            )
            try:
                rounds.append(
                    await _build_round(
                        client,
                        mode=round_mode,
                        difficulty=round_difficulty,
                    )
                )
            except HTTPException:
                continue
    return QueueResponse(rounds=rounds)


@router.post("/submit", response_model=GuessResult)
async def submit_guess(request: GuessRequest) -> GuessResult:
    # 1. Decrypt the token to get the real answer
    try:
        data = decode_game_token(request.game_token)
        correct_artist = data["artist"]
        correct_title = data["title"]
        round_type = data.get("round_type", "artist")
        lyrics_answers = data.get("lyrics_answers", [])
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or tampered game token.")

    if request.give_up:
        return GuessResult(
            is_correct=False,
            correct_artist=correct_artist,
            correct_title=correct_title,
            match_score=0,
            message="The answer was:",
            round_type=round_type,
            correct_words=lyrics_answers if round_type == "lyrics" else [],
        )

    if round_type in {"artist", "track"}:
        guess = request.user_guess
        if not isinstance(guess, str):
            raise HTTPException(status_code=400, detail="Guess must be a string.")

        correct_answer = correct_artist if round_type == "artist" else correct_title
        score = fuzz.ratio(guess.lower(), correct_answer.lower())
        is_correct = score > 80  # 80% similarity threshold

        if is_correct:
            message = "Correct!"
        elif score > 60:
            message = "So close!"
        else:
            message = "Wrong."
        correct_words = []
    else:
        if not isinstance(request.user_guess, list):
            raise HTTPException(
                status_code=400,
                detail="Guess must be a list of words for lyrics mode.",
            )
        guesses = [word.strip() for word in request.user_guess]
        answers = [word.strip() for word in lyrics_answers]
        if not answers:
            raise HTTPException(
                status_code=400,
                detail="Lyrics answers were not found in token.",
            )
        if len(guesses) != len(answers):
            raise HTTPException(
                status_code=400,
                detail="Guess count does not match blanks count.",
            )

        matches = sum(
            1
            for guess, answer in zip(guesses, answers)
            if guess.lower() == answer.lower()
        )
        score = int((matches / len(answers)) * 100)
        is_correct = score == 100
        correct_words = answers

        if is_correct:
            message = "Perfect!"
        elif score >= 60:
            message = "So close!"
        else:
            message = "Keep trying!"

    return GuessResult(
        is_correct=is_correct,
        correct_artist=correct_artist,
        correct_title=correct_title,
        match_score=score,
        message=message,
        round_type=round_type,
        correct_words=correct_words,
    )
