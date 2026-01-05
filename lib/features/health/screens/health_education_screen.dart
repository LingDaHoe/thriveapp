import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/health_content.dart';
import '../services/health_content_service.dart';
import 'package:go_router/go_router.dart';

class HealthEducationScreen extends StatefulWidget {
  const HealthEducationScreen({Key? key}) : super(key: key);

  @override
  State<HealthEducationScreen> createState() => _HealthEducationScreenState();
}

class _HealthEducationScreenState extends State<HealthEducationScreen> {
  final _searchController = TextEditingController();
  ContentType? _selectedType;
  ContentCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ContentType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Content Type',
                ),
                items: ContentType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ContentCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: ContentCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'AI-Powered Filtering',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use AI to find articles based on your preferences and interests.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedType = null;
                _selectedCategory = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Education'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              context.go('/health/progress');
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search health content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          if (_selectedType != null || _selectedCategory != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_selectedType != null)
                    Chip(
                      label: Text(_selectedType.toString().split('.').last),
                      onDeleted: () {
                        setState(() => _selectedType = null);
                      },
                    ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(_selectedCategory.toString().split('.').last),
                      onDeleted: () {
                        setState(() => _selectedCategory = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<HealthContent>>(
              future: context.read<HealthContentService>().getHealthContent(
                    type: _selectedType,
                    category: _selectedCategory,
                    searchQuery: _searchQuery,
                  ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final content = snapshot.data ?? [];

                if (content.isEmpty) {
                  return const Center(
                    child: Text('No content found'),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_selectedType == null && _selectedCategory == null && _searchQuery.isEmpty)
                      _buildRecommendedSection(context),
                    ...content.map((item) => Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: _getContentTypeIcon(item.type),
                            ),
                            title: Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.timer_outlined,
                                      size: 16,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.duration} min',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.category_outlined,
                                      size: 16,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.category.toString().split('.').last,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const Spacer(),
                                    FutureBuilder<Map<String, dynamic>>(
                                      future: context.read<HealthContentService>().getContentProgress(item.id),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Read',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              context.push('/health/${item.id}');
                            },
                          ),
                        )),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<HealthContent>>(
          future: context.read<HealthContentService>().getRecommendedContent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final recommended = snapshot.data ?? [];

            if (recommended.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: recommended.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: _getContentTypeIcon(item.type),
                      ),
                      title: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 16,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.duration} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.category.toString().split('.').last,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/health/${item.id}');
                      },
                    ),
                  )).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'All Content',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
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
} 