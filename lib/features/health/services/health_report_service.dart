import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

class HealthReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Health _health = Health();

  // Health data types to collect
  final List<HealthDataType> _healthDataTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
  ];

  Future<Map<String, dynamic>> generateHealthReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Collect health data
      final healthData = await _collectHealthData(startDate, endDate);
      
      // Get self-reported metrics
      final selfReportedData = await _getSelfReportedMetrics(startDate, endDate);
      
      // Get medication adherence
      final medicationAdherence = await _getMedicationAdherence(startDate, endDate);
      
      // Generate insights
      final insights = await _generateInsights(healthData, selfReportedData, medicationAdherence);

      return {
        'period': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'healthData': healthData,
        'selfReportedData': selfReportedData,
        'medicationAdherence': medicationAdherence,
        'insights': insights,
        'generatedAt': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      debugPrint('Error generating health report: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _collectHealthData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final healthData = <String, dynamic>{};

    for (final type in _healthDataTypes) {
      try {
        final data = await _health.getHealthDataFromTypes(
          types: [type],
          startTime: startDate,
          endTime: endDate,
        );

        if (data.isNotEmpty) {
          healthData[type.toString()] = _processHealthData(data, type);
        }
      } catch (e) {
        debugPrint('Error collecting $type data: $e');
      }
    }

    return healthData;
  }

  Map<String, dynamic> _processHealthData(
    List<HealthDataPoint> data,
    HealthDataType type,
  ) {
    final values = data.map((point) => point.value as num).toList();
    
    return {
      'values': values,
      'average': values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length,
      'min': values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b),
      'max': values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b),
      'lastValue': values.isEmpty ? 0 : values.last,
      'dataPoints': data.length,
    };
  }

  Future<Map<String, dynamic>> _getSelfReportedMetrics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('self_reported_metrics')
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final metrics = <String, List<Map<String, dynamic>>>{};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final metricType = data['type'] as String;
        
        metrics.putIfAbsent(metricType, () => []).add({
          'value': data['value'],
          'timestamp': data['timestamp'],
          'notes': data['notes'],
        });
      }

      return metrics;
    } catch (e) {
      debugPrint('Error getting self-reported metrics: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getMedicationAdherence(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final medicationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .get();

      final adherence = <String, Map<String, dynamic>>{};

      for (final medication in medicationsSnapshot.docs) {
        final historySnapshot = await medication.reference
            .collection('history')
            .where('takenAt', isGreaterThanOrEqualTo: startDate)
            .where('takenAt', isLessThanOrEqualTo: endDate)
            .get();

        final totalDoses = historySnapshot.docs.length;
        final takenDoses = historySnapshot.docs
            .where((doc) => doc.data()['status'] == 'taken')
            .length;

        adherence[medication.id] = {
          'name': medication.data()['name'],
          'totalDoses': totalDoses,
          'takenDoses': takenDoses,
          'adherenceRate': totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0.0,
        };
      }

      return adherence;
    } catch (e) {
      debugPrint('Error getting medication adherence: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _generateInsights(
    Map<String, dynamic> healthData,
    Map<String, dynamic> selfReportedData,
    Map<String, dynamic> medicationAdherence,
  ) async {
    final insights = <Map<String, dynamic>>[];

    // Analyze steps
    if (healthData.containsKey(HealthDataType.STEPS.toString())) {
      final stepsData = healthData[HealthDataType.STEPS.toString()];
      final averageSteps = stepsData['average'] as double;
      
      if (averageSteps < 5000) {
        insights.add({
          'type': 'steps',
          'severity': 'warning',
          'message': 'Your average daily steps are below the recommended 5,000 steps. Consider increasing your daily activity.',
        });
      } else if (averageSteps >= 10000) {
        insights.add({
          'type': 'steps',
          'severity': 'positive',
          'message': 'Great job! You\'re consistently meeting the recommended 10,000 steps per day.',
        });
      }
    }

    // Analyze heart rate
    if (healthData.containsKey(HealthDataType.HEART_RATE.toString())) {
      final heartRateData = healthData[HealthDataType.HEART_RATE.toString()];
      final averageHeartRate = heartRateData['average'] as double;
      
      if (averageHeartRate > 100) {
        insights.add({
          'type': 'heart_rate',
          'severity': 'warning',
          'message': 'Your average heart rate is elevated. Consider consulting with your healthcare provider.',
        });
      }
    }

    // Analyze sleep
    if (healthData.containsKey(HealthDataType.SLEEP_ASLEEP.toString())) {
      final sleepData = healthData[HealthDataType.SLEEP_ASLEEP.toString()];
      final averageSleep = sleepData['average'] as double;
      
      if (averageSleep < 7) {
        insights.add({
          'type': 'sleep',
          'severity': 'warning',
          'message': 'You\'re getting less than the recommended 7-9 hours of sleep. Consider improving your sleep habits.',
        });
      }
    }

    // Analyze medication adherence
    for (final medication in medicationAdherence.entries) {
      final adherenceRate = medication.value['adherenceRate'] as double;
      
      if (adherenceRate < 80) {
        insights.add({
          'type': 'medication',
          'severity': 'warning',
          'message': 'Your adherence rate for ${medication.value['name']} is below 80%. Consider setting up additional reminders.',
        });
      }
    }

    return insights;
  }

  Future<void> saveSelfReportedMetric({
    required String type,
    required double value,
    String? notes,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('self_reported_metrics')
          .add({
        'type': type,
        'value': value,
        'notes': notes,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving self-reported metric: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getHealthReports() {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      return _firestore
          .collection('users')
          .doc(userId)
          .collection('health_reports')
          .orderBy('generatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error getting health reports: $e');
      rethrow;
    }
  }
} 