import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'models/activity.dart';
import 'models/achievement.dart';
import 'services/activity_service.dart';

// Events
abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object> get props => [];
}

class LoadActivities extends ActivityEvent {}

class LoadActivitiesByType extends ActivityEvent {
  final String type;

  const LoadActivitiesByType(this.type);

  @override
  List<Object> get props => [type];
}

class StartActivity extends ActivityEvent {
  final String activityId;

  const StartActivity(this.activityId);

  @override
  List<Object> get props => [activityId];
}

class InitializeActivities extends ActivityEvent {}

class CompleteActivity extends ActivityEvent {
  final String activityId;

  const CompleteActivity(this.activityId);

  @override
  List<Object> get props => [activityId];
}

class LoadAchievements extends ActivityEvent {}

// States
abstract class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivitiesLoaded extends ActivityState {
  final List<Activity> activities;

  const ActivitiesLoaded(this.activities);

  @override
  List<Object> get props => [activities];
}

class AchievementsLoaded extends ActivityState {
  final List<Achievement> achievements;

  const AchievementsLoaded(this.achievements);

  @override
  List<Object> get props => [achievements];
}

class ActivityError extends ActivityState {
  final String message;

  const ActivityError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityService _activityService;

  ActivityBloc(this._activityService) : super(ActivityInitial()) {
    on<LoadActivities>(_onLoadActivities);
    on<LoadActivitiesByType>(_onLoadActivitiesByType);
    on<StartActivity>(_onStartActivity);
    on<InitializeActivities>(_onInitializeActivities);
    on<CompleteActivity>(_onCompleteActivity);
    on<LoadAchievements>(_onLoadAchievements);
  }

  Future<void> _onLoadActivities(
    LoadActivities event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());
      final activities = await _activityService.getActivities();
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  Future<void> _onLoadActivitiesByType(
    LoadActivitiesByType event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());
      final activities = await _activityService.getActivitiesByType(event.type);
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  Future<void> _onStartActivity(
    StartActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      await _activityService.startActivity(event.activityId);
      // Reload activities after starting
      final activities = await _activityService.getActivities();
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  Future<void> _onInitializeActivities(
    InitializeActivities event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());
      await _activityService.initializeSampleActivities();
      final activities = await _activityService.getActivities();
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  Future<void> _onCompleteActivity(
    CompleteActivity event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());
      await _activityService.completeActivity(event.activityId);
      final activities = await _activityService.getActivities();
      emit(ActivitiesLoaded(activities));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }

  Future<void> _onLoadAchievements(
    LoadAchievements event,
    Emitter<ActivityState> emit,
  ) async {
    try {
      emit(ActivityLoading());
      final achievements = await _activityService.getUserAchievements();
      emit(AchievementsLoaded(achievements));
    } catch (e) {
      emit(ActivityError(e.toString()));
    }
  }
} 