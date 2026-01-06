import 'package:cloud_firestore/cloud_firestore.dart';

class SocialActivity {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final DateTime scheduledTime;
  final String location;
  final int maxParticipants;
  final List<String> participantIds;
  final DateTime createdAt;
  final String? chatId; // Group chat ID for the activity

  SocialActivity({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.scheduledTime,
    required this.location,
    required this.maxParticipants,
    required this.participantIds,
    required this.createdAt,
    this.chatId,
  });

  factory SocialActivity.fromJson(Map<String, dynamic> json) {
    return SocialActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      scheduledTime: (json['scheduledTime'] as Timestamp).toDate(),
      location: json['location'] as String,
      maxParticipants: json['maxParticipants'] as int,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      chatId: json['chatId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'location': location,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'chatId': chatId,
    };
  }

  bool get isFull => participantIds.length >= maxParticipants;
  int get availableSpots => maxParticipants - participantIds.length;
  bool isParticipant(String userId) => participantIds.contains(userId);
}


