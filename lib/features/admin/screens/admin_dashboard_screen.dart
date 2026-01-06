import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
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
  bool _usersSectionExpanded = false; // Auto-minimize
  bool _sosSectionExpanded = false; // Auto-minimize
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic>? _latestSOSEvent; // Track latest SOS for notification
  DateTime? _lastSOSCheckTime; // Track when we last checked for SOS

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSOSListener();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _setupSOSListener() {
    // Listen to real-time SOS events
    _adminService.watchAllSOSEvents().listen((events) {
      if (mounted && events.isNotEmpty) {
        final latestEvent = events.first;
        final eventTime = latestEvent['timestamp'] as Timestamp?;
        
        // Only show notification if this is a new event (after last check)
        if (eventTime != null) {
          final eventDateTime = eventTime.toDate();
          if (_lastSOSCheckTime == null || eventDateTime.isAfter(_lastSOSCheckTime!)) {
            setState(() {
              _latestSOSEvent = latestEvent;
              _recentSOSEvents = events;
            });
            
            // Show notification banner
            _showSOSNotification(latestEvent);
            
            // Update last check time
            _lastSOSCheckTime = DateTime.now();
          } else {
            // Just update the list without showing notification
            setState(() {
              _recentSOSEvents = events;
            });
          }
        }
      }
    });
  }

  void _showSOSNotification(Map<String, dynamic> event) {
    final userName = event['userName'] ?? 'Unknown User';
    final location = event['location'] as Map<String, dynamic>?;
    final latitude = location?['latitude'];
    final longitude = location?['longitude'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🚨 SOS ALERT: $userName',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Emergency triggered - Immediate action required!'),
            if (latitude != null && longitude != null)
              TextButton(
                onPressed: () {
                  // Open maps - URL can be used with url_launcher if needed
                  // final url = 'https://maps.google.com/?q=$latitude,$longitude';
                },
                child: const Text('View Location', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'View Details',
          textColor: Colors.white,
          onPressed: () {
            if (event['userId'] != null) {
              context.push('/admin/user/${event['userId']}?tab=sos');
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    // Get pending caregivers (refresh this list)
    final pendingCaregivers = await _adminService.getPendingCaregivers();

    debugPrint('Loaded ${pendingCaregivers.length} pending caregivers');

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
                    // Show SOS notification banner if there's a recent event
                    if (_latestSOSEvent != null) _buildSOSBanner(),
                    _buildAdminInfo(),
                    const SizedBox(height: 24),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildCaregiverManagementSection(),
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

  Widget _buildSOSBanner() {
    if (_latestSOSEvent == null) return const SizedBox.shrink();
    
    final userName = _latestSOSEvent!['userName'] ?? 'Unknown User';
    final location = _latestSOSEvent!['location'] as Map<String, dynamic>?;
    final latitude = location?['latitude'];
    final longitude = location?['longitude'];
    final timestamp = _latestSOSEvent!['timestamp'] as Timestamp?;
    final timeAgo = timestamp != null ? _getTimeAgo(timestamp.toDate()) : 'Just now';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.red, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🚨 SOS ALERT: $userName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Emergency triggered - $timeAgo'),
                if (latitude != null && longitude != null)
                  Text(
                    'Location: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (_latestSOSEvent!['userId'] != null) {
                context.push('/admin/user/${_latestSOSEvent!['userId']}?tab=sos');
              }
            },
            child: const Text('View Details'),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _latestSOSEvent = null;
              });
            },
          ),
        ],
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _sosSectionExpanded = !_sosSectionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent SOS Alerts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      if (_recentSOSEvents.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            // Navigate to full SOS history
                          },
                          child: const Text('View All'),
                        ),
                      Icon(
                        _sosSectionExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_sosSectionExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _recentSOSEvents.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'No SOS events',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  : ListView.builder(
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
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.warning, color: Colors.red),
                            title: Text('${event['type'] ?? 'SOS'} - $userName'),
                            subtitle: Text('${event['description'] ?? 'Emergency triggered'}\n$timeAgo'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to user detail page, specifically to SOS tab
                              if (event['userId'] != null) {
                                context.push('/admin/user/${event['userId']}?tab=sos');
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAllUsersSection() {
    // Filter users based on search query
    final filteredUsers = _allUsers.where((user) {
      if (_searchQuery.isEmpty) return true;
      final name = (user['displayName'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _usersSectionExpanded = !_usersSectionExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Users (${_allUsers.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Icon(
                    _usersSectionExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (_usersSectionExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (filteredUsers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No users found matching "$_searchQuery"'
                              : 'No users found',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
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
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCaregiverManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Caregiver Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadData(); // Refresh all data including pending caregivers
              },
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _adminService.getPendingCaregivers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final pendingCaregivers = snapshot.data ?? [];

            if (pendingCaregivers.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No pending caregiver registrations',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }

            return Column(
              children: [
                if (pendingCaregivers.length > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${pendingCaregivers.length} pending registration(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pendingCaregivers.length,
                  itemBuilder: (context, index) {
                    final caregiver = pendingCaregivers[index];
                    final createdAt = caregiver['createdAt'];
                    String timeInfo = '';
                    if (createdAt != null) {
                      if (createdAt is Timestamp) {
                        final date = createdAt.toDate();
                        timeInfo = 'Registered: ${_formatDate(date)}';
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person_add, color: Colors.orange, size: 32),
                        title: Text(
                          caregiver['displayName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(caregiver['email'] ?? ''),
                            if (caregiver['phoneNumber'] != null && caregiver['phoneNumber'].toString().isNotEmpty)
                              Text('Phone: ${caregiver['phoneNumber']}'),
                            if (caregiver['organization'] != null && caregiver['organization'].toString().isNotEmpty)
                              Text('Organization: ${caregiver['organization']}'),
                            if (timeInfo.isNotEmpty)
                              Text(
                                timeInfo,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              tooltip: 'Approve',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Approve Caregiver?'),
                                    content: Text(
                                      'Approve ${caregiver['displayName']} (${caregiver['email']}) as a caregiver?\n\nThey will be able to access the caregiver dashboard and manage assigned users.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: const Text('Approve'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true) {
                                  try {
                                    await _adminService.approveCaregiver(caregiver['id']);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '✅ ${caregiver['displayName']} approved as caregiver!',
                                          ),
                                          backgroundColor: Colors.green,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      _loadData(); // Refresh the list
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error approving caregiver: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: 'Reject',
                              onPressed: () async {
                                final reason = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    final controller = TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Reject Caregiver Registration'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Reject ${caregiver['displayName']} (${caregiver['email']})?',
                                          ),
                                          const SizedBox(height: 16),
                                          TextField(
                                            controller: controller,
                                            decoration: const InputDecoration(
                                              labelText: 'Reason (optional)',
                                              hintText: 'Enter rejection reason...',
                                            ),
                                            maxLines: 3,
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, controller.text),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Reject'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (reason != null) {
                                  try {
                                    await _adminService.rejectCaregiver(
                                      caregiver['id'],
                                      reason.isEmpty ? 'No reason provided' : reason,
                                    );
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '❌ ${caregiver['displayName']} registration rejected',
                                          ),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error rejecting caregiver: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
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

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

