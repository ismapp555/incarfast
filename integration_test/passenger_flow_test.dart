import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:in_car/main.dart' as app;
import 'package:firebase_core/firebase_core.dart';
import 'package:in_car/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Passenger Flow', () {
    testWidgets('A passenger can request a ride', (WidgetTester tester) async {
      // Initialize Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Map Screen
      final commanderButton = find.widgetWithText(ElevatedButton, 'Commander une course');
      expect(commanderButton, findsOneWidget);
      await tester.tap(commanderButton);
      await tester.pumpAndSettle();

      // On the MapScreen, find the request ride button and tap it.
      final requestButton = find.widgetWithText(ElevatedButton, 'Continuer');
      expect(requestButton, findsOneWidget);
      await tester.tap(requestButton);
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for bottom sheet

      // Tap the first vehicle in the list
      final firstVehicle = find.byType(ListTile).first;
      expect(firstVehicle, findsOneWidget);
      await tester.tap(firstVehicle);
      await tester.pumpAndSettle();

      // Wait for the ride request to appear in Firestore
      bool rideFound = false;
      for (int i = 0; i < 10; i++) {
        final rideQuery = await FirebaseFirestore.instance
            .collection('rides')
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();

        if (rideQuery.docs.isNotEmpty) {
          rideFound = true;
          break;
        }
        await Future.delayed(const Duration(seconds: 2));
      }

      expect(rideFound, isTrue, reason: "A pending ride should exist in Firestore");
    });
  });
}
