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
  final bool isLoading;

  const AIChatLoaded(this.messages, {this.isLoading = false});

  @override
  List<Object?> get props => [messages, isLoading];
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
      List<ChatMessage> currentMessages = [];
      
      if (currentState is AIChatLoaded) {
        currentMessages = List<ChatMessage>.from(currentState.messages);
      }
      
      // Add user message
      final userMessage = ChatMessage(
        id: _uuid.v4(),
        content: event.message,
        isUser: true,
        timestamp: DateTime.now(),
      );

      currentMessages.add(userMessage);
      emit(AIChatLoaded(currentMessages, isLoading: true));

      // Get AI response
      final aiResponse = await _aiService.getResponse(event.message);
      
      final aiMessage = ChatMessage(
        id: _uuid.v4(),
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      currentMessages.add(aiMessage);
      emit(AIChatLoaded(currentMessages, isLoading: false));
    } catch (e) {
      // Get current messages
      List<ChatMessage> currentMessages = [];
      if (state is AIChatLoaded) {
        currentMessages = (state as AIChatLoaded).messages;
      }
      
      // Add error message as AI response
      final errorMessage = ChatMessage(
        id: _uuid.v4(),
        content: '❌ Error: ${e.toString()}\n\nPlease try again or rephrase your question.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      currentMessages.add(errorMessage);
      emit(AIChatLoaded(currentMessages, isLoading: false));
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