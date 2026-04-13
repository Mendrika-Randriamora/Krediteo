import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
// import 'package:vibration/vibration.dart';

import '../models/scan_state.dart';
import '../models/operator.dart';
import '../services/camera_service.dart';
import '../services/call_service.dart';
import '../services/ocr_service.dart';
import '../services/persistence_service.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/number_result_card.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/operator_selector.dart';

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
  final _persistenceService = PersistenceService();

  ScanState _state = const ScanState.idle();
  Operator _selectedOperator = Operator.yas;
  bool _isInitializing = true;
  String? _initError;
  Key _cardKey = UniqueKey();
  bool _isFlashOn = false;

  // Anti-spam : temps de gel après détection d'un nouveau numéro (ms)
  static const int _detectionCooldownMs = 2500;
  DateTime _lastDetectionTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadSettings();
    _initCamera();
  }

  Future<void> _loadSettings() async {
    final operator = await _persistenceService.getOperator();
    if (mounted) {
      setState(() => _selectedOperator = operator);
    }
  }

  Future<void> _handleOperatorChanged(Operator operator) async {
    HapticFeedback.lightImpact();
    setState(() => _selectedOperator = operator);
    await _persistenceService.saveOperator(operator);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _cameraService.stopImageStream();
        if (_isFlashOn) _toggleFlash(false);
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

  Future<void> _toggleFlash(bool on) async {
    if (!_cameraService.isInitialized || _isFlashOn == on) return;
    
    if (on) {
      HapticFeedback.mediumImpact();
    }
    
    setState(() => _isFlashOn = on);
    await _cameraService.setFlashMode(on ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _startStream() async {
    await _cameraService.startImageStream((image, rotation) async {
      final now = DateTime.now();
      final msSinceLast = now.difference(_lastDetectionTime).inMilliseconds;

      // Throttle l'analyse OCR pour économiser la batterie et le CPU
      if (msSinceLast < 400) return;

      final number = await _ocrService.processFrame(image, rotation);
      if (!mounted) return;

      if (number != null) {
        final isNewNumber = number != _state.detectedNumber;
        
        // Si c'est un nouveau numéro, on impose un cooldown minimum pour laisser l'utilisateur lire
        if (isNewNumber && msSinceLast < _detectionCooldownMs) {
          return;
        }

        if (isNewNumber) {
          _lastDetectionTime = now;
          _vibrate();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _cardKey = UniqueKey();
                _state = ScanState.detected(number);
              });
            }
          });
        } else {
          // Même numéro : on rafraîchit le timestamp pour maintenir l'affichage
          _lastDetectionTime = now;
        }
      } else {
        // Aucun numéro détecté dans cette frame
        if (_state.status == ScanStatus.detected) {
          // On garde l'affichage pendant 3s après la disparition du numéro
          if (msSinceLast > 3000) {
            setState(() => _state = const ScanState.scanning());
          }
        } else if (_state.status == ScanStatus.scanning) {
          if (msSinceLast > 1000) {
            setState(() => _state = const ScanState.idle());
          }
        } else if (_state.status == ScanStatus.idle && msSinceLast > 500) {
          // Repasser en scanning pour montrer que l'app cherche toujours
          setState(() => _state = const ScanState.scanning());
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
    final success = await _callService.call(number, _selectedOperator);

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
      _cardKey = UniqueKey();
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

    return GestureDetector(
      onLongPressStart: (_) => _toggleFlash(true),
      onLongPressEnd: (_) => _toggleFlash(false),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Flux caméra
          CameraPreviewWidget(controller: _cameraService.controller!),

          // 2. Overlay de scan (fond semi-transparent + cadre + animation)
          ScanOverlay(status: _state.status),

          // 3. Sélecteur d'opérateur (Pill en haut)
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Center(
              child: OperatorSelector(
                selectedOperator: _selectedOperator,
                onOperatorChanged: _handleOperatorChanged,
                isFlashOn: _isFlashOn,
              ),
            ),
          ),

          // 4. Carte de résultat (slide depuis le bas quand détecté)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _state.status == ScanStatus.detected && _state.hasNumber
                  ? NumberResultCard(
                key: _cardKey,
                number: _state.detectedNumber!,
                onCall: _handleCall,
                onDismiss: _dismissResult,
              )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
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