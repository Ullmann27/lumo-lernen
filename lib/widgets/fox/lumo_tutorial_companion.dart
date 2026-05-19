// ════════════════════════════════════════════════════════════════════════
// LUMO TUTORIAL COMPANION
// ════════════════════════════════════════════════════════════════════════
// Heinz: "Lumo soll frei am Homescreen herumlaufen. Er soll von rechts
// nach links wandern, zu den Rubriken laufen, sie erklaeren, klicken,
// dann zur naechsten gehen — wie eine Leiter."
//
// Diese Component ist ein Overlay-Layer ueber dem Home-Screen. Lumo
// wandert frei zwischen vordefinierten Waypoints (in Bildschirm-Prozent
// angegeben, damit es auf jeder Geraetegroesse passt), bleibt an
// Stationen stehen, dreht sich, zeigt eine Sprechblase mit Erklaerung,
// und geht zur naechsten Station weiter.
//
// Bewegungs-States:
//   - idle:    Lumo steht und atmet leicht (subtle bobbing)
//   - walking: Lumo bewegt sich zum Ziel, Run-Cycle aktiv
//   - talking: Lumo steht beim Ziel, Sprechblase erscheint
//   - jumping: Lumo springt zwischen Reihen (Leiter-Animation)
// ════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ein einzelner Tutorial-Halt auf der Reise durch den Home-Screen.
class LumoTutorialStop {
  const LumoTutorialStop({
    required this.xFraction,
    required this.yFraction,
    required this.message,
    this.duration = const Duration(milliseconds: 3800),
    this.jumpToReach = false,
  });

  /// Position auf dem Screen in Prozent (0.0 - 1.0).
  final double xFraction;
  final double yFraction;

  /// Was Lumo an diesem Stop sagt (max 2-3 kurze Saetze, kindgerecht).
  final String message;

  /// Wie lange Lumo hier verweilt bevor er weitergeht.
  final Duration duration;

  /// Wenn true, springt Lumo zur Position statt zu laufen
  /// (fuer Uebergaenge zwischen Reihen — "Leiter-Effekt").
  final bool jumpToReach;
}

class LumoTutorialCompanion extends StatefulWidget {
  const LumoTutorialCompanion({
    super.key,
    required this.stops,
    required this.childName,
    this.foxAssetPath = 'assets/lumo_jump/fox/idle/fox_idle_01.png',
    this.foxSize = 130.0,
    this.autoStart = false,
    this.onCompleted,
  });

  final List<LumoTutorialStop> stops;
  final String childName;
  final String foxAssetPath;
  final double foxSize;
  final bool autoStart;
  final VoidCallback? onCompleted;

  @override
  State<LumoTutorialCompanion> createState() => LumoTutorialCompanionState();
}

