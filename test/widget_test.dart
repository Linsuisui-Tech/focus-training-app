import 'package:flutter_test/flutter_test.dart';

import 'package:focus_training_app/app.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FocusTrainingApp());

    expect(find.text('Focus Spark'), findsOneWidget);
    expect(find.text('点亮你的专注力'), findsOneWidget);
  });
}
