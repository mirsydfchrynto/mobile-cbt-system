import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/core/utils/local_db_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hive LocalDB Isolation & Account Switching Tests', () {
    setUp(() async {
      Hive.init('./test_hive_db');
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    test('Student A answers are saved locally', () async {
      await LocalDBService.saveStudentMetadata('Student A', 'TI-4A', 'uid_student_a');
      await LocalDBService.saveAnswers('exam_101', {0: 'A', 1: 'B'});
      
      final answers = LocalDBService.getAnswers('exam_101');
      expect(answers[0], equals('A'));
      expect(answers[1], equals('B'));
    });

    test('Account switch from Student A to Student B clears cached answers', () async {
      // 1. Student A logs in and saves answers
      await LocalDBService.saveStudentMetadata('Student A', 'TI-4A', 'uid_student_a');
      await LocalDBService.saveAnswers('exam_101', {0: 'A', 1: 'B'});
      
      // 2. Student B logs in on same device
      await LocalDBService.saveStudentMetadata('Student B', 'TI-4B', 'uid_student_b');
      
      // 3. Verify Student A answers are wiped for Student B!
      final answersForB = LocalDBService.getAnswers('exam_101');
      expect(answersForB.isEmpty, isTrue);
    });
  });
}
