# Lyrics Guesser Mini Game - Project Overview

This project is a full-stack mini-game where users guess song titles, artists, or missing lyrics from snippets. It features a FastAPI-based Python backend and a Flutter-based mobile/web frontend.

## Project Structure

- `backend/`: FastAPI application providing the game logic and external API integrations.
- `frontend/`: Flutter application using BLoC for state management and Dio for networking.

## Backend (Python/FastAPI)

### Technologies
- **Python**: 3.14+
- **FastAPI**: Web framework for the API.
- **Poetry**: Dependency management.
- **Httpx**: For asynchronous HTTP requests to external APIs.
- **TheFuzz**: For fuzzy string matching of user guesses.
- **ItsDangerous**: For secure token generation (storing game state on the client).

### Key APIs Integrated
- **Deezer API**: Used to fetch random track information.
- **iTunes Search API**: Alternative source for track information.
- **Lyrics.ovh**: Used to fetch song lyrics.

### Main Endpoints
- `GET /api/game/new`: Starts a single new round.
- `GET /api/game/queue`: Fetches a queue of multiple rounds for smoother gameplay.
- `POST /api/game/submit`: Submits a user guess and returns the result (is_correct, score, etc.).

### Development Commands
```bash
cd backend
# Install dependencies
poetry install
# Run the development server
poetry run uvicorn app.main:app --reload
```

---

## Frontend (Flutter)

### Technologies
- **Flutter**: UI toolkit for building natively compiled applications.
- **Dart**: Programming language.
- **BLoC (flutter_bloc)**: State management for handling game flow and API interactions.
- **Dio**: HTTP client for API communication.
- **Google Fonts**: Custom typography.

### Architecture
- **Models**: Defines game modes, difficulties, and API response structures (DTOs).
- **Networking**: `GameApi` handles communication with the backend.
- **BLoC**: `GameBloc` manages game states (Initial, Loading, Loaded, GuessSubmitted, Error).
- **Screens**: `HomeScreen` for mode selection, `GameScreen` for interactive gameplay.

### Development Commands
```bash
cd frontend
# Install dependencies
flutter pub get
# Run the application
flutter run
```

---

## Game Mechanics

1.  **Game Modes**:
    - `artist`: Guess the artist of the song.
    - `track`: Guess the song title.
    - `lyrics`: Fill in the blanks for missing words in the lyrics.
    - `shuffle`: Randomly selects one of the above modes for each round.
2.  **Difficulties**:
    - `easy`: Standard masking/hinting.
    - `hard`: More aggressive masking (more blanks or masked characters).
3.  **Scoring**:
    - Uses fuzzy matching (threshold > 80% for artist/track) or exact word matching for lyrics blanks.
