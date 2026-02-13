import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/home/home_page.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  setUpAll(() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<FlutterSecureStorage>()) {
      sl.registerLazySingleton<FlutterSecureStorage>(() => MockFlutterSecureStorage());
    }
  });

  testWidgets('HomePage shows SCAN QR button', (WidgetTester tester) async {
    // Set a larger surface size to prevent overflow in tests
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(
      home: HomePage(),
    ));

    // Wait for initial animations
    await tester.pump(const Duration(seconds: 1));

    // Verify Scan Button exists
    expect(find.text('SCAN QR'), findsOneWidget);

    // Clear animations/timers before finishing test
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 1));
  });
}
