import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_contact.dart';

class EmergencyService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  late final CollectionReference _emergencyContactsCollection;
  late final CollectionReference _emergencyEventsCollection;

  EmergencyService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('No authenticated user');
    }
    _emergencyContactsCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('emergency_contacts');
    _emergencyEventsCollection = _firestore
        .collection('users')
        .doc(userId)
        .collection('emergency_events');
  }

  // Emergency Contacts
  Stream<List<EmergencyContact>> getEmergencyContacts() {
    try {
      return _emergencyContactsCollection
          .orderBy('isPrimary', descending: true)
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Ensure required fields exist
              if (data['id'] == null) {
                data['id'] = doc.id; // Use document ID if id field is missing
              }
              if (data['createdAt'] == null) {
                data['createdAt'] = DateTime.now().toIso8601String();
              }
              if (data['updatedAt'] == null) {
                data['updatedAt'] = DateTime.now().toIso8601String();
              }
              return EmergencyContact.fromJson(data);
            }).toList();
          });
    } catch (e) {
      // If the index is not created yet, fall back to a simpler query
      return _emergencyContactsCollection
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              // Ensure required fields exist
              if (data['id'] == null) {
                data['id'] = doc.id; // Use document ID if id field is missing
              }
              if (data['createdAt'] == null) {
                data['createdAt'] = DateTime.now().toIso8601String();
              }
              if (data['updatedAt'] == null) {
                data['updatedAt'] = DateTime.now().toIso8601String();
              }
              return EmergencyContact.fromJson(data);
            }).toList();
          });
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    // Use phoneNumber as document ID for consistency with profile sync
    // Store the original id in the document data, but use phoneNumber as doc ID
    final contactData = contact.toJson();
    contactData['id'] = contact.id; // Preserve original ID in data
    
    // Add to emergency_contacts collection using phoneNumber as document ID
    await _emergencyContactsCollection.doc(contact.phoneNumber).set(contactData);
    
    // Also sync to profile
    await _syncToProfile(contact);
  }

  Future<void> _syncToProfile(EmergencyContact contact) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final profileDoc = await _firestore.collection('profiles').doc(userId).get();
      if (!profileDoc.exists) return;

      final profileData = profileDoc.data();
      if (profileData == null) return;

      final existingContacts = (profileData['emergencyContacts'] as List<dynamic>?) ?? [];
      
      // Check if contact already exists in profile (by phoneNumber)
      final contactIndex = existingContacts.indexWhere(
        (c) => (c as Map<String, dynamic>)['phoneNumber'] == contact.phoneNumber,
      );

      // Convert EmergencyContact to profile format (profile uses simpler format)
      final profileContact = {
        'name': contact.name,
        'phoneNumber': contact.phoneNumber,
        'relationship': contact.relationship,
        'isPrimary': contact.isPrimary,
      };

      if (contactIndex >= 0) {
        // Update existing contact
        existingContacts[contactIndex] = profileContact;
      } else {
        // Add new contact
        existingContacts.add(profileContact);
      }

      // If this is primary, remove primary from others
      if (contact.isPrimary) {
        for (var i = 0; i < existingContacts.length; i++) {
          if (i != contactIndex && (existingContacts[i] as Map)['isPrimary'] == true) {
            existingContacts[i]['isPrimary'] = false;
          }
        }
      }

      // Update profile
      await _firestore.collection('profiles').doc(userId).update({
        'emergencyContacts': existingContacts,
      });
      
      debugPrint('Successfully synced emergency contact to profile: ${contact.name}');
    } catch (e) {
      debugPrint('Error syncing emergency contact to profile: $e');
      // Don't throw - sync failure shouldn't block adding contact
    }
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    // Update in emergency_contacts collection using phoneNumber as document ID
    final contactData = contact.toJson();
    contactData['id'] = contact.id; // Preserve original ID in data
    await _emergencyContactsCollection.doc(contact.phoneNumber).set(contactData, SetOptions(merge: true));
    
    // Also sync to profile
    await _syncToProfile(contact);
  }

  Future<void> deleteEmergencyContact(String id) async {
    // id can be either UUID or phoneNumber
    // Try to get the contact by id first, then try by phoneNumber
    var contactDoc = await _emergencyContactsCollection.doc(id).get();
    
    // If not found, try searching by phoneNumber (in case id is phoneNumber)
    if (!contactDoc.exists) {
      // Search for document with matching phoneNumber
      final snapshot = await _emergencyContactsCollection
          .where('phoneNumber', isEqualTo: id)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        contactDoc = snapshot.docs.first;
      }
    }
    
    if (contactDoc.exists) {
      final contactData = contactDoc.data() as Map<String, dynamic>?;
      final phoneNumber = contactData?['phoneNumber'] as String? ?? id;
      
      // Delete from emergency_contacts collection using phoneNumber as doc ID
      await _emergencyContactsCollection.doc(phoneNumber).delete();
      
      // Also remove from profile using phoneNumber
      await _removeFromProfile(phoneNumber);
    } else {
      // Try to delete by id anyway (could be phoneNumber)
      await _emergencyContactsCollection.doc(id).delete();
      await _removeFromProfile(id);
    }
  }

  Future<void> _removeFromProfile(String phoneNumber) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final profileDoc = await _firestore.collection('profiles').doc(userId).get();
      if (!profileDoc.exists) return;

      final profileData = profileDoc.data();
      final existingContacts = (profileData?['emergencyContacts'] as List<dynamic>?) ?? [];
      
      // Remove contact with matching phone number
      existingContacts.removeWhere(
        (c) => (c as Map<String, dynamic>)['phoneNumber'] == phoneNumber,
      );

      // Update profile
      await _firestore.collection('profiles').doc(userId).update({
        'emergencyContacts': existingContacts,
      });
    } catch (e) {
      debugPrint('Error removing emergency contact from profile: $e');
      // Don't throw - sync failure shouldn't block deletion
    }
  }

  // Emergency Events
  Future<void> logEmergencyEvent({
    required String type,
    required String description,
    required Map<String, dynamic> location,
    required List<String> notifiedContacts,
  }) async {
    await _emergencyEventsCollection.add({
      'type': type,
      'description': description,
      'location': location,
      'notifiedContacts': notifiedContacts,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  // Location Services
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services to use SOS feature.');
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied. Please grant location permission to use SOS feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied. Please enable location permission in app settings to use SOS feature.');
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  // Request permissions
  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.sms,
      Permission.phone,
      Permission.location,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  // Call all emergency contacts
  Future<void> callAllEmergencyContacts(List<EmergencyContact> contacts) async {
    try {
      // Request phone permission
      final phoneStatus = await Permission.phone.request();
      if (!phoneStatus.isGranted) {
        debugPrint('Phone permission not granted');
        return;
      }

      // Call each contact sequentially (with small delay between calls)
      for (int i = 0; i < contacts.length; i++) {
        final contact = contacts[i];
        
        // Format phone number
        String formattedPhone = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        
        // Handle Malaysian phone numbers
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+60${formattedPhone.substring(1)}';
        } else if (formattedPhone.startsWith('60')) {
          formattedPhone = '+$formattedPhone';
        } else if (!formattedPhone.startsWith('+')) {
          formattedPhone = '+60$formattedPhone';
        }

        // Make phone call
        final telUri = Uri.parse('tel:$formattedPhone');
        final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
        
        if (launched) {
          debugPrint('Emergency call launched to: $formattedPhone (${contact.name})');
        } else {
          debugPrint('Failed to launch emergency call to: $formattedPhone');
        }
        
        // Add a small delay between calls (except for the last one)
        if (i < contacts.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      debugPrint('Error making emergency calls: $e');
      // Don't throw - continue with other notifications
    }
  }

  // Call primary emergency contact immediately (deprecated - use callAllEmergencyContacts)
  Future<void> callPrimaryEmergencyContact(EmergencyContact contact) async {
    try {
      // Request phone permission
      final phoneStatus = await Permission.phone.request();
      if (!phoneStatus.isGranted) {
        debugPrint('Phone permission not granted');
        return;
      }

      // Format phone number
      String formattedPhone = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Handle Malaysian phone numbers
      if (formattedPhone.startsWith('0')) {
        formattedPhone = '+60${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('60')) {
        formattedPhone = '+$formattedPhone';
      } else if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+60$formattedPhone';
      }

      // Make immediate phone call
      final telUri = Uri.parse('tel:$formattedPhone');
      final launched = await launchUrl(telUri, mode: LaunchMode.externalApplication);
      
      if (launched) {
        debugPrint('Emergency call launched to: $formattedPhone');
      } else {
        debugPrint('Failed to launch emergency call');
      }
    } catch (e) {
      debugPrint('Error making emergency call: $e');
      // Don't throw - continue with other notifications
    }
  }

  // Emergency Notifications
  Future<void> notifyEmergencyContacts(
    List<EmergencyContact> contacts,
    Map<String, dynamic> location,
  ) async {
    // Request permissions first
    bool permissionsGranted = await _requestPermissions();
    if (!permissionsGranted) {
      throw Exception('Required permissions not granted');
    }

    for (final contact in contacts) {
      final message = '''
EMERGENCY ALERT from ${_auth.currentUser?.displayName ?? 'User'}!

Location: https://maps.google.com/?q=${location['latitude']},${location['longitude']}
Time: ${DateTime.now().toIso8601String()}

This is an automated emergency alert. Please respond immediately.
''';

      // Format phone number for SMS (Malaysian format)
      String formattedPhone = contact.phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Handle Malaysian phone numbers
      if (formattedPhone.startsWith('0')) {
        // Remove leading 0 and add +60
        formattedPhone = '+60${formattedPhone.substring(1)}';
      } else if (formattedPhone.startsWith('60')) {
        // Add + if it starts with 60
        formattedPhone = '+$formattedPhone';
      } else if (!formattedPhone.startsWith('+')) {
        // If it's just the number without country code, assume it's Malaysian
        formattedPhone = '+60$formattedPhone';
      }

      print('Attempting to send SMS to: $formattedPhone'); // Debug log

      // Try different URI schemes for SMS
      bool smsSent = false;
      
      // Try SMS - Note: sms: URI opens the default SMS app with pre-filled message
      // The user must manually tap "Send" in the SMS app (this is Android security)
      // We cannot programmatically send SMS without user interaction on modern Android
      try {
        // Remove + for SMS URI (some devices don't handle it well)
        String smsPhone = formattedPhone.replaceAll('+', '');
        final smsUri = Uri.parse('sms:$smsPhone?body=${Uri.encodeComponent(message)}');
        final launched = await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        if (launched) {
          smsSent = true;
          debugPrint('SMS app opened successfully for: $smsPhone (user must tap Send)');
        } else {
          debugPrint('SMS app launch failed');
        }
      } catch (e) {
        debugPrint('SMS failed: $e');
      }
      
      // Note: Phone call is handled separately in callPrimaryEmergencyContact()
      // which is called BEFORE notifyEmergencyContacts() in the SOS flow

      if (!smsSent) {
        print('Could not launch SMS or call for number: $formattedPhone');
        // Log this failure for debugging
        await logEmergencyEvent(
          type: 'notification_failed',
          description: 'Failed to send SMS/call to $formattedPhone',
          location: location,
          notifiedContacts: [contact.id],
        );
      }

      // Send Email if available
      if (contact.email != null) {
        try {
          final emailUri = Uri.parse('mailto:${contact.email}?subject=${Uri.encodeComponent('EMERGENCY ALERT')}&body=${Uri.encodeComponent(message)}');
          await launchUrl(emailUri, mode: LaunchMode.externalApplication);
          print('Email launched successfully');
        } catch (e) {
          print('Email failed: $e');
          // Log this failure for debugging
          await logEmergencyEvent(
            type: 'email_failed',
            description: 'Failed to send email to ${contact.email}',
            location: location,
            notifiedContacts: [contact.id],
          );
        }
      }
    }
  }
} 