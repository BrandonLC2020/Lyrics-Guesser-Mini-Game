---
name: mock-music-provider
description: Provides mock data and utilities for simulating music API responses (Deezer, iTunes). Use for offline testing, CI/CD, or when external APIs are rate-limited.
---

# Mock Music Provider

This skill helps simulate responses from external music APIs used by the backend.

## Resources

- **Deezer Mocks**: `assets/mocks/deezer_chart.json`
- **iTunes Mocks**: `assets/mocks/itunes_top.json`

## Workflow

1.  **Local Testing**: Replace the API calls in `backend/app/core/deezer.py` or `itunes.py` with logic that reads from these mock files.
2.  **Schema Validation**: Ensure any changes to the expected JSON structure in the code are reflected in these mock files.
3.  **Edge Cases**: Use the mock files to simulate empty responses, malformed JSON, or missing fields by editing the local copies during a task.

## Example Mock Structure (Deezer)

```json
{
  "tracks": {
    "data": [
      {
        "title": "Rolling in the Deep",
        "artist": { "name": "Adele" },
        "album": { "cover_medium": "https://..." }
      }
    ]
  }
}
```
