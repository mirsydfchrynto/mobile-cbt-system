import 'package:flutter/foundation.dart';

class IntegrityService {
  /// Cek apakah aplikasi berjalan di lingkungan yang tidak aman
  static bool isUnsafeEnvironment() {
    // 1. Cek Debug Mode (Hanya untuk rilis nanti)
    if (!kReleaseMode) { 
       // return true; // Disabled for dev
    }

    // 2. Cek Emulator (Sederhana)
    // Di produksi, kita harus memblokir emulator
    return false;
  }
}