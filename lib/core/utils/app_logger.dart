import 'package:talker_flutter/talker_flutter.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  static final talker = TalkerFlutter.init(
    settings: TalkerSettings(
      enabled: true,
      useConsoleLogs: kDebugMode,
      maxHistoryItems: 1000,
    ),
  );

  static void d(String message) => talker.debug(message);
  static void i(String message) => talker.info(message);
  static void w(String message) => talker.warning(message);
  static void e(String message, [dynamic error, StackTrace? stackTrace]) => 
      talker.handle(error ?? message, stackTrace, message);

  static void security(String message) => talker.critical("SECURITY ALERT: $message");
  
  static void logAction(String action) => talker.log("USER ACTION: $action");
}