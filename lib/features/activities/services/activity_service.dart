import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../models/activity.dart';
import '../models/user_progress.dart';
import '../models/achievement.dart';
import '../models/points_history.dart';

class ActivityService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Health _health;
  bool _permissionsGranted = false;

  ActivityService()
      : _firestore = FirebaseFirestore.instance,
        _auth = FirebaseAuth.instance,
        _health = Health();

  Future<bool> requestHealthPermissions() async {
    try {
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
      ];

      final authorized = await _health.requestAuthorization(types);
      _permissionsGranted = authorized;
      debugPrint('Health permissions result: $authorized');
      return authorized;
    } catch (e) {
      debugPrint('Error requesting health permissions: $e');
      // Don't throw error, just return false to allow activity completion
      _permissionsGranted = false;
      return false;
    }
  }

  Future<List<Activity>> getActivities() async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Activity.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting activities: $e');
      rethrow;
    }
  }

  Future<List<Activity>> getActivitiesByType(String type) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('type', isEqualTo: type)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Activity.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting activities by type: $e');
      rethrow;
    }
  }

  Future<UserProgress> getActivityProgress(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .get();

      if (!doc.exists) {
        throw Exception('Activity progress not found');
      }

      return UserProgress.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error getting activity progress: $e');
      rethrow;
    }
  }

  Future<void> startActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final activity = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!activity.exists) {
        throw Exception('Activity not found');
      }

      final progress = UserProgress(
        userId: userId,
        activityId: activityId,
        startedAt: DateTime.now(),
        status: 'in_progress',
        pointsEarned: 0,
      );

      await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .set(progress.toJson());
    } catch (e) {
      debugPrint('Error starting activity: $e');
      rethrow;
    }
  }

  Future<List<Achievement>> completeActivity(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Try to get health data, but don't fail if permissions aren't granted
      int steps = 0;
      double heartRate = 0.0;
      double sleepHours = 0.0;

      try {
        if (!_permissionsGranted) {
          final granted = await requestHealthPermissions();
          if (granted) {
            _permissionsGranted = true;
          }
        }

        if (_permissionsGranted) {
          steps = await _getSteps(startOfDay, now);
          heartRate = await _getHeartRate(startOfDay, now);
          sleepHours = await _getSleepHours(startOfDay, now);
        }
      } catch (e) {
        debugPrint('Health data not available: $e');
        // Continue with activity completion even without health data
      }

      final activity = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!activity.exists) {
        throw Exception('Activity not found');
      }

      final activityData = Activity.fromJson(activity.data()!);
      final progress = UserProgress(
        userId: userId,
        activityId: activityId,
        startedAt: now.subtract(Duration(minutes: activityData.duration)),
        completedAt: now,
        status: 'completed',
        healthData: {
          'steps': steps,
          'heartRate': heartRate,
          'sleepHours': sleepHours,
        },
        pointsEarned: activityData.points,
      );

      // Create a new document for each completion
      await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .add(progress.toJson());

      // Add points history
      final pointsHistory = PointsHistory(
        id: '${userId}_${now.millisecondsSinceEpoch}',
        userId: userId,
        points: activityData.points,
        source: 'activity',
        sourceId: activityId,
        timestamp: now,
        metadata: {
          'activityType': activityData.type,
          'activityTitle': activityData.title,
        },
      );
      await addPointsHistory(pointsHistory);

      // Check for achievements
      final newAchievements = await _checkAndUpdateAchievements(userId);

      // Add points history for achievements
      for (var achievement in newAchievements) {
        final achievementHistory = PointsHistory(
          id: '${userId}_achievement_${achievement.id}_${now.millisecondsSinceEpoch}',
          userId: userId,
          points: achievement.points,
          source: 'achievement',
          sourceId: achievement.id,
          timestamp: now,
          metadata: {
            'achievementTitle': achievement.title,
            'achievementType': achievement.type,
          },
        );
        await addPointsHistory(achievementHistory);
      }

      return newAchievements;
    } catch (e) {
      debugPrint('Error completing activity: $e');
      rethrow;
    }
  }

  Future<List<Achievement>> _checkAndUpdateAchievements(String userId) async {
    final List<Achievement> newlyUnlocked = [];
    try {
      // Get user's completed activities
      final completedActivities = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();

      // Get all achievements
      final achievements = await _firestore
          .collection('achievements')
          .get();

      // Calculate activity counts by type
      final activityCounts = <String, int>{};
      for (var doc in completedActivities.docs) {
        final activityId = doc.data()['activityId'] as String;
        final activityDoc = await _firestore
            .collection('activities')
            .doc(activityId)
            .get();
        if (activityDoc.exists) {
          final type = activityDoc.data()?['type'] as String? ?? 'unknown';
          activityCounts[type] = (activityCounts[type] ?? 0) + 1;
        }
      }

      // Calculate streak
      final dates = completedActivities.docs
          .map((doc) => (doc.data()['completedAt'] as Timestamp).toDate())
          .toList();
      dates.sort();
      final currentStreak = _calculateCurrentStreak(dates);

      // Calculate total points
      final totalPoints = completedActivities.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['pointsEarned'] as int? ?? 0),
      );

      for (var achievementDoc in achievements.docs) {
        final achievement = Achievement.fromJson(achievementDoc.data());
        
        // Skip if already unlocked
        final userAchievementDoc = await _firestore
          .collection('achievements')
          .doc(userId)
          .collection('userAchievements')
          .doc(achievement.id)
          .get();
        if (userAchievementDoc.exists) continue;

        bool shouldUnlock = false;
        Map<String, dynamic> progress = {};

        switch (achievement.type) {
          case 'activity':
            final requiredCount = achievement.requirements?['count'] as int? ?? 1;
            final activityType = achievement.requirements?['activityType'] as String? ?? 'any';
            final currentCount = activityType == 'any' 
                ? completedActivities.docs.length 
                : activityCounts[activityType] ?? 0;
            progress = {
              'count': requiredCount,
              'current': currentCount,
            };
            shouldUnlock = currentCount >= requiredCount;
            break;

          case 'streak':
            final requiredDays = achievement.requirements?['days'] as int? ?? 7;
            progress = {
              'days': requiredDays,
              'current': currentStreak,
            };
            shouldUnlock = currentStreak >= requiredDays;
            break;

          case 'milestone':
            final requiredPoints = achievement.requirements?['points'] as int? ?? 1000;
            progress = {
              'points': requiredPoints,
              'current': totalPoints,
            };
            shouldUnlock = totalPoints >= requiredPoints;
            break;
        }

        if (shouldUnlock) {
          final unlockedAchievement = achievement.copyWith(
            unlockedAt: DateTime.now(),
            requirements: progress,
          );
          await _firestore
              .collection('achievements')
              .doc(userId)
              .collection('userAchievements')
              .doc(achievement.id)
              .set(unlockedAchievement.toJson());
          newlyUnlocked.add(unlockedAchievement);
        } else {
          // Update progress even if not unlocked
          await _firestore
              .collection('achievements')
              .doc(userId)
              .collection('userAchievements')
              .doc(achievement.id)
              .set({
                'progress': progress,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
      rethrow;
    }
    return newlyUnlocked;
  }

  int _calculateCurrentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // Sort dates in descending order
    dates.sort((a, b) => b.compareTo(a));
    
    // Check if the last activity was today or yesterday
    final lastDate = DateTime(dates[0].year, dates[0].month, dates[0].day);
    if (lastDate != today && lastDate != yesterday) return 0;
    
    int streak = 1;
    DateTime currentDate = lastDate;
    
    for (int i = 1; i < dates.length; i++) {
      final date = DateTime(dates[i].year, dates[i].month, dates[i].day);
      final difference = currentDate.difference(date).inDays;
      
      if (difference == 1) {
        streak++;
        currentDate = date;
      } else {
        break;
      }
    }
    
    return streak;
  }

  Future<int> _getSteps(DateTime start, DateTime end) async {
    try {
      final stepsData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.STEPS],
      );
      int totalSteps = 0;
      for (var data in stepsData) {
        totalSteps += (data.value as num?)?.toInt() ?? 0;
      }
      return totalSteps;
    } catch (e) {
      debugPrint('Error getting steps: $e');
      return 0;
    }
  }

  Future<double> _getHeartRate(DateTime start, DateTime end) async {
    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.HEART_RATE],
      );
      if (heartRateData.isEmpty) return 0.0;
      double sum = 0;
      for (var data in heartRateData) {
        sum += (data.value as num?)?.toDouble() ?? 0.0;
      }
      return sum / heartRateData.length;
    } catch (e) {
      debugPrint('Error getting heart rate: $e');
      return 0.0;
    }
  }

  Future<double> _getSleepHours(DateTime start, DateTime end) async {
    try {
      final sleepData = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: [HealthDataType.SLEEP_ASLEEP],
      );
      double totalMinutes = 0;
      for (var data in sleepData) {
        totalMinutes += data.dateTo.difference(data.dateFrom).inMinutes.toDouble();
      }
      return totalMinutes / 60.0;
    } catch (e) {
      debugPrint('Error getting sleep hours: $e');
      return 0.0;
    }
  }

  Future<List<Achievement>> getUserAchievements() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get all available achievements from the main collection
      final allAchievementsSnapshot = await _firestore
          .collection('achievements')
          .get();

      // Get user's achievement progress
      final userAchievementsSnapshot = await _firestore
          .collection('achievements')
          .doc(userId)
          .collection('userAchievements')
          .get();

      // Create a map of user achievement data by achievement ID
      final userAchievementsMap = <String, Map<String, dynamic>>{};
      for (var doc in userAchievementsSnapshot.docs) {
        final data = doc.data();
        final achievementId = data['id'] as String? ?? doc.id;
        userAchievementsMap[achievementId] = data;
      }

      // Get user's completed activities to calculate progress
      final completedActivities = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate activity counts by type
      final activityCounts = <String, int>{};
      for (var doc in completedActivities.docs) {
        final activityId = doc.data()['activityId'] as String;
        final activityDoc = await _firestore
            .collection('activities')
            .doc(activityId)
            .get();
        if (activityDoc.exists) {
          final type = activityDoc.data()?['type'] as String? ?? 'unknown';
          activityCounts[type] = (activityCounts[type] ?? 0) + 1;
        }
      }

      // Calculate streak
      final dates = completedActivities.docs
          .map((doc) => (doc.data()['completedAt'] as Timestamp).toDate())
          .toList();
      dates.sort();
      final currentStreak = _calculateCurrentStreak(dates);

      // Calculate total points
      final totalPoints = completedActivities.docs.fold<int>(
        0,
        (sum, doc) => sum + (doc.data()['pointsEarned'] as int? ?? 0),
      );

      // Merge all achievements with user progress
      final List<Achievement> achievements = [];
      for (var doc in allAchievementsSnapshot.docs) {
        final achievementData = doc.data();
        final achievementId = achievementData['id'] as String? ?? doc.id;
        final userAchievementData = userAchievementsMap[achievementId];

        // Get unlock status and progress from user data
        DateTime? unlockedAt;
        Map<String, dynamic>? requirements = achievementData['requirements'] as Map<String, dynamic>?;

        if (userAchievementData != null) {
          if (userAchievementData['unlockedAt'] != null) {
            unlockedAt = (userAchievementData['unlockedAt'] as Timestamp).toDate();
          }
          // Use progress from user data if available
          if (userAchievementData['progress'] != null) {
            requirements = userAchievementData['progress'] as Map<String, dynamic>?;
          }
        } else {
          // Calculate current progress if not stored
          final achievement = Achievement.fromJson(achievementData);
          switch (achievement.type) {
            case 'activity':
              final requiredCount = achievement.requirements?['count'] as int? ?? 1;
              final activityType = achievement.requirements?['activityType'] as String? ?? 'any';
              final currentCount = activityType == 'any' 
                  ? completedActivities.docs.length 
                  : activityCounts[activityType] ?? 0;
              requirements = {
                'count': requiredCount,
                'current': currentCount,
              };
              break;
            case 'streak':
              final requiredDays = achievement.requirements?['days'] as int? ?? 7;
              requirements = {
                'days': requiredDays,
                'current': currentStreak,
              };
              break;
            case 'milestone':
              final requiredPoints = achievement.requirements?['points'] as int? ?? 1000;
              requirements = {
                'points': requiredPoints,
                'current': totalPoints,
              };
              break;
          }
        }

        final achievement = Achievement(
          id: achievementId,
          title: achievementData['title'] as String,
          description: achievementData['description'] as String,
          type: achievementData['type'] as String,
          points: achievementData['points'] as int,
          icon: achievementData['icon'] as String,
          requirements: requirements,
          unlockedAt: unlockedAt,
        );

        achievements.add(achievement);
      }

      return achievements;
    } catch (e) {
      debugPrint('Error getting user achievements: $e');
      rethrow;
    }
  }

  Future<void> initializeSampleActivities() async {
    try {
      final activities = [
        {
          'id': 'physical_1',
          'title': 'Morning Walk',
          'description': 'Take a 30-minute walk in your neighborhood',
          'type': 'physical',
          'difficulty': 'easy',
          'points': 50,
          'duration': 30,
          'content': {
            'instructions': '1. Start with a 5-minute warm-up\n2. Walk at a comfortable pace\n3. Stay hydrated\n4. Cool down for 5 minutes',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'physical_2',
          'title': 'Chair Exercises',
          'description': 'Simple exercises you can do while sitting',
          'type': 'physical',
          'difficulty': 'easy',
          'points': 30,
          'duration': 15,
          'content': {
            'instructions': '1. Arm circles\n2. Leg lifts\n3. Shoulder rolls\n4. Ankle rotations',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'mental_1',
          'title': 'Memory Game',
          'description': 'Test your memory with a card matching game',
          'type': 'mental',
          'difficulty': 'medium',
          'points': 40,
          'duration': 20,
          'content': {
            'instructions': '1. Match pairs of cards\n2. Remember card positions\n3. Complete within time limit',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'mental_2',
          'title': 'Word Puzzle',
          'description': 'Complete a crossword puzzle',
          'type': 'mental',
          'difficulty': 'medium',
          'points': 45,
          'duration': 25,
          'content': {
            'instructions': '1. Read clues carefully\n2. Fill in words\n3. Check your answers',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'social_1',
          'title': 'Group Exercise',
          'description': 'Join a group exercise class',
          'type': 'social',
          'difficulty': 'medium',
          'points': 60,
          'duration': 45,
          'content': {
            'instructions': '1. Find a local class\n2. Introduce yourself\n3. Follow instructor\n4. Socialize after class',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'social_2',
          'title': 'Book Club',
          'description': 'Join a book discussion group',
          'type': 'social',
          'difficulty': 'easy',
          'points': 35,
          'duration': 60,
          'content': {
            'instructions': '1. Read the book\n2. Prepare discussion points\n3. Share your thoughts\n4. Listen to others',
          },
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (var activity in activities) {
        final docRef = _firestore.collection('activities').doc(activity['id'] as String);
        batch.set(docRef, activity);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing sample activities: $e');
      rethrow;
    }
  }

  Future<void> completeMemoryGame(String activityId, int score, int moves, Duration duration) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final activity = await _firestore
          .collection('activities')
          .doc(activityId)
          .get();

      if (!activity.exists) {
        throw Exception('Activity not found');
      }

      final activityData = Activity.fromJson(activity.data()!);
      final batch = _firestore.batch();
      
      // Create a new document for each completion
      final progressRef = _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .doc();
      
      batch.set(progressRef, {
        'userId': userId,
        'activityId': activityId,
        'status': 'completed',
        'completedAt': DateTime.now(),
        'pointsEarned': activityData.points,
        'score': score,
        'moves': moves,
        'duration': duration.inSeconds,
        'type': 'memory_game',
      });

      // Update user achievements
      final achievementsRef = _firestore
          .collection('achievements')
          .doc(userId)
          .collection('userAchievements')
          .doc('memory_games');
      
      final currentStats = await achievementsRef.get();
      final currentData = currentStats.data() ?? {};
      final currentBestScore = currentData['bestScore'] as int? ?? 0;

      batch.set(achievementsRef, {
        'gamesPlayed': FieldValue.increment(1),
        'totalScore': FieldValue.increment(score),
        'bestScore': score > currentBestScore ? score : currentBestScore,
        'lastPlayed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      debugPrint('Error completing memory game: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMemoryGameStats(String activityId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final progressDoc = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .get();

      final achievementsDoc = await _firestore
          .collection('achievements')
          .doc(userId)
          .collection('userAchievements')
          .doc('memory_games')
          .get();

      return {
        'progress': progressDoc.data() ?? {},
        'achievements': achievementsDoc.data() ?? {},
      };
    } catch (e) {
      debugPrint('Error getting memory game stats: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getActivityStats(String activityId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .doc(activityId)
        .get();

    if (!doc.exists) {
      return {
        'highScore': 0,
        'timesPlayed': 0,
        'lastPlayed': null,
      };
    }

    return doc.data() ?? {};
  }

  Future<void> completeActivityWithScore(
    String activityId,
    int score,
    Map<String, dynamic> additionalData,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final activity = await _firestore
        .collection('activities')
        .doc(activityId)
        .get();

    if (!activity.exists) {
      throw Exception('Activity not found');
    }

    final activityData = Activity.fromJson(activity.data()!);
    final stats = await getActivityStats(activityId);
    final highScore = stats['highScore'] ?? 0;
    final timesPlayed = (stats['timesPlayed'] ?? 0) + 1;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .doc(activityId)
        .set({
      'highScore': score > highScore ? score : highScore,
      'timesPlayed': timesPlayed,
      'lastPlayed': DateTime.now().toIso8601String(),
      ...additionalData,
    }, SetOptions(merge: true));

    // Create a new document for each completion
    await _firestore
        .collection('activityProgress')
        .doc(user.uid)
        .collection('activities')
        .add({
      'userId': user.uid,
      'activityId': activityId,
      'status': 'completed',
      'completedAt': DateTime.now(),
      'pointsEarned': activityData.points,
      ...additionalData,
    });
  }

  Future<void> completeMentalGame(
    String activityId,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final progress = UserProgress(
        userId: userId,
        activityId: activityId,
        startedAt: now.subtract(const Duration(minutes: 5)), // Approximate game duration
        completedAt: now,
        status: 'completed',
        activityData: gameData,
        pointsEarned: gameData['score'] as int? ?? 0,
      );

      await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .doc(activityId)
          .set(progress.toJson());

      // Check for achievements
      await _checkAndUpdateAchievements(userId);
    } catch (e) {
      debugPrint('Error completing mental game: $e');
      rethrow;
    }
  }

  Future<int> getTotalPoints() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final completed = await _firestore
          .collection('activityProgress')
          .doc(userId)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();

      int total = 0;
      for (var doc in completed.docs) {
        total += (doc.data()['pointsEarned'] as int? ?? 0);
      }
      debugPrint('Total points calculated: $total');
      return total;
    } catch (e) {
      debugPrint('Error getting total points: $e');
      rethrow;
    }
  }

  Future<void> initializeAchievements() async {
    try {
      final achievements = [
        // Activity-based achievements
        {
          'id': 'first_activity',
          'title': 'First Steps',
          'description': 'Complete your first activity',
          'type': 'activity',
          'points': 50,
          'icon': '🎯',
          'requirements': {
            'count': 1,
            'activityType': 'any',
          },
        },
        {
          'id': 'five_activities',
          'title': 'Getting Started',
          'description': 'Complete 5 activities',
          'type': 'activity',
          'points': 100,
          'icon': '⭐',
          'requirements': {
            'count': 5,
            'activityType': 'any',
          },
        },
        {
          'id': 'ten_activities',
          'title': 'Activity Enthusiast',
          'description': 'Complete 10 activities',
          'type': 'activity',
          'points': 200,
          'icon': '🌟',
          'requirements': {
            'count': 10,
            'activityType': 'any',
          },
        },
        {
          'id': 'twenty_five_activities',
          'title': 'Activity Champion',
          'description': 'Complete 25 activities',
          'type': 'activity',
          'points': 400,
          'icon': '🏆',
          'requirements': {
            'count': 25,
            'activityType': 'any',
          },
        },
        {
          'id': 'fifty_activities',
          'title': 'Activity Master',
          'description': 'Complete 50 activities',
          'type': 'activity',
          'points': 750,
          'icon': '👑',
          'requirements': {
            'count': 50,
            'activityType': 'any',
          },
        },
        {
          'id': 'physical_beginner',
          'title': 'Physical Beginner',
          'description': 'Complete 3 physical activities',
          'type': 'activity',
          'points': 150,
          'icon': '🏃',
          'requirements': {
            'count': 3,
            'activityType': 'physical',
          },
        },
        {
          'id': 'physical_master',
          'title': 'Physical Master',
          'description': 'Complete 10 physical activities',
          'type': 'activity',
          'points': 300,
          'icon': '💪',
          'requirements': {
            'count': 10,
            'activityType': 'physical',
          },
        },
        {
          'id': 'physical_expert',
          'title': 'Physical Expert',
          'description': 'Complete 25 physical activities',
          'type': 'activity',
          'points': 600,
          'icon': '🏋️',
          'requirements': {
            'count': 25,
            'activityType': 'physical',
          },
        },
        {
          'id': 'mental_beginner',
          'title': 'Mental Beginner',
          'description': 'Complete 3 mental activities',
          'type': 'activity',
          'points': 150,
          'icon': '🧩',
          'requirements': {
            'count': 3,
            'activityType': 'mental',
          },
        },
        {
          'id': 'mental_master',
          'title': 'Mental Master',
          'description': 'Complete 10 mental activities',
          'type': 'activity',
          'points': 300,
          'icon': '🧠',
          'requirements': {
            'count': 10,
            'activityType': 'mental',
          },
        },
        {
          'id': 'mental_expert',
          'title': 'Mental Expert',
          'description': 'Complete 25 mental activities',
          'type': 'activity',
          'points': 600,
          'icon': '🎓',
          'requirements': {
            'count': 25,
            'activityType': 'mental',
          },
        },
        {
          'id': 'social_beginner',
          'title': 'Social Beginner',
          'description': 'Complete 3 social activities',
          'type': 'activity',
          'points': 150,
          'icon': '👥',
          'requirements': {
            'count': 3,
            'activityType': 'social',
          },
        },
        {
          'id': 'social_master',
          'title': 'Social Master',
          'description': 'Complete 10 social activities',
          'type': 'activity',
          'points': 300,
          'icon': '🤝',
          'requirements': {
            'count': 10,
            'activityType': 'social',
          },
        },
        {
          'id': 'social_expert',
          'title': 'Social Expert',
          'description': 'Complete 25 social activities',
          'type': 'activity',
          'points': 600,
          'icon': '🎉',
          'requirements': {
            'count': 25,
            'activityType': 'social',
          },
        },

        // Streak achievements
        {
          'id': 'three_day_streak',
          'title': 'Three Day Streak',
          'description': 'Complete activities for 3 days in a row',
          'type': 'streak',
          'points': 100,
          'icon': '🔥',
          'requirements': {
            'days': 3,
          },
        },
        {
          'id': 'five_day_streak',
          'title': 'Five Day Streak',
          'description': 'Complete activities for 5 days in a row',
          'type': 'streak',
          'points': 200,
          'icon': '🔥🔥',
          'requirements': {
            'days': 5,
          },
        },
        {
          'id': 'seven_day_streak',
          'title': 'Week Warrior',
          'description': 'Complete activities for 7 days in a row',
          'type': 'streak',
          'points': 300,
          'icon': '🔥🔥🔥',
          'requirements': {
            'days': 7,
          },
        },
        {
          'id': 'fourteen_day_streak',
          'title': 'Two Week Champion',
          'description': 'Complete activities for 14 days in a row',
          'type': 'streak',
          'points': 500,
          'icon': '💯',
          'requirements': {
            'days': 14,
          },
        },
        {
          'id': 'thirty_day_streak',
          'title': 'Monthly Master',
          'description': 'Complete activities for 30 days in a row',
          'type': 'streak',
          'points': 1000,
          'icon': '🏅',
          'requirements': {
            'days': 30,
          },
        },
        {
          'id': 'sixty_day_streak',
          'title': 'Dedication Legend',
          'description': 'Complete activities for 60 days in a row',
          'type': 'streak',
          'points': 2000,
          'icon': '👑',
          'requirements': {
            'days': 60,
          },
        },

        // Milestone achievements
        {
          'id': 'points_100',
          'title': 'Points Collector',
          'description': 'Earn 100 points',
          'type': 'milestone',
          'points': 50,
          'icon': '💰',
          'requirements': {
            'points': 100,
          },
        },
        {
          'id': 'points_250',
          'title': 'Points Accumulator',
          'description': 'Earn 250 points',
          'type': 'milestone',
          'points': 100,
          'icon': '💵',
          'requirements': {
            'points': 250,
          },
        },
        {
          'id': 'points_500',
          'title': 'Points Enthusiast',
          'description': 'Earn 500 points',
          'type': 'milestone',
          'points': 200,
          'icon': '💎',
          'requirements': {
            'points': 500,
          },
        },
        {
          'id': 'points_1000',
          'title': 'Points Master',
          'description': 'Earn 1,000 points',
          'type': 'milestone',
          'points': 500,
          'icon': '💍',
          'requirements': {
            'points': 1000,
          },
        },
        {
          'id': 'points_2500',
          'title': 'Points Expert',
          'description': 'Earn 2,500 points',
          'type': 'milestone',
          'points': 1000,
          'icon': '💸',
          'requirements': {
            'points': 2500,
          },
        },
        {
          'id': 'points_5000',
          'title': 'Points Legend',
          'description': 'Earn 5,000 points',
          'type': 'milestone',
          'points': 2000,
          'icon': '🏆',
          'requirements': {
            'points': 5000,
          },
        },
        {
          'id': 'points_10000',
          'title': 'Points Grandmaster',
          'description': 'Earn 10,000 points',
          'type': 'milestone',
          'points': 5000,
          'icon': '👑',
          'requirements': {
            'points': 10000,
          },
        },
      ];

      final batch = _firestore.batch();
      for (var achievement in achievements) {
        final docRef = _firestore.collection('achievements').doc(achievement['id'] as String);
        batch.set(docRef, achievement);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing achievements: $e');
      rethrow;
    }
  }

  Future<void> addPointsHistory(PointsHistory history) async {
    try {
      // Add points history
      await _firestore
          .collection('pointsHistory')
          .doc(history.id)
          .set(history.toJson());

      // Update user's total points in profile
      await _firestore
          .collection('profiles')
          .doc(history.userId)
          .set({
        'totalPoints': FieldValue.increment(history.points),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('Added ${history.points} points to user profile. Source: ${history.source}');
    } catch (e) {
      debugPrint('Error adding points history: $e');
      rethrow;
    }
  }

  Future<List<PointsHistory>> getPointsHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final snapshot = await _firestore
          .collection('pointsHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => PointsHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting points history: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPointsSummary() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfDay.subtract(Duration(days: startOfDay.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await _firestore
          .collection('pointsHistory')
          .where('userId', isEqualTo: userId)
          .get();

      int dailyPoints = 0;
      int weeklyPoints = 0;
      int monthlyPoints = 0;
      int totalPoints = 0;

      for (var doc in snapshot.docs) {
        final history = PointsHistory.fromJson(doc.data());
        final timestamp = history.timestamp;

        if (timestamp.isAfter(startOfDay)) {
          dailyPoints += history.points;
        }
        if (timestamp.isAfter(startOfWeek)) {
          weeklyPoints += history.points;
        }
        if (timestamp.isAfter(startOfMonth)) {
          monthlyPoints += history.points;
        }
        totalPoints += history.points;
      }

      return {
        'daily': dailyPoints,
        'weekly': weeklyPoints,
        'monthly': monthlyPoints,
        'total': totalPoints,
      };
    } catch (e) {
      debugPrint('Error getting points summary: $e');
      rethrow;
    }
  }
} 