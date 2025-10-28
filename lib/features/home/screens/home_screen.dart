import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thriveapp/features/activities/screens/activities_screen.dart';
import 'package:provider/provider.dart';
import 'package:thriveapp/features/activities/services/activity_service.dart';
import 'package:thriveapp/features/activities/activity_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:thriveapp/features/profile/screens/profile_screen.dart';
import 'package:thriveapp/features/profile/services/profile_service.dart';
import 'package:thriveapp/features/profile/blocs/profile_bloc.dart';
import 'package:thriveapp/features/health/screens/health_education_screen.dart';
import 'package:thriveapp/features/health/services/health_content_service.dart';
import 'package:thriveapp/features/health/screens/health_monitoring_screen.dart';
import 'package:thriveapp/features/health/services/health_monitoring_service.dart';

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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.health_and_safety,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Thrive.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.menu, color: Color(0xFF00BCD4)),
            ),
            onPressed: () {
              // TODO: Show menu
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00BCD4).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication, color: Color(0xFF00BCD4)),
            ),
            onPressed: () {
              context.push('/health/medications');
            },
            tooltip: 'Add Medication',
          ),
          const SizedBox(width: 16),
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
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section with Avatar
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('profiles')
                .doc(_auth.currentUser?.uid)
                .get(),
            builder: (context, snapshot) {
              String name = 'User';
              if (snapshot.hasData && snapshot.data?.data() != null) {
                name = snapshot.data!.data()!['displayName'] ?? name;
              } else if (_auth.currentUser?.email != null) {
                name = _auth.currentUser!.email!.split('@')[0];
              }
              
              return Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF00BCD4), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, size: 30, color: Color(0xFF00BCD4)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00BCD4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Health Stats Cards Row
          FutureBuilder<Map<String, dynamic>>(
            future: _getHealthStats(),
            builder: (context, snapshot) {
              final heartRate = snapshot.data?['heartRate'] ?? '0';
              final steps = snapshot.data?['steps'] ?? '0';
              
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.favorite,
                      color: const Color(0xFFFF6B6B),
                      value: '$heartRate',
                      label: 'Heart Rate',
                      subtitle: 'BPM',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.directions_walk,
                      color: const Color(0xFF4E9FFF),
                      value: '$steps',
                      label: 'Steps',
                      subtitle: 'Steps Taken',
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Quick Access Section
          const Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
            ),
          ),
          
          const SizedBox(height: 16),
          
          _buildQuickAccessGrid(),
          
          const SizedBox(height: 24),
          
          // Recent Activities
          _buildUpcomingActivities(),
          
          const SizedBox(height: 24),
          
          // Medication Reminder (only if medications exist)
          _buildMedicationReminder(),
          
          // Games and Progress
          Row(
            children: [
              Expanded(child: _buildGamesCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildEmergencyCard()),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAccessGrid() {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildQuickAccessItem(Icons.dashboard, 'Dashboard', const Color(0xFF00BCD4), () {
          setState(() => _selectedIndex = 0);
        }),
        _buildQuickAccessItem(Icons.health_and_safety, 'Health Forum', const Color(0xFFFF6B6B), () {
          setState(() => _selectedIndex = 3); // Navigate to Learn tab
        }),
        _buildQuickAccessItem(Icons.psychology, 'Health AI', const Color(0xFF9B59B6), () {
          context.push('/ai/chat');
        }),
        _buildQuickAccessItem(Icons.games, 'Games Area', const Color(0xFFFFA726), () {
          setState(() => _selectedIndex = 2); // Navigate to Activities tab
        }),
      ],
    );
  }
  
  Widget _buildQuickAccessItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUpcomingActivities() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _selectedIndex = 2); // Navigate to Activities tab
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _getRecentActivitiesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No recent activities',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              final recentActivities = snapshot.data!.take(3).toList();
              
              return Column(
                children: recentActivities.map((activity) {
                  final title = activity['title'] ?? 'Activity';
                  final type = activity['type'] ?? 'general';
                  final completedAt = activity['completedAt'] as Timestamp?;
                  final timeAgo = completedAt != null 
                      ? _formatTimeAgo(completedAt.toDate())
                      : '';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00BCD4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getActivityIcon(type),
                            color: const Color(0xFF00BCD4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeAgo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildGamesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Games',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('profiles')
                .doc(_auth.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              int points = 0;
              if (snapshot.hasData && snapshot.data?.data() != null) {
                points = snapshot.data!.data()!['totalPoints'] ?? 0;
              }
              
              return Row(
                children: [
                  const Text(
                    'Points:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$points Points',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.push('/progress');
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('Track Progress', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmergencyCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Call',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please press the "SOS Call" button to initiate an emergency call.',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.push('/emergency');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Text('SOS CALL', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationReminder() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('medications')
          .doc(_auth.currentUser?.uid)
          .collection('userMedications')
          .snapshots(),
      builder: (context, snapshot) {
        // Only show if medications exist
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00BCD4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color(0xFF00BCD4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Medication Reminder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have ${snapshot.data!.docs.length} medication${snapshot.data!.docs.length > 1 ? 's' : ''} to take today',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/health/medications');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View Medications',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
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
                child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance
                      .collection('profiles')
                      .doc(_auth.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    String initial = 'U';
                    if (snapshot.hasData && snapshot.data?.data() != null) {
                      final dn = snapshot.data!.data()!['displayName'] as String?;
                      if (dn != null && dn.isNotEmpty) {
                        initial = dn[0].toUpperCase();
                      }
                    } else if ((_auth.currentUser?.email ?? '').isNotEmpty) {
                      initial = _auth.currentUser!.email!.split('@')[0].toUpperCase()[0];
                    }
                    return Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('profiles')
                          .doc(_auth.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        String name = 'User';
                        if (snapshot.hasData && snapshot.data?.data() != null) {
                          name = snapshot.data!.data()!['displayName'] ?? name;
                        } else {
                          name = _auth.currentUser?.email?.split('@')[0] ?? name;
                        }
                        return Text(
                          name,
                          style: Theme.of(context).textTheme.titleLarge,
                        );
                      },
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
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getRecentActivitiesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Error loading activities: ${snapshot.error}'),
                ),
              );
            }

            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No recent activities. Start an activity to see your progress here!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return ListTile(
                    leading: Icon(_getActivityIcon(activity['type'])),
                    title: Text(activity['title'] ?? 'Unknown Activity'),
                    subtitle: Text('Completed ${_formatTimeAgo(activity['completedAt'])}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('+${activity['pointsEarned'] ?? 0} pts'),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getHealthStats() async {
    try {
      final healthService = HealthMonitoringService();
      final metrics = await healthService.getHealthMetrics();
      
      return {
        'heartRate': metrics['heartRate']?.toStringAsFixed(0) ?? '0',
        'steps': metrics['steps']?.toStringAsFixed(0) ?? '0',
      };
    } catch (e) {
      print('Error fetching health stats: $e');
      return {'heartRate': '0', 'steps': '0'};
    }
  }

  Stream<List<Map<String, dynamic>>> _getRecentActivitiesStream() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return Stream.value([]);

      return FirebaseFirestore.instance
          .collection('activityProgress')
          .doc(user.uid)
          .collection('activities')
          .where('status', isEqualTo: 'completed')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .snapshots()
          .asyncMap((snapshot) async {
        final List<Map<String, dynamic>> results = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final activityId = data['activityId'] as String?;
          String? title;
          String? type;
          if (activityId != null && activityId.isNotEmpty) {
            try {
              final actDoc = await FirebaseFirestore.instance
                  .collection('activities')
                  .doc(activityId)
                  .get();
              if (actDoc.exists) {
                final act = actDoc.data();
                title = act?['title'] as String?;
                type = act?['type'] as String?;
              }
            } catch (_) {}
          }
          results.add({
            ...data,
            if (title != null) 'title': title,
            if (type != null) 'type': type,
          });
        }
        return results;
      });
    } catch (e) {
      debugPrint('Error getting recent activities: $e');
      return Stream.value([]);
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type?.toLowerCase()) {
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

  String _formatTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      return 'Unknown time';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildHealthMetrics() {
    return MultiProvider(
      providers: [
        Provider<HealthMonitoringService>(
          create: (_) => HealthMonitoringService(),
        ),
      ],
      child: const HealthMonitoringScreen(),
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