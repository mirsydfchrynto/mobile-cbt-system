import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';

void main() {
  group('Security & Logic Integrity Tests', () {
    
    test('Normalization should prevent ID hijacking with spaces', () {
      final id1 = StudentUtils.generateSlugId(StudentUtils.normalizeName('Irsyad'));
      final id2 = StudentUtils.generateSlugId(StudentUtils.normalizeName('  irsyad  '));
      final id3 = StudentUtils.generateSlugId(StudentUtils.normalizeName('IRSYAD'));

      expect(id1, id2);
      expect(id2, id3);
      expect(id1, 'irsyad');
    });

    test('Should handle complex names with multiple spaces', () {
      final name = '  Budi    Santoso   ';
      final normalized = StudentUtils.normalizeName(name);
      expect(normalized, 'Budi Santoso');
      expect(StudentUtils.generateSlugId(normalized), 'budi_santoso');
    });

    test('Stress Test: Rapid normalization of 1000 names', () {
      final start = DateTime.now();
      for (int i = 0; i < 1000; i++) {
        StudentUtils.normalizeName('Student Number $i');
      }
      final end = DateTime.now();
      final duration = end.difference(start).inMilliseconds;
      
      expect(duration, lessThan(100), reason: 'Normalization is too slow');
    });
  });
}
