import 'package:flutter/material.dart';
import 'create_admin_and_caregiver.dart';

class CreateAccountsScreen extends StatefulWidget {
  const CreateAccountsScreen({super.key});

  @override
  State<CreateAccountsScreen> createState() => _CreateAccountsScreenState();
}

class _CreateAccountsScreenState extends State<CreateAccountsScreen> {
  bool _isCreating = false;
  String _statusMessage = '';
  bool _showSuccess = false;

  Future<void> _createAccounts() async {
    setState(() {
      _isCreating = true;
      _statusMessage = 'Creating accounts...';
      _showSuccess = false;
    });

    try {
      await CreateAdminAndCaregiver.createAccounts();
      setState(() {
        _statusMessage = 'Accounts created successfully!';
        _showSuccess = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _showSuccess = false;
      });
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin & Caregiver Accounts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAccountInfo(
                      'Admin Account',
                      'risadmin@thriveapp.com',
                      'Admin12312#',
                      'admin',
                    ),
                    const SizedBox(height: 16),
                    _buildAccountInfo(
                      'Caregiver Account',
                      'riscaregiver@thriveapp.com',
                      'Caregiver12312#',
                      'caretaker',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createAccounts,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Accounts'),
            ),
            if (_statusMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _showSuccess ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _showSuccess ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _showSuccess ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ExpansionTile(
              title: const Text('Manual Firestore Setup Instructions'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'If the script fails, follow these steps:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Create Firebase Auth Users:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '   - Go to Firebase Console > Authentication > Users',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '   - Add user: risadmin@thriveapp.com / Admin12312#',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '   - Add user: riscaregiver@thriveapp.com / Caregiver12312#',
                        style: TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '   - Copy the UID for each user',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '2. Create Firestore Documents:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '   Collection: admins',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '   Document ID: [Firebase Auth UID]',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '   Fields for Admin:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        '     - email: "risadmin@thriveapp.com"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - displayName: "Admin User"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - role: "admin"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - assignedUsers: []',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - createdAt: [Server Timestamp]',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - lastLogin: [Server Timestamp]',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - isActive: true',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '   Fields for Caregiver:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        '     - email: "riscaregiver@thriveapp.com"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - displayName: "Caregiver User"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - role: "caretaker"',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - assignedUsers: []',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - createdAt: [Server Timestamp]',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - lastLogin: [Server Timestamp]',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                      const Text(
                        '     - isActive: true',
                        style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo(String title, String email, String password, String role) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Email: $email'),
          Text('Password: $password'),
          Text('Role: $role'),
        ],
      ),
    );
  }
}


