class NewRoundResponse {
  final String gameToken;
  final String maskedLyrics;
  final int hintLength;
  final String roundType;
  final String difficulty;
  final List<BlankMetadata> blanksMetadata;

  NewRoundResponse({
    required this.gameToken,
    required this.maskedLyrics,
    required this.hintLength,
    required this.roundType,
    required this.difficulty,
    required this.blanksMetadata,
  });

  factory NewRoundResponse.fromJson(Map<String, dynamic> json) {
    final blanksJson = json['blanks_metadata'] as List<dynamic>? ?? [];
    return NewRoundResponse(
      gameToken: json['game_token'] as String,
      maskedLyrics: json['masked_lyrics'] as String,
      hintLength: json['hint_length'] as int,
      roundType: json['round_type'] as String? ?? 'artist',
      difficulty: json['difficulty'] as String? ?? 'easy',
      blanksMetadata: blanksJson
          .map((item) => BlankMetadata.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BlankMetadata {
  final String key;
  final int length;

  BlankMetadata({required this.key, required this.length});

  factory BlankMetadata.fromJson(Map<String, dynamic> json) {
    return BlankMetadata(
      key: json['key'] as String,
      length: json['length'] as int,
    );
  }
}
