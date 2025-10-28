import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _healthMetrics;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _sosEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Load user profile
      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(widget.userId)
          .get();

      // Load health metrics
      final healthMetrics = await _adminService.getUserHealthMetrics(widget.userId);

      // Load activities
      final activities = await _adminService.getUserActivities(widget.userId);

      // Load medications
      final medications = await _adminService.getUserMedications(widget.userId);

      // Load SOS events
      final sosEvents = await _adminService.getSOSEvents(widget.userId);

      if (mounted) {
        setState(() {
          _userProfile = profileDoc.data();
          _healthMetrics = healthMetrics;
          _activities = activities;
          _medications = medications;
          _sosEvents = sosEvents;
          _isLoading = false;
        });
      }
    } catch (e) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_userProfile?['displayName'] ?? 'User Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.health_and_safety), text: 'Health'),
            Tab(icon: Icon(Icons.directions_run), text: 'Activities'),
            Tab(icon: Icon(Icons.medication), text: 'Medications'),
            Tab(icon: Icon(Icons.warning), text: 'SOS Events'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHealthTab(),
                _buildActivitiesTab(),
                _buildMedicationsTab(),
                _buildSOSTab(),
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
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(activity['activityId'] ?? 'Unknown Activity'),
                    subtitle: Text('Points: ${activity['pointsEarned'] ?? 0}'),
                    trailing: Text(
                      _formatDate(activity['completedAt']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
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
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.red, size: 32),
                    title: Text(event['type'] ?? 'SOS'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event['description'] ?? ''),
                        if (event['location'] != null)
                          Text('Location: ${event['location']['latitude']}, ${event['location']['longitude']}'),
                      ],
                    ),
                    trailing: Text(
                      _formatDate(event['timestamp']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              },
            ),
    );
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
}

