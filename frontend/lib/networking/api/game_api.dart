import 'package:dio/dio.dart';
import '../../models/game_mode.dart';
import '../dto/new_round_response.dart';
import '../dto/guess_result.dart';
import '../dto/queue_response.dart';

class GameApi {
  // Update this to match your backend URL
  static const String baseUrl = 'http://localhost:8000';
  
  final Dio _dio;

  GameApi({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: baseUrl));

  Future<NewRoundResponse> startNewRound({
    required GameMode mode,
    required GameDifficulty difficulty,
  }) async {
    final response = await _dio.get(
      '/api/game/new',
      queryParameters: {
        'mode': mode.apiValue,
        'difficulty': difficulty.apiValue,
      },
    );

    // Dio throwsDioException on non-2xx status codes by default,
    // so if we get here, it's a 2xx.
    return NewRoundResponse.fromJson(response.data);
  }

  Future<QueueResponse> fetchRoundQueue({
    int count = 7,
    required GameMode mode,
    required GameDifficulty difficulty,
  }) async {
    final response = await _dio.get(
      '/api/game/queue',
      queryParameters: {
        'count': count,
        'mode': mode.apiValue,
        'difficulty': difficulty.apiValue,
      },
    );

    return QueueResponse.fromJson(response.data);
  }

  Future<GuessResult> submitGuess(
    String gameToken,
    Object userGuess, {
    bool giveUp = false,
  }) async {
    final response = await _dio.post(
      '/api/game/submit',
      data: {
        'game_token': gameToken,
        'user_guess': userGuess,
        'give_up': giveUp,
      },
    );

    return GuessResult.fromJson(response.data);
  }
}
