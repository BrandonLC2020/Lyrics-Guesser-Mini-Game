import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/game_mode.dart';
import '../dto/new_round_response.dart';
import '../dto/guess_result.dart';
import '../dto/queue_response.dart';

class GameApi {
  // Update this to match your backend URL
  static const String baseUrl = 'http://localhost:8000';

  Future<NewRoundResponse> startNewRound({
    required GameMode mode,
    required GameDifficulty difficulty,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/game/new?mode=${mode.apiValue}&difficulty=${difficulty.apiValue}',
      ),
    );

    if (response.statusCode == 200) {
      return NewRoundResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to start new round: ${response.statusCode}');
    }
  }

  Future<QueueResponse> fetchRoundQueue({
    int count = 7,
    required GameMode mode,
    required GameDifficulty difficulty,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/game/queue?count=$count&mode=${mode.apiValue}&difficulty=${difficulty.apiValue}',
      ),
    );

    if (response.statusCode == 200) {
      return QueueResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch queue: ${response.statusCode}');
    }
  }

  Future<GuessResult> submitGuess(String gameToken, Object userGuess) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/game/submit'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'game_token': gameToken,
        'user_guess': userGuess,
      }),
    );

    if (response.statusCode == 200) {
      return GuessResult.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit guess: ${response.statusCode}');
    }
  }
}
