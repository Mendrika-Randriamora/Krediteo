import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/operator.dart';

class CallService {
  static const _channel = MethodChannel('com.example.krediteo/call');

  DateTime? _lastCallTime;

  /// Délai anti-spam entre deux appels (secondes)
  static const int _cooldownSeconds = 3;

  Future<bool> call(String number, Operator operator) async {
    final now = DateTime.now();
    if (_lastCallTime != null &&
        now.difference(_lastCallTime!).inSeconds < _cooldownSeconds) {
      return false;
    }

    // Demander la permission CALL_PHONE au runtime
    final status = await Permission.phone.request();
    if (!status.isGranted) {
      print('Permission d\'appel refusée');
      return false;
    }

    final cleanNumber = _sanitizeNumber(number);

    // Formatage selon l'opérateur (on utilise le format brut, l'encodage est fait côté natif)
    final ussd = operator.formatCall(cleanNumber);

    try {
      _lastCallTime = now;
      final bool? success = await _channel.invokeMethod<bool>(
        'makeDirectCall',
        {'number': ussd},
      );
      return success ?? false;
    } on PlatformException catch (e) {
      print('Erreur lors de l\'appel direct: ${e.message}');
      return false;
    }
  }

  /// Nettoie le numéro (supprime espaces, tirets, etc.)
  String _sanitizeNumber(String raw) {
    return raw.replaceAll(RegExp(r'[^\d+]'), '');
  }
}