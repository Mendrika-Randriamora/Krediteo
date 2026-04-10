import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class CallService {
  DateTime? _lastCallTime;

  /// Délai anti-spam entre deux appels (secondes)
  static const int _cooldownSeconds = 3;

  Future<bool> call(String number) async {
    final now = DateTime.now();
    if (_lastCallTime != null &&
        now.difference(_lastCallTime!).inSeconds < _cooldownSeconds) {
      return false;
    }

    // Demander la permission CALL_PHONE au runtime
    final status = await Permission.phone.request();
    if (!status.isGranted) return false;

    final cleanNumber = _sanitizeNumber(number);

    // Format USSD : #321*14chiffres#
    // Le # doit être encodé en %23 dans une URI tel:
    final ussd = '%23321*$cleanNumber%23';
    final uri = Uri.parse('tel:$ussd');

    // Pour les codes USSD, LaunchMode.externalApplication est recommandé
    if (!await canLaunchUrl(uri)) {
      print('Impossible de lancer l\'appel pour: $uri');
      // On tente quand même le launchUrl direct car canLaunchUrl peut échouer pour des USSD
    }

    _lastCallTime = now;
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Nettoie le numéro (supprime espaces, tirets, etc.)
  String _sanitizeNumber(String raw) {
    return raw.replaceAll(RegExp(r'[^\d+]'), '');
  }
}