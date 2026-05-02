import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:developer' as dev;

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  static final RegExp _numberRegex = RegExp(r'(?<!\d)(\d{14})(?!\d)');

  bool _isProcessing = false;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);
  static const int _throttleMs = 400;

  // Zone de scan autorisée (en ratio de l'image)
  // Correspond au cadre visuel dans scan_overlay.dart
  // static const double _zoneTopRatio    = 0.28; // début vertical de la zone
  // static const double _zoneBottomRatio = 0.62; // fin verticale de la zone
  // static const double _zoneLeftRatio   = 0.05; // marge gauche
  // static const double _zoneRightRatio  = 0.95; // marge droite
  // Correspond exactement au cadre visuel (frameW=82%, frameH=90px, frameTop=38%)
  // frameH=90px sur un écran ~800px de haut ≈ 11%
  static const double _zoneTopRatio    = 0.36; // un peu avant frameTop (0.38)
  static const double _zoneBottomRatio = 0.52; // frameTop(0.38) + frameH(~11%) + marge
  static const double _zoneLeftRatio   = 0.09; // (1 - 0.82) / 2
  static const double _zoneRightRatio  = 0.91; // 1 - 0.09

  Future<String?> processFrame(CameraImage image, InputImageRotation rotation) async {
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

      final bool isRotated = rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;

      // Dimensions réelles de l'image telle que ML Kit la voit
      final double imgW = (isRotated ? image.height : image.width).toDouble();
      final double imgH = (isRotated ? image.width : image.height).toDouble();

      return _extractNumberInZone(recognized, imgW, imgH);
    } catch (e) {
      dev.log('OCR Error: $e');
      return null;
    } finally {
      _isProcessing = false;
    }
  }

  String? _extractNumberInZone(RecognizedText recognized, double imgW, double imgH) {
    // Calculer la zone autorisée en pixels
    final zoneTop    = imgH * _zoneTopRatio;
    final zoneBottom = imgH * _zoneBottomRatio;
    final zoneLeft   = imgW * _zoneLeftRatio;
    final zoneRight  = imgW * _zoneRightRatio;

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;

        // Centre de la ligne détectée
        final lineCenterX = rect.left + rect.width / 2;
        final lineCenterY = rect.top + rect.height / 2;

        // Ignorer si le centre est hors de la zone de scan
        final isInZone = lineCenterX >= zoneLeft &&
            lineCenterX <= zoneRight &&
            lineCenterY >= zoneTop &&
            lineCenterY <= zoneBottom;

        if (!isInZone) {
          dev.log('Hors zone: "${line.text}" (cx:${lineCenterX.toInt()}, cy:${lineCenterY.toInt()})');
          continue;
        }

        // Chercher un numéro à 14 chiffres dans cette ligne
        final cleaned = line.text.replaceAll(RegExp(r'(?<=\d)[\s\-.](?=\d)'), '');
        final match = _numberRegex.firstMatch(cleaned);

        if (match != null) {
          dev.log('IN ZONE: "${line.text}" → ${match.group(1)}');
          return match.group(1);
        }
      }
    }

    return null;
  }

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