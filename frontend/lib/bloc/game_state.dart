part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  final GameMode selectedMode;
  final GameDifficulty selectedDifficulty;

  const GameState({
    required this.selectedMode,
    required this.selectedDifficulty,
  });

  @override
  List<Object?> get props => [selectedMode, selectedDifficulty];
}

class GameInitial extends GameState {
  const GameInitial({
    required super.selectedMode,
    required super.selectedDifficulty,
  });
}

class GameLoading extends GameState {
  const GameLoading({
    required super.selectedMode,
    required super.selectedDifficulty,
  });
}

class GameLoaded extends GameState {
  final NewRoundResponse round;

  const GameLoaded(
    this.round, {
    required super.selectedMode,
    required super.selectedDifficulty,
  });

  @override
  List<Object> get props => [round, selectedMode, selectedDifficulty];
}

class GameGuessSubmitted extends GameState {
  final GuessResult result;
  final NewRoundResponse round;

  const GameGuessSubmitted(
    this.result,
    this.round, {
    required super.selectedMode,
    required super.selectedDifficulty,
  });

  @override
  List<Object> get props => [result, round, selectedMode, selectedDifficulty];
}

class GameError extends GameState {
  final String message;

  const GameError(
    this.message, {
    required super.selectedMode,
    required super.selectedDifficulty,
  });

  @override
  List<Object> get props => [message, selectedMode, selectedDifficulty];
}
