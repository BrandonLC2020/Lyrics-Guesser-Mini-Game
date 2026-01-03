part of 'game_bloc.dart';

abstract class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameStarted extends GameEvent {}

class GuessSubmitted extends GameEvent {
  final String guess;

  const GuessSubmitted(this.guess);

  @override
  List<Object> get props => [guess];
}

class NewRoundStarted extends GameEvent {}
