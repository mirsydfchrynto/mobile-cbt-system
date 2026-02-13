import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/features/exam/presentation/pages/exam_prep_page.dart';
import 'package:okey_bimbel/features/exam/data/models/exam_model.dart';

void main() {
  testWidgets('ExamPrepPage should render correctly with Exam model', (WidgetTester tester) async {
    final exam = Exam(
      id: 'test_id',
      title: 'Ujian Matematika',
      questions: [
        Question(id: '1', text: '1+1?', options: ['2', '3']),
      ],
      durationMinutes: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const ExamPrepPage(),
            settings: RouteSettings(arguments: {'exam': exam}),
          );
        },
      ),
    );

    // Tunggu render awal
    await tester.pump();

    expect(find.text('Ujian Matematika'), findsOneWidget);
    expect(find.text('30'), findsOneWidget); 
    expect(find.text('1'), findsOneWidget);  
    expect(find.text('MULAI MENGERJAKAN'), findsOneWidget);

    // Selesaikan animasi sebelum menghancurkan widget untuk menghindari "Pending Timers"
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 2));
  });
}