class LumoTutorialCompanionState extends State<LumoTutorialCompanion>
    with TickerProviderStateMixin {
  late final AnimationController _walkCtrl;       // X/Y movement
  late final AnimationController _bobCtrl;        // continuous idle bob
  late final AnimationController _runCycleCtrl;   // legs running cycle
  late final AnimationController _jumpCtrl;       // jump arc
  late final AnimationController _bubbleCtrl;     // speech-bubble pop

  late Animation<double> _xAnim;
  late Animation<double> _yAnim;

  int _currentStop = 0;
  bool _isTalking = false;
  bool _isJumping = false;
  bool _facingRight = true;
  bool _isActive = false;
  String _bubbleText = '';

  Timer? _stayTimer;

  // Current position (in fractions of screen)
  double _curX = 0.95;  // Start rechts unten am Screen-Rand
  double _curY = 0.85;

  @override
  void initState() {
    super.initState();

    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _bobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _runCycleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _jumpCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _xAnim = AlwaysStoppedAnimation(_curX);
    _yAnim = AlwaysStoppedAnimation(_curY);

    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => start());
    }
  }

  @override
  void dispose() {
    _stayTimer?.cancel();
    _walkCtrl.dispose();
    _bobCtrl.dispose();
    _runCycleCtrl.dispose();
    _jumpCtrl.dispose();
    _bubbleCtrl.dispose();
    super.dispose();
  }

  /// Tutorial starten (von aussen aufrufbar via GlobalKey<LumoTutorialCompanionState>).
  void start() {
    if (_isActive || widget.stops.isEmpty) return;
    setState(() {
      _isActive = true;
      _currentStop = 0;
    });
    _goToStop(0);
  }

  void stop() {
    _stayTimer?.cancel();
    _walkCtrl.stop();
    _jumpCtrl.stop();
    setState(() {
      _isActive = false;
      _isTalking = false;
      _isJumping = false;
      _bubbleText = '';
    });
    _bubbleCtrl.reverse();
  }

  void _goToStop(int idx) async {
    if (idx >= widget.stops.length) {
      // Tutorial fertig — Lumo winkt zum Abschied
      _bubbleText = 'Viel Spaß beim Lernen, ${widget.childName}! 🦊';
      await _bubbleCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 2500));
      if (!mounted) return;
      _bubbleCtrl.reverse();
      stop();
      widget.onCompleted?.call();
      return;
    }

    final stop = widget.stops[idx];
    final fromX = _curX;
    final fromY = _curY;
    final toX = stop.xFraction;
    final toY = stop.yFraction;

    // Lumo dreht sich in die Bewegungsrichtung
    setState(() {
      _facingRight = toX > fromX;
      _isTalking = false;
      _bubbleText = '';
    });
    _bubbleCtrl.reverse();

    if (stop.jumpToReach) {
      // ── JUMP-MODUS: kurzer hoher Bogen zur naechsten Reihe ──
      await _animateJump(fromX, fromY, toX, toY);
    } else {
      // ── WALK-MODUS: langsamere geschmeidige Wanderung ──
      await _animateWalk(fromX, fromY, toX, toY);
    }

    if (!mounted) return;
    _curX = toX;
    _curY = toY;

    // Angekommen — Sprechblase zeigen
    setState(() {
      _isTalking = true;
      _bubbleText = stop.message;
    });
    await _bubbleCtrl.forward();

    // Verweildauer am Ziel
    _stayTimer?.cancel();
    _stayTimer = Timer(stop.duration, () {
      if (!mounted) return;
      setState(() {
        _currentStop = idx + 1;
      });
      _goToStop(idx + 1);
    });
  }

  Future<void> _animateWalk(
      double fromX, double fromY, double toX, double toY) async {
    // Distanz bestimmt Dauer (mind. 900ms, max 2200ms)
    final dist = math.sqrt(math.pow(toX - fromX, 2) + math.pow(toY - fromY, 2));
    final ms = (900 + dist * 1800).clamp(900, 2200).round();
    _walkCtrl.duration = Duration(milliseconds: ms);

    _xAnim = Tween<double>(begin: fromX, end: toX).animate(
        CurvedAnimation(parent: _walkCtrl, curve: Curves.easeInOutCubic));
    _yAnim = Tween<double>(begin: fromY, end: toY).animate(
        CurvedAnimation(parent: _walkCtrl, curve: Curves.easeInOutCubic));

    setState(() {});

    _runCycleCtrl.repeat();
    _walkCtrl.reset();
    await _walkCtrl.forward();
    _runCycleCtrl.stop();
    _runCycleCtrl.reset();
  }

  Future<void> _animateJump(
      double fromX, double fromY, double toX, double toY) async {
    setState(() => _isJumping = true);

    _xAnim = Tween<double>(begin: fromX, end: toX)
        .animate(CurvedAnimation(parent: _jumpCtrl, curve: Curves.easeInOut));
    _yAnim = Tween<double>(begin: fromY, end: toY)
        .animate(CurvedAnimation(parent: _jumpCtrl, curve: Curves.easeInOut));

    _jumpCtrl.reset();
    await _jumpCtrl.forward();

    if (!mounted) return;
    setState(() => _isJumping = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _walkCtrl,
        _bobCtrl,
        _runCycleCtrl,
        _jumpCtrl,
        _bubbleCtrl,
      ]),
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final foxSize = widget.foxSize;
        final isWalking = _walkCtrl.isAnimating;

        // Aktuelle Position
        final px = _xAnim.value * size.width - foxSize / 2;
        // Jump-Bogen: parabolisch -16px in der Mitte
        final jumpOffset = _isJumping
            ? -math.sin(_jumpCtrl.value * math.pi) * 36
            : 0.0;
        // Walk-Bob: leichtes Auf-und-Ab waehrend Laufen
        final walkBob = isWalking
            ? math.sin(_runCycleCtrl.value * math.pi * 2) * 3
            : math.sin(_bobCtrl.value * math.pi) * 1.5;
        final py = _yAnim.value * size.height - foxSize + jumpOffset + walkBob;

        // Run-Cycle: Beine simulieren via subtle skewing
        final runTilt = isWalking
            ? math.sin(_runCycleCtrl.value * math.pi * 2) * 0.04
            : 0.0;

        // Bubble-Scale
        final bubbleScale = Curves.elasticOut.transform(_bubbleCtrl.value);

        return Stack(
          children: [
            // ── Sprechblase ueber Lumo ──
            if (_bubbleText.isNotEmpty)
              Positioned(
                left: (_xAnim.value * size.width - 130).clamp(8.0, size.width - 268),
                top: py - 78,
                child: Transform.scale(
                  scale: bubbleScale.clamp(0.0, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: _SpeechBubble(text: _bubbleText),
                ),
              ),

            // ── Lumo ──
            Positioned(
              left: px,
              top: py,
              child: GestureDetector(
                onTap: stop,  // Tap auf Lumo bricht Tutorial ab
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..rotateZ(runTilt)
                    ..scale(_facingRight ? 1.0 : -1.0, 1.0, 1.0),
                  child: SizedBox(
                    width: foxSize,
                    height: foxSize,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Schatten am Boden (faded waehrend Sprung)
                        Positioned(
                          bottom: 2,
                          child: Opacity(
                            opacity: _isJumping ? 0.3 : 0.55,
                            child: Container(
                              width: foxSize * (_isJumping ? 0.45 : 0.62),
                              height: 7,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(foxSize),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 2))
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Fox-Sprite
                        Image.asset(
                          widget.foxAssetPath,
                          width: foxSize,
                          height: foxSize,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => _FallbackFox(size: foxSize),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// Speech-Bubble mit kindgerechtem Comic-Look
// ────────────────────────────────────────────────────────────────────────
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, minWidth: 140),
      child: CustomPaint(
        painter: _BubblePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C2D12),
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glow hinter Bubble
    final glowPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(-2, -2, w + 4, h + 4 - 6),
            const Radius.circular(18)),
        glowPaint);

    // Bubble-Body
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFFFFF), Color(0xFFFFF8E7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    final bubbleRect =
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h - 6), const Radius.circular(18));
    canvas.drawRRect(bubbleRect, bodyPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(bubbleRect, outlinePaint);

    // Comic-Tail unten
    final tailPath = Path()
      ..moveTo(w * 0.42, h - 6)
      ..lineTo(w * 0.52, h)
      ..lineTo(w * 0.56, h - 6)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);
    canvas.drawPath(tailPath, outlinePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ────────────────────────────────────────────────────────────────────────
// Fallback wenn Sprite fehlt
// ────────────────────────────────────────────────────────────────────────
class _FallbackFox extends StatelessWidget {
  const _FallbackFox({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFF97316),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text('🦊', style: TextStyle(fontSize: 50)),
      ),
    );
  }
}
