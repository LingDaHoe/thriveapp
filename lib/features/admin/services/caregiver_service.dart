import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/caregiver_invitation.dart';

class CaregiverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register as caregiver (requires admin approval)
  Future<void> registerAsCaregiver({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
    String? organization,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create registration request
      await _firestore
          .collection('caregiver_registrations')
          .doc(userCredential.user!.uid)
          .set({
        'userId': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'phoneNumber': phoneNumber,
        'organization': organization,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error registering as caregiver: $e');
      rethrow;
    }
  }

  // Check if current user is a caregiver
  Future<bool> isCaregiver() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] as String?;
      return role == 'caretaker';
    } catch (e) {
      debugPrint('Error checking caregiver status: $e');
      return false;
    }
  }

  // Get assigned users for current caregiver
  Future<List<Map<String, dynamic>>> getAssignedUsers() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final adminDoc = await _firestore.collection('admins').doc(user.uid).get();
      if (!adminDoc.exists) return [];

      final assignedUserIds = List<String>.from(adminDoc.data()?['assignedUsers'] ?? []);
      if (assignedUserIds.isEmpty) return [];

      final users = <Map<String, dynamic>>[];
      for (var userId in assignedUserIds) {
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

  // Get all user emails for autocomplete (filtered by first letter)
  Future<List<String>> getUserEmailsByFirstLetter(String firstLetter) async {
    try {
      if (firstLetter.isEmpty) return [];
      
      final snapshot = await _firestore
          .collection('profiles')
          .where('email', isGreaterThanOrEqualTo: firstLetter.toLowerCase())
          .where('email', isLessThan: String.fromCharCode(firstLetter.toLowerCase().codeUnitAt(0) + 1))
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['email'] as String? ?? '')
          .where((email) => email.isNotEmpty && email.toLowerCase().startsWith(firstLetter.toLowerCase()))
          .toList()
        ..sort();
    } catch (e) {
      debugPrint('Error getting user emails: $e');
      // Fallback: get all users and filter in memory
      try {
        final snapshot = await _firestore.collection('profiles').limit(100).get();
        return snapshot.docs
            .map((doc) => doc.data()['email'] as String? ?? '')
            .where((email) => email.isNotEmpty && email.toLowerCase().startsWith(firstLetter.toLowerCase()))
            .toList()
          ..sort();
      } catch (e2) {
        debugPrint('Error in fallback email query: $e2');
        return [];
      }
    }
  }

  // Invite user to join care team via email
  Future<void> inviteUserByEmail(String userEmail) async {
    try {
      final caregiver = _auth.currentUser;
      if (caregiver == null) throw Exception('Not authenticated');

      // Get caregiver info
      final caregiverDoc = await _firestore.collection('admins').doc(caregiver.uid).get();
      final caregiverData = caregiverDoc.data();
      final caregiverName = caregiverData?['displayName'] ?? 'Caregiver';
      final caregiverEmail = caregiverData?['email'] ?? caregiver.email ?? '';

      // Find user by email
      final usersSnapshot = await _firestore
          .collection('profiles')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();

      if (usersSnapshot.docs.isEmpty) {
        throw Exception('User with email $userEmail not found');
      }

      final userDoc = usersSnapshot.docs.first;
      final userId = userDoc.id;

      // Check if invitation already exists
      final existingInvitation = await _firestore
          .collection('caregiver_invitations')
          .where('caregiverId', isEqualTo: caregiver.uid)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingInvitation.docs.isNotEmpty) {
        throw Exception('Invitation already sent to this user');
      }

      // Create invitation
      final invitationRef = await _firestore.collection('caregiver_invitations').add({
        'caregiverId': caregiver.uid,
        'caregiverName': caregiverName,
        'caregiverEmail': caregiverEmail,
        'userId': userId,
        'userEmail': userEmail,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Create notification for user
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'type': 'caregiver_invitation',
        'title': 'Caregiver Invitation',
        'message': '$caregiverName wants to be your caregiver',
        'caregiverId': caregiver.uid,
        'caregiverName': caregiverName,
        'invitationId': invitationRef.id,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error inviting user: $e');
      rethrow;
    }
  }

  // Get pending invitations sent by current caregiver
  Future<List<CaregiverInvitation>> getPendingInvitations() async {
    try {
      final caregiver = _auth.currentUser;
      if (caregiver == null) return [];

      final snapshot = await _firestore
          .collection('caregiver_invitations')
          .where('caregiverId', isEqualTo: caregiver.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CaregiverInvitation.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting pending invitations: $e');
      return [];
    }
  }

  // Get invitations received by current user
  Future<List<CaregiverInvitation>> getReceivedInvitations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('caregiver_invitations')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CaregiverInvitation.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting received invitations: $e');
      return [];
    }
  }

  // Get stream of received invitations (for real-time updates)
  Stream<List<CaregiverInvitation>> getReceivedInvitationsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('caregiver_invitations')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CaregiverInvitation.fromFirestore(doc))
          .toList();
    });
  }

  // Accept caregiver invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final invitationDoc = await _firestore
          .collection('caregiver_invitations')
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = CaregiverInvitation.fromFirestore(invitationDoc);

      // Update invitation status
      await _firestore
          .collection('caregiver_invitations')
          .doc(invitationId)
          .update({
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Add user to caregiver's assigned users
      await _firestore.collection('admins').doc(invitation.caregiverId).update({
        'assignedUsers': FieldValue.arrayUnion([user.uid]),
      });

      // Mark notification as read
      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'caregiver_invitation')
          .where('caregiverId', isEqualTo: invitation.caregiverId)
          .where('read', isEqualTo: false)
          .get();

      for (var notifDoc in notificationsSnapshot.docs) {
        await notifDoc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('Error accepting invitation: $e');
      rethrow;
    }
  }

  // Reject caregiver invitation
  Future<void> rejectInvitation(String invitationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      await _firestore
          .collection('caregiver_invitations')
          .doc(invitationId)
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Mark notification as read
      final invitationDoc = await _firestore
          .collection('caregiver_invitations')
          .doc(invitationId)
          .get();
      final invitation = CaregiverInvitation.fromFirestore(invitationDoc);

      final notificationsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'caregiver_invitation')
          .where('caregiverId', isEqualTo: invitation.caregiverId)
          .where('read', isEqualTo: false)
          .get();

      for (var notifDoc in notificationsSnapshot.docs) {
        await notifDoc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('Error rejecting invitation: $e');
      rethrow;
    }
  }

  // Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    });
  }
}

