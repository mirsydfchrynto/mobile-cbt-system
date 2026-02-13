import 'package:flutter_test/flutter_test.dart';
import 'package:okey_bimbel/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SecureCBTApp());

    // Basic check for one of the main components
    expect(find.byType(SecureCBTApp), findsOneWidget);
  });
}