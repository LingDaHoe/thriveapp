import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/achievement_service.dart';
import '../services/activity_service.dart';

// Events
abstract class AchievementEvent extends Equatable {
  const AchievementEvent();

  @override
  List<Object> get props => [];
}

class LoadAchievements extends AchievementEvent {}

class UnlockAchievement extends AchievementEvent {
  final String achievementId;

  const UnlockAchievement(this.achievementId);

  @override
  List<Object> get props => [achievementId];
}

// States
abstract class AchievementState extends Equatable {
  const AchievementState();

  @override
  List<Object> get props => [];
}

class AchievementInitial extends AchievementState {}

class AchievementLoading extends AchievementState {}

class AchievementsLoaded extends AchievementState {
  final List<Map<String, dynamic>> achievements;

  const AchievementsLoaded(this.achievements);

  @override
  List<Object> get props => [achievements];
}

class AchievementError extends AchievementState {
  final String message;

  const AchievementError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class AchievementBloc extends Bloc<AchievementEvent, AchievementState> {
  final ActivityService _activityService;
  final AchievementService _achievementService;

  AchievementBloc(this._activityService, this._achievementService)
      : super(AchievementInitial()) {
    on<LoadAchievements>(_onLoadAchievements);
    on<UnlockAchievement>(_onUnlockAchievement);
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<AchievementState> emit,
  ) async {
    emit(AchievementLoading());
    try {
      final achievements = await _achievementService.getAchievements();
      emit(AchievementsLoaded(achievements));
    } catch (e) {
      emit(AchievementError(e.toString()));
    }
  }

  Future<void> _onUnlockAchievement(
    UnlockAchievement event,
    Emitter<AchievementState> emit,
  ) async {
    try {
      await _achievementService.unlockAchievement(event.achievementId);
      add(LoadAchievements());
    } catch (e) {
      emit(AchievementError(e.toString()));
    }
  }
} 