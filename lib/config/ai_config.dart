import 'package:flutter/foundation.dart';

class AIConfig {
  // Using Google Gemini API (Free tier available)
  // Get your free API key from: https://makersuite.google.com/app/apikey
  static const String apiKey = 'AIzaSyBIawQwJCKQhW47htS8FPdkIQ18DE-xOe8';

  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static bool get isConfigured {
    final hasKey = apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';
    if (!hasKey && kDebugMode) {
      print('Warning: Gemini API key is not configured.');
      print('Get your free API key from: https://makersuite.google.com/app/apikey');
    }
    return hasKey;
  }
} 