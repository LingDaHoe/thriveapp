import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
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
          .map((snapshot) => snapshot.docs
              .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    } catch (e) {
      // If the index is not created yet, fall back to a simpler query
      return _emergencyContactsCollection
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => EmergencyContact.fromJson(doc.data() as Map<String, dynamic>))
              .toList());
    }
  }

  Future<void> addEmergencyContact(EmergencyContact contact) async {
    await _emergencyContactsCollection.doc(contact.id).set(contact.toJson());
  }

  Future<void> updateEmergencyContact(EmergencyContact contact) async {
    await _emergencyContactsCollection.doc(contact.id).update(contact.toJson());
  }

  Future<void> deleteEmergencyContact(String id) async {
    await _emergencyContactsCollection.doc(id).delete();
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
        'timestamp': position.timestamp?.toIso8601String(),
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
      
      // Try different SMS URI formats
      final smsUris = [
        Uri.parse('sms:$formattedPhone?body=${Uri.encodeComponent(message)}'),
        Uri.parse('smsto:$formattedPhone?body=${Uri.encodeComponent(message)}'),
        Uri.parse('sms:$formattedPhone'),
      ];

      for (final uri in smsUris) {
        try {
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            smsSent = true;
            break;
          }
        } catch (e) {
          print('Failed to launch SMS URI: $uri - $e');
        }
      }

      if (!smsSent) {
        print('SMS schemes failed, trying tel scheme...');
        
        // Try different phone URI formats
        final telUris = [
          Uri.parse('tel:$formattedPhone'),
          Uri.parse('tel://$formattedPhone'),
        ];

        for (final uri in telUris) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              smsSent = true;
              break;
            }
          } catch (e) {
            print('Failed to launch tel URI: $uri - $e');
          }
        }
      }

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
        final emailUris = [
          Uri.parse('mailto:${contact.email}?subject=EMERGENCY ALERT&body=${Uri.encodeComponent(message)}'),
          Uri.parse('mailto:${contact.email}'),
        ];

        bool emailSent = false;
        for (final uri in emailUris) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              emailSent = true;
              break;
            }
          } catch (e) {
            print('Failed to launch email URI: $uri - $e');
          }
        }

        if (!emailSent) {
          print('Could not launch email for: ${contact.email}');
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