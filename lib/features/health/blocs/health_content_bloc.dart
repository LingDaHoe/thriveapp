import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/health_content_service.dart';

// Events
abstract class HealthContentEvent extends Equatable {
  const HealthContentEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthContent extends HealthContentEvent {
  final String contentId;

  const LoadHealthContent(this.contentId);

  @override
  List<Object?> get props => [contentId];
}

// States
abstract class HealthContentState extends Equatable {
  const HealthContentState();

  @override
  List<Object?> get props => [];
}

class HealthContentInitial extends HealthContentState {}

class HealthContentLoading extends HealthContentState {}

class HealthContentLoaded extends HealthContentState {
  final Map<String, dynamic> content;

  const HealthContentLoaded(this.content);

  @override
  List<Object?> get props => [content];
}

class HealthContentError extends HealthContentState {
  final String message;

  const HealthContentError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HealthContentBloc extends Bloc<HealthContentEvent, HealthContentState> {
  final HealthContentService _healthContentService;

  HealthContentBloc({required HealthContentService healthContentService})
      : _healthContentService = healthContentService,
        super(HealthContentInitial()) {
    on<LoadHealthContent>(_onLoadHealthContent);
  }

  Future<void> _onLoadHealthContent(
    LoadHealthContent event,
    Emitter<HealthContentState> emit,
  ) async {
    emit(HealthContentLoading());
    try {
      final content = await _healthContentService.getContent(event.contentId);
      emit(HealthContentLoaded(content));
    } catch (e) {
      emit(HealthContentError(e.toString()));
    }
  }
} 