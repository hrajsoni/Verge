import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:verge_mobile/main.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('VergeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VergeApp());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(VergeApp), findsOneWidget);
  });
}
