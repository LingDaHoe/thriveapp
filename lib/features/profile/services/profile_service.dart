import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Profile> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final userId = user.uid;
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (!doc.exists) {
        // Create default profile if it doesn't exist
        final defaultProfile = Profile(
          uid: userId,
          displayName: user.displayName ?? (user.email?.split('@')[0] ?? 'User'),
          email: user.email,
          phoneNumber: user.phoneNumber,
          age: 0,
          gender: null,
          preferredLanguage: 'English',
          emergencyContacts: [],
          location: null,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          settings: ProfileSettings(
            notifications: true,
            darkMode: false,
            fontSize: 'medium',
            voiceGuidance: false,
          ),
        );
        await _firestore.collection('profiles').doc(userId).set(defaultProfile.toMap());
        return defaultProfile;
      }
      return Profile.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<void> updateProfile(Profile profile) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');
      await _firestore.collection('profiles').doc(userId).update(profile.toMap());
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user profile
  Future<Profile?> getUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      if (!doc.exists) return null;

      return Profile.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Create or update user profile
  Future<void> saveProfile(Profile profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection('profiles').doc(user.uid).set(
            profile.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  // Update last login timestamp
  Future<void> updateLastLogin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('profiles').doc(user.uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  // Add emergency contact
  Future<void> addEmergencyContact(EmergencyContact contact) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final profile = await getUserProfile();
      if (profile == null) throw Exception('Profile not found');

      final contacts = List<EmergencyContact>.from(profile.emergencyContacts);
      if (contact.isPrimary) {
        // Remove primary status from other contacts
        for (var i = 0; i < contacts.length; i++) {
          if (contacts[i].isPrimary) {
            contacts[i] = EmergencyContact(
              name: contacts[i].name,
              relationship: contacts[i].relationship,
              phoneNumber: contacts[i].phoneNumber,
              isPrimary: false,
            );
          }
        }
      }
      contacts.add(contact);

      await _firestore.collection('profiles').doc(user.uid).update({
        'emergencyContacts': contacts.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to add emergency contact: $e');
    }
  }

  // Remove emergency contact
  Future<void> removeEmergencyContact(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      final profile = await getUserProfile();
      if (profile == null) throw Exception('Profile not found');

      final contacts = profile.emergencyContacts
          .where((contact) => contact.phoneNumber != phoneNumber)
          .toList();

      await _firestore.collection('profiles').doc(user.uid).update({
        'emergencyContacts': contacts.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      throw Exception('Failed to remove emergency contact: $e');
    }
  }

  // Update profile settings
  Future<void> updateSettings(ProfileSettings settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await _firestore.collection('profiles').doc(user.uid).update({
        'settings': settings.toMap(),
      });
    } catch (e) {
      throw Exception('Failed to update settings: $e');
    }
  }
} 