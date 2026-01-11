enum GameMode { artist, track, lyrics }

enum GameDifficulty { easy, hard }

GameMode parseGameMode(String value) {
  return switch (value) {
    'track' => GameMode.track,
    'lyrics' => GameMode.lyrics,
    _ => GameMode.artist,
  };
}

GameDifficulty parseGameDifficulty(String value) {
  return switch (value) {
    'hard' => GameDifficulty.hard,
    _ => GameDifficulty.easy,
  };
}

extension GameModeLabel on GameMode {
  String get apiValue => switch (this) {
        GameMode.artist => 'artist',
        GameMode.track => 'track',
        GameMode.lyrics => 'lyrics',
      };

  String get title => switch (this) {
        GameMode.artist => 'Guess the Artist',
        GameMode.track => 'Guess the Track',
        GameMode.lyrics => 'Fill the Lyrics',
      };
}

extension GameDifficultyLabel on GameDifficulty {
  String get apiValue => switch (this) {
        GameDifficulty.easy => 'easy',
        GameDifficulty.hard => 'hard',
      };

  String get label => switch (this) {
        GameDifficulty.easy => 'Easy',
        GameDifficulty.hard => 'Hard',
      };
}
