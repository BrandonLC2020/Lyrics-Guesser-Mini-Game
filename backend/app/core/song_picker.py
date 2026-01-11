import logging
import random
from collections import deque

from app.core.config import SONG_DATABASE
from app.core.deezer import get_random_song as get_deezer_song
from app.core.itunes import get_top_song as get_itunes_song

_RECENT_TRACKS_MAX = 50
_recent_track_keys: deque[str] = deque()
_recent_track_set: set[str] = set()
logger = logging.getLogger(__name__)


def _track_key(song: dict[str, str]) -> str:
    artist = song.get("artist", "").strip().lower()
    title = song.get("title", "").strip().lower()
    return f"{artist}::{title}"


def _is_recent(song: dict[str, str]) -> bool:
    return _track_key(song) in _recent_track_set


def _mark_recent(song: dict[str, str]) -> None:
    key = _track_key(song)
    if key in _recent_track_set:
        return
    if len(_recent_track_keys) >= _RECENT_TRACKS_MAX:
        oldest = _recent_track_keys.popleft()
        _recent_track_set.discard(oldest)
    _recent_track_keys.append(key)
    _recent_track_set.add(key)


async def get_random_song(max_attempts: int = 6) -> dict[str, str]:
    providers = [
        (get_deezer_song, 70),
        (get_itunes_song, 30),
    ]

    attempts = 0
    while attempts < max_attempts:
        attempts += 1
        provider = random.choices(
            [provider for provider, _ in providers],
            weights=[weight for _, weight in providers],
            k=1,
        )[0]
        logger.info("Song provider selected: %s", provider.__name__)
        song = await provider()
        if not song:
            continue
        if _is_recent(song):
            logger.info("Track skipped (recent): %s - %s", song["artist"], song["title"])
            continue
        _mark_recent(song)
        logger.info("Track selected: %s - %s", song["artist"], song["title"])
        return song

    fallback_pool = [song for song in SONG_DATABASE if not _is_recent(song)]
    if not fallback_pool:
        fallback_pool = SONG_DATABASE
    selection = random.choice(fallback_pool)
    _mark_recent(selection)
    logger.info("Fallback track selected: %s - %s", selection["artist"], selection["title"])
    return selection
