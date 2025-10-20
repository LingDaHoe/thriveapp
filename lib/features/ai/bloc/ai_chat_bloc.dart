import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

// Events
abstract class AIChatEvent extends Equatable {
  const AIChatEvent();

  @override
  List<Object?> get props => [];
}

class SendMessage extends AIChatEvent {
  final String message;

  const SendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class ClearChat extends AIChatEvent {}

// States
abstract class AIChatState extends Equatable {
  const AIChatState();

  @override
  List<Object?> get props => [];
}

class AIChatInitial extends AIChatState {}

class AIChatLoading extends AIChatState {}

class AIChatLoaded extends AIChatState {
  final List<ChatMessage> messages;

  const AIChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class AIChatError extends AIChatState {
  final String message;

  const AIChatError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AIChatBloc extends Bloc<AIChatEvent, AIChatState> {
  final _uuid = const Uuid();
  final AIService _aiService;

  AIChatBloc({required AIService aiService})
      : _aiService = aiService,
        super(AIChatInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ClearChat>(_onClearChat);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<AIChatState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is AIChatLoaded) {
        // Add user message
        final userMessage = ChatMessage(
          id: _uuid.v4(),
          content: event.message,
          isUser: true,
          timestamp: DateTime.now(),
        );

        final updatedMessages = List<ChatMessage>.from(currentState.messages)
          ..add(userMessage);

        emit(AIChatLoaded(updatedMessages));

        // Get AI response
        emit(AIChatLoading());
        final aiResponse = await _aiService.getResponse(event.message);
        
        final aiMessage = ChatMessage(
          id: _uuid.v4(),
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        updatedMessages.add(aiMessage);
        emit(AIChatLoaded(updatedMessages));
      } else {
        // First message
        final userMessage = ChatMessage(
          id: _uuid.v4(),
          content: event.message,
          isUser: true,
          timestamp: DateTime.now(),
        );

        emit(AIChatLoaded([userMessage]));

        // Get AI response
        emit(AIChatLoading());
        final aiResponse = await _aiService.getResponse(event.message);
        
        final aiMessage = ChatMessage(
          id: _uuid.v4(),
          content: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        );

        emit(AIChatLoaded([userMessage, aiMessage]));
      }
    } catch (e) {
      emit(AIChatError(e.toString()));
    }
  }

  void _onClearChat(
    ClearChat event,
    Emitter<AIChatState> emit,
  ) {
    _aiService.clearHistory();
    emit(AIChatInitial());
  }
} 