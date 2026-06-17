import 'package:flutter_test/flutter_test.dart';
import 'package:academia360_app/main.dart';

void main() {
  testWidgets('Academia360 app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const Academia360App());

    expect(find.text('Academia360'), findsWidgets);
  });
}
