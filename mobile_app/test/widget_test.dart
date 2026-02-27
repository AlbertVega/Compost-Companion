import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_piles_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyPilesApp());

    // Verify that our app title is present.
    expect(find.text('My Piles'), findsWidgets);
  });
}
