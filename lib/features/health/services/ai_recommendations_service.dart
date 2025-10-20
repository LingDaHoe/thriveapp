import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AIRecommendationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _apiKey = const String.fromEnvironment('DEEPSEEK_API_KEY');
  final String _apiUrl = 'https://api.deepseek.com/v1/chat/completions';

  // Get personalized recommendations based on user data
  Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's health data
      final healthData = await _getUserHealthData();
      
      // Get user's activity data
      final activityData = await _getUserActivityData();
      
      // Get user's medication data
      final medicationData = await _getUserMedicationData();

      // Prepare context for AI
      final context = {
        'health_data': healthData,
        'activity_data': activityData,
        'medication_data': medicationData,
      };

      // Get AI recommendations
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
              'content': '''You are a health recommendation AI that provides personalized health and wellness recommendations.
              Analyze the user's health data, activity patterns, and medication information to provide relevant suggestions.
              Focus on actionable, practical recommendations that can improve the user's health and well-being.
              Always consider the user's current health status and limitations.'''
            },
            {
              'role': 'user',
              'content': jsonEncode(context),
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = data['choices'][0]['message']['content'];
        
        // Parse and structure recommendations
        final structuredRecommendations = _parseRecommendations(recommendations);
        
        // Save recommendations
        await _saveRecommendations(structuredRecommendations);
        
        return structuredRecommendations;
      } else {
        throw Exception('Failed to get recommendations: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting recommendations: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getUserHealthData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('health_reports')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return {};

      return snapshot.docs.first.data();
    } catch (e) {
      debugPrint('Error getting user health data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getUserActivityData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .limit(7)
          .get();

      return {
        'recent_activities': snapshot.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      debugPrint('Error getting user activity data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _getUserMedicationData() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .get();

      return {
        'medications': snapshot.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      debugPrint('Error getting user medication data: $e');
      return {};
    }
  }

  List<Map<String, dynamic>> _parseRecommendations(String recommendations) {
    try {
      final List<Map<String, dynamic>> parsed = [];
      final lines = recommendations.split('\n');
      
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        
        final parts = line.split(':');
        if (parts.length >= 2) {
          parsed.add({
            'category': parts[0].trim(),
            'recommendation': parts[1].trim(),
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
      
      return parsed;
    } catch (e) {
      debugPrint('Error parsing recommendations: $e');
      return [];
    }
  }

  Future<void> _saveRecommendations(List<Map<String, dynamic>> recommendations) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      
      for (final recommendation in recommendations) {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('recommendations')
            .doc();
            
        batch.set(docRef, {
          ...recommendation,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error saving recommendations: $e');
    }
  }

  // Get saved recommendations
  Stream<List<Map<String, dynamic>>> getSavedRecommendations() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
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
      debugPrint('Error getting saved recommendations: $e');
      rethrow;
    }
  }
} 