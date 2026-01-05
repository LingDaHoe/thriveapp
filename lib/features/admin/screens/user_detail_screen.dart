import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String? initialTab; // For navigating to specific tab (e.g., 'sos')

  const UserDetailScreen({super.key, required this.userId, this.initialTab});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  TabController? _tabController; // Make nullable to handle async initialization
  bool _isCaregiver = false; // Track if current user is caregiver
  bool _isInitializing = true; // Track if we're still initializing
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _healthMetrics;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _sosEvents = [];
  List<Map<String, dynamic>> _socialActivities = [];
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Don't create TabController here - wait until we know the role
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    if (!mounted) return;
    
    final adminUser = await _adminService.getCurrentAdminUser();
    if (!mounted) return;
    
    final isCaregiver = adminUser?.isCaretaker ?? false;
    
    // Determine number of tabs based on role
    // Admin: 5 tabs (Activities, Medications, SOS, Social, Chats) - no Health
    // Caregiver: 3 tabs (Activities, Medications, SOS) - no Health, Social, Chats
    final tabCount = isCaregiver ? 3 : 5;
    
    // Create TabController only once we know the role
    if (mounted) {
      setState(() {
        _isCaregiver = isCaregiver;
        _tabController = TabController(length: tabCount, vsync: this);
        _isInitializing = false;
      });
      
      // Check if we need to navigate to a specific tab (from SOS notification)
      if (widget.initialTab == 'sos') {
        // Use a delayed callback to ensure tab controller is ready
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _tabController != null) {
            final sosTabIndex = 2; // SOS is index 2 for both (no health tab)
            if (_tabController!.length > sosTabIndex) {
              _tabController!.animateTo(sosTabIndex);
            }
          }
        });
      }
      
      _loadUserData();
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Load user profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();

      if (!mounted) return;

      // Health metrics removed - no longer loading for admin or caregiver
      Map<String, dynamic>? healthMetrics;

      // Load activities
      final activities = await _adminService.getUserActivities(widget.userId);
      if (!mounted) return;

      // Load medications
      final medications = await _adminService.getUserMedications(widget.userId);
      if (!mounted) return;

      // Load SOS events
      final sosEvents = await _adminService.getSOSEvents(widget.userId);
      if (!mounted) return;

      // Load social activities (only for admins, not caregivers)
      List<Map<String, dynamic>> socialActivities = [];
      if (!_isCaregiver) {
        socialActivities = await _adminService.getUserSocialActivities(widget.userId);
        if (!mounted) return;
      }

      // Load chat history (only for admins, not caregivers)
      List<Map<String, dynamic>> chatHistory = [];
      if (!_isCaregiver) {
        chatHistory = await _adminService.getUserChatHistory(widget.userId);
        if (!mounted) return;
      }

      if (mounted) {
        setState(() {
          _userProfile = profileDoc.data();
          _healthMetrics = healthMetrics;
          _activities = activities;
          _medications = medications;
          _sosEvents = sosEvents;
          _socialActivities = socialActivities;
          _chatHistory = chatHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if tab controller is not initialized yet
    if (_isInitializing || _tabController == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile?['displayName'] ?? 'User Details'),
        bottom: TabBar(
          controller: _tabController!,
          isScrollable: true,
          tabs: _isCaregiver
              ? const [
                  // Caregiver tabs: Activities, Medications, SOS Events (no Health, Social, Chats)
                  Tab(icon: Icon(Icons.directions_run), text: 'Activities'),
                  Tab(icon: Icon(Icons.medication), text: 'Medications'),
                  Tab(icon: Icon(Icons.warning), text: 'SOS Events'),
                ]
              : const [
                  // Admin tabs: Activities, Medications, SOS, Social, Chats (no Health)
                  Tab(icon: Icon(Icons.directions_run), text: 'Activities'),
                  Tab(icon: Icon(Icons.medication), text: 'Medications'),
                  Tab(icon: Icon(Icons.warning), text: 'SOS Events'),
                  Tab(icon: Icon(Icons.people), text: 'Social'),
                  Tab(icon: Icon(Icons.chat), text: 'Chats'),
                ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController!,
              children: _isCaregiver
                  ? [
                      // Caregiver tabs
                      _buildActivitiesTab(),
                      _buildMedicationsTab(),
                      _buildSOSTab(),
                    ]
                  : [
                      // Admin tabs (no Health tab)
                      _buildActivitiesTab(),
                      _buildMedicationsTab(),
                      _buildSOSTab(),
                      _buildSocialActivitiesTab(),
                      _buildChatHistoryTab(),
                    ],
            ),
    );
  }

  Widget _buildHealthTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Health Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_healthMetrics?['error'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_healthMetrics!['error']),
                ),
              )
            else ...[
              _buildMetricCard('Steps', '${_healthMetrics?['metrics']?['steps'] ?? 0}', Icons.directions_walk),
              _buildMetricCard('Heart Rate', '${_healthMetrics?['metrics']?['heartRate'] ?? 0} bpm', Icons.favorite),
              _buildMetricCard('Sleep', '${(_healthMetrics?['metrics']?['sleep'] ?? 0).toStringAsFixed(1)} hrs', Icons.bedtime),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _activities.isEmpty
          ? const Center(child: Text('No activities yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _activities.length,
              itemBuilder: (context, index) {
                final activity = _activities[index];
                final title = activity['title'] ?? activity['activityId'] ?? 'Unknown Activity';
                final type = activity['type'] ?? 'unknown';
                final points = activity['pointsEarned'] ?? 0;
                final completedAt = activity['completedAt'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      _getActivityIcon(type),
                      color: Colors.green,
                    ),
                    title: Text(title),
                    subtitle: Text('Type: ${type.toUpperCase()} • Points: $points'),
                    trailing: Text(
                      _formatDate(completedAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Activity ID', activity['activityId'] ?? 'N/A'),
                            _buildDetailRow('Status', activity['status'] ?? 'completed'),
                            _buildDetailRow('Points Earned', points.toString()),
                            if (activity['startedAt'] != null)
                              _buildDetailRow('Started', _formatDate(activity['startedAt'])),
                            if (completedAt != null)
                              _buildDetailRow('Completed', _formatDate(completedAt)),
                            if (activity['healthData'] != null)
                              _buildDetailRow('Health Data', 'Available'),
                            if (activity['activityData'] != null)
                              _buildDetailRow('Activity Data', 'Available'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'memory_game':
        return Icons.memory;
      case 'word_puzzle':
        return Icons.text_fields;
      case 'article':
      case 'reading':
        return Icons.article;
      case 'exercise':
        return Icons.fitness_center;
      default:
        return Icons.check_circle;
    }
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddMedicationDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadUserData,
            child: _medications.isEmpty
                ? const Center(child: Text('No medications'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _medications.length,
                    itemBuilder: (context, index) {
                      final med = _medications[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.medication),
                          title: Text(med['name'] ?? 'Unknown'),
                          subtitle: Text('${med['dosage']} - ${med['frequency']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditMedicationDialog(med),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteMedication(med['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSOSTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _sosEvents.isEmpty
          ? const Center(child: Text('No SOS events'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sosEvents.length,
              itemBuilder: (context, index) {
                final event = _sosEvents[index];
                final location = event['location'];
                final coordinates = event['coordinates'] ?? event['gps'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.red.shade50,
                  child: ExpansionTile(
                    leading: const Icon(Icons.warning, color: Colors.red, size: 32),
                    title: Text(
                      event['type'] ?? 'SOS Emergency',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['description'] ?? 'Emergency triggered'),
                        Text(
                          _formatDate(event['timestamp']),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event['userName'] != null)
                              _buildDetailRow('User', event['userName']),
                            if (event['userEmail'] != null)
                              _buildDetailRow('Email', event['userEmail']),
                            if (event['userPhone'] != null)
                              _buildDetailRow('Phone', event['userPhone']),
                            _buildDetailRow('Event Type', event['type'] ?? 'SOS'),
                            if (event['description'] != null)
                              _buildDetailRow('Description', event['description']),
                            if (location != null)
                              _buildLocationDetails(location),
                            if (coordinates != null && location == null)
                              _buildLocationDetails(coordinates),
                            if (event['contacted'] != null)
                              _buildDetailRow('Contacts Notified', event['contacted'].toString()),
                            if (event['responseTime'] != null)
                              _buildDetailRow('Response Time', '${event['responseTime']} seconds'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
  
  Widget _buildLocationDetails(dynamic location) {
    if (location is Map) {
      final lat = location['latitude'] ?? location['lat'];
      final lng = location['longitude'] ?? location['lng'] ?? location['lon'];
      final address = location['address'] ?? location['formattedAddress'];
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Latitude', lat?.toString() ?? 'N/A'),
          _buildDetailRow('Longitude', lng?.toString() ?? 'N/A'),
          if (address != null)
            _buildDetailRow('Address', address),
          if (lat != null && lng != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  // Open maps with location
                  // You can use url_launcher here
                },
                icon: const Icon(Icons.map, size: 16),
                label: const Text('View on Map'),
              ),
            ),
        ],
      );
    }
    return _buildDetailRow('Location', location.toString());
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final frequencyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            TextField(
              controller: frequencyController,
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _adminService.addMedicationForUser(
                    widget.userId,
                    {
                      'name': nameController.text,
                      'dosage': dosageController.text,
                      'frequency': frequencyController.text,
                    },
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    _loadUserData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Medication added')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMedicationDialog(Map<String, dynamic> med) {
    final nameController = TextEditingController(text: med['name']);
    final dosageController = TextEditingController(text: med['dosage']);
    final frequencyController = TextEditingController(text: med['frequency']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Medication Name'),
            ),
            TextField(
              controller: dosageController,
              decoration: const InputDecoration(labelText: 'Dosage'),
            ),
            TextField(
              controller: frequencyController,
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _adminService.updateMedication(med['id'], {
                  'name': nameController.text,
                  'dosage': dosageController.text,
                  'frequency': frequencyController.text,
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadUserData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medication updated')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMedication(String medicationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminService.deleteMedication(medicationId);
        if (mounted) {
          _loadUserData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.parse(timestamp);
    } else {
      return 'Unknown';
    }
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSocialActivitiesTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _socialActivities.isEmpty
          ? const Center(child: Text('No social activities'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _socialActivities.length,
              itemBuilder: (context, index) {
                final activity = _socialActivities[index];
                final scheduledTime = (activity['scheduledTime'] as Timestamp?)?.toDate();
                final isCreator = activity['isCreator'] == true;
                final participantCount = (activity['participantIds'] as List?)?.length ?? 0;
                final maxParticipants = activity['maxParticipants'] ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: Icon(
                      isCreator ? Icons.create : Icons.event,
                      color: isCreator ? Colors.orange : Colors.blue,
                    ),
                    title: Text(activity['title'] ?? 'Unknown Activity'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isCreator)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CREATOR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        if (scheduledTime != null)
                          Text('Scheduled: ${_formatDate(scheduledTime)}'),
                        Text(
                          'Participants: $participantCount/$maxParticipants',
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Activity ID', activity['id'] ?? 'N/A'),
                            _buildDetailRow('Title', activity['title'] ?? 'N/A'),
                            if (activity['description'] != null)
                              _buildDetailRow('Description', activity['description']),
                            _buildDetailRow('Location', activity['location'] ?? 'N/A'),
                            if (scheduledTime != null)
                              _buildDetailRow('Scheduled Time', _formatDate(scheduledTime)),
                            _buildDetailRow('Max Participants', maxParticipants.toString()),
                            _buildDetailRow('Current Participants', participantCount.toString()),
                            if (activity['chatId'] != null)
                              _buildDetailRow('Chat ID', activity['chatId']),
                            if (activity['createdAt'] != null)
                              _buildDetailRow('Created', _formatDate(activity['createdAt'])),
                            if (activity['participantIds'] != null)
                              _buildDetailRow(
                                'Participant IDs',
                                (activity['participantIds'] as List).join(', '),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildChatHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _chatHistory.isEmpty
          ? const Center(child: Text('No chat history'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                final messages = chat['messages'] as List? ?? [];
                final lastMessageAt = (chat['lastMessageAt'] as Timestamp?)?.toDate();
                final participantCount = chat['participantCount'] ?? 0;
                final totalMessages = chat['totalMessages'] ?? messages.length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(Icons.chat, color: Colors.green),
                    title: Text(chat['activityTitle'] ?? 'Group Chat'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lastMessageAt != null)
                          Text('Last message: ${_formatDate(lastMessageAt)}'),
                        Text('Participants: $participantCount • Messages: $totalMessages'),
                        if (chat['lastMessageContent'] != null)
                          Text(
                            'Latest: ${chat['lastMessageContent']}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Chat ID', chat['chatId'] ?? 'N/A'),
                            if (chat['activityId'] != null)
                              _buildDetailRow('Activity ID', chat['activityId']),
                            _buildDetailRow('Activity Title', chat['activityTitle'] ?? 'N/A'),
                            _buildDetailRow('Total Messages', totalMessages.toString()),
                            _buildDetailRow('Participants', participantCount.toString()),
                            if (chat['participants'] != null)
                              _buildDetailRow(
                                'Participant IDs',
                                (chat['participants'] as List).join(', '),
                              ),
                            if (lastMessageAt != null)
                              _buildDetailRow('Last Message Time', _formatDate(lastMessageAt)),
                            if (chat['lastMessageSender'] != null)
                              _buildDetailRow('Last Message From', chat['lastMessageSender']),
                            const Divider(),
                            const Text(
                              'Recent Messages:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (messages.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No messages in this chat'),
                              )
                            else
                              ...messages.map((message) {
                                final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            message['userName'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (timestamp != null)
                                            Text(
                                              _formatDate(timestamp),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message['content'] ?? '',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (message['seenBy'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Seen by ${(message['seenBy'] as List).length}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

