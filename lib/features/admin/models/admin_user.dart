import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'admin' or 'caretaker'
  final List<String> assignedUsers; // user IDs they can monitor
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  AdminUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.assignedUsers,
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle nullable timestamps
    DateTime createdAt;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.now();
      }
    } else {
      createdAt = DateTime.now();
    }
    
    DateTime lastLogin;
    if (data['lastLogin'] != null) {
      if (data['lastLogin'] is Timestamp) {
        lastLogin = (data['lastLogin'] as Timestamp).toDate();
      } else {
        lastLogin = DateTime.now();
      }
    } else {
      lastLogin = DateTime.now();
    }
    
    return AdminUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'caretaker',
      assignedUsers: List<String>.from(data['assignedUsers'] ?? []),
      createdAt: createdAt,
      lastLogin: lastLogin,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'assignedUsers': assignedUsers,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'isActive': isActive,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isCaretaker => role == 'caretaker';

  AdminUser copyWith({
    String? email,
    String? displayName,
    String? role,
    List<String>? assignedUsers,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return AdminUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}

