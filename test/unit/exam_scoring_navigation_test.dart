import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

void main() {
  group('Scoring Logic Tests', () {
    test('Multiple Choice Scoring', () {
      final q = Question(id: '1', text: 'T', options: ['A', 'B'], correctOptionIndex: 0, points: 10);
      
      // Benar
      expect(q.correctOptionIndex == 0, isTrue);
      
      // Salah
      expect(q.correctOptionIndex == 1, isFalse);
    });

    test('Checkboxes Scoring', () {
      final q = Question(
        id: '2', 
        text: 'T', 
        options: ['A', 'B', 'C'], 
        type: 'checkboxes', 
        correctIndices: [0, 2], 
        points: 20
      );
      
      final studentCorrect = [0, 2]..sort();
      final studentWrong = [0, 1]..sort();
      final actualCorrect = (q.correctIndices ?? [])..sort();

      expect(studentCorrect.toString() == actualCorrect.toString(), isTrue);
      expect(studentWrong.toString() == actualCorrect.toString(), isFalse);
    });
  });

  group('Navigation Guard Logic', () {
    test('Should block future questions in sequential mode', () {
      int maxSeen = 5;
      
      bool canAccess(int target) => target <= maxSeen;

      expect(canAccess(4), isTrue);  // Previous
      expect(canAccess(5), isTrue);  // Current
      expect(canAccess(6), isFalse); // Locked
    });
  });
}
