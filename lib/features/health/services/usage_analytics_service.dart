import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UsageAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Track feature usage
  Future<void> trackFeatureUsage({
    required String feature,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('usage_analytics')
          .add({
        'feature': feature,
        'action': action,
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking feature usage: $e');
    }
  }

  // Track screen view
  Future<void> trackScreenView(String screenName) async {
    await trackFeatureUsage(
      feature: 'screen_view',
      action: 'view',
      metadata: {'screen_name': screenName},
    );
  }

  // Track health data input
  Future<void> trackHealthDataInput({
    required String dataType,
    required String inputMethod,
    Map<String, dynamic>? metadata,
  }) async {
    await trackFeatureUsage(
      feature: 'health_data',
      action: 'input',
      metadata: {
        'data_type': dataType,
        'input_method': inputMethod,
        ...?metadata,
      },
    );
  }

  // Get usage statistics
  Future<Map<String, dynamic>> getUsageStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('usage_analytics')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final analytics = <String, Map<String, int>>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final feature = data['feature'] as String;
        final action = data['action'] as String;

        analytics.putIfAbsent(feature, () => {});
        analytics[feature]!.update(
          action,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }

      return {
        'total_events': snapshot.docs.length,
        'feature_usage': analytics,
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
      };
    } catch (e) {
      debugPrint('Error getting usage statistics: $e');
      rethrow;
    }
  }

  // Get feature usage trends
  Stream<Map<String, dynamic>> getFeatureUsageTrends({
    required String feature,
    required Duration interval,
  }) async* {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      while (true) {
        final endDate = DateTime.now();
        final startDate = endDate.subtract(interval);

        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('usage_analytics')
            .where('feature', isEqualTo: feature)
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .get();

        final trends = <String, int>{};
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final action = data['action'] as String;
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          final timeKey = _getTimeKey(timestamp, interval);

          trends.update(
            timeKey,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }

        yield {
          'feature': feature,
          'trends': trends,
          'period': {
            'start': startDate.toIso8601String(),
            'end': endDate.toIso8601String(),
          },
        };

        await Future.delayed(const Duration(minutes: 1));
      }
    } catch (e) {
      debugPrint('Error getting feature usage trends: $e');
      rethrow;
    }
  }

  String _getTimeKey(DateTime timestamp, Duration interval) {
    if (interval.inHours <= 1) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (interval.inDays <= 1) {
      return DateFormat('HH:00').format(timestamp);
    } else if (interval.inDays <= 7) {
      return DateFormat('E').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
} 