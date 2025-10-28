import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_user.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current session is admin
  static Future<bool> isAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('isAdmin') ?? false;
    } catch (e) {
      return false;
    }
  }

  // Clear admin session
  static Future<void> clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdmin');
    } catch (e) {
      debugPrint('Error clearing admin session: $e');
    }
  }

  // Check if current user is admin/caretaker
  Future<AdminUser?> getCurrentAdminUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (!doc.exists) return null;

      return AdminUser.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error getting admin user: $e');
      return null;
    }
  }

  // Get all users assigned to this admin/caretaker
  Future<List<Map<String, dynamic>>> getAssignedUsers(String adminUid) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminUid).get();
      if (!adminDoc.exists) return [];

      final assignedUserIds = List<String>.from(adminDoc.data()?['assignedUsers'] ?? []);
      
      if (assignedUserIds.isEmpty) return [];

      final users = <Map<String, dynamic>>[];
      for (final userId in assignedUserIds) {
        final userDoc = await _firestore.collection('profiles').doc(userId).get();
        if (userDoc.exists) {
          users.add({
            'uid': userId,
            ...userDoc.data()!,
          });
        }
      }

      return users;
    } catch (e) {
      debugPrint('Error getting assigned users: $e');
      return [];
    }
  }

  // Get all users in the system
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection('profiles')
          .orderBy('displayName')
          .get();

      return snapshot.docs.map((doc) => {
        'uid': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      return [];
    }
  }

  // Get user's health metrics
  Future<Map<String, dynamic>> getUserHealthMetrics(String userId) async {
    try {
      // Get latest health data
      final healthSnapshot = await _firestore
          .collection('healthData')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (healthSnapshot.docs.isEmpty) {
        return {'error': 'No health data available'};
      }

      return healthSnapshot.docs.first.data();
    } catch (e) {
      debugPrint('Error getting health metrics: $e');
      return {'error': e.toString()};
    }
  }

  // Get user's activity progress
  Future<List<Map<String, dynamic>>> getUserActivities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting user activities: $e');
      return [];
    }
  }

  // Get user's medications
  Future<List<Map<String, dynamic>>> getUserMedications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('medications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting medications: $e');
      return [];
    }
  }

  // Add medication for user
  Future<void> addMedicationForUser(String userId, Map<String, dynamic> medication) async {
    try {
      await _firestore.collection('medications').add({
        ...medication,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'addedBy': _auth.currentUser?.uid,
        'addedByRole': 'admin',
      });
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  // Update medication
  Future<void> updateMedication(String medicationId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('medications').doc(medicationId).update(updates);
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  // Delete medication
  Future<void> deleteMedication(String medicationId) async {
    try {
      await _firestore.collection('medications').doc(medicationId).delete();
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // Get SOS events
  Future<List<Map<String, dynamic>>> getSOSEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_events')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting SOS events: $e');
      return [];
    }
  }

  // Get all SOS events for all assigned users
  Future<List<Map<String, dynamic>>> getAllSOSEvents(String adminUid) async {
    try {
      final adminDoc = await _firestore.collection('admins').doc(adminUid).get();
      if (!adminDoc.exists) return [];

      final assignedUserIds = List<String>.from(adminDoc.data()?['assignedUsers'] ?? []);
      
      final allEvents = <Map<String, dynamic>>[];
      for (final userId in assignedUserIds) {
        final events = await getSOSEvents(userId);
        for (final event in events) {
          allEvents.add({
            ...event,
            'userId': userId,
          });
        }
      }

      // Sort by timestamp descending
      allEvents.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return allEvents;
    } catch (e) {
      debugPrint('Error getting all SOS events: $e');
      return [];
    }
  }

  // Get all SOS events from all users in the system
  Future<List<Map<String, dynamic>>> getAllSOSEventsFromAllUsers() async {
    try {
      // Get all users
      final usersSnapshot = await _firestore.collection('profiles').get();
      
      final allEvents = <Map<String, dynamic>>[];
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final events = await getSOSEvents(userId);
        for (final event in events) {
          // Add user info to the event
          allEvents.add({
            ...event,
            'userId': userId,
            'userName': userDoc.data()['displayName'] ?? 'Unknown User',
            'userEmail': userDoc.data()['email'] ?? '',
          });
        }
      }

      // Sort by timestamp descending
      allEvents.sort((a, b) {
        final aTime = a['timestamp'] as Timestamp?;
        final bTime = b['timestamp'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return allEvents;
    } catch (e) {
      debugPrint('Error getting all SOS events from all users: $e');
      return [];
    }
  }

  // Admin login (check if user exists in admins collection)
  Future<AdminUser?> adminLogin(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if user is in admins collection
      final adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      if (!adminDoc.exists) {
        // Not an admin, sign out
        await _auth.signOut();
        return null;
      }

      // Mark as admin in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', true);

      // Update last login
      await _firestore.collection('admins').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return AdminUser.fromFirestore(adminDoc);
    } catch (e) {
      debugPrint('Error during admin login: $e');
      rethrow;
    }
  }

  // Create admin user (for initial setup)
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String displayName,
    required String role,
    List<String> assignedUsers = const [],
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create admin document
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'email': email,
        'displayName': displayName,
        'role': role,
        'assignedUsers': assignedUsers,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e) {
      debugPrint('Error creating admin user: $e');
      rethrow;
    }
  }
}

