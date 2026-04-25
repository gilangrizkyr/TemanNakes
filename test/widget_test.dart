// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:temannakes/main.dart';

void main() {
  testWidgets('App starts and shows splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TemanNakesApp()));

    // Verify that the medication icon is present on the splash screen.
    expect(find.byIcon(Icons.medication_liquid), findsOneWidget);
    
    // Advance time to clear the 2-second splash timer
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    
    // After splash, should show Disclaimer
    expect(find.text('PENTING'), findsOneWidget);

    // Tap button to continue
    await tester.tap(find.text('SAYA MENGERTI & LANJUTKAN'));
    await tester.pumpAndSettle();

    // Verify app name is 'TemanNakes' on HomeSearchView
    expect(find.text('TemanNakes'), findsWidgets);
  });
}
