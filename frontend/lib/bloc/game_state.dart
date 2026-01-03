part of 'game_bloc.dart';

abstract class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final NewRoundResponse round;

  const GameLoaded(this.round);

  @override
  List<Object> get props => [round];
}

class GameGuessSubmitted extends GameState {
  final GuessResult result;
  final NewRoundResponse round;

  const GameGuessSubmitted(this.result, this.round);

  @override
  List<Object> get props => [result, round];
}

class GameError extends GameState {
  final String message;

  const GameError(this.message);

  @override
  List<Object> get props => [message];
}
