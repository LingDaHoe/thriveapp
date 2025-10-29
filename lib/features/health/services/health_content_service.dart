import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/health_content.dart';

class HealthContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<HealthContent>> getHealthContent({
    ContentType? type,
    ContentCategory? category,
    String? searchQuery,
  }) async {
    try {
      // Structured content for each category
      final content = [
        // Cardiovascular Health
        HealthContent(
          id: 'cv_1',
          title: 'Understanding Heart Health',
          description: 'Learn about maintaining a healthy heart and preventing cardiovascular diseases.',
          type: ContentType.article,
          category: ContentCategory.cardiovascular,
          content: '''
# Understanding Heart Health

Your heart is one of the most vital organs in your body. Here are some key points about maintaining heart health:

## Key Factors for Heart Health

1. **Regular Exercise**
   - Aim for 150 minutes of moderate exercise per week
   - Include both cardio and strength training
   - Start slow and gradually increase intensity

2. **Healthy Diet**
   - Focus on whole foods
   - Limit processed foods and added sugars
   - Include plenty of fruits and vegetables

3. **Stress Management**
   - Practice mindfulness and meditation
   - Get adequate sleep
   - Maintain work-life balance

## Warning Signs to Watch For

- Chest pain or discomfort
- Shortness of breath
- Irregular heartbeat
- Fatigue
- Swelling in legs or ankles

Remember to consult your healthcare provider for personalized advice.
''',
          duration: 10,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        HealthContent(
          id: 'cv_2',
          title: 'Exercise for Heart Health',
          description: 'A guided video on heart-healthy exercises you can do at home.',
          type: ContentType.video,
          category: ContentCategory.cardiovascular,
          content: 'Follow along with this guided exercise routine designed to improve your heart health.',
          mediaUrl: 'https://example.com/heart-exercise-video.mp4',
          duration: 15,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),

        // Sleep Health
        HealthContent(
          id: 'sleep_1',
          title: 'The Science of Sleep',
          description: 'Discover the importance of quality sleep and how it affects your overall health.',
          type: ContentType.article,
          category: ContentCategory.sleep,
          content: '''
# The Science of Sleep

Sleep is essential for your physical and mental well-being. Here's what you need to know:

## Sleep Cycles

1. **REM Sleep**
   - Occurs every 90 minutes
   - Important for memory consolidation
   - Associated with dreaming

2. **Non-REM Sleep**
   - Deep sleep phase
   - Physical restoration
   - Immune system strengthening

## Tips for Better Sleep

- Maintain a consistent sleep schedule
- Create a relaxing bedtime routine
- Keep your bedroom cool and dark
- Limit screen time before bed
- Avoid caffeine and alcohol

## Common Sleep Disorders

- Insomnia
- Sleep apnea
- Restless leg syndrome
- Narcolepsy

If you're experiencing sleep problems, consult a healthcare professional.
''',
          duration: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        HealthContent(
          id: 'sleep_2',
          title: 'Sleep Meditation',
          description: 'A calming audio guide to help you fall asleep faster and sleep better.',
          type: ContentType.audio,
          category: ContentCategory.sleep,
          content: 'Listen to this guided meditation designed to help you relax and prepare for sleep.',
          mediaUrl: 'https://example.com/sleep-meditation.mp3',
          duration: 20,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),

        // Nutrition
        HealthContent(
          id: 'nut_1',
          title: 'Nutrition Basics',
          description: 'A comprehensive guide to understanding nutrition and making healthy food choices.',
          type: ContentType.article,
          category: ContentCategory.nutrition,
          content: '''
# Nutrition Basics

Understanding nutrition is key to maintaining a healthy lifestyle. Here's what you need to know:

## Essential Nutrients

1. **Macronutrients**
   - Proteins: Building blocks for muscles
   - Carbohydrates: Primary energy source
   - Fats: Essential for hormone production

2. **Micronutrients**
   - Vitamins: Support various bodily functions
   - Minerals: Important for bone health and more

## Building a Balanced Plate

- Fill half your plate with vegetables and fruits
- Include lean proteins
- Choose whole grains
- Add healthy fats in moderation

## Reading Food Labels

- Check serving sizes
- Look for added sugars
- Monitor sodium content
- Understand ingredient lists

Remember, a balanced diet is about variety and moderation.
''',
          duration: 15,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        HealthContent(
          id: 'nut_2',
          title: 'Healthy Cooking Basics',
          description: 'Learn essential cooking techniques for preparing nutritious meals.',
          type: ContentType.video,
          category: ContentCategory.nutrition,
          content: 'Watch this video to learn basic cooking techniques for preparing healthy meals.',
          mediaUrl: 'https://example.com/healthy-cooking.mp4',
          duration: 25,
          createdAt: DateTime.now(),
        ),

        // Mental Health
        HealthContent(
          id: 'mh_1',
          title: 'Understanding Stress',
          description: 'Learn about stress management and its impact on your health.',
          type: ContentType.article,
          category: ContentCategory.mentalHealth,
          content: '''
# Understanding Stress

Stress is a natural response to challenges, but chronic stress can impact your health. Here's what you need to know:

## Types of Stress

1. **Acute Stress**
   - Short-term response
   - Helps with immediate challenges
   - Usually resolves quickly

2. **Chronic Stress**
   - Long-term response
   - Can impact physical health
   - May lead to health problems

## Stress Management Techniques

- Deep breathing exercises
- Regular physical activity
- Mindfulness meditation
- Adequate sleep
- Social support

## When to Seek Help

- Persistent feelings of anxiety
- Difficulty sleeping
- Changes in appetite
- Physical symptoms
- Difficulty concentrating

Remember, it's okay to seek professional help when needed.
''',
          duration: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        HealthContent(
          id: 'mh_2',
          title: 'Mindfulness Meditation',
          description: 'A guided meditation session for stress relief and mental clarity.',
          type: ContentType.audio,
          category: ContentCategory.mentalHealth,
          content: 'Follow this guided meditation to practice mindfulness and reduce stress.',
          mediaUrl: 'https://example.com/mindfulness-meditation.mp3',
          duration: 15,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),

        // Exercise
        HealthContent(
          id: 'ex_1',
          title: 'Getting Started with Exercise',
          description: 'A beginner-friendly guide to starting your fitness journey.',
          type: ContentType.article,
          category: ContentCategory.exercise,
          content: '''
# Getting Started with Exercise

Starting a new exercise routine can be challenging. Here's how to begin:

## Getting Started

1. **Set Realistic Goals**
   - Start small and build up
   - Be specific and measurable
   - Track your progress

2. **Choose Activities You Enjoy**
   - Walking or jogging
   - Swimming
   - Cycling
   - Group fitness classes

3. **Create a Schedule**
   - Plan your workouts
   - Be consistent
   - Allow for rest days

## Safety Tips

- Warm up properly
- Stay hydrated
- Listen to your body
- Use proper form
- Don't overdo it

Remember, consistency is key to seeing results.
''',
          duration: 10,
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        HealthContent(
          id: 'ex_2',
          title: 'Home Workout Routine',
          description: 'A complete workout routine you can do at home with minimal equipment.',
          type: ContentType.video,
          category: ContentCategory.exercise,
          content: 'Follow this guided workout routine designed for home exercise.',
          mediaUrl: 'https://example.com/home-workout.mp4',
          duration: 30,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),

        // General Health
        HealthContent(
          id: 'gen_1',
          title: 'Preventive Health Care',
          description: 'Learn about important health screenings and preventive care.',
          type: ContentType.article,
          category: ContentCategory.general,
          content: '''
# Preventive Health Care

Taking care of your health before problems arise is crucial. Here's what you need to know:

## Regular Check-ups

1. **Annual Physical Exam**
   - Blood pressure check
   - Cholesterol screening
   - Blood sugar test
   - Weight and BMI

2. **Age-Appropriate Screenings**
   - Cancer screenings
   - Bone density tests
   - Vision and hearing
   - Dental check-ups

## Healthy Habits

- Regular exercise
- Balanced diet
- Adequate sleep
- Stress management
- Regular check-ups

Remember, prevention is better than cure.
''',
          duration: 12,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        HealthContent(
          id: 'gen_2',
          title: 'Health and Wellness Tips',
          description: 'Daily tips and practices for maintaining overall health and wellness.',
          type: ContentType.audio,
          category: ContentCategory.general,
          content: 'Listen to these daily health and wellness tips for a healthier lifestyle.',
          mediaUrl: 'https://example.com/wellness-tips.mp3',
          duration: 15,
          createdAt: DateTime.now(),
        ),
      ];

      // Filter content based on parameters
      var filteredContent = content;
      if (type != null) {
        filteredContent = filteredContent.where((c) => c.type == type).toList();
      }
      if (category != null) {
        filteredContent = filteredContent.where((c) => c.category == category).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filteredContent = filteredContent
            .where((c) =>
                c.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                c.description.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();
      }

      return filteredContent;
    } catch (e) {
      debugPrint('Error getting health content: $e');
      throw Exception('Failed to load health content');
    }
  }

  Future<HealthContent> getHealthContentById(String id) async {
    try {
      // First try to get from Firestore
      try {
        final doc = await _firestore.collection('healthContent').doc(id).get();
        if (doc.exists) {
          return HealthContent.fromJson(doc.data()!);
        }
      } catch (e) {
        debugPrint('Error fetching from Firestore: $e');
      }

      // If not found in Firestore, get from local content
      final allContent = await getHealthContent();
      final content = allContent.firstWhere(
        (c) => c.id == id,
        orElse: () => throw Exception('Health content not found'),
      );
      return content;
    } catch (e) {
      debugPrint('Error getting health content by id: $e');
      rethrow;
    }
  }

  Future<void> initializeSampleContent() async {
    try {
      final content = [
        {
          'id': 'diabetes_1',
          'title': 'Understanding Diabetes',
          'description': 'Learn about diabetes types, symptoms, and management',
          'type': 'article',
          'category': 'diabetes',
          'content': 'Diabetes is a chronic condition that affects how your body turns food into energy...',
          'duration': 10,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'heart_1',
          'title': 'Heart Health Basics',
          'description': 'Essential information about maintaining a healthy heart',
          'type': 'video',
          'category': 'heartHealth',
          'content': 'Your heart is a vital organ that pumps blood throughout your body...',
          'mediaUrl': 'https://example.com/heart-health-video.mp4',
          'thumbnailUrl': 'https://example.com/heart-thumbnail.jpg',
          'duration': 15,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'sleep_1',
          'title': 'Better Sleep Habits',
          'description': 'Tips for improving your sleep quality',
          'type': 'audio',
          'category': 'sleepHygiene',
          'content': 'Good sleep is essential for your physical and mental health...',
          'mediaUrl': 'https://example.com/sleep-audio.mp3',
          'duration': 20,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'med_1',
          'title': 'Medication Safety',
          'description': 'Important guidelines for medication management',
          'type': 'article',
          'category': 'medicationManagement',
          'content': 'Proper medication management is crucial for your health...',
          'duration': 12,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      final batch = _firestore.batch();
      for (var item in content) {
        final docRef = _firestore.collection('healthContent').doc(item['id'] as String);
        batch.set(docRef, item);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error initializing sample content: $e');
      rethrow;
    }
  }

  Future<void> trackContentProgress(String contentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final progressRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .doc(contentId);

      final progressDoc = await progressRef.get();
      final isFirstView = !progressDoc.exists;

      await progressRef.set({
        'lastViewed': FieldValue.serverTimestamp(),
        'viewCount': FieldValue.increment(1),
        'pointsAwarded': isFirstView,
      }, SetOptions(merge: true));

      // Award 5 points on first view only
      if (isFirstView) {
        final profileRef = _firestore.collection('profiles').doc(userId);
        await profileRef.update({
          'totalPoints': FieldValue.increment(5),
        });

        // Get content details for the activity log
        final contentDoc = await _firestore
            .collection('healthContent')
            .doc(contentId)
            .get();
        
        if (contentDoc.exists) {
          final contentData = contentDoc.data()!;
          final now = DateTime.now();
          
          // Log as a completed activity for "Recent Activities"
          await _firestore
              .collection('activityProgress')
              .doc(userId)
              .collection('activities')
              .add({
            'userId': userId,
            'activityId': contentId,
            'title': contentData['title'],
            'type': 'reading',  // or contentData['type']
            'status': 'completed',
            'pointsEarned': 5,
            'completedAt': FieldValue.serverTimestamp(),
            'startedAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
            'healthData': {},
          });
        }
      }
    } catch (e) {
      debugPrint('Error tracking content progress: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getContentProgress(String contentId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .doc(contentId)
          .get();

      return doc.data() ?? {};
    } catch (e) {
      debugPrint('Error getting content progress: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProgressStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get total content count
      final totalContent = await _firestore.collection('healthContent').count().get();

      // Get user's viewed content
      final viewedContent = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .get();

      // Calculate total time spent
      int totalTime = 0;
      for (var doc in viewedContent.docs) {
        final content = await getHealthContentById(doc.id);
        final viewCount = doc.data()['viewCount'] as int? ?? 0;
        if (content.duration != null) {
          totalTime += content.duration! * viewCount;
        }
      }

      return {
        'totalContent': totalContent.count,
        'completedContent': viewedContent.docs.length,
        'totalTime': totalTime,
      };
    } catch (e) {
      debugPrint('Error getting progress stats: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final progress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .orderBy('lastViewed', descending: true)
          .limit(10)
          .get();

      final List<Map<String, dynamic>> recentlyViewed = [];
      for (var doc in progress.docs) {
        final content = await getHealthContentById(doc.id);
        recentlyViewed.add({
          'id': content.id,
          'title': content.title,
          'type': content.type,
          'lastViewed': doc.data()['lastViewed'],
          'viewCount': doc.data()['viewCount'] ?? 0,
        });
      }

      return recentlyViewed;
    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      rethrow;
    }
  }

  Future<Map<String, double>> getCategoryProgress() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get all content progress
      final progress = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .get();

      // Get all content to calculate category totals
      final allContent = await _firestore.collection('healthContent').get();

      // Calculate progress for each category
      final Map<String, int> categoryViewed = {};
      final Map<String, int> categoryTotal = {};

      for (var doc in allContent.docs) {
        final content = HealthContent.fromJson(doc.data());
        final category = content.category.toString();
        categoryTotal[category] = (categoryTotal[category] ?? 0) + 1;
      }

      for (var doc in progress.docs) {
        final content = await getHealthContentById(doc.id);
        final category = content.category.toString();
        categoryViewed[category] = (categoryViewed[category] ?? 0) + 1;
      }

      // Calculate progress percentages
      final Map<String, double> categoryProgress = {};
      for (var category in categoryTotal.keys) {
        final viewed = categoryViewed[category] ?? 0;
        final total = categoryTotal[category] ?? 1;
        categoryProgress[category] = viewed / total;
      }

      return categoryProgress;
    } catch (e) {
      debugPrint('Error getting category progress: $e');
      rethrow;
    }
  }

  Future<List<HealthContent>> getRecommendedContent() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's viewed content
      final viewedContent = await _firestore
          .collection('users')
          .doc(userId)
          .collection('contentProgress')
          .get();

      // Get categories with least progress
      final categoryProgress = await getCategoryProgress();
      final sortedCategories = categoryProgress.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Get content from least viewed categories
      final recommendedContent = <HealthContent>[];
      for (var category in sortedCategories) {
        if (recommendedContent.length >= 5) break;

        final content = await getHealthContent(
          category: ContentCategory.values.firstWhere(
            (c) => c.toString() == category.key,
          ),
        );

        // Filter out already viewed content
        final newContent = content.where((c) {
          return !viewedContent.docs.any((doc) => doc.id == c.id);
        }).toList();

        recommendedContent.addAll(newContent);
      }

      return recommendedContent.take(5).toList();
    } catch (e) {
      debugPrint('Error getting recommended content: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getContent(String contentId) async {
    // TODO: Implement actual API call to fetch health content
    // This is a placeholder implementation
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'id': contentId,
      'title': 'Health Content Title',
      'content': 'Health content details...',
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }
} 