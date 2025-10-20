import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/word_puzzle.dart';
import '../services/activity_service.dart';

// Events
abstract class WordPuzzleEvent extends Equatable {
  const WordPuzzleEvent();

  @override
  List<Object?> get props => [];
}

class LoadWordPuzzleStats extends WordPuzzleEvent {
  final String activityId;

  const LoadWordPuzzleStats(this.activityId);

  @override
  List<Object?> get props => [activityId];
}

class CompleteWordPuzzle extends WordPuzzleEvent {
  final String activityId;
  final int score;
  final int wordsFound;
  final Duration duration;

  const CompleteWordPuzzle({
    required this.activityId,
    required this.score,
    required this.wordsFound,
    required this.duration,
  });

  @override
  List<Object?> get props => [activityId, score, wordsFound, duration];
}

// States
abstract class WordPuzzleState extends Equatable {
  const WordPuzzleState();

  @override
  List<Object?> get props => [];
}

class WordPuzzleInitial extends WordPuzzleState {}

class WordPuzzleLoading extends WordPuzzleState {}

class WordPuzzleLoaded extends WordPuzzleState {
  final Map<String, dynamic> stats;

  const WordPuzzleLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class WordPuzzleError extends WordPuzzleState {
  final String message;

  const WordPuzzleError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class WordPuzzleBloc extends Bloc<WordPuzzleEvent, WordPuzzleState> {
  final ActivityService _activityService;

  WordPuzzleBloc(this._activityService) : super(WordPuzzleInitial()) {
    on<LoadWordPuzzleStats>(_onLoadWordPuzzleStats);
    on<CompleteWordPuzzle>(_onCompleteWordPuzzle);
  }

  Future<void> _onLoadWordPuzzleStats(
    LoadWordPuzzleStats event,
    Emitter<WordPuzzleState> emit,
  ) async {
    try {
      emit(WordPuzzleLoading());
      final stats = await _activityService.getActivityStats(event.activityId);
      emit(WordPuzzleLoaded(stats));
    } catch (e) {
      emit(WordPuzzleError(e.toString()));
    }
  }

  Future<void> _onCompleteWordPuzzle(
    CompleteWordPuzzle event,
    Emitter<WordPuzzleState> emit,
  ) async {
    try {
      emit(WordPuzzleLoading());
      await _activityService.completeActivityWithScore(
        event.activityId,
        event.score,
        {
          'wordsFound': event.wordsFound,
          'duration': event.duration.inSeconds,
        },
      );
      final stats = await _activityService.getActivityStats(event.activityId);
      emit(WordPuzzleLoaded(stats));
    } catch (e) {
      emit(WordPuzzleError(e.toString()));
    }
  }
} 