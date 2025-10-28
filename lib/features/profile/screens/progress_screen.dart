import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      // Get user profile for points
      final profileDoc = await _firestore.collection('profiles').doc(user.uid).get();
      final totalPoints = profileDoc.data()?['totalPoints'] ?? 0;

      // Get completed activities count
      final activitiesSnapshot = await _firestore
          .collection('activityProgress')
          .doc(user.uid)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .get();
      final completedActivities = activitiesSnapshot.docs.length;

      // Get activities by type
      final activityTypes = <String, int>{};
      for (final doc in activitiesSnapshot.docs) {
        final data = doc.data();
        final activityId = data['activityId'] as String?;
        if (activityId != null) {
          final actDoc = await _firestore.collection('activities').doc(activityId).get();
          final type = actDoc.data()?['type'] as String? ?? 'general';
          activityTypes[type] = (activityTypes[type] ?? 0) + 1;
        }
      }

      // Get read content count
      final contentProgressSnapshot = await _firestore
          .collection('contentProgress')
          .doc(user.uid)
          .collection('items')
          .get();
      final readContent = contentProgressSnapshot.docs.length;

      // Get active streak (days with at least one completed activity)
      final now = DateTime.now();
      final last30Days = now.subtract(const Duration(days: 30));
      final recentActivities = await _firestore
          .collection('activityProgress')
          .doc(user.uid)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .where('completedAt', isGreaterThan: last30Days)
          .orderBy('completedAt', descending: true)
          .get();

      // Calculate streak
      int currentStreak = 0;
      DateTime? lastDate;
      for (final doc in recentActivities.docs) {
        final completedAt = (doc.data()['completedAt'] as Timestamp).toDate();
        final completedDate = DateTime(completedAt.year, completedAt.month, completedAt.day);
        
        if (lastDate == null) {
          // First activity
          final today = DateTime(now.year, now.month, now.day);
          if (completedDate == today || completedDate == today.subtract(const Duration(days: 1))) {
            currentStreak = 1;
            lastDate = completedDate;
          } else {
            break;
          }
        } else {
          final diff = lastDate.difference(completedDate).inDays;
          if (diff == 1) {
            currentStreak++;
            lastDate = completedDate;
          } else if (diff == 0) {
            // Same day, continue
            continue;
          } else {
            break;
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Progress'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getProgressData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
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

