import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';

void main() {
  group('Security Stress Audit', () {
    test('Rapid ID Generation Stability', () {
      final ids = <String>{};
      for (int i = 0; i < 1000; i++) {
        ids.add(StudentUtils.generateNewId());
      }
      expect(ids.length, 1000, reason: "ID collisions detected in rapid generation!");
    });

    test('Normalization Bypass Attempt', () {
      // Menggunakan raw string untuk karakter spesial
      const dangerousName = r"Agus\n\t<script>alert('hack')</script>";
      final clean = StudentUtils.normalizeName(dangerousName);
      
      expect(clean.contains('\n'), isFalse);
      expect(clean.contains('\t'), isFalse);
      // Memastikan spasi berlebih dari tag script dirapikan
      expect(clean, isNot(contains('  ')));
    });
  });
}