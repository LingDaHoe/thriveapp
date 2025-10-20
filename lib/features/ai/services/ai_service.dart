import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:thriveapp/config/ai_config.dart';
import 'package:flutter/foundation.dart';

class AIService {
  final String _apiKey;
  final String _apiUrl;
  final List<Map<String, String>> _messageHistory = [];

  AIService({
    required String apiKey,
    String? apiUrl,
  })  : _apiKey = apiKey,
        _apiUrl = apiUrl ?? 'https://openrouter.ai/api/v1/chat/completions' {
    if (kDebugMode) {
      print('Initializing AIService with API key: ${_apiKey.substring(0, 10)}...');
    }
    
    // Add system message
    _messageHistory.add({
      'role': 'system',
      'content': '''You are a helpful health and wellness assistant. Your role is to:
1. Provide accurate, evidence-based information about health and wellness
2. Offer personalized advice while respecting medical boundaries
3. Support users in their health journey with practical tips
4. Encourage healthy habits and lifestyle changes
5. Help users understand their health data and medications
6. Provide guidance on nutrition, exercise, and mental health
7. Always prioritize user safety and recommend consulting healthcare professionals for medical advice

Remember to:
- Be empathetic and supportive
- Use clear, easy-to-understand language
- Provide actionable advice
- Acknowledge limitations and uncertainties
- Encourage professional medical consultation when appropriate''',
    });
  }

  Future<String> getResponse(String message) async {
    try {
      if (kDebugMode) {
        print('Making API request to: $_apiUrl');
        print('Using API key: ${_apiKey.substring(0, 10)}...');
      }

      // Add user message to history
      _messageHistory.add({
        'role': 'user',
        'content': message,
      });

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://thriveapp.com', // Required by OpenRouter
          'X-Title': 'Thrive App', // Required by OpenRouter
        },
        body: jsonEncode({
          'model': 'mistralai/mistral-7b-instruct', // Using Mistral 7B which is free
          'messages': _messageHistory,
          'temperature': 0.5,
          'max_tokens': 300,
          'stream': false,
        }),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];

        // Add AI response to history
        _messageHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        // Keep only last 6 messages to reduce context length
        if (_messageHistory.length > 6) {
          _messageHistory.removeRange(1, 3); // Remove oldest user-assistant pair
        }

        return aiResponse;
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please check your OpenRouter API key. Response: ${response.body}');
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in getResponse: $e');
      }
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error communicating with AI service: $e');
    }
  }

  void clearHistory() {
    _messageHistory.clear();
    // Re-add system message
    _messageHistory.add({
      'role': 'system',
      'content': '''You are a helpful health and wellness assistant. Your role is to:
1. Provide accurate, evidence-based information about health and wellness
2. Offer personalized advice while respecting medical boundaries
3. Support users in their health journey with practical tips
4. Encourage healthy habits and lifestyle changes
5. Help users understand their health data and medications
6. Provide guidance on nutrition, exercise, and mental health
7. Always prioritize user safety and recommend consulting healthcare professionals for medical advice

Remember to:
- Be empathetic and supportive
- Use clear, easy-to-understand language
- Provide actionable advice
- Acknowledge limitations and uncertainties
- Encourage professional medical consultation when appropriate''',
    });
  }
} 