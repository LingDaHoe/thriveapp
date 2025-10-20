import 'package:cloud_firestore/cloud_firestore.dart';

enum ContentType {
  article,
  video,
  audio,
}

enum ContentCategory {
  cardiovascular,
  sleep,
  nutrition,
  mentalHealth,
  exercise,
  general,
}

class HealthContent {
  final String id;
  final String title;
  final String description;
  final ContentType type;
  final ContentCategory category;
  final String content;
  final String? mediaUrl;
  final int? duration;
  final DateTime createdAt;

  HealthContent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.content,
    this.mediaUrl,
    this.duration,
    required this.createdAt,
  });

  factory HealthContent.fromJson(Map<String, dynamic> json) {
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
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'content': content,
      'mediaUrl': mediaUrl,
      'duration': duration,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
} 