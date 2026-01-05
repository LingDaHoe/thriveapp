import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverInvitation {
  final String id;
  final String caregiverId;
  final String caregiverName;
  final String caregiverEmail;
  final String userId;
  final String userEmail;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;
  final DateTime? respondedAt;

  CaregiverInvitation({
    required this.id,
    required this.caregiverId,
    required this.caregiverName,
    required this.caregiverEmail,
    required this.userId,
    required this.userEmail,
    this.status = 'pending',
    required this.createdAt,
    this.respondedAt,
  });

  factory CaregiverInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CaregiverInvitation(
      id: doc.id,
      caregiverId: data['caregiverId'] ?? '',
      caregiverName: data['caregiverName'] ?? '',
      caregiverEmail: data['caregiverEmail'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'caregiverId': caregiverId,
      'caregiverName': caregiverName,
      'caregiverEmail': caregiverEmail,
      'userId': userId,
      'userEmail': userEmail,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}

