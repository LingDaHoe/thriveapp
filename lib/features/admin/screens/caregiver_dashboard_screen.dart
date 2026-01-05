import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/caregiver_service.dart';
import '../services/admin_service.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final CaregiverService _caregiverService = CaregiverService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _assignedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final users = await _caregiverService.getAssignedUsers();
    if (mounted) {
      setState(() {
        _assignedUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _inviteUser() async {
    final emailController = TextEditingController();
    List<String> _suggestedEmails = [];
    bool _isLoadingEmails = false;

    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Invite User'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'User Email',
                      hintText: 'Type first letter to see suggestions...',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) async {
                      if (value.isNotEmpty) {
                        final firstLetter = value[0];
                        setDialogState(() {
                          _isLoadingEmails = true;
                        });
                        final emails = await _caregiverService.getUserEmailsByFirstLetter(firstLetter);
                        setDialogState(() {
                          _suggestedEmails = emails;
                          _isLoadingEmails = false;
                        });
                      } else {
                        setDialogState(() {
                          _suggestedEmails = [];
                        });
                      }
                    },
                  ),
                  if (_isLoadingEmails)
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  else if (_suggestedEmails.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Suggestions (${_suggestedEmails.length}):',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _suggestedEmails.length,
                        itemBuilder: (context, index) {
                          final email = _suggestedEmails[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.email, size: 20),
                            title: Text(
                              email,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () {
                              emailController.text = email;
                              setDialogState(() {
                                _suggestedEmails = [];
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (emailController.text.isNotEmpty) {
                    Navigator.pop(context, true);
                  }
                },
                child: const Text('Send Invitation'),
              ),
            ],
          );
        },
      ),
    ).then((result) async {
      if (result == true && emailController.text.isNotEmpty) {
        try {
          await _caregiverService.inviteUserByEmail(emailController.text.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invitation sent successfully'),
                backgroundColor: Colors.green,
              ),
            );
            _loadData(); // Refresh the list
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _inviteUser,
            tooltip: 'Invite User',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AdminService.clearAdminSession();
              await _auth.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _assignedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No assigned users yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Invite users to join your care team',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _inviteUser,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Invite User'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assigned Users',
                                  style:
                                      Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${_assignedUsers.length} user${_assignedUsers.length == 1 ? '' : 's'}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._assignedUsers.map((user) {
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                child: Text(
                                  (user['displayName'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(user['displayName'] ?? 'Unknown'),
                              subtitle: Text(user['email'] ?? ''),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                // Navigate to user detail (caregiver view)
                                context.push('/caregiver/user/${user['uid']}');
                              },
                            ),
                          );
                        }).toList(),
                      ],
                    ),
            ),
    );
  }
}

