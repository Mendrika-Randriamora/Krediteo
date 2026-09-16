import 'dart:async';

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Tokens de design
// ═══════════════════════════════════════════════════════════════════════════

/// Fond du splash : #1A1A1A (noirci pour meilleure lisibilité).
const Color _kSplashBackground = Color(0xFF1A1A1A);

const Color _kYellow = Color(0xFFFFD21A);
const Color _kRed = Color(0xFFF53823);
const Color _kBlue = Color(0xFF3E5BE7);
const Color _kGreen = Color(0xFF27A84E);

// ═══════════════════════════════════════════════════════════════════════════
// Géométrie du cadre de scan
// ═══════════════════════════════════════════════════════════════════════════

/// Zone du logo (tailles en dp, zone carrée 160×160).
const double _kZoneSize = 160.0;

/// Épaisseur du trait.
const double _kStrokeWidth = _kZoneSize * 0.08;

/// Côté de la boîte carrée d'un coin (le "L"). 2×0.30 = 60% de la zone,
/// le reste devient l'espace central : c'est ce qui décolle les 4 parties.
const double _kCornerBox = _kZoneSize * 0.30; //      = 48

/// Rayon de l'arrondi du coin.
const double _kCornerRadius = _kZoneSize * 0.115; //  ≈ 18.4

/// Distance parcourue par chaque coin le long de sa diagonale à l'entrée.
const double _kEntranceTravel = 90.0;

// ═══════════════════════════════════════════════════════════════════════════
// Timing d'entrée (0 → 750 ms)
// ═══════════════════════════════════════════════════════════════════════════

const int _kEntranceMs = 750; // durée totale de l'entrée
const int _kCornerMs = 500; //   durée de chaque coin
const int _kCornerStaggerMs = 60; // délai entre deux coins

// ═══════════════════════════════════════════════════════════════════════════
// Maintien — durée minimale d'affichage
// ═══════════════════════════════════════════════════════════════════════════

const Duration _kMinHold = Duration(milliseconds: 1500);

// ═══════════════════════════════════════════════════════════════════════════
// Timing de sortie (~700 ms)
// ═══════════════════════════════════════════════════════════════════════════

const int _kExitMs = 700; // durée totale de la sortie
const int _kCornerExitStartMs = 300; // phase B : départ des coins
const double _kExitTravel = 60.0; // translation de sortie des coins (dp)

// ═══════════════════════════════════════════════════════════════════════════
// Réduction des animations (accessibilité)
// ═══════════════════════════════════════════════════════════════════════════

const Duration _kReducedDuration = Duration(milliseconds: 200);

/// La police Kanit (Medium/SemiBold) déclarée dans pubspec.yaml.
const String _kTitleFontFamily = 'Kanit';

/// Directions diagonales des coins (jaune → rouge → bleu → vert).
const List<Offset> _diagonals = [
  Offset(-0.7071067811865476, -0.7071067811865476), // haut-gauche
  Offset(0.7071067811865476, -0.7071067811865476), // haut-droit
  Offset(-0.7071067811865476, 0.7071067811865476), // bas-gauche
  Offset(0.7071067811865476, 0.7071067811865476), //  bas-droit
];

/// Couleurs des coins dans le même ordre que [_diagonals].
const List<Color> _colors = [_kYellow, _kRed, _kBlue, _kGreen];

// ═══════════════════════════════════════════════════════════════════════════
// Widget du splash animé (isolé et réutilisable)
// ═══════════════════════════════════════════════════════════════════════════

