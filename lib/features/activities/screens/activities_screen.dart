import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../activity_bloc.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../screens/achievements_screen.dart';
import 'exercise_routine_screen.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ActivitiesScreenBody();
  }
}

class _ActivitiesScreenBody extends StatefulWidget {
  @override
  State<_ActivitiesScreenBody> createState() => _ActivitiesScreenBodyState();
}

class _ActivitiesScreenBodyState extends State<_ActivitiesScreenBody> with SingleTickerProviderStateMixin {
  int? _totalPoints;
  bool _loadingPoints = true;
  String _activeFilter = 'All Activities';
  String _activeDifficulty = 'All';
  String _searchQuery = '';
  String _sortBy = 'points';
  bool _sortAscending = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _fetchTotalPoints();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchTotalPoints();
  }

  Future<void> _fetchTotalPoints() async {
    final activityService = context.read<ActivityService>();
    try {
      final points = await activityService.getTotalPoints();
      if (mounted) {
        setState(() {
          _totalPoints = points;
          _loadingPoints = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _totalPoints = 0;
          _loadingPoints = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activities'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events),
            onPressed: () => context.push('/achievements'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Physical'),
            Tab(text: 'Mental'),
            Tab(text: 'Social'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Points Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.white, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Points',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 4),
                        _loadingPoints
                            ? const LinearProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text(
                                '${_totalPoints ?? 0}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: Text(_activeDifficulty),
                  selected: true,
                  onSelected: (selected) => _showDifficultyDialog(context),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Sort: ${_sortBy.toUpperCase()}'),
                  selected: true,
                  onSelected: (selected) => _showSortDialog(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActivitiesList(context, 'All'),
                _buildActivitiesList(context, 'Physical'),
                _buildActivitiesList(context, 'Mental'),
                _buildActivitiesList(context, 'Social'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(BuildContext context, String type) {
    return BlocBuilder<ActivityBloc, ActivityState>(
      builder: (context, state) {
        if (state is ActivityLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ActivityError) {
          return Center(child: Text(state.message));
        }
        if (state is ActivitiesLoaded) {
          var activities = state.activities;
          if (type != 'All') {
            activities = activities.where((a) => a.type.toLowerCase() == type.toLowerCase()).toList();
          }
          return _buildFilteredActivitiesList(context, activities);
        }
        return const Center(child: Text('No activities available'));
      },
    );
  }

  Widget _buildFilteredActivitiesList(BuildContext context, List<Activity> activities) {
    // Apply filters
    var filteredActivities = activities;
    
    // Difficulty filter
    if (_activeDifficulty != 'All') {
      filteredActivities = filteredActivities
          .where((activity) => activity.difficulty.toLowerCase() == _activeDifficulty.toLowerCase())
          .toList();
    }
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filteredActivities = filteredActivities
          .where((activity) =>
              activity.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              activity.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Sort activities
    filteredActivities.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'points':
          comparison = a.points.compareTo(b.points);
          break;
        case 'duration':
          comparison = a.duration.compareTo(b.duration);
          break;
        case 'difficulty':
          comparison = _getDifficultyWeight(a.difficulty)
              .compareTo(_getDifficultyWeight(b.difficulty));
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    if (filteredActivities.isEmpty) {
      return const Center(child: Text('No activities match your filters'));
    }

    return ListView.builder(
      itemCount: filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = filteredActivities[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => _showActivityDetails(context, activity),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              activity.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDifficultyColor(activity.difficulty),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              activity.difficulty,
                              style: TextStyle(
                                color: _getDifficultyTextColor(activity.difficulty),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.points} pts',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.duration} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        _getActivityTypeIcon(activity.type),
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        activity.type,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getActivityTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'physical':
        return Icons.fitness_center;
      case 'mental':
        return Icons.psychology;
      case 'social':
        return Icons.people;
      default:
        return Icons.star;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade100;
      case 'medium':
        return Colors.orange.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getDifficultyTextColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade800;
      case 'medium':
        return Colors.orange.shade800;
      case 'hard':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  int _getDifficultyWeight(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      default:
        return 0;
    }
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Activities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Activities'),
              onTap: () {
                context.read<ActivityBloc>().add(LoadActivities());
                setState(() {
                  _activeFilter = 'All Activities';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Physical'),
              onTap: () {
                context.read<ActivityBloc>().add(const LoadActivitiesByType('physical'));
                setState(() {
                  _activeFilter = 'Physical';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Mental'),
              onTap: () {
                context.read<ActivityBloc>().add(const LoadActivitiesByType('mental'));
                setState(() {
                  _activeFilter = 'Mental';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Social'),
              onTap: () {
                context.read<ActivityBloc>().add(const LoadActivitiesByType('social'));
                setState(() {
                  _activeFilter = 'Social';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              onTap: () {
                setState(() {
                  _activeDifficulty = 'All';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Easy'),
              onTap: () {
                setState(() {
                  _activeDifficulty = 'Easy';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Medium'),
              onTap: () {
                setState(() {
                  _activeDifficulty = 'Medium';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Hard'),
              onTap: () {
                setState(() {
                  _activeDifficulty = 'Hard';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Activities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Points'),
              trailing: _sortBy == 'points'
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'points';
                  _sortAscending = !_sortAscending;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Duration'),
              trailing: _sortBy == 'duration'
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'duration';
                  _sortAscending = !_sortAscending;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Difficulty'),
              trailing: _sortBy == 'difficulty'
                  ? Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                  : null,
              onTap: () {
                setState(() {
                  _sortBy = 'difficulty';
                  _sortAscending = !_sortAscending;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, Activity activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Chip(
                      label: Text(activity.type),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${activity.difficulty}'),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('${activity.points} points'),
                      backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Instructions:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(activity.content['instructions'] ?? 'No instructions available'),
                const SizedBox(height: 24),
                if (activity.type.toLowerCase() == 'physical')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseRoutineScreen(activity: activity),
                        ),
                      );
                    },
                    child: const Text('Start Activity'),
                  )
                else if (activity.type.toLowerCase() == 'mental')
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Activity type: ${activity.type}');
                      debugPrint('Activity title: ${activity.title}');
                      debugPrint('Activity ID: ${activity.id}');
                      if (activity.title.toLowerCase().contains('word')) {
                        debugPrint('Navigating to word puzzle: /activities/${activity.id}/word-puzzle');
                        Navigator.pop(context);
                        context.go('/activities/${activity.id}/word-puzzle');
                      } else if (activity.title.toLowerCase().contains('memory')) {
                        debugPrint('Navigating to memory game: /activities/${activity.id}/memory-game');
                        Navigator.pop(context);
                        context.go('/activities/${activity.id}/memory-game');
                      }
                    },
                    child: const Text('Start Game'),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      debugPrint('Starting physical/social activity: ${activity.id}');
                      Navigator.pop(context);
                      context.read<ActivityBloc>().add(StartActivity(activity.id));
                    },
                    child: const Text('Start Activity'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 