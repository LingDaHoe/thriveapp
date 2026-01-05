import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatMessage {
  final String id;
  final String chatId;
  final String userId;
  final String userName;
  final String content;
  final DateTime timestamp;
  final List<String> seenBy; // Users who have seen this message

  GroupChatMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.userName,
    required this.content,
    required this.timestamp,
    this.seenBy = const [],
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
    };
  }
}

