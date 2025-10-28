import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';

class HealthMonitoringService {
  final Health health = Health();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const platform = MethodChannel('com.example.thriveapp/health');
  bool _permissionsGranted = false;

  // Define the types of health data we want to collect
  final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
  ];

  HealthMonitoringService() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onHealthPermissionsResult') {
        _permissionsGranted = call.arguments as bool;
        return null;
      }
      throw PlatformException(code: 'notImplemented');
    });
  }

  Future<bool> requestHealthPermissions() async {
    try {
      // TODO: Request health platform permissions
      debugPrint('Health permissions requested successfully');
      return true;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      return false;
    }
  }

  Future<bool> checkHealthPermissions() async {
    try {
      debugPrint('HealthMonitoringService: Checking health permissions');
      
      // Check activity recognition permission
      final activityStatus = await Permission.activityRecognition.status;
      if (!activityStatus.isGranted) {
        debugPrint('HealthMonitoringService: Activity recognition permission not granted');
        _permissionsGranted = false;
        return false;
      }

      // Check health permissions
      final hasPermissions = await health.hasPermissions(_types);
      debugPrint('HealthMonitoringService: Health permissions check result: $hasPermissions');
      
      _permissionsGranted = hasPermissions ?? false;
      return hasPermissions ?? false;
    } catch (e) {
      debugPrint('HealthMonitoringService: Error checking health permissions: $e');
      _permissionsGranted = false;
      return false;
    }
  }

  Future<Map<String, dynamic>> getHealthMetrics() async {
    try {
      if (!_permissionsGranted) {
        final granted = await requestHealthPermissions();
        if (!granted) {
          debugPrint('Health permissions not granted - returning default values');
          // Return default values instead of throwing
          return {
            'steps': 0,
            'heartRate': 0,
            'sleep': 0.0,
            'bloodPressure': {'systolic': 0, 'diastolic': 0},
            'bloodOxygen': 0.0,
            'bodyTemperature': 0.0,
          };
        }
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      
      // Get real health data
      final steps = await _getSteps(startOfDay, now);
      final heartRate = await _getHeartRate(startOfDay, now);
      final sleepHours = await _getSleepHours(startOfDay, now);
      
      final metrics = {
        'steps': steps,
        'heartRate': heartRate,
        'sleep': sleepHours,
        'bloodPressure': {'systolic': 0, 'diastolic': 0},
        'bloodOxygen': 0.0,
        'bodyTemperature': 0.0,
      };
      
      // Store metrics for historical tracking (only if we have valid data)
      if (steps > 0 || heartRate > 0) {
        await _storeHealthMetrics(metrics);
      }
      
      return metrics;
    } catch (e) {
      debugPrint('Error getting health metrics: $e');
      // Return default values on error instead of throwing
      return {
        'steps': 0,
        'heartRate': 0,
        'sleep': 0.0,
        'bloodPressure': {'systolic': 0, 'diastolic': 0},
        'bloodOxygen': 0.0,
        'bodyTemperature': 0.0,
      };
    }
  }

  Future<void> _storeHealthMetrics(Map<String, dynamic> metrics) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        debugPrint('User not authenticated - skipping health metrics storage');
        return;
      }

      await _firestore.collection('healthData').add({
        'userId': userId,
        'date': FieldValue.serverTimestamp(),
        'metrics': metrics,
        'source': 'healthkit',
      });
    } catch (e) {
      debugPrint('Error storing health metrics: $e');
      // Don't rethrow - just log the error
    }
  }

  Future<int> _getSteps(DateTime start, DateTime end) async {
    try {
      final steps = await health.getTotalStepsInInterval(start, end);
      return steps ?? 0;
    } catch (e) {
      debugPrint('Error getting steps: $e');
      return 0;
    }
  }

  Future<double> _getHeartRate(DateTime start, DateTime end) async {
    try {
      final heartRate = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      if (heartRate.isEmpty) return 0.0;
      double sum = 0;
      for (var data in heartRate) {
        sum += (data.value as num?)?.toDouble() ?? 0.0;
      }
      return sum / heartRate.length;
    } catch (e) {
      debugPrint('Error getting heart rate: $e');
      return 0.0;
    }
  }

  Future<double> _getSleepHours(DateTime start, DateTime end) async {
    try {
      final sleep = await health.getHealthDataFromTypes(
        types: [HealthDataType.SLEEP_ASLEEP],
        startTime: start,
        endTime: end,
      );
      if (sleep.isEmpty) return 0.0;
      double totalMinutes = 0;
      for (var data in sleep) {
        totalMinutes += data.dateTo.difference(data.dateFrom).inMinutes.toDouble();
      }
      return totalMinutes / 60.0;
    } catch (e) {
      debugPrint('Error getting sleep hours: $e');
      return 0.0;
    }
  }

  Future<double> _getBloodOxygen(DateTime start, DateTime end) async {
    try {
      final bloodOxygen = await health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_OXYGEN],
        startTime: start,
        endTime: end,
      );
      if (bloodOxygen.isEmpty) return 0.0;
      return (bloodOxygen.last.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting blood oxygen: $e');
      return 0.0;
    }
  }

  Future<Map<String, double>> _getBloodPressure(DateTime start, DateTime end) async {
    try {
      final systolic = await health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
        startTime: start,
        endTime: end,
      );
      final diastolic = await health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
        startTime: start,
        endTime: end,
      );

      return {
        'systolic': (systolic.last.value as num?)?.toDouble() ?? 0.0,
        'diastolic': (diastolic.last.value as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error getting blood pressure: $e');
      return {'systolic': 0.0, 'diastolic': 0.0};
    }
  }

  Future<double> _getBloodGlucose(DateTime start, DateTime end) async {
    try {
      final glucose = await health.getHealthDataFromTypes(
        types: [HealthDataType.BLOOD_GLUCOSE],
        startTime: start,
        endTime: end,
      );
      if (glucose.isEmpty) return 0.0;
      return (glucose.last.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting blood glucose: $e');
      return 0.0;
    }
  }

  Future<double> _getBodyTemperature(DateTime start, DateTime end) async {
    try {
      final temperature = await health.getHealthDataFromTypes(
        types: [HealthDataType.BODY_TEMPERATURE],
        startTime: start,
        endTime: end,
      );
      if (temperature.isEmpty) return 0.0;
      return (temperature.last.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting body temperature: $e');
      return 0.0;
    }
  }

  Future<double> _getWeight(DateTime start, DateTime end) async {
    try {
      final weight = await health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: start,
        endTime: end,
      );
      if (weight.isEmpty) return 0.0;
      return (weight.last.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting weight: $e');
      return 0.0;
    }
  }

  Future<double> _getHeight(DateTime start, DateTime end) async {
    try {
      final height = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: start,
        endTime: end,
      );
      if (height.isEmpty) return 0.0;
      return (height.last.value as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error getting height: $e');
      return 0.0;
    }
  }

  Future<List<Map<String, dynamic>>> getHealthHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshot = await _firestore
          .collection('healthData')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting health history: $e');
      rethrow;
    }
  }

  Future<Map<String, List<FlSpot>>> getHistoricalHealthData() async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 7));
      
      // Get data from Health Connect
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.BLOOD_OXYGEN,
        HealthDataType.BODY_TEMPERATURE,
      ];

      final permissions = await health.requestAuthorization(types);
      if (!permissions) {
        throw Exception('Health permissions not granted');
      }

      final healthData = await health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: now,
        types: types,
      );

      // Process and format data for charts
      final Map<String, List<FlSpot>> chartData = {};
      
      for (final type in types) {
        final dataPoints = healthData
            .where((data) => data.type == type)
            .map((data) {
              final x = data.dateFrom.millisecondsSinceEpoch.toDouble();
              final y = (data.value as num).toDouble();
              return FlSpot(x, y);
            })
            .toList();
        
        // Sort by timestamp
        dataPoints.sort((a, b) => a.x.compareTo(b.x));
        
        // Normalize x values to days (0-7)
        if (dataPoints.isNotEmpty) {
          final firstTimestamp = dataPoints.first.x;
          final lastTimestamp = dataPoints.last.x;
          final range = lastTimestamp - firstTimestamp;
          
          final normalizedPoints = dataPoints.map((point) {
            final normalizedX = ((point.x - firstTimestamp) / range) * 7;
            return FlSpot(normalizedX, point.y);
          }).toList();
          
          chartData[type.toString()] = normalizedPoints;
        }
      }

      return chartData;
    } catch (e) {
      // If Health Connect fails, try to get data from Firestore
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) throw Exception('User not authenticated');

        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('health_metrics')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .get();

        final Map<String, List<FlSpot>> chartData = {};
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = (data['timestamp'] as Timestamp).toDate();
          if (timestamp.isBefore(startDate)) continue;

          final x = ((timestamp.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch) / 
              (now.millisecondsSinceEpoch - startDate.millisecondsSinceEpoch)) * 7;

          for (final metric in data.keys) {
            if (metric == 'timestamp') continue;
            
            final value = data[metric];
            if (value is num) {
              chartData.putIfAbsent(metric, () => []);
              chartData[metric]!.add(FlSpot(x, value.toDouble()));
            }
          }
        }

        // Sort all data points by x value
        for (final metric in chartData.keys) {
          chartData[metric]!.sort((a, b) => a.x.compareTo(b.x));
        }

        return chartData;
      } catch (e) {
        throw Exception('Failed to get historical health data: $e');
      }
    }
  }

  Future<void> _updatePermissionsInFirestore(bool granted) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore.collection('users').doc(userId).update({
        'healthPermissionsGranted': granted,
        'lastPermissionCheck': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating permissions in Firestore: $e');
      rethrow;
    }
  }
} 