class NewRoundResponse {
  final String gameToken;
  final String maskedLyrics;
  final int hintLength;

  NewRoundResponse({
    required this.gameToken,
    required this.maskedLyrics,
    required this.hintLength,
  });

  factory NewRoundResponse.fromJson(Map<String, dynamic> json) {
    return NewRoundResponse(
      gameToken: json['game_token'] as String,
      maskedLyrics: json['masked_lyrics'] as String,
      hintLength: json['hint_length'] as int,
    );
  }
}