/// Splash animé "Scan Lock".
///
/// L'[cameraReadyFuture] se résout quand la caméra est prête OU en erreur
/// définitive : le splash n'entame sa sortie qu'à ce moment-là, et au plus tôt
/// après [_kMinHold]. Quand la sortie est terminée, [onSplashFinished] est
/// appelé pour que le parent retire le splash et révèle l'écran en dessous.
class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({
    super.key,
    required this.cameraReadyFuture,
    required this.onSplashFinished,
  });

  final Future<void> cameraReadyFuture;
  final VoidCallback onSplashFinished;

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _entrance;
  late final AnimationController _exit;

  late final List<Animation<double>> _cornerIn;
  late final List<Animation<double>> _cornerOut;
  late final Animation<double> _titleIn;
  late final Animation<double> _titleOut;
  late final Animation<double> _backgroundOut;

  bool _reducedMotion = false;
  bool _configured = false;
  bool _exitStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kEntranceMs),
    );

    _exit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kExitMs),
    );

    // Entrée : un intervalle par coin (stagger de 60 ms).
    _cornerIn = List.generate(4, (i) {
      final start = (i * _kCornerStaggerMs) / _kEntranceMs;
      final end = (i * _kCornerStaggerMs + _kCornerMs) / _kEntranceMs;
      return CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      );
    });

    // Entrée : le titre apparaît de 400 ms à 750 ms.
    _titleIn = CurvedAnimation(
      parent: _entrance,
      curve: Interval(400 / _kEntranceMs, 1, curve: Curves.easeOut),
    );

    // Sortie : les coins et le fond démarrent à 300 ms (phase B).
    _cornerOut = List.generate(4, (i) {
      return CurvedAnimation(
        parent: _exit,
        curve: Interval(
          _kCornerExitStartMs / _kExitMs,
          1,
          curve: Curves.easeInBack,
        ),
      );
    });

    // Sortie : le titre s'efface dès 300 ms.
    _titleOut = CurvedAnimation(
      parent: _exit,
      curve: Interval(_kCornerExitStartMs / _kExitMs, 0.9, curve: Curves.easeOut),
    );

    // Sortie : le fond s'efface sur toute la phase B.
    _backgroundOut = CurvedAnimation(
      parent: _exit,
      curve: Interval(_kCornerExitStartMs / _kExitMs, 1),
    );

    // Attente des deux conditions (min. 1500 ms + caméra prête/en erreur)
    // avant de lancer la sortie. Le délai commence au premier frame Flutter.
    _startHoldWait();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_configured) return;
    _configured = true;

    _reducedMotion = MediaQuery.of(context).disableAnimations;
    if (_reducedMotion) {
      _entrance.duration = _kReducedDuration;
      _exit.duration = _kReducedDuration;
    }

    // L'animation d'entrée démarre après la toute première frame pour que
    // celle-ci montre le logo complet (enchaînement natif → Flutter invisible).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entrance.forward(from: 0);
    });
  }

  Future<void> _startHoldWait() async {
    await Future.wait([
      widget.cameraReadyFuture.catchError((_) {}),
      Future<void>.delayed(_kMinHold),
    ]);
    if (!mounted) return;
    _startExit();
  }

  void _startExit() {
    if (_exitStarted) return;
    setState(() => _exitStarted = true);
    _exit.addStatusListener(_onExitStatus);
    _exit.forward();
  }

  void _onExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      widget.onSplashFinished();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        _entrance.stop();
        _exit.stop();
        break;
      case AppLifecycleState.resumed:
        if (_exitStarted) {
          if (_exit.value < 1) _exit.forward();
        } else if (_entrance.value < 1 && _entrance.value > 0) {
          _entrance.forward();
        }
        break;
      default:
        break;
    }
  }
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  // Les CurvedAnimation sont disposées par les AnimationControllers parents.
  _entrance.dispose();
  _exit.dispose();
  super.dispose();
}

  @override
  Widget build(BuildContext context) {
    if (_reducedMotion) return _buildReduced();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Fond du splash (s'efface pendant la phase B de la sortie).
            AnimatedBuilder(
              animation: _backgroundOut,
              builder: (context, _) {
                return IgnorePointer(
                  child: ColoredBox(
                    color: _kSplashBackground.withValues(
                      alpha: (1 - _backgroundOut.value),
                    ),
                  ),
                );
              },
            ),

            // Cadre à 4 coins animés.
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFrame(),
                  const SizedBox(height: 28),
                  _buildTitle(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Cadre de scan : les 4 coins dessinés par [CustomPaint].
  Widget _buildFrame() {
    return AnimatedBuilder(
      animation: Listenable.merge([..._cornerIn, ..._cornerOut]),
      builder: (context, _) {
        final corners = <_CornerState>[];
        for (var i = 0; i < 4; i++) {
          final tIn = _cornerIn[i].value;
          final tOut = _cornerOut[i].value;

          final opacity = (tIn.clamp(0.0, 1.0) * (1 - tOut.clamp(0.0, 1.0)));
          final travel =
              _kEntranceTravel * (1 - tIn) + _kExitTravel * tOut;

          corners.add(
            _CornerState(
              color: _colors[i],
              offset: _diagonals[i] * travel,
              opacity: opacity,
            ),
          );
        }

        return CustomPaint(
          size: const Size.square(_kZoneSize),
          painter: _SplashFramePainter(
            zoneSize: _kZoneSize,
            strokeWidth: _kStrokeWidth,
            cornerBox: _kCornerBox,
            cornerRadius: _kCornerRadius,
            corners: corners,
          ),
        );
      },
    );
  }

  /// Titre "Krediteo" : fade-in + translation vers le haut à l'entrée.
  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: Listenable.merge([_titleIn, _titleOut]),
      builder: (context, _) {
        final opacity =
            _titleIn.value.clamp(0.0, 1.0) * (1 - _titleOut.value.clamp(0.0, 1.0));
        final translateY = 8 * (1 - _titleIn.value.clamp(0.0, 1.0));

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: const Text(
              'Krediteo',
              style: TextStyle(
                fontFamily: _kTitleFontFamily,
                fontSize: 34,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Variante accessible : simple fondu d'entrée puis de sortie (200 ms).
  Widget _buildReduced() {
    return AnimatedBuilder(
      animation: Listenable.merge([_entrance, _exit]),
      builder: (context, _) {
        final opacity =
            _entrance.value.clamp(0.0, 1.0) * (1 - _exit.value.clamp(0.0, 1.0));
        return Opacity(
          opacity: opacity,
          child: _buildStaticContent(),
        );
      },
    );
  }

  /// Contenu statique (coins en position finale, titre visible).
  Widget _buildStaticContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final corners = <_CornerState>[];
        for (var i = 0; i < 4; i++) {
          corners.add(
            _CornerState(
              color: _colors[i],
              offset: Offset.zero,
              opacity: 1,
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _kSplashBackground),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomPaint(
                    size: const Size.square(_kZoneSize),
                    painter: _SplashFramePainter(
                      zoneSize: _kZoneSize,
                      strokeWidth: _kStrokeWidth,
                      cornerBox: _kCornerBox,
                      cornerRadius: _kCornerRadius,
                      corners: corners,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Krediteo',
                    style: TextStyle(
                      fontFamily: _kTitleFontFamily,
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Peinture du cadre de scan
// ═══════════════════════════════════════════════════════════════════════════

/// État d'un coin du cadre (couleur, translation et opacité animées).
class _CornerState {
  const _CornerState({
    required this.color,
    required this.offset,
    required this.opacity,
  });

  final Color color;
  final Offset offset;
  final double opacity;
}

/// Dessine les 4 coins arrondis du cadre de scan.
class _SplashFramePainter extends CustomPainter {
  const _SplashFramePainter({
    required this.zoneSize,
    required this.strokeWidth,
    required this.cornerBox,
    required this.cornerRadius,
    required this.corners,
  });

  final double zoneSize;
  final double strokeWidth;
  final double cornerBox;
  final double cornerRadius;
  final List<_CornerState> corners;

  /// Origine locale de chaque coin, dans le repère du canvas.
  /// Les 4 boîtes font toutes [cornerBox] de côté et sont plaquées dans les
  /// angles de la zone, retrait de [strokeWidth]/2 compris.
  Offset _origin(int i, Size size) {
    final inset = strokeWidth / 2;
    final near = inset;
    final far = zoneSize - inset - cornerBox;
    final dx = (i == 1 || i == 3) ? far : near;
    final dy = (i == 2 || i == 3) ? far : near;
    return Offset(
      (size.width - zoneSize) / 2 + dx,
      (size.height - zoneSize) / 2 + dy,
    );
  }

  /// Un "L" arrondi inscrit dans une boîte [box]×[box], l'angle étant placé
  /// dans le coin correspondant à [i] (0 = HG, 1 = HD, 2 = BG, 3 = BD).
  Path _path(int i, double box, double r) {
    switch (i) {
      case 0: // haut-gauche : bras vertical en bas, horizontal à droite
        return Path()
          ..moveTo(0, box)
          ..lineTo(0, r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..lineTo(box, 0);
      case 1: // haut-droit : bras horizontal à gauche, vertical en bas
        return Path()
          ..moveTo(0, 0)
          ..lineTo(box - r, 0)
          ..quadraticBezierTo(box, 0, box, r)
          ..lineTo(box, box);
      case 2: // bas-gauche : bras vertical en haut, horizontal à droite
        return Path()
          ..moveTo(0, 0)
          ..lineTo(0, box - r)
          ..quadraticBezierTo(0, box, r, box)
          ..lineTo(box, box);
      default: // bas-droit : bras vertical en haut, horizontal à gauche
        return Path()
          ..moveTo(box, 0)
          ..lineTo(box, box - r)
          ..quadraticBezierTo(box, box, box - r, box)
          ..lineTo(0, box);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < corners.length; i++) {
      final corner = corners[i];
      if (corner.opacity <= 0) continue;

      final paint = Paint()
        ..color = corner.color.withValues(alpha: corner.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final origin = _origin(i, size) + corner.offset;

      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.drawPath(_path(i, cornerBox, cornerRadius), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SplashFramePainter oldDelegate) {
    if (oldDelegate.zoneSize != zoneSize ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cornerBox != cornerBox ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.corners.length != corners.length) {
      return true;
    }
    for (var i = 0; i < corners.length; i++) {
      final a = oldDelegate.corners[i];
      final b = corners[i];
      if (a.color != b.color || a.opacity != b.opacity || a.offset != b.offset) {
        return true;
      }
    }
    return false;
  }
}