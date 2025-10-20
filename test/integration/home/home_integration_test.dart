import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:thriveapp/main.dart' as app;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Home Feature Integration Tests', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      // Sign in with a test account
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'testpassword',
      );
    });

    testWidgets('complete home screen flow', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Verify initial loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pumpAndSettle();

      // Verify welcome section is displayed
      expect(find.text('Welcome,'), findsOneWidget);

      // Verify activity summary is displayed
      expect(find.text('Daily Activity'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.bedtime), findsOneWidget);

      // Verify quick access section
      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Activities'), findsOneWidget);
      expect(find.text('Social'), findsOneWidget);
      expect(find.text('Health'), findsOneWidget);
      expect(find.text('Emergency'), findsOneWidget);

      // Verify recommendations section
      expect(find.text('Recommended for You'), findsOneWidget);

      // Test quick access navigation
      await tester.tap(find.text('Activities'));
      await tester.pumpAndSettle();
      // TODO: Add navigation verification once Activities screen is implemented

      // Test recommendation interaction
      final firstRecommendation = find.byType(ListTile).first;
      await tester.tap(firstRecommendation);
      await tester.pumpAndSettle();
      // TODO: Add recommendation interaction verification
    });

    testWidgets('error handling and retry', (WidgetTester tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Simulate network error by signing out
      await FirebaseAuth.instance.signOut();
      await tester.pumpAndSettle();

      // Verify error state
      expect(find.text('No authenticated user'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Sign back in and retry
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'test@example.com',
        password: 'testpassword',
      );
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Verify data is loaded again
      expect(find.text('Welcome,'), findsOneWidget);
    });
  });
} 