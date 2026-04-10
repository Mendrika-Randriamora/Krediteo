import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart'; // WriteBuffer
import 'package:flutter/painting.dart';   // Size
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:developer' as dev;

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Regex stricte : exactement 14 chiffres, isolés (pas collés à d'autres chiffres)
  static final RegExp _numberRegex = RegExp(r'(?<!\d)(\d{14})(?!\d)');

  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  /// Délai minimum entre deux analyses (ms) – réduit le lag
  static const int _throttleMs = 400;

  /// Analyse une frame caméra. Retourne le numéro trouvé ou null.
  Future<String?> processFrame(CameraImage image, InputImageRotation rotation) async {
    // Throttling : on ignore les frames trop rapprochées
    final now = DateTime.now();
    if (_isProcessing || now.difference(_lastProcessed).inMilliseconds < _throttleMs) {
      return null;
    }

    _isProcessing = true;
    _lastProcessed = now;

    try {
      final inputImage = _buildInputImage(image, rotation);
      if (inputImage == null) return null;

      final recognized = await _recognizer.processImage(inputImage);
      return _extractNumber(recognized.text);
    } catch (_) {
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Cherche un numéro à 14 chiffres dans le texte reconnu
  // String? _extractNumber(String text) {
  //   // Nettoyage : supprimer espaces et tirets entre chiffres (ex: "1234 5678 9012 34")
  //   final cleaned = text.replaceAll(RegExp(r'(?<=\d)[\s\-.](?=\d)'), '');
  //   final match = _numberRegex.firstMatch(cleaned);
  //   return match?.group(1);
  // }
  String? _extractNumber(String text) {
    // Chercher d'abord sur chaque ligne individuellement
    for (final line in text.split('\n')) {
      final cleanedLine = line.replaceAll(RegExp(r'(?<=\d)[\s\-.](?=\d)'), '');
      final match = _numberRegex.firstMatch(cleanedLine);
      if (match != null) {
        print('=== MATCH sur ligne "${line.trim()}" : ${match.group(1)} ===');
        return match.group(1);
      }
    }

    // Fallback : chercher dans le texte entier nettoyé
    final cleaned = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'(?<=\d)[\s\-.](?=\d)'), '');
    final match = _numberRegex.firstMatch(cleaned);
    print('=== MATCH global : ${match?.group(1) ?? "AUCUN"} ===');
    return match?.group(1);
  }

  /// Convertit une CameraImage en InputImage pour ML Kit
  InputImage? _buildInputImage(CameraImage image, InputImageRotation rotation) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}