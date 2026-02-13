import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';

void main() {
  group('StudentUtils - Normalization & ID Logic', () {
    test('Should normalize name correctly (Trim & Capitalize)', () {
      expect(StudentUtils.normalizeName('  irsyad  '), 'Irsyad');
      expect(StudentUtils.normalizeName('irsyad fadhil'), 'Irsyad Fadhil');
      expect(StudentUtils.normalizeName('IRSYAD FADHIL'), 'Irsyad Fadhil');
      expect(StudentUtils.normalizeName('irsyad   fadhil'), 'Irsyad Fadhil');
    });

    test('Should generate consistent ID from name', () {
      final name = StudentUtils.normalizeName('Irsyad Fadhil');
      final id = StudentUtils.generateSlugId(name);
      
      expect(id, 'irsyad_fadhil');
      expect(StudentUtils.generateSlugId('Budi'), 'budi');
    });

    test('Should handle empty inputs safely', () {
      expect(StudentUtils.normalizeName(''), '');
      expect(StudentUtils.normalizeName('   '), '');
    });
  });
}
