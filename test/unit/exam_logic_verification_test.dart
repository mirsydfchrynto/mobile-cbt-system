import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

void main() {
  group('Exam Shuffling & Navigation Logic Tests', () {
    test('Should maintain consistent question order with mapping', () {
      final questions = [
        Question(id: '1', text: 'Q1', options: ['A', 'B']),
        Question(id: '2', text: 'Q2', options: ['C', 'D']),
        Question(id: '3', text: 'Q3', options: ['E', 'F']),
      ];

      // Simulasi urutan yang sudah diacak (misal: 2, 0, 1)
      final mapping = [2, 0, 1];
      
      final shuffled = mapping.map((i) => questions[i]).toList();
      
      expect(shuffled[0].id, '3');
      expect(shuffled[1].id, '1');
      expect(shuffled[2].id, '2');
      
      // Pastikan jika dipanggil lagi dengan mapping yang sama, urutan tetap sama
      final reshuffled = mapping.map((i) => questions[i]).toList();
      expect(reshuffled[0].id, '3');
    });

    test('Sequential navigation locking simulation', () {
      int maxSeenIndex = 2; // Siswa sudah sampai soal indeks 2 (soal ke-3)
      
      bool canAccess(int targetIndex) {
        return targetIndex <= maxSeenIndex;
      }

      expect(canAccess(0), isTrue); // Soal 1 boleh
      expect(canAccess(1), isTrue); // Soal 2 boleh
      expect(canAccess(2), isTrue); // Soal 3 boleh
      expect(canAccess(3), isFalse); // Soal 4 TERKUNCI
    });
  });
}
