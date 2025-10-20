import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String type; // 'activity', 'streak', 'milestone'
  final int points;
  final String icon;
  final Map<String, dynamic>? requirements;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.points,
    required this.icon,
    this.requirements,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      points: json['points'] as int,
      icon: json['icon'] as String,
      requirements: json['requirements'] as Map<String, dynamic>?,
      unlockedAt: json['unlockedAt'] != null
          ? (json['unlockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'points': points,
      'icon': icon,
      'requirements': requirements,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
    };
  }

  bool isUnlocked() => unlockedAt != null;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    int? points,
    String? icon,
    Map<String, dynamic>? requirements,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      requirements: requirements ?? this.requirements,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
} 