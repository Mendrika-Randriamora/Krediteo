import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:vibration/vibration.dart';

import '../models/scan_state.dart';
import '../services/camera_service.dart';
import '../services/call_service.dart';
import '../services/ocr_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/number_result_card.dart';
import '../widgets/scan_overlay.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with WidgetsBindingObserver {
  final _cameraService = CameraService();
  final _ocrService = OcrService();
  final _callService = CallService();

  ScanState _state = const ScanState.idle();
  bool _isInitializing = true;
  String? _initError;

  // Anti-spam : temps de gel après détection (ms)
  static const int _detectionCooldownMs = 2500;
  DateTime _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _cameraService.stopImageStream();
        break;
      case AppLifecycleState.resumed:
        _startStream();
        break;
      default:
        break;
    }
  }

  Future<void> _initCamera() async {
    try {
      await _cameraService.initialize();
      if (!mounted) return;
      setState(() => _isInitializing = false);
      await _startStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  Future<void> _startStream() async {
    await _cameraService.startImageStream((image, rotation) async {
      // Ignorer les frames si on est en cooldown post-détection
      final now = DateTime.now();
      if (now.difference(_lastDetectionTime).inMilliseconds < _detectionCooldownMs) {
        return;
      }

      // Indiquer que l'OCR tourne (sans flood du setState)
      if (_state.status == ScanStatus.idle && mounted) {
        setState(() => _state = const ScanState.scanning());
      }

      final number = await _ocrService.processFrame(image, rotation);

      if (!mounted) return;

      if (number != null) {
        _lastDetectionTime = DateTime.now();
        _vibrate();
        // Force l'exécution sur le main thread
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _state = ScanState.detected(number));
          }
        });
      } else if (_state.status == ScanStatus.scanning) {
        // Revenir à idle seulement si pas de numéro détecté récemment
        if (now.difference(_lastDetectionTime).inMilliseconds > 800) {
          setState(() => _state = const ScanState.idle());
        }
      }
    });
  }

  Future<void> _vibrate() async {
    HapticFeedback.mediumImpact();
  }

  Future<void> _handleCall() async {
    final number = _state.detectedNumber;
    if (number == null) return;
    HapticFeedback.heavyImpact();
    final success = await _callService.call(number);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de lancer l\'appel. Vérifiez les permissions.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _dismissResult() {
    setState(() {
      _state = const ScanState.idle();
      _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const _LoadingView();
    }

    if (_initError != null) {
      return _ErrorView(
        message: _initError!,
        onRetry: () {
          setState(() {
            _isInitializing = true;
            _initError = null;
          });
          _initCamera();
        },
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Flux caméra
        CameraPreviewWidget(controller: _cameraService.controller!),

        // 2. Overlay de scan (fond semi-transparent + cadre + animation)
        ScanOverlay(status: _state.status),

        // 3. Carte de résultat (slide depuis le bas quand détecté)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _state.status == ScanStatus.detected && _state.hasNumber
                ? NumberResultCard(
              key: ValueKey(_state.detectedNumber),
              number: _state.detectedNumber!,
              onCall: _handleCall,
              onDismiss: _dismissResult,
            )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// Vue de chargement
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF38BDF8),
            strokeWidth: 2,
          ),
          SizedBox(height: 20),
          Text(
            'Initialisation de la caméra…',
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Vue d'erreur
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined,
                color: Colors.white38, size: 56),
            const SizedBox(height: 20),
            const Text(
              'Impossible d\'accéder à la caméra',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF38BDF8)),
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}