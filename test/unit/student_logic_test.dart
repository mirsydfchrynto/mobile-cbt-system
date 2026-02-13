import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/core/utils/student_utils.dart';

void main() {
  group('Enterprise Logic Audit - StudentUtils', () {
    test('Normalization should be robust against weird casing and spaces', () {
      expect(StudentUtils.normalizeName('  aGuS   pUrNoMo  '), 'Agus Purnomo');
      expect(StudentUtils.normalizeName('budi'), 'Budi');
    });

    test('UID generation should follow STD-timestamp format', () {
      final uid = StudentUtils.generateNewId();
      expect(uid.startsWith('STD-'), isTrue);
      expect(uid.length, greaterThan(10));
    });

    test('Slug generation for legacy support', () {
      expect(StudentUtils.generateSlugId('Agus Purnomo'), 'agus_purnomo');
    });
  });
}
