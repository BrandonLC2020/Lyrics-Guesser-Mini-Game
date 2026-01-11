enum GameMode { artist, track, lyrics, shuffle }

enum GameDifficulty { easy, hard, random }

GameMode parseGameMode(String value) {
  return switch (value) {
    'track' => GameMode.track,
    'lyrics' => GameMode.lyrics,
    'shuffle' => GameMode.shuffle,
    _ => GameMode.artist,
  };
}

GameDifficulty parseGameDifficulty(String value) {
  return switch (value) {
    'hard' => GameDifficulty.hard,
    'random' => GameDifficulty.random,
    _ => GameDifficulty.easy,
  };
}

extension GameModeLabel on GameMode {
  String get apiValue => switch (this) {
        GameMode.artist => 'artist',
        GameMode.track => 'track',
        GameMode.lyrics => 'lyrics',
        GameMode.shuffle => 'shuffle',
      };

  String get title => switch (this) {
        GameMode.artist => 'Guess the Artist',
        GameMode.track => 'Guess the Track',
        GameMode.lyrics => 'Fill the Lyrics',
        GameMode.shuffle => 'Shuffle Mode',
      };
}

extension GameDifficultyLabel on GameDifficulty {
  String get apiValue => switch (this) {
        GameDifficulty.easy => 'easy',
        GameDifficulty.hard => 'hard',
        GameDifficulty.random => 'random',
      };

  String get label => switch (this) {
        GameDifficulty.easy => 'Easy',
        GameDifficulty.hard => 'Hard',
        GameDifficulty.random => 'Random',
      };
}
