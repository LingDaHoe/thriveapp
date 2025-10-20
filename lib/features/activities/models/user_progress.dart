import 'package:cloud_firestore/cloud_firestore.dart';

class UserProgress {
  final String userId;
  final String activityId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String status; // 'in_progress', 'completed', 'abandoned'
  final Map<String, dynamic>? healthData;
  final int pointsEarned;
  final Map<String, dynamic>? activityData; // Additional data specific to activity type

  UserProgress({
    required this.userId,
    required this.activityId,
    required this.startedAt,
    this.completedAt,
    required this.status,
    this.healthData,
    required this.pointsEarned,
    this.activityData,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] as String,
      activityId: json['activityId'] as String,
      startedAt: (json['startedAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      status: json['status'] as String,
      healthData: json['healthData'] as Map<String, dynamic>?,
      pointsEarned: json['pointsEarned'] as int,
      activityData: json['activityData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'activityId': activityId,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'status': status,
      'healthData': healthData,
      'pointsEarned': pointsEarned,
      'activityData': activityData,
    };
  }

  UserProgress copyWith({
    String? userId,
    String? activityId,
    DateTime? startedAt,
    DateTime? completedAt,
    String? status,
    Map<String, dynamic>? healthData,
    int? pointsEarned,
    Map<String, dynamic>? activityData,
  }) {
    return UserProgress(
      userId: userId ?? this.userId,
      activityId: activityId ?? this.activityId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      healthData: healthData ?? this.healthData,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      activityData: activityData ?? this.activityData,
    );
  }
} 