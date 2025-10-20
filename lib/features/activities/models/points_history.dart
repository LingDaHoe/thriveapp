import 'package:cloud_firestore/cloud_firestore.dart';

class PointsHistory {
  final String id;
  final String userId;
  final int points;
  final String source; // 'activity', 'achievement', 'streak'
  final String sourceId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PointsHistory({
    required this.id,
    required this.userId,
    required this.points,
    required this.source,
    required this.sourceId,
    required this.timestamp,
    this.metadata,
  });

  factory PointsHistory.fromJson(Map<String, dynamic> json) {
    return PointsHistory(
      id: json['id'] as String,
      userId: json['userId'] as String,
      points: json['points'] as int,
      source: json['source'] as String,
      sourceId: json['sourceId'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'source': source,
      'sourceId': sourceId,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
} 