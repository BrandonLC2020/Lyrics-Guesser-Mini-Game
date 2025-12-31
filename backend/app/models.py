from pydantic import BaseModel

class NewRoundResponse(BaseModel):
    game_token: str       # Encrypted token containing the answer
    masked_lyrics: str    # The lyrics with words hidden
    hint_length: int      # Length of the artist name (e.g. 5 for "Adele")

class GuessRequest(BaseModel):
    game_token: str
    user_guess: str

class GuessResult(BaseModel):
    is_correct: bool
    correct_artist: str
    match_score: int      # 0 to 100 similarity score
    message: str          # Feedback message ("Correct!", "So close!", etc.)