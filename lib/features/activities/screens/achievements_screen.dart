import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../activity_bloc.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    // Load achievements when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityBloc>().add(LoadAchievements());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state is ActivityLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ActivityError) {
            return Center(child: Text(state.message));
          }
          if (state is AchievementsLoaded) {
            if (state.achievements.isEmpty) {
              return const Center(
                child: Text('No achievements available'),
              );
            }
            return _buildAchievementsList(context, state.achievements);
          }
          // Initial state - show loading while fetching
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAchievementsList(BuildContext context, List<Achievement> achievements) {
    // Group achievements by type
    final Map<String, List<Achievement>> groupedAchievements = {};
    for (var achievement in achievements) {
      groupedAchievements.putIfAbsent(achievement.type, () => []).add(achievement);
    }

    return ListView.builder(
      itemCount: groupedAchievements.length,
      itemBuilder: (context, index) {
        final type = groupedAchievements.keys.elementAt(index);
        final typeAchievements = groupedAchievements[type]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _getTypeTitle(type),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ...typeAchievements.map((achievement) => _buildAchievementCard(context, achievement)),
          ],
        );
      },
    );
  }

  String _getTypeTitle(String type) {
    switch (type) {
      case 'activity':
        return 'Activity Achievements';
      case 'streak':
        return 'Streak Achievements';
      case 'milestone':
        return 'Milestone Achievements';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildAchievementCard(BuildContext context, Achievement achievement) {
    final requirements = achievement.requirements ?? {};
    final progress = _calculateProgress(achievement, requirements);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Display emoji instead of Material Icon
                Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: achievement.isUnlocked() ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        achievement.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${achievement.points} pts',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (achievement.isUnlocked())
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ],
            ),
            // Always show requirements and progress, whether locked or unlocked
            const SizedBox(height: 16),
            if (progress != null) ...[
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  achievement.isUnlocked() 
                      ? Colors.green 
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Show requirements text
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: achievement.isUnlocked() 
                    ? Colors.green.shade50 
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.isUnlocked() ? '✅ Unlocked!' : '🔒 Requirements:',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: achievement.isUnlocked() ? Colors.green.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRequirementsText(achievement, requirements),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (progress != null && !achievement.isUnlocked())
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getProgressText(achievement, requirements, progress),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double? _calculateProgress(Achievement achievement, Map<String, dynamic> requirements) {
    switch (achievement.type) {
      case 'activity':
        final count = requirements['count'] as int? ?? 1;
        final current = requirements['current'] as int? ?? 0;
        return current / count;
      case 'streak':
        final days = requirements['days'] as int? ?? 7;
        final current = requirements['current'] as int? ?? 0;
        return current / days;
      case 'milestone':
        final points = requirements['points'] as int? ?? 1000;
        final current = requirements['current'] as int? ?? 0;
        return current / points;
      default:
        return null;
    }
  }

  String _getRequirementsText(Achievement achievement, Map<String, dynamic> requirements) {
    switch (achievement.type) {
      case 'activity':
        final count = requirements['count'] as int? ?? 1;
        final activityType = requirements['activityType'] as String? ?? 'any';
        final typeText = activityType == 'any' 
            ? 'activities' 
            : '$activityType activities';
        return 'Complete $count $typeText';
      case 'streak':
        final days = requirements['days'] as int? ?? 7;
        return 'Complete activities for $days days in a row';
      case 'milestone':
        final points = requirements['points'] as int? ?? 1000;
        return 'Earn $points points';
      default:
        return achievement.description;
    }
  }

  String _getProgressText(Achievement achievement, Map<String, dynamic> requirements, double progress) {
    switch (achievement.type) {
      case 'activity':
        final count = requirements['count'] as int? ?? 1;
        final current = requirements['current'] as int? ?? 0;
        return 'Progress: $current/$count activities completed';
      case 'streak':
        final days = requirements['days'] as int? ?? 7;
        final current = requirements['current'] as int? ?? 0;
        return 'Progress: $current/$days days streak';
      case 'milestone':
        final points = requirements['points'] as int? ?? 1000;
        final current = requirements['current'] as int? ?? 0;
        return 'Progress: $current/$points points';
      default:
        return '';
    }
  }
} 