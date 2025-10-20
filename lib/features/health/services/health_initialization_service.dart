import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'health_content_service.dart';
import 'health_monitoring_service.dart';
import 'medication_service.dart';
import 'package:flutter/foundation.dart';

class HealthInitializationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HealthMonitoringService _healthMonitoringService = HealthMonitoringService();
  final HealthContentService _healthContentService = HealthContentService();
  final MedicationService _medicationService = MedicationService();

  Future<void> initializeHealthFeatures() async {
    try {
      // TODO: Initialize health platform features
      debugPrint('Health features initialized successfully');
    } catch (e) {
      debugPrint('Error initializing health features: $e');
      rethrow;
    }
  }

  Future<void> _initializeHealthContent() async {
    try {
      debugPrint('Initializing health content...');
      await _healthContentService.initializeSampleContent();
      debugPrint('Health content initialized successfully');
    } catch (e) {
      debugPrint('Error initializing health content: $e');
      // Don't rethrow, continue with initialization
    }
  }
} 