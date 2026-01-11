import logging
import random
from typing import Any

import httpx

logger = logging.getLogger(__name__)


async def _get_payload(client: httpx.AsyncClient, url: str) -> dict[str, Any] | None:
    logger.info("iTunes request: %s", url)
    try:
        response = await client.get(url)
    except httpx.HTTPError:
        logger.warning("iTunes request failed: %s", url)
        return None

    if response.status_code != 200:
        logger.info("iTunes response status %s for %s", response.status_code, url)
        return None

    payload = response.json()
    if isinstance(payload, dict):
        return payload
    return None


def _extract_top_songs(payload: dict[str, Any]) -> list[dict[str, Any]]:
    feed = payload.get("feed", {})
    if not isinstance(feed, dict):
        return []
    entries = feed.get("entry", [])
    if isinstance(entries, list):
        return entries
    if isinstance(entries, dict):
        return [entries]
    return []


def _pick_track(entries: list[dict[str, Any]]) -> dict[str, str] | None:
    if not entries:
        return None
    selection = random.choice(entries)
    title = selection.get("im:name", {}).get("label")
    artist = selection.get("im:artist", {}).get("label")
    if not artist or not title:
        return None
    logger.info("iTunes candidate picked: %s - %s", artist, title)
    return {"artist": artist, "title": title}


async def get_top_song() -> dict[str, str] | None:
    async with httpx.AsyncClient(timeout=10.0) as client:
        payload = await _get_payload(
            client,
            "https://itunes.apple.com/us/rss/topsongs/limit=100/json",
        )
        if not payload:
            return None
        entries = _extract_top_songs(payload)
        return _pick_track(entries)
