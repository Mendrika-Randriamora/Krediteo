import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krediteo/main.dart';
import 'package:krediteo/screens/scanner_screen.dart';
import 'package:krediteo/widgets/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Précharge les préférences pour éviter le canal de méthode dans le test.
    SharedPreferences.setMockInitialValues({});

    // Build our app and trigger a frame.
    await tester.pumpWidget(const OcrScannerApp());

    // Verify that the ScannerScreen is present.
    expect(find.byType(ScannerScreen), findsOneWidget);

    // Le splash apparaît dès le départ (durée minimale d'affichage : 1500 ms).
    expect(find.byType(AnimatedSplashScreen), findsOneWidget);

    // Attend la durée minimale d'affichage du splash (1500 ms) - en l'absence
    // de caméra en test, la sortie (700 ms) suit immédiatement.
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(find.byType(AnimatedSplashScreen), findsNothing);
  });
}