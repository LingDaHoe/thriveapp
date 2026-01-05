import 'package:flutter/foundation.dart';

class AIConfig {
  // Using OpenRouter API with Xiaomi MiMo-V2-Flash (free model)
  // Get your API key from: https://openrouter.ai/keys
  // Add your API key here:
  static const String apiKey = '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';

  static const String apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String model = 'xiaomi/mimo-v2-flash:free';

  static bool get isConfigured {
    final hasKey = apiKey.isNotEmpty && apiKey != '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';
    if (!hasKey && kDebugMode) {
      print('Warning: OpenRouter API key is not configured.');
      print('Get your API key from: https://openrouter.ai/keys');
      print('Model: xiaomi/mimo-v2-flash (free)');
    }
    return hasKey;
  }
} 