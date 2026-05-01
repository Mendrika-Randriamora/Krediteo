/// États possibles du scanner OCR
enum ScanStatus {
  /// Caméra prête, en attente d'un numéro
  idle,

  /// Traitement OCR en cours
  scanning,

  /// Numéro valide détecté
  detected,

  /// Appel en cours d'initialisation
  calling,
}

/// Résultat d'un scan
class ScanState {
  final ScanStatus status;
  final String? detectedNumber;

  const ScanState({
    required this.status,
    this.detectedNumber,
  });

  const ScanState.idle()
      : status = ScanStatus.idle,
        detectedNumber = null;

  const ScanState.scanning()
      : status = ScanStatus.scanning,
        detectedNumber = null;

  const ScanState.detected(String number)
      : status = ScanStatus.detected,
        detectedNumber = number;

  const ScanState.calling(String number)
      : status = ScanStatus.calling,
        detectedNumber = number;

  bool get hasNumber => detectedNumber != null;

  @override
  String toString() => 'ScanState($status, $detectedNumber)';
}