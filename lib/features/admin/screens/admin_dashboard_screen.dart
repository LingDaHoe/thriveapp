import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/admin_service.dart';
import '../models/admin_user.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  AdminUser? _currentAdmin;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _recentSOSEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final admin = await _adminService.getCurrentAdminUser();
    if (admin == null) {
      if (mounted) {
        context.go('/admin/login');
      }
      return;
    }

    // Get all users in the system
    final users = await _adminService.getAllUsers();
    // Get all SOS events from all users
    final sosEvents = await _adminService.getAllSOSEventsFromAllUsers();

    if (mounted) {
      setState(() {
        _currentAdmin = admin;
        _allUsers = users;
        _recentSOSEvents = sosEvents;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AdminService.clearAdminSession();
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                context.go('/admin/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdminInfo(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildRecentSOSSection(),
                    const SizedBox(height: 24),
                    _buildAllUsersSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAdminInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                _currentAdmin?.displayName[0].toUpperCase() ?? 'A',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentAdmin?.displayName ?? 'Admin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    _currentAdmin?.role.toUpperCase() ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _currentAdmin?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            _allUsers.length.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'SOS Alerts',
            _recentSOSEvents.length.toString(),
            Icons.warning,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSOSSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent SOS Alerts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_recentSOSEvents.isNotEmpty)
              TextButton(
                onPressed: () {
                  // Navigate to full SOS history
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_recentSOSEvents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No SOS events',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSOSEvents.take(5).length,
            itemBuilder: (context, index) {
              final event = _recentSOSEvents[index];
              final userName = event['userName'] ?? 'Unknown User';
              final timestamp = event['timestamp'] as Timestamp?;
              final timeAgo = timestamp != null 
                  ? _getTimeAgo(timestamp.toDate())
                  : 'Unknown time';
              
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text('${event['type'] ?? 'SOS'} - $userName'),
                  subtitle: Text('${event['description'] ?? 'Emergency triggered'}\n$timeAgo'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to user detail page
                    if (event['userId'] != null) {
                      context.push('/admin/user/${event['userId']}');
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAllUsersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Users',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        if (_allUsers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No users found',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allUsers.length,
            itemBuilder: (context, index) {
              final user = _allUsers[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (user['displayName'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user['displayName'] ?? 'Unknown'),
                  subtitle: Text(user['email'] ?? ''),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to user detail page where admin can view health, add medications, etc.
                    context.push('/admin/user/${user['uid']}');
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

