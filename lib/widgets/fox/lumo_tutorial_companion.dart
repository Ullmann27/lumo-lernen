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
///
/// Position kann auf zwei Arten angegeben werden:
///   - `targetKey`: GlobalKey eines echten Widgets im Home-Screen
///     (z.B. einer Subject-Tile). Der Companion liest dessen
///     RenderBox-Position zur Laufzeit -> Lumo trifft den Button
///     genau, unabhaengig von Bildschirmgroesse oder Scroll.
///   - `xFraction`/`yFraction`: relative Position als Fallback
///     (z.B. fuer FABs ohne Key oder fuer den Abschluss-Stop).
///
/// Genau einer der beiden Modi muss gesetzt sein.
class LumoTutorialStop {
  const LumoTutorialStop({
    this.targetKey,
    this.xFraction,
    this.yFraction,
    required this.message,
    this.duration = const Duration(milliseconds: 3800),
    this.jumpToReach = false,
  }) : assert(
          targetKey != null || (xFraction != null && yFraction != null),
          'LumoTutorialStop braucht entweder targetKey oder x/yFraction',
        );

  /// Optionaler Key auf das echte Ziel-Widget. Bevorzugt vor Fractions.
  final GlobalKey? targetKey;

  /// Position auf dem Screen in Prozent (0.0 - 1.0). Fallback wenn
  /// `targetKey` null ist oder nicht aufgeloest werden kann.
  final double? xFraction;
  final double? yFraction;

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

  /// Loest die Stop-Position in Bildschirm-Fractions auf.
  /// Heinz 2026-05-21: bevorzugt die echte RenderBox-Position des
  /// targetKey-Widgets, damit Lumo direkt am Ziel-Button landet.
  ({double x, double y}) _resolveStopFraction(LumoTutorialStop s) {
    final key = s.targetKey;
    if (key != null) {
      final ctx = key.currentContext;
      final renderObj = ctx?.findRenderObject();
      if (renderObj is RenderBox && renderObj.attached) {
        final size = MediaQuery.of(context).size;
        // Ziel: knapp neben der UEBERSCHRIFT der Card.
        // -> x: 30% von links innerhalb der Card (links neben dem Titel)
        // -> y: 20px unter dem Card-Top (Hoehe der Ueberschrift-Zeile)
        // Heinz: 'immer knapp neben der Ueberschrift'.
        final topLeft = renderObj.localToGlobal(Offset.zero);
        final box = renderObj.size;
        final anchorX = topLeft.dx + box.width * 0.30;
        final anchorY = topLeft.dy + 20.0;
        return (
          x: (anchorX / size.width).clamp(0.05, 0.95),
          y: (anchorY / size.height).clamp(0.05, 0.95),
        );
      }
    }
    return (
      x: s.xFraction ?? 0.5,
      y: s.yFraction ?? 0.5,
    );
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

    final tStop = widget.stops[idx];
    final resolved = _resolveStopFraction(tStop);
    final fromX = _curX;
    final fromY = _curY;
    final toX = resolved.x;
    final toY = resolved.y;

    // Lumo dreht sich in die Bewegungsrichtung
    setState(() {
      _facingRight = toX > fromX;
      _isTalking = false;
      _bubbleText = '';
    });
    _bubbleCtrl.reverse();

    if (tStop.jumpToReach) {
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
      _bubbleText = tStop.message;
    });
    await _bubbleCtrl.forward();

    // Verweildauer am Ziel
    _stayTimer?.cancel();
    _stayTimer = Timer(tStop.duration, () {
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

        // Bubble-Geometrie - 300 max, geclampted an Bildschirmrand.
        const bubbleW = 300.0;
        final foxScreenX = _xAnim.value * size.width;
        final bubbleLeft =
            (foxScreenX - bubbleW / 2).clamp(8.0, size.width - bubbleW - 8.0);
        // Wo zeigt der Tail? Relativ zur Bubble-Breite (0.0..1.0).
        // Heinz' Bubble-Cut-off Fix: wenn die Bubble am Rand geclampted
        // wurde, soll der Tail trotzdem auf den Fuchs zeigen, nicht in
        // die Bubble-Mitte.
        final tailRel = ((foxScreenX - bubbleLeft) / bubbleW).clamp(0.12, 0.88);

        return Stack(
          children: [
            // ── Sprechblase ueber Lumo ──
            if (_bubbleText.isNotEmpty)
              Positioned(
                left: bubbleLeft,
                top: py - 92,
                child: Transform.scale(
                  scale: bubbleScale.clamp(0.0, 1.0),
                  alignment: Alignment.bottomCenter,
                  child: _SpeechBubble(text: _bubbleText, tailRel: tailRel),
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
  const _SpeechBubble({required this.text, this.tailRel = 0.5});
  final String text;

  /// Wo der Tail relativ zur Bubble-Breite sitzt (0..1). 0.5 = Mitte.
  /// Heinz 2026-05-21: wenn die Bubble am Bildschirmrand geclampted
  /// wurde, zeigt der Tail dynamisch zum Fuchs statt zur Bubble-Mitte.
  final double tailRel;

  @override
  Widget build(BuildContext context) {
    // FIX (Heinz 2026-05-21): laengere Tutorial-Texte sollen sauber auf
    // mehrere Zeilen umbrechen. Bubble breiter (300) und Padding etwas
    // mehr, damit 3-4-zeiliger Text gut lesbar bleibt.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300, minWidth: 160),
      child: CustomPaint(
        painter: _BubblePainter(tailRel: tailRel),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C2D12),
              height: 1.32,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({this.tailRel = 0.5});

  /// Tail-Position relativ zur Bubble-Breite (0..1).
  final double tailRel;

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

    // Comic-Tail unten - Position abhaengig von tailRel.
    // Tail-Spitze 'zeigt' nach unten zur Fuchs-Position.
    final cx = w * tailRel.clamp(0.10, 0.90);
    final tailPath = Path()
      ..moveTo(cx - 10, h - 6)
      ..lineTo(cx, h)
      ..lineTo(cx + 6, h - 6)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);
    canvas.drawPath(tailPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.tailRel != tailRel;
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
