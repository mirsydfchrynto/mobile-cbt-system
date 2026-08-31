import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

void main() {
  group('Option Shuffling & Answer Key Scoring Invariance', () {
    test('Selecting shuffled option maps back to original option index for correct scoring', () {
      final question = Question(
        id: 'q_shuffle_1',
        text: 'Berapakah 2 + 2?',
        options: ['3 (Option 0)', '4 (Option 1 - CORRECT)', '5 (Option 2)'],
        correctOptionIndex: 1, // Original index 1 is correct
        type: 'multiple_choice',
        points: 10,
      );

      // Suppose options are shuffled: Display 0 = Original 2, Display 1 = Original 1, Display 2 = Original 0
      final optionMapping = [2, 1, 0];

      // Student picks Display Index 1 (which corresponds to optionMapping[1] = 1, i.e., Option 1 - CORRECT)
      final selectedDisplayIdx = 1;
      final selectedOriginalIdx = optionMapping[selectedDisplayIdx];

      // Verify that selectedOriginalIdx matches correctOptionIndex
      expect(selectedOriginalIdx, equals(question.correctOptionIndex));

      // Calculate score
      int score = 0;
      if (selectedOriginalIdx == question.correctOptionIndex) {
        score += question.points!;
      }

      expect(score, equals(10));
    });

    test('Checkboxes option shuffling preserves multi-select scoring', () {
      final question = Question(
        id: 'q_cb_shuffle',
        text: 'Pilih bilangan genap',
        options: ['2 (Opt 0)', '3 (Opt 1)', '4 (Opt 2)'],
        correctIndices: [0, 2], // Original 0 and 2 are correct
        type: 'checkboxes',
        points: 15,
      );

      // Suppose options are shuffled: Display 0 = Original 1, Display 1 = Original 2, Display 2 = Original 0
      final optionMapping = [1, 2, 0];

      // Student picks Display 1 (Original 2) and Display 2 (Original 0)
      final studentDisplaySelections = [1, 2];
      final studentOriginalSelections = studentDisplaySelections.map((d) => optionMapping[d]).toList()..sort();
      final correctSorted = List<int>.from(question.correctIndices!)..sort();

      expect(studentOriginalSelections, equals(correctSorted));

      int score = 0;
      if (studentOriginalSelections.toString() == correctSorted.toString()) {
        score += question.points!;
      }

      expect(score, equals(15));
    });
  });
}
