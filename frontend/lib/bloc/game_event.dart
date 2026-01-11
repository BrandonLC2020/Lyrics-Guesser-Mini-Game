part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameStarted extends GameEvent {}

class GameModeSelected extends GameEvent {
  final GameMode mode;
  final GameDifficulty difficulty;

  const GameModeSelected({
    required this.mode,
    required this.difficulty,
  });

  @override
  List<Object> get props => [mode, difficulty];
}

class GuessSubmitted extends GameEvent {
  final Object guess;

  const GuessSubmitted(this.guess);

  @override
  List<Object> get props => [guess];
}

class NewRoundStarted extends GameEvent {}

class QueueRefillRequested extends GameEvent {
  const QueueRefillRequested();
}
