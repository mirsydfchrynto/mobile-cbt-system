import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Tambahkan Riverpod
import 'package:okey_bimbel/core/theme/app_theme.dart';
import 'package:okey_bimbel/features/home/home_page.dart';
import 'package:okey_bimbel/features/home/splash_screen.dart';
import 'package:okey_bimbel/features/exam/presentation/pages/exam_prep_page.dart';
import 'package:okey_bimbel/features/exam/presentation/pages/exam_room_page.dart';
import 'package:okey_bimbel/features/exam/presentation/pages/exam_finish_page.dart';
import 'package:okey_bimbel/core/utils/app_logger.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:okey_bimbel/firebase_options.dart';
import 'package:okey_bimbel/injection_container.dart' as di;
import 'package:okey_bimbel/core/utils/local_db_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await LocalDBService.init();
    await di.init();
    
    FlutterError.onError = (details) {
      AppLogger.e("Flutter Error", details.exception, details.stack);
    };

    runApp(
      const ProviderScope( // Bungkus dengan ProviderScope
        child: SecureCBTApp()
      )
    );
  }, (error, stack) {
    AppLogger.e("Global Error", error, stack);
  });
}

class SecureCBTApp extends StatelessWidget {
  const SecureCBTApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okey Bimbel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/exam_prep': (context) => const ExamPrepPage(),
        '/exam_room': (context) => const ExamRoomPage(),
        '/finish': (context) => const ExamFinishPage(),
      },
    );
  }
}
