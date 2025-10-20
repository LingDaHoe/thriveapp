import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatAIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiKey = const String.fromEnvironment('DEEPSEEK_API_KEY');
  final String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  // Send message to AI and get response
  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required List<Map<String, dynamic>> chatHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a health assistant AI that helps users with their health-related questions and concerns. 
              You should provide accurate, helpful, and empathetic responses while being mindful of medical advice limitations.
              Always encourage users to consult healthcare professionals for specific medical advice.'''
            },
            ...chatHistory.map((msg) => {
              'role': msg['role'],
              'content': msg['content'],
            }),
            {
              'role': 'user',
              'content': message,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        // Save chat history
        await _saveChatHistory(message, aiResponse);
        
        return {
          'message': aiResponse,
          'timestamp': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending message to AI: $e');
      rethrow;
    }
  }

  // Save chat history to Firestore
  Future<void> _saveChatHistory(String userMessage, String aiResponse) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .add({
        'user_message': userMessage,
        'ai_response': aiResponse,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Get chat history
  Stream<List<Map<String, dynamic>>> getChatHistory() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting chat history: $e');
      rethrow;
    }
  }

  // Clear chat history
  Future<void> clearChatHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
      rethrow;
    }
  }
} 