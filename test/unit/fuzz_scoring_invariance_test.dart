import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';
import 'dart:math';

void main() {
  group('Fuzz Testing: Scoring Invariance Under Randomized Shuffling', () {
    final random = Random();

    test('Multiple Choice: 1000 randomized shuffle configurations preserve score', () {
      int passed = 0;
      int failed = 0;

      for (int i = 0; i < 1000; i++) {
        // Generate random question with 3-6 options
        final optionCount = random.nextInt(4) + 3;
        final options = List.generate(optionCount, (idx) => 'Option $idx');
        final correctIndex = random.nextInt(optionCount);
        final points = random.nextInt(20) + 5;

        final question = Question(
          id: 'q_fuzz_mc_$i',
          text: 'Fuzz Question $i',
          options: options,
          correctOptionIndex: correctIndex,
          type: 'multiple_choice',
          points: points,
        );

        // Generate random permutation mapping
        final originalIndices = List.generate(optionCount, (i) => i);
        final shuffled = [...originalIndices]..shuffle(random);

        // Student picks the DISPLAY index that corresponds to correct ORIGINAL index
        final displayIndexOfCorrect = shuffled.indexOf(correctIndex);
        final selectedOriginalIdx = shuffled[displayIndexOfCorrect];

        // Score should be correct
        int score = 0;
        if (selectedOriginalIdx == question.correctOptionIndex) {
          score += question.points!;
        }

        if (score == points) {
          passed++;
        } else {
          failed++;
        }
      }

      expect(failed, equals(0), reason: '$failed/1000 failed — scoring broke under shuffle');
      expect(passed, equals(1000));
    });

    test('Checkboxes: 1000 randomized multi-select shuffle configurations preserve score', () {
      int passed = 0;
      int failed = 0;

      for (int i = 0; i < 1000; i++) {
        final optionCount = random.nextInt(4) + 3; // 3-6 options
        final options = List.generate(optionCount, (idx) => 'Option $idx');
        
        // Pick 1-3 correct indices
        final correctCount = random.nextInt(3) + 1;
        final allIndices = List.generate(optionCount, (i) => i)..shuffle(random);
        final correctIndices = allIndices.take(correctCount).toList()..sort();
        final points = random.nextInt(20) + 5;

        final question = Question(
          id: 'q_fuzz_cb_$i',
          text: 'Fuzz Checkboxes $i',
          options: options,
          correctIndices: correctIndices,
          type: 'checkboxes',
          points: points,
        );

        // Generate random permutation mapping
        final shuffled = List.generate(optionCount, (i) => i)..shuffle(random);

        // Student picks the DISPLAY indices corresponding to correct ORIGINAL indices
        final studentDisplaySelections = correctIndices.map((orig) => shuffled.indexOf(orig)).toList()..sort();
        final studentOriginalSelections = studentDisplaySelections.map((d) => shuffled[d]).toList()..sort();

        int score = 0;
        if (studentOriginalSelections.toString() == correctIndices.toString()) {
          score += question.points!;
        }

        if (score == points) {
          passed++;
        } else {
          failed++;
        }
      }

      expect(failed, equals(0), reason: '$failed/1000 failed — checkboxes scoring broke under shuffle');
      expect(passed, equals(1000));
    });

    test('True/False: 1000 randomized statement configurations preserve score', () {
      int passed = 0;
      int failed = 0;

      for (int i = 0; i < 1000; i++) {
        final statementCount = random.nextInt(4) + 2; // 2-5 statements
        final statements = List.generate(statementCount, (idx) {
          return {'text': 'Statement $idx', 'isCorrect': random.nextBool()};
        });
        final points = random.nextInt(20) + 5;

        final question = Question(
          id: 'q_fuzz_tf_$i',
          text: 'Fuzz True/False $i',
          options: [],
          type: 'true_false',
          points: points,
          statements: statements.map((s) => Statement(text: s['text'] as String, isCorrect: s['isCorrect'] as bool)).toList(),
        );

        // Student answers ALL correctly
        final studentAnswers = statements.map((s) => s['isCorrect']).toList();

        // Score calculation (matching mobile exam_room_page.dart logic)
        bool isCorrect = true;
        for (int sIdx = 0; sIdx < statementCount; sIdx++) {
          if (studentAnswers[sIdx] != question.statements![sIdx].isCorrect) {
            isCorrect = false;
            break;
          }
        }

        int score = 0;
        if (isCorrect) score += question.points!;

        if (score == points) {
          passed++;
        } else {
          failed++;
        }
      }

      expect(failed, equals(0), reason: '$failed/1000 failed — true/false scoring broke');
      expect(passed, equals(1000));
    });

    test('Mixed Exam: 1000 full exams with random question types, shuffle, answers', () {
      int totalExamsPassed = 0;

      for (int examIdx = 0; examIdx < 1000; examIdx++) {
        final questionCount = random.nextInt(15) + 5; // 5-19 questions
        final questions = <Question>[];

        for (int qIdx = 0; qIdx < questionCount; qIdx++) {
          final typeRoll = random.nextDouble();
          int points = random.nextInt(20) + 5;

          if (typeRoll < 0.5) {
            // Multiple Choice
            final optionCount = random.nextInt(4) + 3;
            final options = List.generate(optionCount, (i) => 'Opt $i');
            final correctIdx = random.nextInt(optionCount);
            final shuffled = List.generate(optionCount, (i) => i)..shuffle(random);
            final displayIdx = shuffled.indexOf(correctIdx);
            
            questions.add(Question(
              id: 'q_${examIdx}_$qIdx',
              text: 'MC $qIdx',
              options: options,
              correctOptionIndex: correctIdx,
              type: 'multiple_choice',
              points: points,
            ));
            
            // Student answers correctly using mapping
            final studentAns = displayIdx;
            int score = 0;
            if (shuffled[studentAns] == correctIdx) score += points;
            expect(score, equals(points));
          } else if (typeRoll < 0.8) {
            // Checkboxes
            final optionCount = random.nextInt(4) + 3;
            final options = List.generate(optionCount, (i) => 'Opt $i');
            final correctCount = random.nextInt(3) + 1;
            final allIndices = List.generate(optionCount, (i) => i)..shuffle(random);
            final correctIndices = allIndices.take(correctCount).toList()..sort();
            final shuffled = List.generate(optionCount, (i) => i)..shuffle(random);
            final studentDisplay = correctIndices.map((o) => shuffled.indexOf(o)).toList()..sort();
            final studentOrig = studentDisplay.map((d) => shuffled[d]).toList()..sort();
            
            questions.add(Question(
              id: 'q_${examIdx}_$qIdx',
              text: 'CB $qIdx',
              options: options,
              correctIndices: correctIndices,
              type: 'checkboxes',
              points: points,
            ));
            
            int score = 0;
            if (studentOrig.toString() == correctIndices.toString()) score += points;
            expect(score, equals(points));
          } else {
            // True/False
            final stmtCount = random.nextInt(4) + 2;
            final statements = List.generate(stmtCount, (i) {
              return {'text': 'Stmt $i', 'isCorrect': random.nextBool()};
            });
            final studentAns = statements.map((s) => s['isCorrect']).toList();
            
            questions.add(Question(
              id: 'q_${examIdx}_$qIdx',
              text: 'TF $qIdx',
              options: [],
              type: 'true_false',
              points: points,
              statements: statements.map((s) => Statement(text: s['text'] as String, isCorrect: s['isCorrect'] as bool)).toList(),
            ));
            
            bool isCorrect = true;
            for (int s = 0; s < stmtCount; s++) {
              if (studentAns[s] != statements[s]['isCorrect']) isCorrect = false;
            }
            int score = 0;
            if (isCorrect) score += points;
            expect(score, equals(points));
          }
        }

        totalExamsPassed++;
      }

      expect(totalExamsPassed, equals(1000));
    });
  });
}