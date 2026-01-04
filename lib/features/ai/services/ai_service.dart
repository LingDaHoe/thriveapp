import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
        print('=== Gemini API Request ===');
        print('User message: $userMessage');
      }

      // Add user message to history
      _conversationHistory.add({
        'role': 'user',
        'parts': [{'text': userMessage}]
      });

      // Prepare the API request
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=$_apiKey';
      
      final requestBody = {
        'contents': _conversationHistory,
        'systemInstruction': {
          'parts': [
            {
              'text': 'You are a helpful health and wellness assistant. Provide clear, concise, and supportive advice. Keep responses under 200 words.'
            }
          ]
        },
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1000,
        }
      };

      if (kDebugMode) {
        print('Request URL: $url');
        print('Request body: ${jsonEncode(requestBody)}');
      }

      // Make the API call
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      // Handle response
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['candidates'] != null && 
            jsonResponse['candidates'].isNotEmpty) {
          
          final candidate = jsonResponse['candidates'][0];
          final content = candidate['content'];
          
          // Check if parts exist and have text
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            final parts = content['parts'];
            final text = parts[0]['text'];
            
            if (text != null && text.isNotEmpty) {
              // Add assistant response to history
              _conversationHistory.add({
                'role': 'model',
                'parts': [{'text': text}]
              });
              
              return text;
            }
          }
          
          // If we get here, the response was empty or incomplete
          if (kDebugMode) {
            print('Empty response or missing parts. Full candidate: $candidate');
          }
          throw Exception('AI returned an empty response. Please try rephrasing your question.');
        } else {
          throw Exception('No response from Gemini');
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('API Error: ${errorBody['error']['message']}');
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
