import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class SecurityService {
  static const MethodChannel _channel = MethodChannel('com.okeybimbel/security');

  /// Mengunci aplikasi agar tidak bisa keluar dan blokir screenshot
  static Future<void> startKioskMode() async {
    try {
      await _channel.invokeMethod('startLockTask');
      await _channel.invokeMethod('enableSecureFlag'); // Anti-Screenshot
      await WakelockPlus.enable(); 
    } on PlatformException catch (e) {
      log("Failed to start Hardened Security: ${e.message}");
    }
  }

  /// Membuka kunci aplikasi dan lepas blokir screenshot
  static Future<void> stopKioskMode() async {
    try {
      await _channel.invokeMethod('stopLockTask');
      await _channel.invokeMethod('disableSecureFlag');
      await WakelockPlus.disable();
    } on PlatformException catch (e) {
      log("Failed to stop Hardened Security: ${e.message}");
    }
  }
}
