import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../activity_bloc.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

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
            return _buildAchievementsList(context, state.achievements);
          }
          return const Center(child: Text('No achievements available'));
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
                Icon(
                  IconData(
                    int.parse(achievement.icon),
                    fontFamily: 'MaterialIcons',
                  ),
                  size: 32,
                  color: achievement.isUnlocked() ? Colors.amber : Colors.grey,
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
            if (!achievement.isUnlocked() && progress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getProgressText(achievement, requirements, progress),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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

  String _getProgressText(Achievement achievement, Map<String, dynamic> requirements, double progress) {
    switch (achievement.type) {
      case 'activity':
        final count = requirements['count'] as int? ?? 1;
        final current = requirements['current'] as int? ?? 0;
        return '$current/$count activities completed';
      case 'streak':
        final days = requirements['days'] as int? ?? 7;
        final current = requirements['current'] as int? ?? 0;
        return '$current/$days days streak';
      case 'milestone':
        final points = requirements['points'] as int? ?? 1000;
        final current = requirements['current'] as int? ?? 0;
        return '$current/$points points';
      default:
        return '';
    }
  }
} 