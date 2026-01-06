import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility to verify admin setup and help debug issues
class VerifyAdminSetup {
  static Future<Map<String, dynamic>> verifyCurrentUser() async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    final user = auth.currentUser;
    if (user == null) {
      return {
        'error': 'No user logged in',
        'details': 'Please login first',
      };
    }
    
    final results = <String, dynamic>{
      'authUser': {
        'uid': user.uid,
        'email': user.email,
      },
      'firestoreDoc': null,
      'issues': <String>[],
      'fixes': <String>[],
    };
    
    // Check if Firestore document exists
    try {
      final doc = await firestore.collection('admins').doc(user.uid).get();
      
      if (!doc.exists) {
        results['issues'].add('Firestore document does not exist');
        results['fixes'].add('Create a document in "admins" collection with document ID: ${user.uid}');
        return results;
      }
      
      final data = doc.data()!;
      results['firestoreDoc'] = data;
      
      // Check for required fields
      if (data['email'] == null) {
        results['issues'].add('Missing "email" field');
        results['fixes'].add('Add "email" field with value: ${user.email}');
      }
      
      if (data['displayName'] == null) {
        results['issues'].add('Missing "displayName" field');
        results['fixes'].add('Add "displayName" field');
      }
      
      if (data['role'] == null) {
        results['issues'].add('Missing "role" field');
        results['fixes'].add('Add "role" field with value: "admin" or "caretaker"');
      } else if (data['role'] != 'admin' && data['role'] != 'caretaker') {
        results['issues'].add('Invalid "role" value: ${data['role']}');
        results['fixes'].add('Set "role" to either "admin" or "caretaker"');
      }
      
      if (data['createdAt'] == null) {
        results['issues'].add('Missing "createdAt" field (this causes the null timestamp error)');
        results['fixes'].add('Add "createdAt" field as Server Timestamp');
      }
      
      if (data['lastLogin'] == null) {
        results['issues'].add('Missing "lastLogin" field (this causes the null timestamp error)');
        results['fixes'].add('Add "lastLogin" field as Server Timestamp');
      }
      
      if (data['assignedUsers'] == null) {
        results['issues'].add('Missing "assignedUsers" field');
        results['fixes'].add('Add "assignedUsers" field as an empty array []');
      }
      
      if (data['isActive'] == null) {
        results['issues'].add('Missing "isActive" field');
        results['fixes'].add('Add "isActive" field with value: true');
      }
      
      // Check if document ID matches UID
      if (doc.id != user.uid) {
        results['issues'].add('Document ID does not match Firebase Auth UID');
        results['fixes'].add('Document ID must be exactly: ${user.uid}');
      }
      
      if (results['issues'].isEmpty) {
        results['status'] = 'success';
        results['message'] = 'Admin setup is correct!';
      } else {
        results['status'] = 'error';
        results['message'] = 'Found ${results['issues'].length} issue(s)';
      }
      
    } catch (e) {
      results['error'] = e.toString();
      results['issues'].add('Error reading Firestore: $e');
    }
    
    return results;
  }
  
  static void printVerificationResults(Map<String, dynamic> results) {
    print('\n=== Admin Setup Verification ===\n');
    
    if (results['authUser'] != null) {
      final auth = results['authUser'] as Map<String, dynamic>;
      print('Firebase Auth User:');
      print('  UID: ${auth['uid']}');
      print('  Email: ${auth['email']}\n');
    }
    
    if (results['firestoreDoc'] != null) {
      print('Firestore Document Found:');
      final doc = results['firestoreDoc'] as Map<String, dynamic>;
      doc.forEach((key, value) {
        print('  $key: $value');
      });
      print('');
    }
    
    if (results['issues'] != null && (results['issues'] as List).isNotEmpty) {
      print('⚠️  Issues Found:');
      (results['issues'] as List).forEach((issue) {
        print('  - $issue');
      });
      print('');
      
      if (results['fixes'] != null) {
        print('🔧 How to Fix:');
        (results['fixes'] as List).forEach((fix) {
          print('  - $fix');
        });
        print('');
      }
    }
    
    if (results['status'] == 'success') {
      print('✅ ${results['message']}\n');
    } else if (results['status'] == 'error') {
      print('❌ ${results['message']}\n');
    }
  }
}


