import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatMessage {
  final String id;
  final String chatId;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final List<String> seenBy; // Users who have seen this message
  final String? imageUrl; // URL of uploaded image
  final String? videoUrl; // URL of uploaded video
  final String? mediaType; // 'image' or 'video'

  GroupChatMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    this.seenBy = const [],
    this.imageUrl,
    this.videoUrl,
    this.mediaType,
  });

  factory GroupChatMessage.fromJson(Map<String, dynamic> json) {
    return GroupChatMessage(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      content: json['content'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      seenBy: List<String>.from(json['seenBy'] ?? []),
      imageUrl: json['imageUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      mediaType: json['mediaType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'seenBy': seenBy,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (videoUrl != null) 'videoUrl': videoUrl,
      if (mediaType != null) 'mediaType': mediaType,
    };
  }
}

