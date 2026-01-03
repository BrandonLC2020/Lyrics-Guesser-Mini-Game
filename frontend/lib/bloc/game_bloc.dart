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

  GameBloc(this._api) : super(GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<NewRoundStarted>(_onNewRoundStarted);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading());
    try {
      final round = await _api.startNewRound();
      _currentRound = round;
      emit(GameLoaded(round));
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
      final round = await _api.startNewRound();
      _currentRound = round;
      emit(GameLoaded(round));
    } catch (e) {
      emit(GameError('Error loading round: $e'));
    }
  }
}
