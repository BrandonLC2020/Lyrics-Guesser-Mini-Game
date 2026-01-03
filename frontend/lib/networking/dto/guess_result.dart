class GuessResult {
  final bool isCorrect;
  final String correctArtist;
  final int matchScore;
  final String message;

  GuessResult({
    required this.isCorrect,
    required this.correctArtist,
    required this.matchScore,
    required this.message,
  });

  factory GuessResult.fromJson(Map<String, dynamic> json) {
    return GuessResult(
      isCorrect: json['is_correct'] as bool,
      correctArtist: json['correct_artist'] as String,
      matchScore: json['match_score'] as int,
      message: json['message'] as String,
    );
  }
}

