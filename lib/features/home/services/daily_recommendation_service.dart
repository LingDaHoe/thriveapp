import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thriveapp/config/ai_config.dart';

class DailyRecommendationService {
  static const String _recommendationKeyPrefix = 'daily_recommendation_';
  static const String _dateKey = 'daily_recommendation_date';

  /// Get today's recommendation. Returns cached recommendation if available for today,
  /// otherwise generates a new one using AI.
  Future<String> getTodaysRecommendation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayDateString = _getDateString(today);
      
      // Check if we have a cached recommendation for today
      final cachedDate = prefs.getString(_dateKey);
      if (cachedDate == todayDateString) {
        final cachedRecommendation = prefs.getString(_recommendationKeyPrefix + todayDateString);
        if (cachedRecommendation != null && cachedRecommendation.isNotEmpty) {
          return cachedRecommendation;
        }
      }
      
      // Generate new recommendation for today
      final recommendation = await _generateRecommendation();
      
      // Cache the recommendation
      await prefs.setString(_dateKey, todayDateString);
      await prefs.setString(_recommendationKeyPrefix + todayDateString, recommendation);
      
      return recommendation;
    } catch (e) {
      debugPrint('Error getting daily recommendation: $e');
      // Return a fallback recommendation if AI generation fails
      return _getFallbackRecommendation();
    }
  }

  /// Generate a daily recommendation using OpenRouter API
  Future<String> _generateRecommendation() async {
    try {
      final url = AIConfig.apiUrl;
      
      // Create a prompt that generates a daily wellness recommendation for elders
      final prompt = '''Generate a brief, encouraging daily wellness reminder specifically for elderly users (65+). 
The recommendation should be:
- Warm and supportive in tone
- Practical and actionable
- Focused on health, wellness, or social connection
- No more than 2-3 sentences
- Suitable as a daily reminder

Examples of good recommendations:
- "Take a gentle 10-minute walk today to keep your joints flexible and boost your mood. Even a short stroll around your home can make a difference!"
- "Remember to stay hydrated by drinking water throughout the day. Set a gentle reminder to take sips every hour."
- "Connect with a friend or family member today, even if it's just a quick phone call. Social connections are important for your well-being."

Generate ONE new, unique recommendation for today:''';

      final requestBody = {
        'model': AIConfig.model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.8,
        'max_tokens': 200,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AIConfig.apiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['choices'] != null && 
            jsonResponse['choices'].isNotEmpty) {
          final choice = jsonResponse['choices'][0];
          final message = choice['message'];
          
          if (message != null && message['content'] != null) {
            final text = message['content'] as String;
            
            if (text.isNotEmpty) {
              // Clean up the text (remove quotes if present, trim whitespace)
              var cleaned = text.trim();
              if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
                cleaned = cleaned.substring(1, cleaned.length - 1);
              } else if (cleaned.startsWith("'") && cleaned.endsWith("'")) {
                cleaned = cleaned.substring(1, cleaned.length - 1);
              }
              return cleaned.trim();
            }
          }
        }
        
        throw Exception('AI returned an empty response');
      } else {
        final errorBody = jsonDecode(response.body);
        final error = errorBody['error'];
        throw Exception('API Error: ${error is Map ? error['message'] ?? 'Unknown error' : 'Unknown error'}');
      }
    } catch (e) {
      debugPrint('Error generating recommendation: $e');
      rethrow;
    }
  }

  /// Get a fallback recommendation if AI generation fails
  String _getFallbackRecommendation() {
    final fallbacks = [
      'Remember to take your time today and listen to your body. A few moments of gentle movement can go a long way for your well-being.',
      'Stay connected with loved ones today. A simple phone call or message can brighten both your day and theirs.',
      'Take a moment to enjoy something you love today - whether it\'s reading, listening to music, or simply enjoying a cup of tea.',
      'Practice deep breathing throughout the day. Taking a few slow, deep breaths can help you feel more relaxed and centered.',
      'Remember to stay hydrated and eat nutritious meals. Your body will thank you for taking good care of it.',
    ];
    
    // Use the day of year to pick a consistent fallback for the day
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    return fallbacks[dayOfYear % fallbacks.length];
  }

  /// Convert DateTime to a date string (YYYY-MM-DD)
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Clear cached recommendations (useful for testing)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dateKey);
    // Note: We don't remove all cached recommendations, just the date key
    // This allows the system to generate a new one naturally
  }
}

