import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/scan_state.dart';

/// Overlay par-dessus la caméra : cadre de scan, animation, état
class ScanOverlay extends StatefulWidget {
  final ScanStatus status;

  const ScanOverlay({super.key, required this.status});

  @override
  State<ScanOverlay> createState() => _ScanOverlayState();
}

class _ScanOverlayState extends State<ScanOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanLineController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();

    // Animation de la ligne de scan (de haut en bas)
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scanLineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    // Pulsation du cadre en mode scanning
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation de succès (zoom in)
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _successAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(ScanOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == ScanStatus.detected &&
        oldWidget.status != ScanStatus.detected) {
      _successController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Dimensions du cadre de scan (centré, format paysage pour numéros)
        final frameW = w * 0.82;
        const frameH = 90.0;
        final frameLeft = (w - frameW) / 2;
        final frameTop = h * 0.38;

        return Stack(
          children: [
            // Fond semi-transparent avec découpe
            _buildScrim(w, h, frameLeft, frameTop, frameW, frameH),

            // Cadre de scan animé
            Positioned(
              left: frameLeft,
              top: frameTop,
              child: _buildFrame(frameW, frameH),
            ),

            // Ligne de scan (visible seulement en mode scanning)
            if (widget.status == ScanStatus.scanning)
              _buildScanLine(frameLeft, frameTop, frameW, frameH),

            // Label d'état
            Positioned(
              left: 0,
              right: 0,
              top: frameTop + frameH + 24,
              child: _buildStatusLabel(),
            ),

            // Instruction en haut
            Positioned(
              top: 56,
              left: 24,
              right: 24,
              child: _buildTopHint(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScrim(
      double w, double h, double fl, double ft, double fw, double fh) {
    return CustomPaint(
      size: Size(w, h),
      painter: _ScrimPainter(
        frameRect: Rect.fromLTWH(fl, ft, fw, fh),
      ),
    );
  }

  Widget _buildFrame(double frameW, double frameH) {
    final isDetected = widget.status == ScanStatus.detected;
    final color = isDetected ? const Color(0xFF4ADE80) : Colors.white;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _successAnim]),
      builder: (_, __) {
        final scale = isDetected ? _successAnim.value : _pulseAnim.value;
        return Transform.scale(
          scale: scale,
          child: CustomPaint(
            size: Size(frameW, frameH),
            painter: _FramePainter(color: color, isDetected: isDetected),
          ),
        );
      },
    );
  }

  Widget _buildScanLine(double fl, double ft, double fw, double fh) {
    return AnimatedBuilder(
      animation: _scanLineAnim,
      builder: (_, __) {
        final y = ft + _scanLineAnim.value * fh;
        return Positioned(
          left: fl + 8,
          top: y,
          child: Container(
            width: fw - 16,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF38BDF8).withOpacity(0.8),
                  const Color(0xFF38BDF8),
                  const Color(0xFF38BDF8).withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusLabel() {
    final (text, color, icon) = switch (widget.status) {
      ScanStatus.idle => (
      'Pointez vers un numéro à 14 chiffres',
      Colors.white70,
      Icons.search_rounded,
      ),
      ScanStatus.scanning => (
      'Analyse en cours…',
      const Color(0xFF38BDF8),
      Icons.center_focus_strong_rounded,
      ),
      ScanStatus.detected => (
      'Numéro détecté !',
      const Color(0xFF4ADE80),
      Icons.check_circle_rounded,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Row(
        key: ValueKey(widget.status),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 16),
          SizedBox(width: 8),
          Text(
            'Scanner OCR • Numéro 14 chiffres',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine le fond semi-transparent avec découpe rectangulaire
class _ScrimPainter extends CustomPainter {
  final Rect frameRect;
  _ScrimPainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final cutout = RRect.fromRectAndRadius(
      frameRect.inflate(2),
      const Radius.circular(12),
    );
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutout)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.frameRect != frameRect;
}

/// Dessine les coins du cadre de scan
class _FramePainter extends CustomPainter {
  final Color color;
  final bool isDetected;
  _FramePainter({required this.color, required this.isDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = isDetected ? 3 : 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    const r = 10.0;
    final w = size.width;
    final h = size.height;

    // Si détecté : bordure complète avec coins arrondis
    if (isDetected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(r),
        ),
        paint,
      );
      return;
    }

    // Sinon : coins seulement (look "viseur")
    final paths = [
      // Coin haut-gauche
      Path()
        ..moveTo(0, cornerLen + r)
        ..lineTo(0, r)
        ..quadraticBezierTo(0, 0, r, 0)
        ..lineTo(cornerLen + r, 0),
      // Coin haut-droit
      Path()
        ..moveTo(w - cornerLen - r, 0)
        ..lineTo(w - r, 0)
        ..quadraticBezierTo(w, 0, w, r)
        ..lineTo(w, cornerLen + r),
      // Coin bas-droit
      Path()
        ..moveTo(w, h - cornerLen - r)
        ..lineTo(w, h - r)
        ..quadraticBezierTo(w, h, w - r, h)
        ..lineTo(w - cornerLen - r, h),
      // Coin bas-gauche
      Path()
        ..moveTo(cornerLen + r, h)
        ..lineTo(r, h)
        ..quadraticBezierTo(0, h, 0, h - r)
        ..lineTo(0, h - cornerLen - r),
    ];

    for (final p in paths) {
      canvas.drawPath(p, paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color || old.isDetected != isDetected;
}