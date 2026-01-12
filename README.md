# Lyrics Guesser Mini Game

A full-stack cross-platform game where players test their musical knowledge by guessing artists, track titles, or filling in missing lyrics. The project features a robust Python FastAPI backend that dynamically sources songs from external music APIs and a polished Flutter frontend for mobile and web.

## 🚀 Features

* **Multiple Game Modes:**
* **Guess the Artist:** Identify the artist based on a snippet of lyrics.
* **Guess the Track:** Name the song title from the provided lyrics.
* **Fill the Lyrics:** Complete the missing words in a line of lyrics.
* **Shuffle Mode:** A random mix of all game modes.


* **Dynamic Content:** Real-time fetching of trending and top songs using **Deezer** and **iTunes** APIs.
* **Lyrics Integration:** Lyrics retrieval via the **Lyrics.ovh** API.
* **Difficulty Levels:**
* **Easy:** Standard masking for lyrics; lenient fuzzy matching.
* **Hard:** Higher percentage of masked lyrics.
* **Random:** Unpredictable difficulty.


* **Smart Scoring:** Uses **Fuzzy Matching** (via `thefuzz`) to accept close spellings for artist and track names.
* **Secure Gameplay:** Game state is secured using signed tokens (JWT-like implementation with `itsdangerous`) to prevent client-side cheating.

## 🛠️ Tech Stack

### Backend

* **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Python 3.14+)
* **Dependency Management:** [Poetry](https://python-poetry.org/)
* **Key Libraries:**
* `httpx`: For asynchronous external API requests.
* `thefuzz`: For fuzzy string matching on user guesses.
* `itsdangerous`: For cryptographically signing game tokens.
* `uvicorn`: ASGI server implementation.



### Frontend

* **Framework:** [Flutter](https://flutter.dev/) (Dart 3.9+)
* **State Management:** [Bloc / Flutter Bloc](https://pub.dev/packages/flutter_bloc)
* **Networking:** `http` and `dio`
* **Design:** Material 3 with `google_fonts`.

## 📂 Project Structure

```text
.
├── backend/
│   ├── app/
│   │   ├── api/v1/         # API Route definitions
│   │   ├── core/           # Config, Security, and API clients (Deezer, iTunes)
│   │   ├── models/         # Pydantic models (implied)
│   │   └── main.py         # Application entry point
│   └── pyproject.toml      # Backend dependencies and config
├── frontend/
│   ├── lib/
│   │   ├── bloc/           # Game state management (Bloc pattern)
│   │   ├── models/         # Data models (GameMode, GameDifficulty)
│   │   ├── networking/     # API services
│   │   ├── screens/        # UI Screens (Home, Game)
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml        # Frontend dependencies
└── README.md

```

## ⚡ Getting Started

### Prerequisites

* Python 3.14 or higher
* Flutter SDK (v3.29.0 or compatible)
* Poetry (for Python dependency management)

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend

```


2. Install dependencies:
```bash
poetry install

```


3. Run the server:
```bash
poetry run uvicorn app.main:app --reload

```


The API will be available at `http://127.0.0.1:8000`. You can view the automatic documentation at `http://127.0.0.1:8000/docs`.

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend

```


2. Install Flutter dependencies:
```bash
flutter pub get

```


3. Run the application:
```bash
flutter run

```



## 📡 API Endpoints

The backend exposes several endpoints under the `/api/game` prefix:

* **GET** `/api/game/new`: Starts a single new game round.
* **Params:** `mode` (artist, track, lyrics, shuffle), `difficulty` (easy, hard, random).
* **Returns:** A secure `game_token`, masked lyrics, and hint metadata.


* **GET** `/api/game/queue`: Fetches a queue of multiple rounds (useful for continuous play).
* **POST** `/api/game/submit`: Submits a user's guess.
* **Body:** `game_token`, `user_guess`.
* **Returns:** Success status, score, correct answer, and updated game state.



## 🛡️ Security

The application uses a stateless security model. When a game round is created, the correct answer is embedded into a cryptographically signed token (`game_token`) sent to the client. When the client submits a guess, they must return this token. The backend verifies the signature and decodes the token to check the answer, ensuring users cannot simply inspect network traffic to find the solution.

## 📄 License

MIT License