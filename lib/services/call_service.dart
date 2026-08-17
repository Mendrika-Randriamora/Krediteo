import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  static const _channel = MethodChannel('com.example.krediteo/call');

  DateTime? _lastCallTime;

  /// Délai anti-spam entre deux appels (secondes)
  static const int _cooldownSeconds = 3;

  Future<bool> call(String ussdCode) async {
    final now = DateTime.now();
    if (_lastCallTime != null &&
        now.difference(_lastCallTime!).inSeconds < _cooldownSeconds) {
      return false;
    }

    // Demander la permission CALL_PHONE au runtime
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      debugPrint('Permission d\'appel refusée');
      return false;
    }

    try {
      _lastCallTime = now;
      final bool? success = await _channel.invokeMethod<bool>(
        'makeDirectCall',
        {'number': ussdCode},
      );
      return success ?? false;
    } on PlatformException catch (e) {
      debugPrint('Erreur lors de l\'appel direct: ${e.message}');
      return false;
    }
  }
}