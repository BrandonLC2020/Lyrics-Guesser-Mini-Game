import logging
from urllib.parse import quote

import httpx
from fastapi import APIRouter, HTTPException, Query
from thefuzz import fuzz

from app.core.song_picker import get_random_song
from app.core.security import create_game_token, decode_game_token
from app.core.utils import mask_text
from app.schemas.game import GuessRequest, GuessResult, NewRoundResponse, QueueResponse

router = APIRouter(prefix="/game", tags=["game"])
logger = logging.getLogger(__name__)


async def _build_round(client: httpx.AsyncClient) -> NewRoundResponse:
    clean_lyrics = ""
    artist = ""
    title = ""

    for _ in range(12):
        logger.info("Selecting a new track for lyrics lookup.")
        selection = await get_random_song()
        artist = selection["artist"]
        title = selection["title"]

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

    masked = mask_text(clean_lyrics, mask_ratio=0.4)
    game_token = create_game_token({"artist": artist, "title": title})

    return NewRoundResponse(
        game_token=game_token,
        masked_lyrics=masked[:500] + "..." if len(masked) > 500 else masked,
        hint_length=len(artist),
    )


@router.get("/new", response_model=NewRoundResponse)
async def start_new_round() -> NewRoundResponse:
    async with httpx.AsyncClient(timeout=10.0) as client:
        return await _build_round(client)


@router.get("/queue", response_model=QueueResponse)
async def get_round_queue(
    count: int = Query(7, ge=5, le=10, description="Number of rounds to enqueue."),
) -> QueueResponse:
    async with httpx.AsyncClient(timeout=10.0) as client:
        rounds = [await _build_round(client) for _ in range(count)]
    return QueueResponse(rounds=rounds)


@router.post("/submit", response_model=GuessResult)
async def submit_guess(request: GuessRequest) -> GuessResult:
    # 1. Decrypt the token to get the real answer
    try:
        data = decode_game_token(request.game_token)
        correct_artist = data["artist"]
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid or tampered game token.")

    # 2. Fuzzy Match Logic
    # ratio compares strings ignoring case/punctuation differences
    # e.g. "shawn mendez" vs "Shawn Mendes" -> High score
    score = fuzz.ratio(request.user_guess.lower(), correct_artist.lower())

    # 3. Determine Win/Loss logic
    is_correct = score > 80  # 80% similarity threshold

    if is_correct:
        message = "Correct!"
    elif score > 60:
        message = "So close!"
    else:
        message = "Wrong."

    return GuessResult(
        is_correct=is_correct,
        correct_artist=correct_artist,
        match_score=score,
        message=message,
    )
