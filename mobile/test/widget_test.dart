import 'package:flutter_test/flutter_test.dart';
import 'package:besnap_mobile/main.dart';

void main() {
  testWidgets('BeSnapApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BeSnapApp());
    expect(find.byType(BeSnapApp), findsOneWidget);
  });
}
