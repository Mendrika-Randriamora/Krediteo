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

      final RecognizedText recognized = await _recognizer.processImage(inputImage);
      
      // Calculer le centre de l'image (en tenant compte de la rotation)
      // Si rotation 90/270, width et height sont inversés pour ML Kit
      final bool isRotated = rotation == InputImageRotation.rotation90deg || 
                           rotation == InputImageRotation.rotation270deg;
      final double centerX = (isRotated ? image.height : image.width) / 2;
      final double centerY = (isRotated ? image.width : image.height) / 2;

      return _extractBestNumber(recognized, centerX, centerY);
    } catch (e) {
      dev.log('OCR Error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  /// Trouve le meilleur numéro (le plus central) parmi tous les blocs détectés
  String? _extractBestNumber(RecognizedText recognized, double centerX, double centerY) {
    String? bestNumber;
    double minDistance = double.infinity;

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        // Nettoyage de la ligne pour trouver les numéros potentiels
        // (on garde les espaces/tirets pour le split si besoin, mais on nettoie pour le regex)
        final cleanedLine = line.text.replaceAll(RegExp(r'(?<=\d)[\s\-.](?=\d)'), '');
        final match = _numberRegex.firstMatch(cleanedLine);

        if (match != null) {
          final number = match.group(1)!;
          
          // Calculer le centre de la ligne
          final rect = line.boundingBox;
          final lineCenterX = rect.left + rect.width / 2;
          final lineCenterY = rect.top + rect.height / 2;

          // Distance au centre de l'image (au carré pour la perf)
          final distanceSq = (lineCenterX - centerX) * (lineCenterX - centerX) +
                             (lineCenterY - centerY) * (lineCenterY - centerY);

          if (distanceSq < minDistance) {
            minDistance = distanceSq;
            bestNumber = number;
          }
        }
      }
    }

    if (bestNumber != null) {
      dev.log('=== MATCH OPTIMAL : $bestNumber (dist: ${minDistance.toStringAsFixed(0)}) ===');
    }
    
    return bestNumber;
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