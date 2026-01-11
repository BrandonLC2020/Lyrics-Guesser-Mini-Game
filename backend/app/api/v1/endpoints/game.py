import random

import httpx
from fastapi import APIRouter, HTTPException
from thefuzz import fuzz

from app.core.config import SONG_DATABASE
from app.core.security import create_game_token, decode_game_token
from app.core.utils import mask_text
from app.schemas.game import GuessRequest, GuessResult, NewRoundResponse

router = APIRouter(prefix="/game", tags=["game"])


@router.get("/new", response_model=NewRoundResponse)
async def start_new_round() -> NewRoundResponse:
    # 1. Pick a random song
    selection = random.choice(SONG_DATABASE)
    artist = selection["artist"]
    title = selection["title"]

    # 2. Fetch Lyrics from Lyrics.ovh
    # Using AsyncClient ensures the server doesn't freeze while waiting for lyrics
    async with httpx.AsyncClient() as client:
        url = f"https://api.lyrics.ovh/v1/{artist}/{title}"
        response = await client.get(url)

        if response.status_code != 200:
            print(f"Error fetching lyrics for {artist} - {title}")
            raise HTTPException(status_code=503, detail="Could not fetch lyrics provider.")

        data = response.json()
        raw_lyrics = data.get("lyrics", "")

        # Cleanup: API sometimes returns "Paroles de la chanson..." headers
        clean_lyrics = raw_lyrics.replace(f"Paroles de la chanson {title}", "").strip()

    # 3. Mask the lyrics
    masked = mask_text(clean_lyrics, mask_ratio=0.4)

    # 4. Create a secure token containing the correct answer
    # This keeps the server stateless (no database needed)
    game_token = create_game_token({"artist": artist, "title": title})

    return NewRoundResponse(
        game_token=game_token,
        # Send only the first 500 chars to keep the UI clean
        masked_lyrics=masked[:500] + "..." if len(masked) > 500 else masked,
        hint_length=len(artist),
    )


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
