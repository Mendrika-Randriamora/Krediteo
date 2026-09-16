import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/scanner_screen.dart';
import 'widgets/splash_screen.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation de Hive
  await Hive.initFlutter();

  // Forcer l'orientation portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OcrScannerApp());
}

class OcrScannerApp extends StatelessWidget {
  const OcrScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Krediteo',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const AppHome(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.black,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Gère l'affichage du splash et l'initialisation de la caméra en parallèle.
class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  bool _splashDone = false;
  List<CameraDescription>? _cameras;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    // Initialise la caméra en parallèle (ne bloque pas le splash).
    _initializeCamera();
  }

  /// Initialise la caméra : récupère les caméras disponibles et les stocke
  /// pour être utilisées par [ScannerScreen]. Le splash ne l'attend que
  /// par ce future, donc l'initialisation complète du [CameraController]
  /// se fait dans [ScannerScreen].
  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _cameraError =
          'Aucune caméra disponible sur cet appareil.';
        });
        return;
      }
      setState(() {
        _cameras = cameras;
      });
    } catch (e) {
      setState(() {
        _cameraError = 'Erreur lors de l\'initialisation de la caméra: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ScannerScreen en arrière-plan, montée immédiatement
        // (visible quand le splash disparaît).
        if (_cameraError != null)
          _buildErrorScreen()
        else
          ScannerScreen(),

        // Splash animé qui se révèle en disparaissant.
        if (!_splashDone)
          AnimatedSplashScreen(
            // Le splash attend que les caméras soient prêtes OU qu'une
            // erreur se soit produite.
            cameraReadyFuture: Future.wait([
              if (_cameras == null) _waitForCameras() else Future.value(),
            ]),
            onSplashFinished: () {
              setState(() => _splashDone = true);
            },
          ),
      ],
    );
  }

  /// Attend que les caméras soient initialisées (ou en erreur).
  Future<void> _waitForCameras() async {
    while (_cameras == null && _cameraError == null) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Écran d'erreur en cas d'absence de caméra.
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _cameraError ?? 'Erreur inconnue',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
