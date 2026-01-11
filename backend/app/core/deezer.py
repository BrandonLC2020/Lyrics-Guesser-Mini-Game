import logging
import random
from collections import deque
from typing import Any

import httpx

from app.core.config import SONG_DATABASE

_RECENT_TRACKS_MAX = 50
_recent_track_keys: deque[str] = deque()
_recent_track_set: set[str] = set()
logger = logging.getLogger(__name__)


async def _get_payload(client: httpx.AsyncClient, url: str) -> dict[str, Any] | None:
    logger.info("Deezer request: %s", url)
    try:
        response = await client.get(url)
    except httpx.HTTPError:
        logger.warning("Deezer request failed: %s", url)
        return None

    if response.status_code != 200:
        logger.info("Deezer response status %s for %s", response.status_code, url)
        return None

    payload = response.json()
    if isinstance(payload, dict):
        return payload
    return None


async def _get_data(client: httpx.AsyncClient, url: str) -> list[dict[str, Any]]:
    payload = await _get_payload(client, url)
    if not payload:
        return []
    data = payload.get("data", [])
    if isinstance(data, list):
        return data
    return []


def _extract_chart_tracks(payload: dict[str, Any]) -> list[dict[str, Any]]:
    tracks = payload.get("tracks", {})
    if isinstance(tracks, dict):
        data = tracks.get("data", [])
        if isinstance(data, list):
            return data
    return []


def _pick_track(tracks: list[dict[str, Any]]) -> dict[str, str] | None:
    if not tracks:
        return None

    selection = random.choice(tracks)
    artist = selection.get("artist", {}).get("name")
    title = selection.get("title")
    if not artist or not title:
        return None
    logger.info("Deezer candidate picked: %s - %s", artist, title)
    return {"artist": artist, "title": title}


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


async def _get_song_from_radio(client: httpx.AsyncClient) -> dict[str, str] | None:
    radios = await _get_data(client, "https://api.deezer.com/radio")
    if not radios:
        return None

    radio_id = random.choice(radios).get("id")
    if not radio_id:
        return None
    logger.info("Deezer radio selected: %s", radio_id)

    tracks = await _get_data(client, f"https://api.deezer.com/radio/{radio_id}/tracks")
    return _pick_track(tracks)


async def _get_song_from_genre_chart(client: httpx.AsyncClient) -> dict[str, str] | None:
    genres = await _get_data(client, "https://api.deezer.com/genre")
    if not genres:
        return None

    valid_genres = [genre for genre in genres if genre.get("id") not in (None, 0)]
    if not valid_genres:
        return None

    genre_id = random.choice(valid_genres).get("id")
    if not genre_id:
        return None
    logger.info("Deezer genre selected: %s", genre_id)

    tracks = await _get_data(client, f"https://api.deezer.com/chart/{genre_id}/tracks")
    return _pick_track(tracks)


async def _get_song_from_global_chart(client: httpx.AsyncClient) -> dict[str, str] | None:
    payload = await _get_payload(client, "https://api.deezer.com/chart?limit=50")
    if not payload:
        return None
    tracks = _extract_chart_tracks(payload)
    return _pick_track(tracks)


async def _get_song_from_editorial_chart(client: httpx.AsyncClient) -> dict[str, str] | None:
    editorials = await _get_data(client, "https://api.deezer.com/editorial")
    if not editorials:
        return None

    valid_editorials = [editorial for editorial in editorials if editorial.get("id") not in (None, 0)]
    if not valid_editorials:
        return None

    editorial_id = random.choice(valid_editorials).get("id")
    if not editorial_id:
        return None
    logger.info("Deezer editorial selected: %s", editorial_id)

    payload = await _get_payload(client, f"https://api.deezer.com/editorial/{editorial_id}/charts")
    if not payload:
        return None
    tracks = _extract_chart_tracks(payload)
    return _pick_track(tracks)


async def _get_song_from_artist_top(client: httpx.AsyncClient) -> dict[str, str] | None:
    payload = await _get_payload(client, "https://api.deezer.com/chart?limit=50")
    if not payload:
        return None
    chart_tracks = _extract_chart_tracks(payload)
    if not chart_tracks:
        return None

    artist = random.choice(chart_tracks).get("artist", {})
    artist_id = artist.get("id")
    if not artist_id:
        return None
    logger.info("Deezer artist selected for top tracks: %s", artist_id)

    top_tracks = await _get_data(client, f"https://api.deezer.com/artist/{artist_id}/top?limit=50")
    return _pick_track(top_tracks)


async def get_random_song(max_attempts: int = 6) -> dict[str, str]:
    async with httpx.AsyncClient(timeout=10.0) as client:
        attempts = 0
        fetchers = [
            (_get_song_from_global_chart, 10),
            (_get_song_from_editorial_chart, 40),
            (_get_song_from_artist_top, 20),
            (_get_song_from_genre_chart, 15),
            (_get_song_from_radio, 15),
        ]

        while attempts < max_attempts:
            attempts += 1
            logger.info("Deezer fetch attempt %s/%s", attempts, max_attempts)
            fetcher = random.choices(
                [fetcher for fetcher, _ in fetchers],
                weights=[weight for _, weight in fetchers],
                k=1,
            )[0]
            logger.info("Deezer fetcher: %s", fetcher.__name__)
            song = await fetcher(client)
            if not song:
                continue
            if _is_recent(song):
                logger.info("Deezer track skipped (recent): %s - %s", song["artist"], song["title"])
                continue
            _mark_recent(song)
            logger.info("Deezer track selected: %s - %s", song["artist"], song["title"])
            return song

    fallback_pool = [song for song in SONG_DATABASE if not _is_recent(song)]
    if not fallback_pool:
        fallback_pool = SONG_DATABASE
    selection = random.choice(fallback_pool)
    _mark_recent(selection)
    logger.info("Fallback track selected: %s - %s", selection["artist"], selection["title"])
    return selection
