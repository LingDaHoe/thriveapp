import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/activity_service.dart';

// Events
abstract class MemoryGameEvent extends Equatable {
  const MemoryGameEvent();

  @override
  List<Object> get props => [];
}

class CompleteMemoryGame extends MemoryGameEvent {
  final String activityId;
  final int score;
  final int moves;
  final Duration duration;

  const CompleteMemoryGame({
    required this.activityId,
    required this.score,
    required this.moves,
    required this.duration,
  });

  @override
  List<Object> get props => [activityId, score, moves, duration];
}

class LoadMemoryGameStats extends MemoryGameEvent {
  final String activityId;

  const LoadMemoryGameStats(this.activityId);

  @override
  List<Object> get props => [activityId];
}

// States
abstract class MemoryGameState extends Equatable {
  const MemoryGameState();

  @override
  List<Object> get props => [];
}

class MemoryGameInitial extends MemoryGameState {}

class MemoryGameLoading extends MemoryGameState {}

class MemoryGameStatsLoaded extends MemoryGameState {
  final Map<String, dynamic> stats;

  const MemoryGameStatsLoaded(this.stats);

  @override
  List<Object> get props => [stats];
}

class MemoryGameSuccess extends MemoryGameState {}

class MemoryGameError extends MemoryGameState {
  final String message;

  const MemoryGameError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class MemoryGameBloc extends Bloc<MemoryGameEvent, MemoryGameState> {
  final ActivityService _activityService;

  MemoryGameBloc(this._activityService) : super(MemoryGameInitial()) {
    on<CompleteMemoryGame>(_onCompleteMemoryGame);
    on<LoadMemoryGameStats>(_onLoadMemoryGameStats);
  }

  Future<void> _onCompleteMemoryGame(
    CompleteMemoryGame event,
    Emitter<MemoryGameState> emit,
  ) async {
    try {
      emit(MemoryGameLoading());
      await _activityService.completeMemoryGame(
        event.activityId,
        event.score,
        event.moves,
        event.duration,
      );
      emit(MemoryGameSuccess());
    } catch (e) {
      emit(MemoryGameError(e.toString()));
    }
  }

  Future<void> _onLoadMemoryGameStats(
    LoadMemoryGameStats event,
    Emitter<MemoryGameState> emit,
  ) async {
    try {
      emit(MemoryGameLoading());
      final stats = await _activityService.getMemoryGameStats(event.activityId);
      emit(MemoryGameStatsLoaded(stats));
    } catch (e) {
      emit(MemoryGameError(e.toString()));
    }
  }
} 