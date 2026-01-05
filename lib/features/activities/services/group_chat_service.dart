import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/group_chat_message.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get messages for a chat
  Stream<List<GroupChatMessage>> getMessages(String chatId) {
    return _firestore
        .collection('group_chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return GroupChatMessage.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    });
  }

  /// Send a message to a chat
  Future<void> sendMessage(String chatId, String content) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get user name
      final profileDoc = await _firestore.collection('profiles').doc(userId).get();
      final userName = profileDoc.data()?['displayName'] ?? 'User';

      // Create message
      final messageRef = _firestore
          .collection('group_chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final message = GroupChatMessage(
        id: messageRef.id,
        chatId: chatId,
        userId: userId,
        userName: userName,
        content: content.trim(),
        timestamp: DateTime.now(),
        seenBy: [userId], // Sender has seen their own message
      );

      // Save message
      await messageRef.set(message.toJson());

      // Update chat's last message timestamp
      await _firestore.collection('group_chats').doc(chatId).update({
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageContent': content.trim(),
        'lastMessageSender': userName,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  /// Mark a message as seen by the current user
  Future<void> markMessageAsSeen(String chatId, String messageId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final messageRef = _firestore
          .collection('group_chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId);

      await messageRef.update({
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error marking message as seen: $e');
    }
  }

  /// Mark all messages in chat as seen by current user
  Future<void> markAllMessagesAsSeen(String chatId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      final messagesSnapshot = await _firestore
          .collection('group_chats')
          .doc(chatId)
          .collection('messages')
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        final seenBy = List<String>.from(doc.data()['seenBy'] ?? []);
        if (!seenBy.contains(userId)) {
          batch.update(doc.reference, {
            'seenBy': FieldValue.arrayUnion([userId]),
          });
        }
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all messages as seen: $e');
    }
  }

  /// Get list of participants with their names
  Future<List<Map<String, String>>> getParticipants(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('group_chats').doc(chatId).get();
      if (!chatDoc.exists) return [];

      final members = List<String>.from(chatDoc.data()?['members'] ?? []);
      final participants = <Map<String, String>>[];

      for (var memberId in members) {
        try {
          final profileDoc = await _firestore.collection('profiles').doc(memberId).get();
          final displayName = profileDoc.data()?['displayName'] ?? 'User';
          participants.add({
            'userId': memberId,
            'name': displayName,
          });
        } catch (e) {
          debugPrint('Error getting participant name: $e');
        }
      }

      return participants;
    } catch (e) {
      debugPrint('Error getting participants: $e');
      return [];
    }
  }

  /// Get stream of participants
  Stream<List<Map<String, String>>> getParticipantsStream(String chatId) {
    return _firestore
        .collection('group_chats')
        .doc(chatId)
        .collection('members')
        .snapshots()
        .asyncMap((snapshot) async {
      final participants = <Map<String, String>>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        participants.add({
          'userId': data['userId'] as String? ?? doc.id,
          'name': data['name'] as String? ?? 'User',
        });
      }
      return participants;
    });
  }

  /// Get chat info
  Future<Map<String, dynamic>?> getChatInfo(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('group_chats').doc(chatId).get();
      if (!chatDoc.exists) return null;
      return chatDoc.data();
    } catch (e) {
      debugPrint('Error getting chat info: $e');
      return null;
    }
  }

  /// Check if user is a member of the chat
  Future<bool> isMember(String chatId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final chatDoc = await _firestore.collection('group_chats').doc(chatId).get();
      if (!chatDoc.exists) return false;

      final members = List<String>.from(chatDoc.data()?['members'] ?? []);
      return members.contains(userId);
    } catch (e) {
      debugPrint('Error checking membership: $e');
      return false;
    }
  }
}

