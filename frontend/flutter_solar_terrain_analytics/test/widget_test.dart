// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_solar_terrain_analytics/main.dart';

void main() {
  testWidgets('Solar app renders and shows increment controls', (tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const SolarAnalyticsApp());

    // Basic smoke checks: title and controls exist.
    expect(find.text('Solar Terrain Analytics'), findsOneWidget);
    expect(find.text('Increment'), findsOneWidget); // button label
    expect(find.byIcon(Icons.add), findsWidgets); // icon button + FAB

    // Tap increment button to ensure it’s wired (network may fail but should not crash UI).
    await tester.tap(find.text('Increment'));
    await tester.pump();
  });
}
