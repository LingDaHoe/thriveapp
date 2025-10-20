import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AchievementService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AchievementService()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getAchievements() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final achievementsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      return achievementsSnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error fetching achievements: $e');
      return [];
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .set({
        'unlockedAt': FieldValue.serverTimestamp(),
        'achievementId': achievementId,
      });
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  Future<bool> isAchievementUnlocked(String achievementId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final achievementDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .get();

      return achievementDoc.exists;
    } catch (e) {
      print('Error checking achievement status: $e');
      return false;
    }
  }
} 