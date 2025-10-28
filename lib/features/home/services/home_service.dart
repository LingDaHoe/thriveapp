import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart' show Health, HealthDataType;
import '../home_bloc.dart';
import '../models/recommendation.dart';

class HomeData {
  final String userName;
  final int steps;
  final int heartRate;
  final double sleepHours;
  final List<Recommendation> recommendations;

  HomeData({
    required this.userName,
    required this.steps,
    required this.heartRate,
    required this.sleepHours,
    required this.recommendations,
  });
}

class HomeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Health _health = Health();
  static const platform = MethodChannel('com.example.thriveapp/health');
  bool _permissionsGranted = false;

  HomeService() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onHealthPermissionsResult') {
        _permissionsGranted = call.arguments as bool;
        return null;
      }
      throw PlatformException(code: 'notImplemented');
    });
  }

  Future<HomeData> getHomeData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Get user profile
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Request health permissions through platform channel
      if (!_permissionsGranted) {
        try {
          final result = await platform.invokeMethod('requestHealthPermissions');
          if (result != true) {
            debugPrint('Health permissions not granted, using fallback data');
            // Use fallback data instead of throwing error
            return HomeData(
              userName: userData['displayName'] ?? 'User',
              steps: 0,
              heartRate: 0,
              sleepHours: 0,
              recommendations: [Recommendation(
                title: 'Grant Health Permissions',
                description: 'Grant health permissions to see your activity data',
                icon: Icons.health_and_safety,
              )],
            );
          }
          _permissionsGranted = true;
        } catch (e) {
          debugPrint('Error requesting health permissions: $e');
          // Use fallback data instead of throwing error
          return HomeData(
            userName: userData['displayName'] ?? 'User',
            steps: 0,
            heartRate: 0,
            sleepHours: 0,
            recommendations: [Recommendation(
              title: 'Grant Health Permissions',
              description: 'Grant health permissions to see your activity data',
              icon: Icons.health_and_safety,
            )],
          );
        }
      }

      // Get health data
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 1));
      
      final steps = await _getSteps(startTime, now);
      final heartRate = await _getHeartRate(startTime, now);
      final sleepHours = await _getSleepHours(startTime, now);

      // Generate recommendations
      final recommendations = _generateRecommendations(steps, heartRate, sleepHours);

      return HomeData(
        userName: userData['displayName'] ?? 'User',
        steps: steps,
        heartRate: heartRate,
        sleepHours: sleepHours,
        recommendations: recommendations,
      );
    } catch (e) {
      debugPrint('Error in getHomeData: $e');
      throw Exception('Failed to load home data: $e');
    }
  }

  Future<int> _getSteps(DateTime start, DateTime end) async {
    try {
      final steps = await _health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Error getting steps: $e');
      return 0;
    }
  }

  Future<int> _getHeartRate(DateTime start, DateTime end) async {
    try {
      final heartRate = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (heartRate.isNotEmpty) {
        final value = heartRate.last.value;
        if (value is num) {
          return (value as num).toInt();
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting heart rate: $e');
      return 0;
    }
  }

  Future<double> _getSleepHours(DateTime start, DateTime end) async {
    try {
      final sleep = await _health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: end,
      );
      if (sleep.isNotEmpty) {
        final value = sleep.last.value;
        if (value is num) {
          return (value as num) / 3600; // Convert seconds to hours
        }
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting sleep hours: $e');
      return 0;
    }
  }

  List<Recommendation> _generateRecommendations(
    int steps,
    int heartRate,
    double sleepHours,
  ) {
    final recommendations = <Recommendation>[];

    // Activity recommendations
    if (steps < 5000) {
      recommendations.add(
        Recommendation(
          title: 'Increase Daily Steps',
          description: 'Try to reach at least 5,000 steps today',
          icon: Icons.directions_walk,
        ),
      );
    }

    // Heart rate recommendations
    if (heartRate > 100) {
      recommendations.add(
        Recommendation(
          title: 'High Heart Rate',
          description: 'Consider taking a short rest',
          icon: Icons.favorite,
        ),
      );
    }

    // Sleep recommendations
    if (sleepHours < 7) {
      recommendations.add(
        Recommendation(
          title: 'Improve Sleep',
          description: 'Aim for 7-9 hours of sleep',
          icon: Icons.bedtime,
        ),
      );
    }

    // Health education recommendations
    recommendations.add(
      Recommendation(
        title: 'Health Education',
        description: 'Learn about managing your health',
        icon: Icons.school,
      ),
    );

    return recommendations;
  }
} 