import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:thriveapp/config/ai_config.dart';

class AIService {
  final String _apiKey;
  final List<Map<String, dynamic>> _conversationHistory = [];

  AIService({
    required String apiKey,
    String? apiUrl, // Ignored, we'll use the correct URL directly
  }) : _apiKey = apiKey {
    if (kDebugMode) {
      print('AIService initialized with API key: ${_apiKey.substring(0, 10)}...');
    }
  }

  Future<String> getResponse(String userMessage) async {
    try {
      if (kDebugMode) {
        print('=== OpenRouter API Request ===');
        print('User message: $userMessage');
      }

      // Convert conversation history to OpenRouter format
      final messages = <Map<String, String>>[];
      
      // Add system message
      messages.add({
        'role': 'system',
        'content': 'You are a helpful health and wellness assistant. Provide clear, concise, and supportive advice. Keep responses under 200 words.'
      });
      
      // Convert conversation history from Gemini format to OpenRouter format
      for (var msg in _conversationHistory) {
        final role = msg['role'] as String;
        if (role == 'user' || role == 'assistant') {
          final parts = msg['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) {
              messages.add({
                'role': role == 'user' ? 'user' : 'assistant',
                'content': text,
              });
            }
          }
        }
      }
      
      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage,
      });

      // Prepare the API request for OpenRouter
      final url = AIConfig.apiUrl;
      
      final requestBody = {
        'model': AIConfig.model,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000,
      };

      if (kDebugMode) {
        print('Request URL: $url');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      // Make the API call
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      // Handle response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['choices'] != null && 
            jsonResponse['choices'].isNotEmpty) {
          
          final choice = jsonResponse['choices'][0];
          final message = choice['message'];
          
          if (message != null && message['content'] != null) {
            final text = message['content'] as String;
            
            if (text.isNotEmpty) {
              // Add assistant response to history (in Gemini format for compatibility)
              _conversationHistory.add({
                'role': 'assistant',
                'parts': [{'text': text}]
              });
              
              return text;
            }
          }
          
          throw Exception('AI returned an empty response. Please try rephrasing your question.');
        } else {
          throw Exception('No response from AI');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final error = errorBody['error'];
        throw Exception('API Error: ${error is Map ? error['message'] ?? 'Unknown error' : 'Unknown error'}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error: $e');
      }
      throw Exception('Failed to get AI response: $e');
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
  }

  List<Map<String, dynamic>> get messageHistory => _conversationHistory;
}
