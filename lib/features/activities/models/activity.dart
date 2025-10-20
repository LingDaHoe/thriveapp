import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String title;
  final String description;
  final String type;
  final String difficulty;
  final int points;
  final int duration;
  final Map<String, dynamic> content;
  final DateTime? createdAt;

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.points,
    required this.duration,
    required this.content,
    this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      points: json['points'] as int,
      duration: json['duration'] as int,
      content: json['content'] as Map<String, dynamic>,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'points': points,
      'duration': duration,
      'content': content,
      'createdAt': createdAt,
    };
  }
} 