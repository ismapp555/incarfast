// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_car/main.dart';

void main() {
  testWidgets('Smoke test: App should build and show titles and buttons', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // As the main() function initializes Firebase, we cannot call it directly.
    // We will just build the MyApp widget, which is the root of the UI.
    await tester.pumpWidget(const MyApp());

    // Verify that the AppBar title is correct.
    expect(find.text('inCar Backend Test'), findsOneWidget);

    // Verify that the main instruction text is present.
    expect(
      find.text('Press a button to write test data to a backend.'),
      findsOneWidget,
    );

    // Verify that both buttons are present.
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.text('Test & Seed Passager'), findsOneWidget);
    expect(find.text('Test & Seed Chauffeur'), findsOneWidget);
  });
}
