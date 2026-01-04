import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _getProgressData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      // Get user profile for points - use StreamBuilder for real-time updates
      final profileDoc = await _firestore.collection('profiles').doc(user.uid).get();
      final totalPoints = profileDoc.data()?['totalPoints'] ?? 0;

      // Get completed activities count (including reading activities)
      final activitiesSnapshot = await _firestore
          .collection('activityProgress')
          .doc(user.uid)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();
      final completedActivities = activitiesSnapshot.docs.length;

      // Get activities by type and count articles read
      final activityTypes = <String, int>{};
      final Set<String> uniqueArticleIds = {};
      
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;
        
        // Count reading activities as articles read
        if (type == 'reading' || type == 'content') {
          final activityId = data['activityId'] as String?;
          if (activityId != null) {
            uniqueArticleIds.add(activityId);
          }
        }
        
        // Get activity type from activityId if not directly available
        final activityId = data['activityId'] as String?;
        if (activityId != null && type == null) {
          try {
            final actDoc = await _firestore.collection('activities').doc(activityId).get();
            final actType = actDoc.data()?['type'] as String? ?? 'general';
            activityTypes[actType] = (activityTypes[actType] ?? 0) + 1;
          } catch (_) {
            // If activity not found, use type from data or default
            final fallbackType = data['type'] as String? ?? 'general';
            activityTypes[fallbackType] = (activityTypes[fallbackType] ?? 0) + 1;
          }
        } else if (type != null) {
          activityTypes[type] = (activityTypes[type] ?? 0) + 1;
        } else {
          activityTypes['general'] = (activityTypes['general'] ?? 0) + 1;
        }
      }

      // Also check contentProgress collection for articles read
      try {
        final contentProgressSnapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('contentProgress')
            .get();
        for (final doc in contentProgressSnapshot.docs) {
          uniqueArticleIds.add(doc.id);
        }
      } catch (_) {
        // Fallback to old collection path
        try {
          final contentProgressSnapshot = await _firestore
              .collection('contentProgress')
              .doc(user.uid)
              .collection('items')
              .get();
          for (final doc in contentProgressSnapshot.docs) {
            uniqueArticleIds.add(doc.id);
          }
        } catch (_) {}
      }
      
      final readContent = uniqueArticleIds.length;

      // Get active streak (days with at least one completed activity)
      final now = DateTime.now();
      final last30Days = Timestamp.fromDate(now.subtract(const Duration(days: 30)));
      final recentActivities = await _firestore
          .collection('activityProgress')
          .doc(user.uid)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThan: last30Days)
          .orderBy('completedAt', descending: true)
          .get();

      // Calculate streak - count unique days with activities
      final Set<String> activityDays = {};
      for (final doc in recentActivities.docs) {
        final completedAt = doc.data()['completedAt'];
        if (completedAt != null) {
          DateTime completedDate;
          if (completedAt is Timestamp) {
            completedDate = completedAt.toDate();
          } else if (completedAt is DateTime) {
            completedDate = completedAt;
          } else {
            continue;
          }
          final dayKey = '${completedDate.year}-${completedDate.month}-${completedDate.day}';
          activityDays.add(dayKey);
        }
      }

      // Calculate current streak by checking consecutive days
      int currentStreak = 0;
      final today = DateTime(now.year, now.month, now.day);
      DateTime checkDate = today;
      
      // Sort activity days
      final sortedDays = activityDays.map((dayKey) {
        final parts = dayKey.split('-');
        return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      }).toList()..sort((a, b) => b.compareTo(a));
      
      for (final activityDay in sortedDays) {
        final diff = checkDate.difference(activityDay).inDays;
        if (diff == 0 || diff == 1) {
          if (diff == 1) {
            currentStreak++;
          } else if (diff == 0 && currentStreak == 0) {
            currentStreak = 1;
          }
          checkDate = activityDay;
        } else {
          break;
        }
      }

      return {
        'totalPoints': totalPoints,
        'completedActivities': completedActivities,
        'readContent': readContent,
        'currentStreak': currentStreak,
        'activityTypes': activityTypes,
      };
    } catch (e) {
      print('Error fetching progress data: $e');
      return {};
    }
  }

  Stream<Map<String, dynamic>> _getProgressDataStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value({});

    // Stream activities for real-time updates - handle errors gracefully
    final activitiesStream = _firestore
        .collection('activityProgress')
        .doc(user.uid)
        .collection('activities')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .handleError((error) {
      debugPrint('Error in activities stream: $error');
      return <QuerySnapshot>[];
    });

    // Combine streams manually
    return activitiesStream.asyncMap((activitiesSnapshot) async {
      try {
        // Get latest profile data
        final profileDoc = await _firestore.collection('profiles').doc(user.uid).get();
        final totalPoints = profileDoc.data()?['totalPoints'] ?? 0;

        // Get latest content progress
        QuerySnapshot contentSnapshot;
        try {
          contentSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('contentProgress')
              .get();
        } catch (_) {
          // Fallback to old collection path
          try {
            contentSnapshot = await _firestore
                .collection('contentProgress')
                .doc(user.uid)
                .collection('items')
                .get();
          } catch (__) {
            // Return empty snapshot if both fail
            contentSnapshot = await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('contentProgress')
                .limit(0)
                .get();
          }
        }

        final completedActivities = activitiesSnapshot.docs.length;

        // Get activities by type and count articles read
        final activityTypes = <String, int>{};
        final Set<String> uniqueArticleIds = {};
        
        for (final doc in activitiesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['type'] as String?;
          
          // Count reading activities as articles read
          if (type == 'reading' || type == 'content') {
            final activityId = data['activityId'] as String?;
            if (activityId != null) {
              uniqueArticleIds.add(activityId);
            }
          }
          
          // Get activity type
          final activityId = data['activityId'] as String?;
          if (activityId != null && type == null) {
            try {
              final actDoc = await _firestore.collection('activities').doc(activityId).get();
              final actType = actDoc.data()?['type'] as String? ?? 'general';
              activityTypes[actType] = (activityTypes[actType] ?? 0) + 1;
            } catch (_) {
              final fallbackType = data['type'] as String? ?? 'general';
              activityTypes[fallbackType] = (activityTypes[fallbackType] ?? 0) + 1;
            }
          } else if (type != null) {
            activityTypes[type] = (activityTypes[type] ?? 0) + 1;
          } else {
            activityTypes['general'] = (activityTypes['general'] ?? 0) + 1;
          }
        }

        // Add articles from contentProgress
        for (final doc in contentSnapshot.docs) {
          uniqueArticleIds.add(doc.id);
        }
        
        final readContent = uniqueArticleIds.length;

        // Calculate streak
        final now = DateTime.now();
        final Set<String> activityDays = {};
        for (final doc in activitiesSnapshot.docs) {
          final completedAt = doc.data()['completedAt'];
          if (completedAt != null) {
            DateTime completedDate;
            if (completedAt is Timestamp) {
              completedDate = completedAt.toDate();
            } else if (completedAt is DateTime) {
              completedDate = completedAt;
            } else {
              continue;
            }
            final dayKey = '${completedDate.year}-${completedDate.month}-${completedDate.day}';
            activityDays.add(dayKey);
          }
        }

        int currentStreak = 0;
        final today = DateTime(now.year, now.month, now.day);
        DateTime checkDate = today;
        
        final sortedDays = activityDays.map((dayKey) {
          final parts = dayKey.split('-');
          return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }).toList()..sort((a, b) => b.compareTo(a));
        
        for (final activityDay in sortedDays) {
          final diff = checkDate.difference(activityDay).inDays;
          if (diff == 0 || diff == 1) {
            if (diff == 1) {
              currentStreak++;
            } else if (diff == 0 && currentStreak == 0) {
              currentStreak = 1;
            }
            checkDate = activityDay;
          } else {
            break;
          }
        }

        return {
          'totalPoints': totalPoints,
          'completedActivities': completedActivities,
          'readContent': readContent,
          'currentStreak': currentStreak,
          'activityTypes': activityTypes,
        };
      } catch (e) {
        debugPrint('Error in progress data stream: $e');
        // Return default values on error
        return {
          'totalPoints': 0,
          'completedActivities': 0,
          'readContent': 0,
          'currentStreak': 0,
          'activityTypes': <String, int>{},
        };
      }
    }).handleError((error) {
      debugPrint('Error in progress stream: $error');
      return {
        'totalPoints': 0,
        'completedActivities': 0,
        'readContent': 0,
        'currentStreak': 0,
        'activityTypes': <String, int>{},
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Progress'),
        centerTitle: true,
      ),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _getProgressDataStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading progress data: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Unable to load progress data'),
            );
          }

          final data = snapshot.data!;
          final totalPoints = data['totalPoints'] ?? 0;
          final completedActivities = data['completedActivities'] ?? 0;
          final readContent = data['readContent'] ?? 0;
          final currentStreak = data['currentStreak'] ?? 0;
          final activityTypes = data['activityTypes'] as Map<String, int>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Points Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$totalPoints',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Total Points',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle,
                        value: '$completedActivities',
                        label: 'Activities',
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.local_fire_department,
                        value: '$currentStreak',
                        label: 'Day Streak',
                        color: const Color(0xFFFF9800),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.book,
                        value: '$readContent',
                        label: 'Articles Read',
                        color: const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        value: '${(totalPoints / 100).toStringAsFixed(0)}%',
                        label: 'Progress',
                        color: const Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Activity Breakdown
                const Text(
                  'Activity Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                if (activityTypes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No activities completed yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...activityTypes.entries.map((entry) {
                    final type = entry.key;
                    final count = entry.value;
                    final percentage = (count / completedActivities * 100).toInt();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getActivityIcon(type),
                                    size: 20,
                                    color: const Color(0xFF00BCD4),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatActivityType(type),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$count ($percentage%)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF00BCD4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'physical':
        return Icons.directions_run;
      case 'mental':
        return Icons.psychology;
      case 'social':
        return Icons.people;
      case 'nutrition':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  String _formatActivityType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}

