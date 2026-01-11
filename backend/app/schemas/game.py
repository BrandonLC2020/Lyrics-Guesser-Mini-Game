from typing import Union

from pydantic import BaseModel, Field


class BlankMetadata(BaseModel):
    key: str
    length: int


class NewRoundResponse(BaseModel):
    game_token: str       # Encrypted token containing the answer
    masked_lyrics: str    # The lyrics with words hidden
    hint_length: int      # Length of the artist name (e.g. 5 for "Adele")
    round_type: str       # artist, track, lyrics
    difficulty: str       # easy, hard
    blanks_metadata: list[BlankMetadata] = Field(default_factory=list)
    album_cover_url: str | None = None  # URL to the album cover art


class QueueResponse(BaseModel):
    rounds: list[NewRoundResponse]


class GuessRequest(BaseModel):
    game_token: str
    user_guess: Union[str, list[str]]
    give_up: bool = False


class GuessResult(BaseModel):
    is_correct: bool
    correct_artist: str
    correct_title: str
    match_score: int      # 0 to 100 similarity score
    message: str          # Feedback message ("Correct!", "So close!", etc.)
    round_type: str
    correct_words: list[str] = Field(default_factory=list)
