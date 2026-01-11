import 'new_round_response.dart';

class QueueResponse {
  final List<NewRoundResponse> rounds;

  QueueResponse({required this.rounds});

  factory QueueResponse.fromJson(Map<String, dynamic> json) {
    final roundsJson = json['rounds'] as List<dynamic>? ?? [];
    return QueueResponse(
      rounds: roundsJson
          .map((item) => NewRoundResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
