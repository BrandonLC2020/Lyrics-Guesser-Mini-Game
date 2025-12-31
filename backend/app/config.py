import os

# In a real production app, you would load this from os.environ
# e.g., SECRET_KEY = os.getenv("SECRET_KEY", "fallback_dev_key")
SECRET_KEY = "super_secret_game_key_for_signing_tokens"

# Hardcoded list to ensure valid Artist/Title pairs for Lyrics.ovh
SONG_DATABASE = [
    {"artist": "Ed Sheeran", "title": "Shape of You"},
    {"artist": "Queen", "title": "Bohemian Rhapsody"},
    {"artist": "Adele", "title": "Hello"},
    {"artist": "Drake", "title": "Hotline Bling"},
    {"artist": "Taylor Swift", "title": "Shake It Off"},
    {"artist": "Eminem", "title": "Lose Yourself"},
    {"artist": "Billie Eilish", "title": "Bad Guy"},
    {"artist": "The Weeknd", "title": "Blinding Lights"},
    {"artist": "Coldplay", "title": "Yellow"},
    {"artist": "Linkin Park", "title": "In the End"},
]