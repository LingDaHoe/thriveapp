import '../features/admin/services/admin_service.dart';

/// Utility to create admin and caregiver accounts
/// Run this once to set up the initial admin and caregiver accounts
class CreateAdminAndCaregiver {
  static Future<void> createAccounts() async {
    final adminService = AdminService();

    try {
      print('=== Creating Admin and Caregiver Accounts ===\n');

      // 1. Create Admin Account
      print('1. Creating Admin Account...');
      try {
        await adminService.createAdminUser(
          email: 'risadmin@thriveapp.com',
          password: 'Admin12312#',
          displayName: 'Admin User',
          role: 'admin',
          assignedUsers: [],
        );
        print('   ✅ Admin account created successfully!');
        print('   Email: risadmin@thriveapp.com');
        print('   Password: Admin12312#');
        print('   Role: admin\n');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('   ⚠️  Admin account already exists. Skipping...\n');
        } else {
          print('   ❌ Error creating admin: $e\n');
          rethrow;
        }
      }

      // 2. Create Caregiver Account
      print('2. Creating Caregiver Account...');
      try {
        await adminService.createAdminUser(
          email: 'riscaregiver@thriveapp.com',
          password: 'Caregiver12312#',
          displayName: 'Caregiver User',
          role: 'caretaker',
          assignedUsers: [],
        );
        print('   ✅ Caregiver account created successfully!');
        print('   Email: riscaregiver@thriveapp.com');
        print('   Password: Caregiver12312#');
        print('   Role: caretaker\n');
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
          print('   ⚠️  Caregiver account already exists. Skipping...\n');
        } else {
          print('   ❌ Error creating caregiver: $e\n');
          rethrow;
        }
      }

      print('=== Account Creation Complete ===');
      print('\nYou can now login with:');
      print('Admin: risadmin@thriveapp.com / Admin12312#');
      print('Caregiver: riscaregiver@thriveapp.com / Caregiver12312#');
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  /// Manual Firestore setup instructions
  static void printFirestoreInstructions() {
    print('\n=== MANUAL FIRESTORE SETUP (if script fails) ===\n');
    print('If the script fails, you can manually create these documents in Firestore:\n');
    
    print('1. ADMIN ACCOUNT:');
    print('   Collection: admins');
    print('   Document ID: [Firebase Auth UID for risadmin@thriveapp.com]');
    print('   Fields:');
    print('     - email: "risadmin@thriveapp.com"');
    print('     - displayName: "Admin User"');
    print('     - role: "admin"');
    print('     - assignedUsers: []');
    print('     - createdAt: [Server Timestamp]');
    print('     - lastLogin: [Server Timestamp]');
    print('     - isActive: true\n');
    
    print('2. CAREGIVER ACCOUNT:');
    print('   Collection: admins');
    print('   Document ID: [Firebase Auth UID for riscaregiver@thriveapp.com]');
    print('   Fields:');
    print('     - email: "riscaregiver@thriveapp.com"');
    print('     - displayName: "Caregiver User"');
    print('     - role: "caretaker"');
    print('     - assignedUsers: []');
    print('     - createdAt: [Server Timestamp]');
    print('     - lastLogin: [Server Timestamp]');
    print('     - isActive: true\n');
    
    print('STEPS:');
    print('1. First, create Firebase Auth users:');
    print('   - Go to Firebase Console > Authentication > Users');
    print('   - Add user: risadmin@thriveapp.com / Admin12312#');
    print('   - Add user: riscaregiver@thriveapp.com / Caregiver12312#');
    print('   - Copy the UID for each user\n');
    
    print('2. Then create Firestore documents:');
    print('   - Go to Firebase Console > Firestore Database');
    print('   - Create collection "admins" (if it doesn\'t exist)');
    print('   - Create documents with the UIDs from step 1');
    print('   - Add the fields listed above\n');
  }
}

