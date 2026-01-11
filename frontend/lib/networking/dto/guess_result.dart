class GuessResult {
  final bool isCorrect;
  final String correctArtist;
  final String correctTitle;
  final int matchScore;
  final String message;
  final String roundType;
  final List<String> correctWords;

  GuessResult({
    required this.isCorrect,
    required this.correctArtist,
    required this.correctTitle,
    required this.matchScore,
    required this.message,
    required this.roundType,
    required this.correctWords,
  });

  factory GuessResult.fromJson(Map<String, dynamic> json) {
    final wordsJson = json['correct_words'] as List<dynamic>? ?? [];
    return GuessResult(
      isCorrect: json['is_correct'] as bool,
      correctArtist: json['correct_artist'] as String,
      correctTitle: json['correct_title'] as String? ?? '',
      matchScore: json['match_score'] as int,
      message: json['message'] as String,
      roundType: json['round_type'] as String? ?? 'artist',
      correctWords: wordsJson.map((word) => word as String).toList(),
    );
  }
}
