// This script helps create an admin user in Firebase
// Run this once to set up initial admin access

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../features/admin/services/admin_service.dart';

Future<void> createAdminUser() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final adminService = AdminService();

  try {
    // Create admin user
    await adminService.createAdminUser(
      email: 'admin@thriveapp.com',
      password: 'Admin@123',
      displayName: 'Admin User',
      role: 'admin',
      assignedUsers: [], // Initially no users assigned
    );

    debugPrint('✅ Admin user created successfully!');
    debugPrint('Email: admin@thriveapp.com');
    debugPrint('Password: Admin@123');
    debugPrint('Please change the password after first login.');
  } catch (e) {
    debugPrint('❌ Error creating admin user: $e');
  }
}

// Instructions for creating caretaker users:
// 1. Create a Firebase Auth account for the caretaker
// 2. Add a document in the 'admins' collection with the following structure:
// {
//   "email": "caretaker@example.com",
//   "displayName": "Caretaker Name",
//   "role": "caretaker",
//   "assignedUsers": ["userId1", "userId2"], // User IDs they can monitor
//   "createdAt": Timestamp,
//   "lastLogin": Timestamp,
//   "isActive": true
// }

