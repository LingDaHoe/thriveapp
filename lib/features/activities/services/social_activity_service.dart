import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/social_activity.dart';

class SocialActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new social activity
  Future<SocialActivity> createSocialActivity({
    required String title,
    required String description,
    required DateTime scheduledTime,
    required String location,
    required int maxParticipants,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get creator name
      final profileDoc = await _firestore.collection('profiles').doc(userId).get();
      final creatorName = profileDoc.data()?['displayName'] ?? 'User';

      // Create activity document
      final activityId = _firestore.collection('social_activities').doc().id;
      final activityRef = _firestore.collection('social_activities').doc(activityId);

      // Create group chat for the activity
      final chatId = _firestore.collection('group_chats').doc().id;
      final chatRef = _firestore.collection('group_chats').doc(chatId);

      // Create the activity
      final activity = SocialActivity(
        id: activityId,
        title: title,
        description: description,
        creatorId: userId,
        creatorName: creatorName,
        scheduledTime: scheduledTime,
        location: location,
        maxParticipants: maxParticipants,
        participantIds: [userId], // Creator is first participant
        createdAt: DateTime.now(),
        chatId: chatId,
      );

      // Save activity
      await activityRef.set(activity.toJson());

      // Create group chat and add creator as first member
      await chatRef.set({
        'id': chatId,
        'activityId': activityId,
        'activityTitle': title,
        'members': [userId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageAt': FieldValue.serverTimestamp(),
        'isClosed': false,
        'closedAt': null,
      });

      // Add creator to chat members subcollection
      await chatRef.collection('members').doc(userId).set({
        'userId': userId,
        'name': creatorName,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      return activity;
    } catch (e) {
      debugPrint('Error creating social activity: $e');
      rethrow;
    }
  }

  // Join a social activity
  Future<void> joinSocialActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final activityRef = _firestore.collection('social_activities').doc(activityId);
      final activityDoc = await activityRef.get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = SocialActivity.fromJson(activityDoc.data()!);

      if (activity.isParticipant(userId)) {
        throw Exception('Already a participant');
      }

      if (activity.isFull) {
        throw Exception('Activity is full');
      }

      // Get user name
      final profileDoc = await _firestore.collection('profiles').doc(userId).get();
      final userName = profileDoc.data()?['displayName'] ?? 'User';

      // Add user to participants
      await activityRef.update({
        'participantIds': FieldValue.arrayUnion([userId]),
      });

      // Add user to group chat if it exists
      if (activity.chatId != null) {
        final chatRef = _firestore.collection('group_chats').doc(activity.chatId);
        await chatRef.update({
          'members': FieldValue.arrayUnion([userId]),
        });

        // Add user to chat members subcollection
        await chatRef.collection('members').doc(userId).set({
          'userId': userId,
          'name': userName,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error joining social activity: $e');
      rethrow;
    }
  }

  // Leave a social activity
  Future<void> leaveSocialActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final activityRef = _firestore.collection('social_activities').doc(activityId);
      final activityDoc = await activityRef.get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = SocialActivity.fromJson(activityDoc.data()!);

      if (!activity.isParticipant(userId)) {
        throw Exception('Not a participant');
      }

      // Cannot leave if you're the creator
      if (activity.creatorId == userId) {
        throw Exception('Creator cannot leave the activity');
      }

      // Remove user from participants
      await activityRef.update({
        'participantIds': FieldValue.arrayRemove([userId]),
      });

      // Remove user from group chat if it exists
      if (activity.chatId != null) {
        final chatRef = _firestore.collection('group_chats').doc(activity.chatId);
        await chatRef.update({
          'members': FieldValue.arrayRemove([userId]),
        });

        // Remove user from chat members subcollection
        await chatRef.collection('members').doc(userId).delete();
      }
    } catch (e) {
      debugPrint('Error leaving social activity: $e');
      rethrow;
    }
  }

  // Get all social activities
  Stream<List<SocialActivity>> getSocialActivities() {
    return _firestore
        .collection('social_activities')
        .where('scheduledTime', isGreaterThan: Timestamp.now())
        .orderBy('scheduledTime', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SocialActivity.fromJson(data);
      }).toList();
    });
  }

  // Get user's joined social activities
  Stream<List<SocialActivity>> getUserSocialActivities() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    // Query without orderBy to avoid composite index requirement
    // We'll sort in memory instead
    return _firestore
        .collection('social_activities')
        .where('participantIds', arrayContains: userId)
        .where('scheduledTime', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
      final activities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return SocialActivity.fromJson(data);
      }).toList();
      
      // Sort by scheduled time in memory
      activities.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      return activities;
    });
  }

  // Get upcoming social activities for dashboard reminder
  Future<List<SocialActivity>> getUpcomingSocialActivities({int days = 7}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final now = DateTime.now();
      final limit = now.add(Duration(days: days));

      // Query all upcoming activities (avoid composite index by querying only by time)
      // Then filter in memory for user's activities (creator OR participant)
      List<SocialActivity> activities = [];
      
      try {
        // Query all upcoming activities (no composite index needed)
        final snapshot = await _firestore
            .collection('social_activities')
            .where('scheduledTime', isGreaterThan: Timestamp.fromDate(now))
            .get();

        activities = snapshot.docs
            .map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return SocialActivity.fromJson(data);
            })
            .where((activity) {
              // Include if user is creator OR participant, and within time limit
              final isUserActivity = activity.creatorId == userId || 
                                     activity.participantIds.contains(userId);
              final isWithinLimit = activity.scheduledTime.isBefore(limit);
              return isUserActivity && isWithinLimit;
            })
            .toList();
      } catch (e) {
        debugPrint('Error querying social activities: $e');
        // If query fails, try alternative approach: get by creator first
        try {
          final creatorSnapshot = await _firestore
              .collection('social_activities')
              .where('creatorId', isEqualTo: userId)
              .get();

          activities = creatorSnapshot.docs
              .map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return SocialActivity.fromJson(data);
              })
              .where((activity) {
                final isFuture = activity.scheduledTime.isAfter(now);
                final isWithinLimit = activity.scheduledTime.isBefore(limit);
                return isFuture && isWithinLimit;
              })
              .toList();
        } catch (e2) {
          debugPrint('Error in fallback query by creator: $e2');
        }
      }

      // Sort by scheduled time
      activities.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      // Return all activities (not just top 5) for accurate count on dashboard
      return activities;
    } catch (e) {
      debugPrint('Error getting upcoming social activities: $e');
      return [];
    }
  }

  // Get a social activity by ID
  Future<SocialActivity> getSocialActivityById(String activityId) async {
    try {
      final doc = await _firestore.collection('social_activities').doc(activityId).get();
      if (!doc.exists) {
        throw Exception('Activity not found');
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      return SocialActivity.fromJson(data);
    } catch (e) {
      debugPrint('Error getting social activity by id: $e');
      rethrow;
    }
  }

  // Check and close chats that should be auto-closed (1 day after activity)
  Future<void> checkAndCloseExpiredChats() async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(const Duration(days: 1));
      
      // Get all activities that are past their scheduled time + 1 day
      final activitiesSnapshot = await _firestore
          .collection('social_activities')
          .where('scheduledTime', isLessThan: Timestamp.fromDate(oneDayAgo))
          .get();

      final batch = _firestore.batch();
      for (var doc in activitiesSnapshot.docs) {
        final activity = SocialActivity.fromJson(doc.data());
        if (activity.chatId != null) {
          final chatRef = _firestore.collection('group_chats').doc(activity.chatId);
          final chatDoc = await chatRef.get();
          
          if (chatDoc.exists) {
            final chatData = chatDoc.data()!;
            final isClosed = chatData['isClosed'] as bool? ?? false;
            
            if (!isClosed) {
              // Close the chat
              batch.update(chatRef, {
                'isClosed': true,
                'closedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        }
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error checking and closing expired chats: $e');
    }
  }

  // Check if a chat is closed
  Future<bool> isChatClosed(String chatId) async {
    try {
      final chatDoc = await _firestore.collection('group_chats').doc(chatId).get();
      if (!chatDoc.exists) return true;
      
      final data = chatDoc.data()!;
      final isClosed = data['isClosed'] as bool? ?? false;
      
      if (isClosed) return true;
      
      // Also check if activity date + 1 day has passed
      final activityId = data['activityId'] as String?;
      if (activityId != null) {
        final activity = await getSocialActivityById(activityId);
        final closeDate = activity.scheduledTime.add(const Duration(days: 1));
        if (DateTime.now().isAfter(closeDate)) {
          // Auto-close it
          await _firestore.collection('group_chats').doc(chatId).update({
            'isClosed': true,
            'closedAt': FieldValue.serverTimestamp(),
          });
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking if chat is closed: $e');
      return false;
    }
  }

  // Delete a social activity (only creator can delete)
  Future<void> deleteSocialActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final activityRef = _firestore.collection('social_activities').doc(activityId);
      final activityDoc = await activityRef.get();

      if (!activityDoc.exists) {
        throw Exception('Activity not found');
      }

      final activity = SocialActivity.fromJson(activityDoc.data()!);

      if (activity.creatorId != userId) {
        throw Exception('Only creator can delete the activity');
      }

      // Delete activity
      await activityRef.delete();

      // Delete group chat if it exists
      if (activity.chatId != null) {
        await _firestore.collection('group_chats').doc(activity.chatId).delete();
      }
    } catch (e) {
      debugPrint('Error deleting social activity: $e');
      rethrow;
    }
  }
}

