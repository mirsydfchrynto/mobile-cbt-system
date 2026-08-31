import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureCBTApp());

    // Basic check for one of the main components
    expect(find.byType(SecureCBTApp), findsOneWidget);

    // Advance past splash screen
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pump(const Duration(milliseconds: 100));

    // Clear animations/widget tree cleanly
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 500));
  });
}