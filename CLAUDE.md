# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Full-stack lyrics guessing game: Flutter frontend + Python FastAPI backend + AWS infrastructure (Terraform/SAM). Players are given masked lyrics/hints and must guess the artist, title, or fill-in-the-blank words.

## Commands

### Backend (Python/FastAPI)
```bash
cd backend
poetry install                                          # install dependencies
poetry run uvicorn app.main:app --reload               # run dev server (http://localhost:8000)
# API docs available at http://localhost:8000/docs
```

### Frontend (Flutter)
```bash
cd frontend
flutter pub get   # install dependencies
flutter run       # run on connected device/emulator
flutter build     # build for target platform
```

### Infrastructure
```bash
cd infra
terraform init    # initialize
terraform plan    # preview changes
terraform apply   # deploy to AWS
```

## Architecture

### Data Flow
1. Frontend fetches a **queue of 7 rounds** on startup from `GET /api/game/queue`
2. User selects game mode and difficulty on `HomeScreen`
3. `GameBloc` pops the next round from the queue and displays masked content
4. User submits guess → `POST /api/game/submit` with an encrypted `game_token`
5. Backend decrypts token (contains answer), validates guess, returns score
6. Queue refills in the background when ≤3 rounds remain

### Backend (`backend/`)
- **`app/main.py`** — FastAPI app entry point; also exposes `handler` (Mangum) for AWS Lambda
- **`app/api/v1/endpoints/game.py`** — Three endpoints: `/new`, `/queue`, `/submit`
- **`app/core/deezer.py`** — Multi-strategy song fetching from Deezer API with weighted random selection
- **`app/core/song_picker.py`** — Deduplication logic to prevent repeat songs within a session
- **`app/core/security.py`** — `itsdangerous` URLSafeSerializer; game state (answers) is stored in the encrypted client token, not server-side
- **`app/core/utils.py`** — Lyrics masking: 40% of words replaced with blanks on hard difficulty
- **`app/schemas/game.py`** — Pydantic models for all request/response types

**Matching logic:** Artist/track guesses use `thefuzz` fuzzy matching (>80% threshold). Lyrics fill-in-the-blank requires exact word matches.

**No database** — song metadata is fetched from Deezer/iTunes public APIs at runtime.

### Frontend (`frontend/lib/`)
- **`bloc/game_bloc.dart`** — Central state machine. Events: `GameStarted`, `GameModeSelected`, `GuessSubmitted`, `GameGiveUp`, `NewRoundStarted`, `QueueRefillRequested`. States: `GameInitial`, `GameLoading`, `GameLoaded`, `GameGuessSubmitted`, `GameError`
- **`networking/api/game_api.dart`** — API calls wrapping Dio
- **`networking/extensions/dio_client.dart`** — Base URL configuration (change here for local vs. deployed backend)
- **`screens/home_screen.dart`** — Mode/difficulty selection
- **`screens/game_screen.dart`** — Gameplay UI

### Infrastructure (`infra/`)
Two parallel deployment strategies exist:
- **SAM (`backend/template.yaml`)** — Preferred serverless approach: Docker container Lambda + API Gateway
- **Terraform (`infra/`)** — S3 (frontend assets) + EC2 (backend server)

## Key Configuration

**Backend env var:** `SECRET_KEY` — used to sign game tokens. Defaults to a hardcoded dev value if unset.

**Game modes:** `artist`, `track`, `lyrics`, `shuffle`

**Difficulties:** `easy` (no masking), `hard` (40% masked), `random`

## API Contract

```
GET  /api/game/new?mode=&difficulty=       → NewRoundResponse
GET  /api/game/queue?count=7&mode=&difficulty=  → list[NewRoundResponse]
POST /api/game/submit  { game_token, user_guess, give_up }  → GuessResult
```
