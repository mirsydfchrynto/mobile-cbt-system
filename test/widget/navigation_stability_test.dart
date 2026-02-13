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

  testWidgets('Scanner transition test - prevent black screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: HomePage(),
    ));

    // 1. Verifikasi Tombol Mulai Ujian Ada
    expect(find.text('MULAI UJIAN'), findsOneWidget);

    // 2. Klik Tombol Scan
    await tester.tap(find.text('MULAI UJIAN'));
    await tester.pumpAndSettle();

    // 3. Verifikasi Scanner Terbuka (ScannerPage)
    expect(find.text('ARAHKAN KE QR'), findsOneWidget);

    // 4. Simulasi Kembali dari Scanner (Navigator Pop)
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // 5. Verifikasi Kembali ke Beranda (Bukan Layar Hitam)
    expect(find.text('MULAI UJIAN'), findsOneWidget);
  });
}
