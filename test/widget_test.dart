import 'package:flutter_test/flutter_test.dart';
import 'package:krediteo/main.dart';
import 'package:krediteo/screens/scanner_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const OcrScannerApp());

    // Verify that the ScannerScreen is present.
    expect(find.byType(ScannerScreen), findsOneWidget);
  });
}
