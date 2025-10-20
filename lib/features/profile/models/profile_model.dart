import 'package:cloud_firestore/cloud_firestore.dart';

class Profile {
  final String uid;
  final String displayName;
  final String? email;
  final String? phoneNumber;
  final int age;
  final String? gender;
  final String preferredLanguage;
  final List<EmergencyContact> emergencyContacts;
  final Location? location;
  final DateTime createdAt;
  final DateTime lastLogin;
  final ProfileSettings settings;

  Profile({
    required this.uid,
    required this.displayName,
    this.email,
    this.phoneNumber,
    required this.age,
    this.gender,
    required this.preferredLanguage,
    required this.emergencyContacts,
    this.location,
    required this.createdAt,
    required this.lastLogin,
    required this.settings,
  });

  factory Profile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Profile(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      age: data['age'] ?? 0,
      gender: data['gender'],
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      emergencyContacts: (data['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromMap(e))
              .toList() ??
          [],
      location: data['location'] != null
          ? Location.fromMap(data['location'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: (data['lastLogin'] as Timestamp).toDate(),
      settings: ProfileSettings.fromMap(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'age': age,
      'gender': gender,
      'preferredLanguage': preferredLanguage,
      'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      'location': location?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'settings': settings.toMap(),
    };
  }

  Profile copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    int? age,
    String? gender,
    String? preferredLanguage,
    List<EmergencyContact>? emergencyContacts,
    Location? location,
    DateTime? lastLogin,
    ProfileSettings? settings,
  }) {
    return Profile(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      location: location ?? this.location,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? this.settings,
    );
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.isPrimary,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'isPrimary': isPrimary,
    };
  }
}

class Location {
  final double latitude;
  final double longitude;
  final String address;

  Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      address: map['address'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}

class ProfileSettings {
  final bool notifications;
  final bool darkMode;
  final String fontSize;
  final bool voiceGuidance;

  ProfileSettings({
    required this.notifications,
    required this.darkMode,
    required this.fontSize,
    required this.voiceGuidance,
  });

  factory ProfileSettings.fromMap(Map<String, dynamic> map) {
    return ProfileSettings(
      notifications: map['notifications'] ?? true,
      darkMode: map['darkMode'] ?? false,
      fontSize: map['fontSize'] ?? 'medium',
      voiceGuidance: map['voiceGuidance'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifications': notifications,
      'darkMode': darkMode,
      'fontSize': fontSize,
      'voiceGuidance': voiceGuidance,
    };
  }

  ProfileSettings copyWith({
    bool? notifications,
    bool? darkMode,
    String? fontSize,
    bool? voiceGuidance,
  }) {
    return ProfileSettings(
      notifications: notifications ?? this.notifications,
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      voiceGuidance: voiceGuidance ?? this.voiceGuidance,
    );
  }
} 