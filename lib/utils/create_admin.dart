import 'package:flutter/material.dart';
import '../features/admin/services/admin_service.dart';

/// Helper function to create an admin user
/// This should be called ONCE to set up the first admin account
/// 
/// Usage:
/// 1. Import this file in your main.dart or a temporary screen
/// 2. Call createAdminUserHelper() with your desired credentials
/// 3. Comment out or remove the call after the admin is created
/// 
/// Example:
/// ```dart
/// await createAdminUserHelper(
///   email: 'admin@thriveapp.com',
///   password: 'AdminPassword123!',
///   displayName: 'Admin User',
///   role: 'administrator',
/// );
/// ```
Future<void> createAdminUserHelper({
  required String email,
  required String password,
  required String displayName,
  required String role,
  List<String> assignedUsers = const [],
}) async {
  try {
    debugPrint('=== Creating Admin User ===');
    debugPrint('Email: $email');
    debugPrint('Display Name: $displayName');
    debugPrint('Role: $role');
    
    final adminService = AdminService();
    await adminService.createAdminUser(
      email: email,
      password: password,
      displayName: displayName,
      role: role,
      assignedUsers: assignedUsers,
    );
    
    debugPrint('✅ Admin user created successfully!');
    debugPrint('You can now login with:');
    debugPrint('Email: $email');
    debugPrint('Password: $password');
    debugPrint('---');
    debugPrint('⚠️ IMPORTANT: Remove or comment out the createAdminUserHelper() call after first use!');
    
  } catch (e) {
    debugPrint('❌ Error creating admin user: $e');
    debugPrint('This might mean the user already exists or there\'s a Firebase error.');
    rethrow;
  }
}

/// Widget to create admin user with a button (for debugging purposes)
class CreateAdminUserScreen extends StatefulWidget {
  const CreateAdminUserScreen({super.key});

  @override
  State<CreateAdminUserScreen> createState() => _CreateAdminUserScreenState();
}

class _CreateAdminUserScreenState extends State<CreateAdminUserScreen> {
  final _emailController = TextEditingController(text: 'admin@thriveapp.com');
  final _passwordController = TextEditingController(text: 'Admin123!');
  final _nameController = TextEditingController(text: 'Admin User');
  final _roleController = TextEditingController(text: 'administrator');
  bool _isLoading = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      await createAdminUserHelper(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
        role: _roleController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _message = '✅ Admin user created successfully!\nEmail: ${_emailController.text}\nPassword: ${_passwordController.text}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Admin User'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '⚠️ Admin Setup',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use this screen ONCE to create your first admin account. After creation, this screen should be removed from production.',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Admin Email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Admin Password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'Role (administrator/caretaker)',
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createAdmin,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Create Admin User'),
            ),
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _message.startsWith('✅')
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _message.startsWith('✅')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _message.startsWith('✅')
                        ? Colors.green[900]
                        : Colors.red[900],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

