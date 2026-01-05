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
      await prefs.remove('userRole');
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

      try {
        return AdminUser.fromFirestore(doc);
      } catch (parseError) {
        debugPrint('Error parsing admin user: $parseError');
        // If parsing fails due to missing/null timestamps, fix the document
        final data = doc.data()!;
        
        // Update document with missing timestamps
        final updates = <String, dynamic>{};
        if (data['createdAt'] == null) {
          updates['createdAt'] = FieldValue.serverTimestamp();
        }
        if (data['lastLogin'] == null) {
          updates['lastLogin'] = FieldValue.serverTimestamp();
        }
        
        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
          debugPrint('Fixed missing timestamps in admin document');
          // Try parsing again
          final updatedDoc = await doc.reference.get();
          return AdminUser.fromFirestore(updatedDoc);
        }
        
        // If we can't fix it, return null
        return null;
      }
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

  // Get user's activity progress with comprehensive details
  Future<List<Map<String, dynamic>>> getUserActivities(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(50) // Increased limit for comprehensive view
          .get();

      final activities = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get activity details if activityId exists
        String? activityTitle = data['title'] as String?;
        String? activityType = data['type'] as String?;
        
        if (data['activityId'] != null && activityTitle == null) {
          try {
            // Try to get activity details from activities collection
            final activityDoc = await _firestore
                .collection('activities')
                .doc(data['activityId'] as String)
                .get();
            
            if (activityDoc.exists) {
              final activityData = activityDoc.data()!;
              activityTitle = activityData['title'] as String?;
              activityType = activityData['type'] as String?;
            }
          } catch (e) {
            debugPrint('Error fetching activity details: $e');
          }
        }
        
        activities.add({
          'id': doc.id,
          ...data,
          'title': activityTitle ?? data['title'] ?? 'Activity',
          'type': activityType ?? data['type'] ?? 'unknown',
        });
      }
      
      return activities;
    } catch (e) {
      debugPrint('Error getting user activities: $e');
      // Fallback: try without orderBy if index is missing
      try {
        final snapshot = await _firestore
            .collection('activityProgress')
            .doc(userId)
            .collection('activities')
            .where('status', isEqualTo: 'completed')
            .limit(50)
            .get();
        
        final activities = snapshot.docs.map((doc) => doc.data()).toList();
        // Sort in memory
        activities.sort((a, b) {
          final aTime = a['completedAt'] as Timestamp?;
          final bTime = b['completedAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        return activities;
      } catch (e2) {
        debugPrint('Error in fallback query: $e2');
        return [];
      }
    }
  }

  // Get user's medications (check both collections for compatibility)
  Future<List<Map<String, dynamic>>> getUserMedications(String userId) async {
    try {
      final medications = <Map<String, dynamic>>[];
      
      // Try users/{userId}/medications collection first (user's own collection)
      try {
        final userMedicationsSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('medications')
            .orderBy('createdAt', descending: true)
            .get();
        
        for (var doc in userMedicationsSnapshot.docs) {
          final data = doc.data();
          medications.add({
            'id': doc.id,
            ...data,
            'source': 'user_collection',
          });
        }
      } catch (e) {
        debugPrint('Error getting medications from user collection: $e');
      }
      
      // Also check medications collection (admin-added medications)
      try {
        final adminMedicationsSnapshot = await _firestore
            .collection('medications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();
        
        for (var doc in adminMedicationsSnapshot.docs) {
          final data = doc.data();
          // Avoid duplicates
          if (!medications.any((m) => m['id'] == doc.id)) {
            medications.add({
              'id': doc.id,
              ...data,
              'source': 'admin_collection',
            });
          }
        }
      } catch (e) {
        debugPrint('Error getting medications from admin collection: $e');
      }
      
      // Sort by createdAt descending
      medications.sort((a, b) {
        final aTime = a['createdAt'];
        final bTime = b['createdAt'];
        if (aTime == null || bTime == null) return 0;
        
        DateTime aDate, bDate;
        if (aTime is Timestamp) {
          aDate = aTime.toDate();
        } else if (aTime is String) {
          aDate = DateTime.parse(aTime);
        } else {
          return 0;
        }
        
        if (bTime is Timestamp) {
          bDate = bTime.toDate();
        } else if (bTime is String) {
          bDate = DateTime.parse(bTime);
        } else {
          return 0;
        }
        
        return bDate.compareTo(aDate);
      });
      
      return medications;
    } catch (e) {
      debugPrint('Error getting medications: $e');
      return [];
    }
  }

  // Add medication for user (adds to both collections for sync)
  Future<void> addMedicationForUser(String userId, Map<String, dynamic> medication) async {
    try {
      final now = DateTime.now();
      
      // Ensure all required fields are present with defaults
      final medicationData = {
        'id': '', // Will be set after document creation
        'name': medication['name'] ?? '',
        'dosage': medication['dosage'] ?? '',
        'frequency': medication['frequency'] ?? 'Once daily',
        'times': medication['times'] ?? ['09:00'], // Default to morning
        'startDate': medication['startDate'] ?? now.toIso8601String(),
        'endDate': medication['endDate'],
        'instructions': medication['instructions'] ?? medication['dosage'] ?? 'Take as prescribed',
        'isActive': medication['isActive'] ?? true,
        'notes': medication['notes'],
        'userId': userId,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'addedBy': _auth.currentUser?.uid,
        'addedByRole': 'admin',
      };
      
      // Add to user's medications collection (for user app sync)
      final userMedRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('medications')
          .doc();
      
      // Set the ID in the data
      medicationData['id'] = userMedRef.id;
      
      await userMedRef.set(medicationData);
      
      // Also add to medications collection (for admin tracking)
      await _firestore.collection('medications').doc(userMedRef.id).set(medicationData);
    } catch (e) {
      debugPrint('Error adding medication: $e');
      rethrow;
    }
  }

  // Update medication (updates both collections for sync)
  Future<void> updateMedication(String medicationId, Map<String, dynamic> updates) async {
    try {
      final updateData = {
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
        'updatedBy': _auth.currentUser?.uid,
        'updatedByRole': 'admin',
      };
      
      // Update in medications collection
      await _firestore.collection('medications').doc(medicationId).update(updateData);
      
      // Also update in user's medications collection if it exists
      try {
        // Find which user has this medication
        final medDoc = await _firestore.collection('medications').doc(medicationId).get();
        if (medDoc.exists) {
          final userId = medDoc.data()?['userId'] as String?;
          if (userId != null) {
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('medications')
                .doc(medicationId)
                .update(updateData);
          }
        }
      } catch (e) {
        debugPrint('Warning: Could not update in user collection: $e');
        // Continue even if user collection update fails
      }
    } catch (e) {
      debugPrint('Error updating medication: $e');
      rethrow;
    }
  }

  // Delete medication (deletes from both collections for sync)
  Future<void> deleteMedication(String medicationId) async {
    try {
      // Find which user has this medication before deleting
      final medDoc = await _firestore.collection('medications').doc(medicationId).get();
      final userId = medDoc.data()?['userId'] as String?;
      
      // Delete from medications collection
      await _firestore.collection('medications').doc(medicationId).delete();
      
      // Also delete from user's medications collection if it exists
      if (userId != null) {
        try {
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('medications')
              .doc(medicationId)
              .delete();
        } catch (e) {
          debugPrint('Warning: Could not delete from user collection: $e');
          // Continue even if user collection delete fails
        }
      }
    } catch (e) {
      debugPrint('Error deleting medication: $e');
      rethrow;
    }
  }

  // Get SOS events with comprehensive details
  Future<List<Map<String, dynamic>>> getSOSEvents(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emergency_events')
          .orderBy('timestamp', descending: true)
          .limit(50) // Increased limit
          .get();

      final events = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Get user profile for additional context
        final profileDoc = await _firestore.collection('profiles').doc(userId).get();
        final userProfile = profileDoc.data();
        
        events.add({
          'id': doc.id,
          ...data,
          'userName': userProfile?['displayName'] ?? 'Unknown User',
          'userEmail': userProfile?['email'] ?? '',
          'userPhone': userProfile?['phoneNumber'] ?? '',
          // Ensure location is properly formatted
          'location': data['location'] ?? data['coordinates'] ?? data['gps'],
        });
      }
      
      return events;
    } catch (e) {
      debugPrint('Error getting SOS events: $e');
      // Fallback without orderBy
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('emergency_events')
            .limit(50)
            .get();
        
        final events = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        
        // Sort in memory
        events.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        
        return events;
      } catch (e2) {
        debugPrint('Error in fallback SOS query: $e2');
        return [];
      }
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
      debugPrint('=== Admin Login Attempt ===');
      debugPrint('Email: $email');
      
      // Sign in with Firebase Auth
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Firebase Auth successful. UID: ${userCredential.user!.uid}');

      // Check if user is in admins collection
      final adminDoc = await _firestore
          .collection('admins')
          .doc(userCredential.user!.uid)
          .get();

      debugPrint('Admin doc exists: ${adminDoc.exists}');

      if (!adminDoc.exists) {
        // Not an admin, sign out
        debugPrint('User is not an admin. Signing out.');
        await _auth.signOut();
        await clearAdminSession();
        return null;
      }

      debugPrint('Admin user found: ${adminDoc.data()}');

      final adminUser = AdminUser.fromFirestore(adminDoc);
      
      // Mark as admin/caregiver in SharedPreferences based on role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', true); // Both admin and caregiver use this flag
      await prefs.setString('userRole', adminUser.role); // Store specific role
      debugPrint('Admin flag set in SharedPreferences. Role: ${adminUser.role}');

      // Update last login
      await _firestore.collection('admins').doc(userCredential.user!.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('Admin login successful: ${adminUser.displayName}');
      
      return adminUser;
    } catch (e) {
      debugPrint('Error during admin login: $e');
      // Clear admin flag on error
      await clearAdminSession();
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

  // ========== CAREGIVER MANAGEMENT ==========

  // Get pending caregiver registrations
  Future<List<Map<String, dynamic>>> getPendingCaregivers() async {
    try {
      // Try with orderBy first, fallback to in-memory sort if index is missing
      try {
        final snapshot = await _firestore
            .collection('caregiver_registrations')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      } catch (e) {
        debugPrint('Error with orderBy, trying without: $e');
        // Fallback: get all pending without orderBy, sort in memory
        final snapshot = await _firestore
            .collection('caregiver_registrations')
            .where('status', isEqualTo: 'pending')
            .get();

        final registrations = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();

        // Sort by createdAt in memory
        registrations.sort((a, b) {
          final aTime = a['createdAt'];
          final bTime = b['createdAt'];
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          
          DateTime aDate, bDate;
          if (aTime is Timestamp) {
            aDate = aTime.toDate();
          } else {
            return 0;
          }
          
          if (bTime is Timestamp) {
            bDate = bTime.toDate();
          } else {
            return 0;
          }
          
          return bDate.compareTo(aDate); // Descending
        });

        return registrations;
      }
    } catch (e) {
      debugPrint('Error getting pending caregivers: $e');
      return [];
    }
  }

  // Approve caregiver registration
  Future<void> approveCaregiver(String registrationId) async {
    try {
      final registrationDoc = await _firestore
          .collection('caregiver_registrations')
          .doc(registrationId)
          .get();

      if (!registrationDoc.exists) {
        throw Exception('Registration not found');
      }

      final data = registrationDoc.data()!;
      final userId = data['userId'] as String;

      // Update registration status
      await _firestore
          .collection('caregiver_registrations')
          .doc(registrationId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
      });

      final email = data['email'] as String? ?? '';
      final displayName = data['displayName'] as String? ?? 'Caregiver';

      debugPrint('Approving caregiver: $userId, $email, $displayName');

      // Create admin document with caregiver role (caretaker)
      // Use merge: false to ensure role is set correctly and not overwritten
      await _firestore.collection('admins').doc(userId).set({
        'email': email,
        'displayName': displayName,
        'role': 'caretaker', // This role allows access to caregiver dashboard
        'assignedUsers': [],
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isActive': true,
      }, SetOptions(merge: false)); // Use merge: false to ensure role is set correctly

      debugPrint('Caregiver approved and added to admins collection with role: caretaker');
    } catch (e) {
      debugPrint('Error approving caregiver: $e');
      rethrow;
    }
  }

  // Reject caregiver registration
  Future<void> rejectCaregiver(String registrationId, String reason) async {
    try {
      await _firestore
          .collection('caregiver_registrations')
          .doc(registrationId)
          .update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'rejectionReason': reason,
      });
    } catch (e) {
      debugPrint('Error rejecting caregiver: $e');
      rethrow;
    }
  }

  // Get all caregivers
  Future<List<Map<String, dynamic>>> getAllCaregivers() async {
    try {
      final snapshot = await _firestore
          .collection('admins')
          .where('role', isEqualTo: 'caretaker')
          .orderBy('displayName')
          .get();

      return snapshot.docs.map((doc) => {
        'uid': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting all caregivers: $e');
      return [];
    }
  }

  // Assign user to caregiver
  Future<void> assignUserToCaregiver(String caregiverId, String userId) async {
    try {
      await _firestore.collection('admins').doc(caregiverId).update({
        'assignedUsers': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error assigning user to caregiver: $e');
      rethrow;
    }
  }

  // Remove user from caregiver
  Future<void> removeUserFromCaregiver(String caregiverId, String userId) async {
    try {
      await _firestore.collection('admins').doc(caregiverId).update({
        'assignedUsers': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error removing user from caregiver: $e');
      rethrow;
    }
  }

  // ========== SOCIAL ACTIVITY MONITORING ==========

  // Get user's social activities (both created and joined)
  Future<List<Map<String, dynamic>>> getUserSocialActivities(String userId) async {
    try {
      // Get activities where user is a participant
      final participantSnapshot = await _firestore
          .collection('social_activities')
          .where('participantIds', arrayContains: userId)
          .limit(50)
          .get();
      
      // Get activities created by user
      final createdSnapshot = await _firestore
          .collection('social_activities')
          .where('creatorId', isEqualTo: userId)
          .limit(50)
          .get();
      
      // Combine and deduplicate
      final activitiesMap = <String, Map<String, dynamic>>{};
      
      for (var doc in participantSnapshot.docs) {
        final data = doc.data();
        activitiesMap[doc.id] = {
          'id': doc.id,
          ...data,
          'isCreator': data['creatorId'] == userId,
        };
      }
      
      for (var doc in createdSnapshot.docs) {
        final data = doc.data();
        activitiesMap[doc.id] = {
          'id': doc.id,
          ...data,
          'isCreator': true,
        };
      }
      
      final activities = activitiesMap.values.toList();
      
      // Sort by scheduled time descending
      activities.sort((a, b) {
        final aTime = a['scheduledTime'] as Timestamp?;
        final bTime = b['scheduledTime'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });
      
      return activities;
    } catch (e) {
      debugPrint('Error getting user social activities: $e');
      return [];
    }
  }

  // Get chat history for a user (all their group chats with comprehensive data)
  Future<List<Map<String, dynamic>>> getUserChatHistory(String userId) async {
    try {
      // Get all group chats where user is a member
      final chatsSnapshot = await _firestore
          .collection('group_chats')
          .where('members', arrayContains: userId)
          .limit(50)
          .get();

      final chatHistory = <Map<String, dynamic>>[];
      
      for (var chatDoc in chatsSnapshot.docs) {
        final chatData = chatDoc.data();
        
        // Get activity title from associated social activity if chatId is linked
        String? activityTitle = chatData['activityTitle'] as String?;
        String? activityId;
        
        // Try to find associated social activity
        if (activityTitle == null) {
          try {
            final activitySnapshot = await _firestore
                .collection('social_activities')
                .where('chatId', isEqualTo: chatDoc.id)
                .limit(1)
                .get();
            
            if (activitySnapshot.docs.isNotEmpty) {
              final activityData = activitySnapshot.docs.first.data();
              activityTitle = activityData['title'] as String?;
              activityId = activitySnapshot.docs.first.id;
            }
          } catch (e) {
            debugPrint('Error finding associated activity: $e');
          }
        }
        
        // Get all messages (or last 20 for performance)
        final messagesSnapshot = await _firestore
            .collection('group_chats')
            .doc(chatDoc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(20)
            .get();

        final messages = messagesSnapshot.docs.map((doc) {
          final msgData = doc.data();
          return {
            'id': doc.id,
            ...msgData,
          };
        }).toList();
        
        // Reverse to show chronological order
        messages.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return aTime.compareTo(bTime);
        });

        // Get participant count
        final members = List<String>.from(chatData['members'] ?? []);
        
        chatHistory.add({
          'chatId': chatDoc.id,
          'activityTitle': activityTitle ?? 'Group Chat',
          'activityId': activityId,
          'lastMessageAt': chatData['lastMessageAt'],
          'lastMessageContent': chatData['lastMessageContent'],
          'lastMessageSender': chatData['lastMessageSender'],
          'participantCount': members.length,
          'participants': members,
          'messages': messages,
          'totalMessages': messages.length,
        });
      }
      
      // Sort by last message time descending
      chatHistory.sort((a, b) {
        final aTime = a['lastMessageAt'] as Timestamp?;
        final bTime = b['lastMessageAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return chatHistory;
    } catch (e) {
      debugPrint('Error getting user chat history: $e');
      return [];
    }
  }
}

