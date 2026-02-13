import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/home/home_page.dart';
import 'package:okey_bimbel/core/theme/app_colors.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:okey_bimbel/core/utils/remote_data_source.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}
class MockRemoteDataSource extends Mock implements RemoteDataSource {}

void main() {
  setUpAll(() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<FlutterSecureStorage>()) {
      sl.registerLazySingleton<FlutterSecureStorage>(() => MockFlutterSecureStorage());
    }
    if (!sl.isRegistered<RemoteDataSource>()) {
      sl.registerLazySingleton<RemoteDataSource>(() => MockRemoteDataSource());
    }
  });

  testWidgets('Enterprise UI Audit - HomePage structure', (WidgetTester tester) async {
    // Advanced: FakeAsync/Timer handling
    await tester.runAsync(() async {
      tester.view.physicalSize = const Size(1080, 2400);
      
      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      
      // Advance time to bypass initial animations
      await tester.pump(const Duration(seconds: 1));

      // Verify core layout components exist
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(GestureDetector), findsAtLeast(2));

      // Verify Theme Contrast
      expect(AppColors.textPrimary, const Color(0xFF1E293B));
      
      // Force clean up
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  });
}