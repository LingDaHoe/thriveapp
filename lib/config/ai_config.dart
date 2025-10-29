import 'package:flutter/foundation.dart';

class AIConfig {
  static const String apiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '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',
  );

  static const String apiUrl = String.fromEnvironment(
    'OPENROUTER_API_URL',
    defaultValue: 'https://openrouter.ai/api/v1/chat/completions',
  );

  static bool get isConfigured {
    final hasKey = apiKey.isNotEmpty;
    if (!hasKey && kDebugMode) {
      print('Warning: OpenRouter API key is not configured. Please set OPENROUTER_API_KEY environment variable.');
    }
    return hasKey;
  }
} 