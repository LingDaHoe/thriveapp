import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/health_content.dart';
import '../services/health_content_service.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Progress'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgressStats(context),
            const SizedBox(height: 24),
            _buildRecentlyViewed(context),
            const SizedBox(height: 24),
            _buildCategoryProgress(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStats(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: _getProgressStats(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data ?? {
                  'totalContent': 0,
                  'completedContent': 0,
                  'totalTime': 0,
                };

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Content Viewed',
                      '${stats['completedContent']}/${stats['totalContent']}',
                      Icons.visibility,
                    ),
                    _buildStatItem(
                      context,
                      'Total Time',
                      '${stats['totalTime']} min',
                      Icons.timer,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildRecentlyViewed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recently Viewed',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _getRecentlyViewed(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return const Center(
                child: Text('No recently viewed content'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: _getContentTypeIcon(item['type'] as ContentType),
                  title: Text(item['title'] as String),
                  subtitle: Text(
                    'Last viewed: ${_formatDate(item['lastViewed'] as Timestamp)}',
                  ),
                  trailing: Text('${item['viewCount']} views'),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Progress',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FutureBuilder<Map<String, double>>(
          future: _getCategoryProgress(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final progress = snapshot.data ?? {};

            return Column(
              children: ContentCategory.values.map((category) {
                final categoryProgress = progress[category.toString()] ?? 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.toString().split('.').last,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: categoryProgress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(categoryProgress * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _getContentTypeIcon(ContentType type) {
    IconData iconData;
    switch (type) {
      case ContentType.article:
        iconData = Icons.article;
        break;
      case ContentType.video:
        iconData = Icons.video_library;
        break;
      case ContentType.audio:
        iconData = Icons.headphones;
        break;
    }
    return Icon(iconData);
  }

  Future<Map<String, dynamic>> _getProgressStats(BuildContext context) async {
    try {
      return await context.read<HealthContentService>().getProgressStats();
    } catch (e) {
      debugPrint('Error getting progress stats: $e');
      return {
        'totalContent': 0,
        'completedContent': 0,
        'totalTime': 0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> _getRecentlyViewed(BuildContext context) async {
    try {
      return await context.read<HealthContentService>().getRecentlyViewed();
    } catch (e) {
      debugPrint('Error getting recently viewed: $e');
      return [];
    }
  }

  Future<Map<String, double>> _getCategoryProgress(BuildContext context) async {
    try {
      return await context.read<HealthContentService>().getCategoryProgress();
    } catch (e) {
      debugPrint('Error getting category progress: $e');
      return {};
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 