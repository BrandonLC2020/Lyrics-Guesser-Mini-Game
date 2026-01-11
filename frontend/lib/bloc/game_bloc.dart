import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../networking/api/game_api.dart';
import '../networking/dto/new_round_response.dart';
import '../networking/dto/guess_result.dart';

part 'game_event.dart';
part 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final GameApi _api;
  NewRoundResponse? _currentRound;
  List<NewRoundResponse> _queue = [];
  bool _isRefilling = false;

  GameBloc(this._api) : super(GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<NewRoundStarted>(_onNewRoundStarted);
    on<QueueRefillRequested>(_onQueueRefillRequested);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading());
    try {
      final response = await _api.fetchRoundQueue();
      _queue = List<NewRoundResponse>.from(response.rounds);
      if (_queue.isEmpty) {
        emit(const GameError('Queue returned no rounds.'));
        return;
      }
      _currentRound = _queue.removeAt(0);
      emit(GameLoaded(_currentRound!));
      if (_queue.length <= 3) {
        add(const QueueRefillRequested());
      }
    } catch (e) {
      emit(GameError('Error loading round: $e'));
    }
  }

  Future<void> _onGuessSubmitted(
    GuessSubmitted event,
    Emitter<GameState> emit,
  ) async {
    if (_currentRound == null) return;

    emit(GameLoading());
    try {
      final result = await _api.submitGuess(
        _currentRound!.gameToken,
        event.guess,
      );
      emit(GameGuessSubmitted(result, _currentRound!));
    } catch (e) {
      emit(GameError('Error submitting guess: $e'));
    }
  }

  Future<void> _onNewRoundStarted(
    NewRoundStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading());
    try {
      if (_queue.isEmpty) {
        final response = await _api.fetchRoundQueue();
        _queue = List<NewRoundResponse>.from(response.rounds);
      }
      if (_queue.isEmpty) {
        emit(const GameError('Queue returned no rounds.'));
        return;
      }
      _currentRound = _queue.removeAt(0);
      emit(GameLoaded(_currentRound!));
      if (_queue.length <= 3) {
        add(const QueueRefillRequested());
      }
    } catch (e) {
      emit(GameError('Error loading round: $e'));
    }
  }

  Future<void> _onQueueRefillRequested(
    QueueRefillRequested event,
    Emitter<GameState> emit,
  ) async {
    if (_isRefilling) return;
    _isRefilling = true;
    try {
      final response = await _api.fetchRoundQueue();
      _queue = List<NewRoundResponse>.from(_queue)..addAll(response.rounds);
    } catch (_) {
      // Keep current gameplay intact even if the background refill fails.
    } finally {
      _isRefilling = false;
    }
  }
}
