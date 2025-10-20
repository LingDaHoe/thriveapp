import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../widgets/activity_summary_card.dart';
import '../widgets/health_metrics_card.dart';
import '../widgets/recommendations_card.dart';
import 'package:thriveapp/features/activities/screens/activities_screen.dart';
import 'package:provider/provider.dart';
import 'package:thriveapp/features/activities/services/activity_service.dart';
import 'package:thriveapp/features/activities/activity_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thriveapp/features/health/widgets/medication_reminder_card.dart';
import 'package:thriveapp/features/health/blocs/medication_bloc.dart';
import 'package:thriveapp/features/health/services/medication_service.dart';
import 'package:thriveapp/features/profile/screens/profile_screen.dart';
import 'package:thriveapp/features/profile/services/profile_service.dart';
import 'package:thriveapp/features/profile/blocs/profile_bloc.dart';
import 'package:thriveapp/features/health/screens/health_education_screen.dart';
import 'package:thriveapp/features/health/services/health_content_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thrive'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(),
          _buildHealthMetrics(),
          _buildActivities(),
          _buildHealthEducation(),
          _buildProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_run),
            label: 'Activities',
          ),
          NavigationDestination(
            icon: Icon(Icons.school),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${_auth.currentUser?.email?.split('@')[0] ?? 'User'}!',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildHealthSummaryCard(),
          const SizedBox(height: 16),
          const MedicationReminderCard(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedIndex = 4; // Switch to profile tab
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _auth.currentUser?.email?.split('@')[0].toUpperCase()[0] ?? 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _auth.currentUser?.email?.split('@')[0] ?? 'User',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to view and edit profile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Health Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem(Icons.directions_walk, 'Steps', '0'),
                _buildMetricItem(Icons.favorite, 'Heart Rate', '0'),
                _buildMetricItem(Icons.bedtime, 'Sleep', '0h'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.medical_services_outlined,
            label: 'Health',
            onTap: () {
              // TODO: Implement health screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Health features coming soon!')),
              );
            },
          ),
          _buildActionButton(
            icon: Icons.medication,
            label: 'Medication',
            onTap: () => context.go('/health/medications'),
          ),
          _buildActionButton(
            icon: Icons.psychology,
            label: 'AI Assistant',
            onTap: () => context.go('/ai/chat'),
          ),
          _buildActionButton(
            icon: Icons.warning_rounded,
            label: 'SOS',
            onTap: () => _showSOSDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: const Text(
          'This will notify your emergency contacts with your location. Are you sure you want to trigger the SOS?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/emergency');
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('GO TO EMERGENCY'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text('Activity ${index + 1}'),
                subtitle: Text('Description for activity ${index + 1}'),
                trailing: const Icon(Icons.chevron_right),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetrics() {
    return const Center(
      child: Text('Health Metrics Screen - Coming Soon'),
    );
  }

  Widget _buildActivities() {
    return MultiProvider(
      providers: [
        Provider<ActivityService>(
          create: (_) => ActivityService(),
        ),
        BlocProvider<ActivityBloc>(
          create: (context) => ActivityBloc(
            context.read<ActivityService>(),
          )..add(LoadActivities()),
        ),
      ],
      child: const ActivitiesScreen(),
    );
  }

  Widget _buildHealthEducation() {
    return MultiProvider(
      providers: [
        Provider<HealthContentService>(
          create: (_) => HealthContentService(),
        ),
      ],
      child: const HealthEducationScreen(),
    );
  }

  Widget _buildProfile() {
    return MultiProvider(
      providers: [
        Provider<ProfileService>(
          create: (_) => ProfileService(),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(
            context.read<ProfileService>(),
          )..add(LoadProfile()),
        ),
      ],
      child: const ProfileScreen(),
    );
  }
} 