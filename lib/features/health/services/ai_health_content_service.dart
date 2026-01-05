import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thriveapp/config/ai_config.dart';
import '../models/health_content.dart';

class AIHealthContentService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _userContentCacheKey = 'health_content_cache_';
  static const String _cacheKeyPrefix = 'health_content_cache_';

  // Trusted medical sources to reference
  static const List<String> trustedSources = [
    'Mayo Clinic',
    'WebMD',
    'National Institutes of Health (NIH)',
    'American Heart Association',
    'American Diabetes Association',
    'Centers for Disease Control and Prevention (CDC)',
    'World Health Organization (WHO)',
    'Harvard Medical School',
  ];

  /// Generate AI health content for search queries
  Future<List<HealthContent>> generateHealthContent({
    ContentType? type,
    ContentCategory? category,
    String? searchQuery,
    int limit = 5,
  }) async {
    try {
      // This service is now primarily used for search queries
      // Main content comes from predefined articles
      
      if (searchQuery == null || searchQuery.isEmpty) {
        return [];
      }

      final userId = _auth.currentUser?.uid ?? 'anonymous';
      
      // Check cache for this specific search query
      final today = DateTime.now();
      final todayDateString = _getDateString(today);
      final searchCacheKey = '${_cacheKeyPrefix}search_${searchQuery.toLowerCase()}_$todayDateString';
      
      final cachedContent = await _getCachedContent(userId, searchCacheKey);
      if (cachedContent.isNotEmpty) {
        return cachedContent;
      }

      // Generate content for the search query
      final inferredCategory = _inferCategoryFromQuery(searchQuery);
      final generatedContent = await _generateSingleContent(
        category ?? inferredCategory,
        type ?? ContentType.article,
        userId,
      );

      List<HealthContent> results = [];
      if (generatedContent != null) {
        results.add(generatedContent);
        
        // Cache the generated content
        await _cacheContent(userId, results, searchCacheKey);
      }

      return results.take(limit).toList();
    } catch (e) {
      debugPrint('Error generating AI health content: $e');
      // Return empty list on error - predefined content will be used instead
      return [];
    }
  }

  /// Generate personalized content for a user
  Future<List<HealthContent>> _generatePersonalizedContent(String userId, int count) async {
    try {
      final contents = <HealthContent>[];
      
      // Generate a mix of content types and categories
      final categories = ContentCategory.values;
      final types = ContentType.values;
      
      // Generate content in batches to avoid too many API calls
      final batchSize = (count / 3).ceil();
      
      for (int i = 0; i < batchSize && contents.length < count; i++) {
        final category = categories[i % categories.length];
        final type = types[i % types.length];
        
        try {
          final content = await _generateSingleContent(category, type, userId);
          if (content != null) {
            contents.add(content);
          }
        } catch (e) {
          debugPrint('Error generating content for $category/$type: $e');
          // Continue with next content
        }
      }
      
      // Fill remaining slots with varied content
      while (contents.length < count) {
        final randomCategory = categories[contents.length % categories.length];
        final randomType = types[contents.length % types.length];
        
        try {
          final content = await _generateSingleContent(randomCategory, randomType, userId);
          if (content != null && !contents.any((c) => c.id == content.id)) {
            contents.add(content);
          }
        } catch (e) {
          debugPrint('Error generating additional content: $e');
          break;
        }
      }
      
      return contents.isEmpty ? _getFallbackContent() : contents;
    } catch (e) {
      debugPrint('Error in _generatePersonalizedContent: $e');
      return _getFallbackContent();
    }
  }

  /// Generate a single health content item using OpenRouter API
  Future<HealthContent?> _generateSingleContent(
    ContentCategory category,
    ContentType type,
    String userId,
  ) async {
    try {
      final url = AIConfig.apiUrl;
      
      final categoryName = _formatCategoryName(category);
      final typeName = type == ContentType.video ? 'video' : type == ContentType.audio ? 'audio' : 'article';
      
      String prompt;
      if (type == ContentType.video || type == ContentType.audio) {
        prompt = '''Generate a health education ${typeName} content about ${categoryName} specifically for elderly users (65+).

Requirements:
- Create an informative, engaging ${typeName} title and description
- Provide a brief summary of the content (for display purposes)
- Include a relevant YouTube video URL or keyword that would be appropriate for this topic (embed a real YouTube video)
- Content should be based on trusted medical sources like ${trustedSources.join(', ')}
- Make it suitable for seniors: clear, simple language, practical advice
- Include actionable tips and information
- Duration should be reasonable (15-30 minutes for video/audio, 5-10 minutes reading time for articles)

Respond ONLY with valid JSON (no markdown, no explanation):
{
  "title": "Title here",
  "description": "Brief description",
  "content": "Main content text (for articles) or summary (for video/audio). Keep it concise - max 500 words.",
  "youtubeUrl": "YouTube video URL or video ID",
  "duration": 15
}

IMPORTANT: Ensure all strings in JSON are properly escaped. Use double quotes for JSON strings.''';
      } else {
        prompt = '''Generate a comprehensive health education article about ${categoryName} specifically for elderly users (65+).

Requirements:
- Create an informative, engaging article title and description
- Write comprehensive, well-structured article content in markdown format
- Content should be based on trusted medical sources like ${trustedSources.join(', ')}
- Make it suitable for seniors: clear, simple language, practical advice
- Include headings, bullet points, and actionable tips
- Reading time should be 5-15 minutes
- Focus on prevention, management, and practical daily tips

IMPORTANT: Respond with ONLY valid JSON. All string values must be properly escaped using \\n for newlines (not actual newline characters). Do not include markdown code blocks.

Example (use this exact format):
{"title": "Article title", "description": "Brief description", "content": "Article content with \\n for newlines", "duration": 10}''';
      }

      final requestBody = {
        'model': AIConfig.model,
        'messages': [
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.7,
        'max_tokens': 1000, // Reduced for faster responses
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
              // Generate unique ID
              final id = '${category.toString().split('.').last}_${type.toString().split('.').last}_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 8)}';
              
              Map<String, dynamic> contentData;
              try {
                // Try to parse JSON from AI response
                final cleanedText = _extractJsonFromText(text);
                final fixedJson = _fixJsonString(cleanedText);
                contentData = jsonDecode(fixedJson) as Map<String, dynamic>;
              } catch (e) {
                // If JSON parsing fails, extract content from plain text
                debugPrint('JSON parsing failed, using fallback: $e');
                contentData = _parsePlainTextResponse(text, category, type);
              }
              
              String? mediaUrl;
              if (type == ContentType.video || type == ContentType.audio) {
                // Extract YouTube URL/ID and convert to embed URL
                final youtubeUrl = contentData['youtubeUrl'] as String? ?? 
                                  contentData['youtubeKeyword'] as String?;
                if (youtubeUrl != null && youtubeUrl.isNotEmpty) {
                  mediaUrl = _processYouTubeUrl(youtubeUrl);
                }
              }
              
              return HealthContent(
                id: id,
                title: contentData['title'] as String? ?? 'Health Information',
                description: contentData['description'] as String? ?? 'Health education content',
                type: type,
                category: category,
                content: contentData['content'] as String? ?? '',
                mediaUrl: mediaUrl,
                duration: (contentData['duration'] as num?)?.toInt() ?? 10,
                createdAt: DateTime.now(),
              );
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error generating single content: $e');
      return null;
    }
  }

  /// Generate content for a specific search query
  Future<List<HealthContent>> _generateContentForSearch(String query) async {
    try {
      final userId = _auth.currentUser?.uid ?? 'anonymous';
      
      // Determine category and type from query (simple heuristic)
      final category = _inferCategoryFromQuery(query);
      final content = await _generateSingleContent(category, ContentType.article, userId);
      
      if (content != null) {
        return [content];
      }
      
      return [];
    } catch (e) {
      debugPrint('Error generating content for search: $e');
      return [];
    }
  }

  /// Extract JSON from AI response text (may have markdown code blocks)
  String _extractJsonFromText(String text) {
    // Remove markdown code blocks if present
    text = text.replaceAll(RegExp(r'```json\s*'), '');
    text = text.replaceAll(RegExp(r'```\s*'), '');
    text = text.trim();
    
    // Try to extract JSON object (look for balanced braces, handling strings)
    int openBraces = 0;
    int startIndex = -1;
    bool inString = false;
    bool escaped = false;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      
      if (escaped) {
        escaped = false;
        continue;
      }
      
      if (char == '\\') {
        escaped = true;
        continue;
      }
      
      if (char == '"' && !escaped) {
        inString = !inString;
        continue;
      }
      
      if (!inString) {
        if (char == '{') {
          if (startIndex == -1) startIndex = i;
          openBraces++;
        } else if (char == '}') {
          openBraces--;
          if (openBraces == 0 && startIndex != -1) {
            return text.substring(startIndex, i + 1);
          }
        }
      }
    }
    
    // If balanced braces not found, try simple regex
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    
    return text;
  }

  /// Fix common JSON issues like unescaped newlines in strings
  /// Uses Dart's jsonEncode approach to properly escape string values
  String _fixJsonString(String jsonString) {
    try {
      // First, try to parse as-is (might already be valid)
      jsonDecode(jsonString);
      return jsonString; // Already valid
    } catch (e) {
      // JSON is invalid, try to fix it
      try {
        // Extract and fix string values by properly escaping them
        final buffer = StringBuffer();
        bool inString = false;
        bool escaped = false;
        
        for (int i = 0; i < jsonString.length; i++) {
          final char = jsonString[i];
          
          if (escaped) {
            buffer.write(char);
            escaped = false;
            continue;
          }
          
          if (char == '\\') {
            buffer.write(char);
            escaped = true;
            continue;
          }
          
          if (char == '"') {
            inString = !inString;
            buffer.write(char);
            continue;
          }
          
          if (inString) {
            // Inside a string - properly escape special characters
            // Use the same escaping rules as jsonEncode
            switch (char) {
              case '\n':
                buffer.write('\\n');
                break;
              case '\r':
                buffer.write('\\r');
                break;
              case '\t':
                buffer.write('\\t');
                break;
              case '\b':
                buffer.write('\\b');
                break;
              case '\f':
                buffer.write('\\f');
                break;
              case '\\':
                buffer.write('\\\\');
                break;
              case '"':
                buffer.write('\\"');
                break;
              default:
                buffer.write(char);
            }
          } else {
            buffer.write(char);
          }
        }
        
        final fixed = buffer.toString();
        // Verify the fixed JSON is valid
        jsonDecode(fixed);
        return fixed;
      } catch (e2) {
        // If fixing fails, return original and let the fallback handle it
        debugPrint('Error fixing JSON string: $e2');
        return jsonString;
      }
    }
  }

  /// Parse plain text response when JSON parsing fails
  Map<String, dynamic> _parsePlainTextResponse(String text, ContentCategory category, ContentType type) {
    // Extract title (first line or line with #)
    String title = 'Health Information';
    String description = 'Health education content';
    String content = text;
    
    final lines = text.split('\n');
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      // Check for markdown title
      if (line.startsWith('# ')) {
        title = line.substring(2).trim();
        if (i + 1 < lines.length) {
          description = lines[i + 1].trim();
        }
        content = lines.sublist(i + 2).join('\n');
        break;
      } else if (title == 'Health Information' && line.length < 100) {
        title = line;
        if (i + 1 < lines.length) {
          description = lines[i + 1].trim();
        }
      }
    }
    
    return {
      'title': title,
      'description': description,
      'content': content,
      'duration': 10,
    };
  }

  /// Process YouTube URL to get embed URL
  String _processYouTubeUrl(String urlOrId) {
    // If it's already a full URL, extract the ID
    if (urlOrId.contains('youtube.com') || urlOrId.contains('youtu.be')) {
      final regExp = RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})');
      final match = regExp.firstMatch(urlOrId);
      if (match != null) {
        return match.group(1)!;
      }
    }
    
    // If it's just an ID (11 characters)
    if (urlOrId.length == 11 && RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(urlOrId)) {
      return urlOrId;
    }
    
    // Return as-is (might be a keyword - will be handled by UI)
    return urlOrId;
  }

  /// Cache content for user (with optional custom key)
  /// Uses cache-safe JSON format (ISO date strings instead of Timestamps)
  Future<void> _cacheContent(String userId, List<HealthContent> content, [String? cacheKey]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Convert to cache-safe JSON (DateTime to ISO string)
      final contentJson = content.map((c) => _toCacheJson(c)).toList();
      final key = cacheKey ?? '$_userContentCacheKey$userId';
      await prefs.setString(key, jsonEncode(contentJson));
    } catch (e) {
      debugPrint('Error caching content: $e');
    }
  }

  /// Get cached content for user (with optional custom key)
  Future<List<HealthContent>> _getCachedContent(String userId, [String? cacheKey]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = cacheKey ?? '$_userContentCacheKey$userId';
      final cachedJson = prefs.getString(key);
      
      if (cachedJson != null && cachedJson.isNotEmpty) {
        final jsonList = jsonDecode(cachedJson) as List;
        final contentList = jsonList
            .map((json) {
              try {
                return _fromCacheJson(json as Map<String, dynamic>);
              } catch (e) {
                debugPrint('Error parsing cached content item: $e');
                return null;
              }
            })
            .whereType<HealthContent>()
            .toList();
        return contentList;
      }
    } catch (e) {
      debugPrint('Error getting cached content: $e');
    }
    
    return [];
  }

  /// Convert HealthContent to cache-safe JSON (uses ISO date strings)
  Map<String, dynamic> _toCacheJson(HealthContent content) {
    return {
      'id': content.id,
      'title': content.title,
      'description': content.description,
      'type': content.type.toString().split('.').last,
      'category': content.category.toString().split('.').last,
      'content': content.content,
      'mediaUrl': content.mediaUrl,
      'duration': content.duration,
      'createdAt': content.createdAt.toIso8601String(), // Use ISO string instead of Timestamp
    };
  }

  /// Convert cache JSON back to HealthContent
  HealthContent _fromCacheJson(Map<String, dynamic> json) {
    return HealthContent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: ContentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ContentType.article,
      ),
      category: ContentCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => ContentCategory.general,
      ),
      content: json['content'] as String,
      mediaUrl: json['mediaUrl'] as String?,
      duration: json['duration'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String), // Parse ISO string
    );
  }

  /// Filter content by search query
  List<HealthContent> _filterBySearchQuery(List<HealthContent> content, String query) {
    final queryLower = query.toLowerCase();
    return content.where((c) {
      return c.title.toLowerCase().contains(queryLower) ||
             c.description.toLowerCase().contains(queryLower) ||
             c.content.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Infer category from search query
  ContentCategory _inferCategoryFromQuery(String query) {
    final queryLower = query.toLowerCase();
    
    if (queryLower.contains('heart') || queryLower.contains('cardio') || queryLower.contains('blood pressure')) {
      return ContentCategory.cardiovascular;
    } else if (queryLower.contains('sleep') || queryLower.contains('insomnia')) {
      return ContentCategory.sleep;
    } else if (queryLower.contains('nutrition') || queryLower.contains('diet') || queryLower.contains('food')) {
      return ContentCategory.nutrition;
    } else if (queryLower.contains('mental') || queryLower.contains('stress') || queryLower.contains('anxiety') || queryLower.contains('depression')) {
      return ContentCategory.mentalHealth;
    } else if (queryLower.contains('exercise') || queryLower.contains('fitness') || queryLower.contains('workout')) {
      return ContentCategory.exercise;
    }
    
    return ContentCategory.general;
  }

  /// Format category name for AI prompt
  String _formatCategoryName(ContentCategory category) {
    switch (category) {
      case ContentCategory.cardiovascular:
        return 'cardiovascular health and heart health';
      case ContentCategory.sleep:
        return 'sleep health and sleep hygiene';
      case ContentCategory.nutrition:
        return 'nutrition and healthy eating';
      case ContentCategory.mentalHealth:
        return 'mental health and wellness';
      case ContentCategory.exercise:
        return 'exercise and physical fitness';
      case ContentCategory.general:
        return 'general health and wellness';
    }
  }

  /// Get date string for caching
  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get fallback content when AI generation fails
  List<HealthContent> _getFallbackContent() {
    return [
      HealthContent(
        id: 'fallback_1',
        title: 'Importance of Regular Health Check-ups',
        description: 'Learn why regular health check-ups are essential for maintaining good health.',
        type: ContentType.article,
        category: ContentCategory.general,
        content: '''# Importance of Regular Health Check-ups

Regular health check-ups are essential for maintaining good health, especially as we age. They help detect potential health issues early and allow for timely intervention.

## Key Benefits

- Early detection of health problems
- Prevention of serious conditions
- Monitoring of existing health conditions
- Peace of mind

Remember to consult with your healthcare provider regularly.''',
        duration: 5,
        createdAt: DateTime.now(),
      ),
    ];
  }
}

