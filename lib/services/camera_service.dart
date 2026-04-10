import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Initialise la caméra arrière en résolution moyenne (bon compromis perf/qualité)
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) throw Exception('Aucune caméra disponible');

    final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium, // medium = meilleur équilibre OCR / fluidité
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21, // NV21 requis pour ML Kit Android
    );

    await _controller!.initialize();
  }

  /// Démarre le flux d'images et appelle [onFrame] à chaque frame
  Future<void> startImageStream(Function(CameraImage, InputImageRotation) onFrame) async {
    if (_controller == null || !isInitialized) return;

    final camera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    await _controller!.startImageStream((image) {
      final rotation = _getRotation(camera.sensorOrientation);
      onFrame(image, rotation);
    });
  }

  /// Arrête le flux d'images
  Future<void> stopImageStream() async {
    if (_controller?.value.isStreamingImages ?? false) {
      await _controller!.stopImageStream();
    }
  }

  /// Convertit l'orientation du capteur en InputImageRotation
  InputImageRotation _getRotation(int sensorOrientation) {
    final deviceOrientation = _controller?.value.deviceOrientation
        ?? DeviceOrientation.portraitUp;

    int rotationCompensation = 0;
    switch (deviceOrientation) {
      case DeviceOrientation.portraitUp:    rotationCompensation = 0;   break;
      case DeviceOrientation.landscapeLeft: rotationCompensation = 90;  break;
      case DeviceOrientation.portraitDown:  rotationCompensation = 180; break;
      case DeviceOrientation.landscapeRight:rotationCompensation = 270; break;
    }

    final totalRotation = (sensorOrientation - rotationCompensation + 360) % 360;

    switch (totalRotation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}