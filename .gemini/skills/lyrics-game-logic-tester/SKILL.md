---
name: lyrics-game-logic-tester
description: Validates game mechanics including lyrics masking and scoring logic. Use when adjusting difficulty levels, fuzzy matching thresholds, or masking algorithms.
---

# Lyrics Game Logic Tester

This skill provides tools to verify the core game mechanics of the Lyrics Guesser.

## Key Components

- **Masking**: `mask_text` (replaces random words with asterisks) and `mask_text_with_blanks` (uses `[BLANK_n]` placeholders).
- **Scoring**: Uses `thefuzz.fuzz.ratio` for artist/track (threshold > 80) and exact matching for blanks in lyrics mode.

## Workflow

1.  **Test Masking**: Use `scripts/test_logic.py` to simulate masking on sample lyrics. Ensure punctuation and newlines are preserved.
2.  **Verify Scoring**: Run fuzzy match simulations to check if common artist name variations (e.g., "Adele" vs "adele") pass correctly.
3.  **Balance Check**: Adjust `mask_ratio` in `backend/app/core/utils.py` and verify impact on readability using the test script.

## Test Script Usage

```bash
# From the project root
export PYTHONPATH=$PYTHONPATH:$(pwd)/backend
python3 skills/lyrics-game-logic-tester/scripts/test_logic.py --text "Sample lyrics here" --mode lyrics
```
