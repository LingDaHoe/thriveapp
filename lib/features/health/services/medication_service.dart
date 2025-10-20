import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/medication.dart';

class MedicationService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final String _collection = 'medications';

  // Expanded medication interaction database
  final Map<String, List<String>> _interactionDatabase = {
    // Blood Thinners
    'Warfarin': ['Aspirin', 'Ibuprofen', 'Naproxen', 'Vitamin K', 'Green Tea', 'Ginkgo Biloba'],
    'Aspirin': ['Warfarin', 'Ibuprofen', 'Naproxen', 'Clopidogrel', 'Alcohol'],
    'Clopidogrel': ['Aspirin', 'Warfarin', 'Omeprazole'],
    
    // Blood Pressure Medications
    'ACE Inhibitors': ['Potassium Supplements', 'Salt Substitutes', 'Lithium', 'NSAIDs'],
    'ARBs': ['Potassium Supplements', 'Salt Substitutes', 'Lithium'],
    'Beta Blockers': ['Calcium Channel Blockers', 'Insulin', 'Diabetes Medications'],
    'Calcium Channel Blockers': ['Beta Blockers', 'Grapefruit Juice'],
    
    // Diabetes Medications
    'Metformin': ['Contrast Dye', 'Alcohol'],
    'Sulfonylureas': ['Alcohol', 'Beta Blockers'],
    'Insulin': ['Beta Blockers', 'Corticosteroids'],
    
    // Pain Medications
    'Ibuprofen': ['Warfarin', 'Aspirin', 'Naproxen', 'ACE Inhibitors', 'Lithium'],
    'Naproxen': ['Warfarin', 'Aspirin', 'Ibuprofen', 'ACE Inhibitors', 'Lithium'],
    'Acetaminophen': ['Alcohol', 'Warfarin'],
    
    // Mental Health Medications
    'SSRIs': ['MAOIs', 'Triptans', 'NSAIDs'],
    'MAOIs': ['SSRIs', 'Tyramine-rich foods', 'Decongestants'],
    'Benzodiazepines': ['Alcohol', 'Opioids', 'Antihistamines'],
    
    // Cholesterol Medications
    'Statins': ['Grapefruit Juice', 'Fibrates', 'Niacin'],
    'Fibrates': ['Statins', 'Warfarin'],
    
    // Thyroid Medications
    'Levothyroxine': ['Iron Supplements', 'Calcium Supplements', 'Soy Products'],
    
    // Antibiotics
    'Tetracyclines': ['Calcium Supplements', 'Iron Supplements', 'Antacids'],
    'Fluoroquinolones': ['Calcium Supplements', 'Iron Supplements', 'Antacids'],
    
    // Supplements
    'Vitamin K': ['Warfarin'],
    'Potassium Supplements': ['ACE Inhibitors', 'ARBs', 'Spironolactone'],
    'Iron Supplements': ['Tetracyclines', 'Fluoroquinolones', 'Levothyroxine'],
    'Calcium Supplements': ['Tetracyclines', 'Fluoroquinolones', 'Levothyroxine'],
  };

  MedicationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  Future<void> initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Stream<List<Medication>> getMedications() {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Medication.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> addMedication(Medication medication) async {
    final docRef = _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc();
    final now = DateTime.now();
    
    await docRef.set({
      ...medication.toJson(),
      'id': docRef.id,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  Future<void> updateMedication(Medication medication) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc(medication.id)
        .update({
      ...medication.toJson(),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteMedication(String id) async {
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('medications')
        .doc(id)
        .delete();
  }

  Future<void> markMedicationAsTaken(String medicationId, DateTime takenAt) async {
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('medications')
          .doc(medicationId)
          .collection('history')
          .add({
        'takenAt': Timestamp.fromDate(takenAt),
        'status': 'taken',
      });
    } catch (e) {
      print('Error marking medication as taken: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMedicationHistory(String medicationId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('medications')
          .doc(medicationId)
          .collection('history')
          .orderBy('takenAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'takenAt': (doc.data()['takenAt'] as Timestamp).toDate(),
                'status': doc.data()['status'],
              })
          .toList();
    } catch (e) {
      print('Error fetching medication history: $e');
      return [];
    }
  }

  Future<List<String>> checkMedicationInteractions(String medicationName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get all active medications
      final medicationsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .where('isActive', isEqualTo: true)
          .get();

      final activeMedications = medicationsSnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();

      // Check for interactions
      final interactions = <String>[];
      if (_interactionDatabase.containsKey(medicationName)) {
        for (final interactingMed in _interactionDatabase[medicationName]!) {
          if (activeMedications.contains(interactingMed)) {
            interactions.add(
              'Warning: $medicationName may interact with $interactingMed. Please consult your healthcare provider.',
            );
          }
        }
      }

      return interactions;
    } catch (e) {
      debugPrint('Error checking medication interactions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMedicationAdherence(String medicationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(medicationId)
          .collection('history')
          .orderBy('takenAt', descending: true)
          .limit(30) // Last 30 days
          .get();

      final totalDoses = historySnapshot.docs.length;
      final takenDoses = historySnapshot.docs
          .where((doc) => doc.data()['status'] == 'taken')
          .length;

      final adherenceRate = totalDoses > 0 ? (takenDoses / totalDoses) * 100 : 0.0;

      return {
        'totalDoses': totalDoses,
        'takenDoses': takenDoses,
        'adherenceRate': adherenceRate,
      };
    } catch (e) {
      debugPrint('Error getting medication adherence: $e');
      rethrow;
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Notifications for medication reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> _scheduleRefillReminder({
    required int id,
    required String medicationId,
    required String medicationName,
    required int refillDays,
  }) async {
    final now = DateTime.now();
    final refillDate = now.add(Duration(days: refillDays));

    await _notifications.zonedSchedule(
      id,
      'Medication Refill Reminder',
      'Time to refill your $medicationName prescription',
      tz.TZDateTime.from(refillDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_refill_reminders',
          'Medication Refill Reminders',
          channelDescription: 'Notifications for medication refill reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<String> exportMedicationHistory(String medicationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final medicationDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(medicationId)
          .get();

      final historySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc(medicationId)
          .collection('history')
          .orderBy('takenAt', descending: true)
          .get();

      final medication = medicationDoc.data()!;
      final history = historySnapshot.docs.map((doc) => doc.data()).toList();

      // Create CSV content
      final csv = StringBuffer();
      csv.writeln('Medication History Report');
      csv.writeln('Generated: ${DateTime.now()}');
      csv.writeln();
      csv.writeln('Medication Details:');
      csv.writeln('Name: ${medication['name']}');
      csv.writeln('Dosage: ${medication['dosage']}');
      csv.writeln('Frequency: ${medication['frequency']}');
      csv.writeln();
      csv.writeln('History:');
      csv.writeln('Date,Time,Status,Reason');
      
      for (final entry in history) {
        final timestamp = entry['takenAt'] as Timestamp;
        final date = timestamp.toDate();
        final status = entry['status'] as String;
        final reason = entry['reason'] as String?;
        
        csv.writeln(
          '${date.toIso8601String().split('T')[0]},'
          '${date.toIso8601String().split('T')[1].split('.')[0]},'
          '$status,'
          '${reason ?? ""}',
        );
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Error exporting medication history: $e');
      rethrow;
    }
  }
} 