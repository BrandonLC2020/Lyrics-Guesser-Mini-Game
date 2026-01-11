import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_mode.dart';
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
  GameMode _selectedMode;
  GameDifficulty _selectedDifficulty;

  GameBloc(
    this._api, {
    GameMode initialMode = GameMode.artist,
    GameDifficulty initialDifficulty = GameDifficulty.easy,
  })  : _selectedMode = initialMode,
        _selectedDifficulty = initialDifficulty,
        super(
          GameInitial(
            selectedMode: initialMode,
            selectedDifficulty: initialDifficulty,
          ),
        ) {
    on<GameStarted>(_onGameStarted);
    on<GameModeSelected>(_onGameModeSelected);
    on<GuessSubmitted>(_onGuessSubmitted);
    on<GameGiveUp>(_onGameGiveUp);
    on<NewRoundStarted>(_onNewRoundStarted);
    on<QueueRefillRequested>(_onQueueRefillRequested);
  }

  void _onGameModeSelected(
    GameModeSelected event,
    Emitter<GameState> emit,
  ) {
    _selectedMode = event.mode;
    _selectedDifficulty = event.difficulty;
    emit(
      GameInitial(
        selectedMode: _selectedMode,
        selectedDifficulty: _selectedDifficulty,
      ),
    );
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(
      GameLoading(
        selectedMode: _selectedMode,
        selectedDifficulty: _selectedDifficulty,
      ),
    );
    try {
      final response = await _api.fetchRoundQueue(
        mode: _selectedMode,
        difficulty: _selectedDifficulty,
      );
      _queue = List<NewRoundResponse>.from(response.rounds);
      if (_queue.isEmpty) {
        emit(
          GameError(
            'Queue returned no rounds.',
            selectedMode: _selectedMode,
            selectedDifficulty: _selectedDifficulty,
          ),
        );
        return;
      }
      _currentRound = _queue.removeAt(0);
      emit(
        GameLoaded(
          _currentRound!,
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
      if (_queue.length <= 3) {
        add(const QueueRefillRequested());
      }
    } catch (e) {
      emit(
        GameError(
          'Error loading round: $e',
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    }
  }

  Future<void> _onGuessSubmitted(
    GuessSubmitted event,
    Emitter<GameState> emit,
  ) async {
    if (_currentRound == null) return;

    emit(
      GameLoading(
        selectedMode: _selectedMode,
        selectedDifficulty: _selectedDifficulty,
      ),
    );
    try {
      final result = await _api.submitGuess(
        _currentRound!.gameToken,
        event.guess,
      );
      emit(
        GameGuessSubmitted(
          result,
          _currentRound!,
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    } catch (e) {
      emit(
        GameError(
          'Error submitting guess: $e',
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    }
  }

  Future<void> _onGameGiveUp(
    GameGiveUp event,
    Emitter<GameState> emit,
  ) async {
    if (_currentRound == null) return;

    emit(
      GameLoading(
        selectedMode: _selectedMode,
        selectedDifficulty: _selectedDifficulty,
      ),
    );
    try {
      final roundMode = parseGameMode(_currentRound!.roundType);
      final emptyGuess = roundMode == GameMode.lyrics ? <String>[] : '';
      final result = await _api.submitGuess(
        _currentRound!.gameToken,
        emptyGuess,
        giveUp: true,
      );
      emit(
        GameGuessSubmitted(
          result,
          _currentRound!,
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    } catch (e) {
      emit(
        GameError(
          'Error surrendering: $e',
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    }
  }

  Future<void> _onNewRoundStarted(
    NewRoundStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(
      GameLoading(
        selectedMode: _selectedMode,
        selectedDifficulty: _selectedDifficulty,
      ),
    );
    try {
      if (_queue.isEmpty) {
        final response = await _api.fetchRoundQueue(
          mode: _selectedMode,
          difficulty: _selectedDifficulty,
        );
        _queue = List<NewRoundResponse>.from(response.rounds);
      }
      if (_queue.isEmpty) {
        emit(
          GameError(
            'Queue returned no rounds.',
            selectedMode: _selectedMode,
            selectedDifficulty: _selectedDifficulty,
          ),
        );
        return;
      }
      _currentRound = _queue.removeAt(0);
      emit(
        GameLoaded(
          _currentRound!,
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
      if (_queue.length <= 3) {
        add(const QueueRefillRequested());
      }
    } catch (e) {
      emit(
        GameError(
          'Error loading round: $e',
          selectedMode: _selectedMode,
          selectedDifficulty: _selectedDifficulty,
        ),
      );
    }
  }

  Future<void> _onQueueRefillRequested(
    QueueRefillRequested event,
    Emitter<GameState> emit,
  ) async {
    if (_isRefilling) return;
    _isRefilling = true;
    try {
      final response = await _api.fetchRoundQueue(
        mode: _selectedMode,
        difficulty: _selectedDifficulty,
      );
      _queue = List<NewRoundResponse>.from(_queue)..addAll(response.rounds);
    } catch (_) {
      // Keep current gameplay intact even if the background refill fails.
    } finally {
      _isRefilling = false;
    }
  }
}
