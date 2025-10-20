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