import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'embedded_lumo_fox.dart';
import 'fox/lumo_idle_fox.dart';

/// Lumo-Fuchs als lebendiger Charakter.
///
/// Kann:
/// - autonom atmen, blinzeln, schaukeln
/// - sich nach links/rechts drehen (Spiegelung wie ein Mensch)
/// - Kopf nach oben/unten neigen (Head-Tilt)
/// - zu einer Ziel-Position auf dem Bildschirm laufen
/// - durch Tap reagieren, durch Drag bewegt werden
/// - eine Sprechblase anzeigen
class FreeLumoFox extends StatefulWidget {
  const FreeLumoFox({
    super.key,
    this.size = 220,
    this.mood = 'greet',
    this.facing = FoxFacing.right,
    this.headTilt = 0.0,
    this.message,
    this.onTap,
    this.autoDrift = true,
    this.draggable = true,
    this.targetOffset,
  });

  /// Hoehe des Fuchses in logischen Pixeln.
  final double size;

  /// Stimmungs-Tag fuer Aura und Verhalten.
  final String mood;

  /// Welche Richtung der Fuchs schaut.
  final FoxFacing facing;

  /// Kopf-Neigung: -1.0 (nach unten) bis +1.0 (nach oben).
  final double headTilt;

  /// Optionale Sprechblase ueber dem Fuchs.
  final String? message;

  /// Callback beim Antippen.
  final VoidCallback? onTap;

  /// Driftet der Fuchs autonom (Idle-Mode)?
  final bool autoDrift;

  /// Kann das Kind den Fuchs ziehen?
  final bool draggable;

  /// Wenn gesetzt, animiert der Fuchs zu dieser Position
  /// (relativ zu seiner Grund-Position). Ueberschreibt Drift.
  final Offset? targetOffset;

  @override
  State<FreeLumoFox> createState() => _FreeLumoFoxState();
}

enum FoxFacing { left, right }

class _FreeLumoFoxState extends State<FreeLumoFox>
    with TickerProviderStateMixin {
  // ── Endlos-Animationen ─────────────────────────────────────────────────────
  late final AnimationController _breath = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1850),
  )..repeat(reverse: true);

  late final AnimationController _aura = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  // Kleine periodische Kopf-Bewegung (als ob er sich umsieht)
  late final AnimationController _headSway = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 5200),
  )..repeat(reverse: true);

  // Blinzeln (sehr selten, dafuer kurz)
  late final AnimationController _blink = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 180),
  );

  // ── Einmalige Animationen ──────────────────────────────────────────────────
  late final AnimationController _hop = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 520),
  );

  // Drehung beim Richtungswechsel (smooth Mirror-Flip)
  late final AnimationController _flip = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 380),
    value: 1.0, // start = vollstaendig in aktueller Richtung
  );
  late FoxFacing _currentFacing = widget.facing;

  // ── Drift ──────────────────────────────────────────────────────────────────
  Offset _drift = Offset.zero;
  Offset _driftTarget = Offset.zero;
  late final AnimationController _driftCtrl = AnimationController(
    vsync: this, duration: const Duration(seconds: 6),
  );
  final _rng = math.Random();

  // ── Externes Ziel (Tour) ───────────────────────────────────────────────────
  Offset _walkFrom = Offset.zero;
  Offset _walkTo = Offset.zero;
  late final AnimationController _walkCtrl = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1100),
  );

  // ── Drag ───────────────────────────────────────────────────────────────────
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  // ── Blink-Timer ────────────────────────────────────────────────────────────
  bool _blinkScheduled = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoDrift) _scheduleNextDrift();
    _scheduleNextBlink();
    _maybeWalkTo(widget.targetOffset);
  }

  @override
  void didUpdateWidget(covariant FreeLumoFox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Blickrichtung geaendert? Smooth Flip.
    if (widget.facing != _currentFacing) {
      _currentFacing = widget.facing;
      _flip.forward(from: 0);
    }

    // Neues Ziel?
    if (widget.targetOffset != oldWidget.targetOffset) {
      _maybeWalkTo(widget.targetOffset);
    }
  }

  void _maybeWalkTo(Offset? target) {
    if (target == null) return;
    _walkFrom = _isDragging ? _dragOffset : _drift;
    _walkTo = target;
    _walkCtrl
      ..duration = Duration(
        milliseconds: 700 + ((target - _walkFrom).distance * 1.4).clamp(0, 1500).toInt(),
      )
      ..forward(from: 0);
  }

  void _scheduleNextDrift() {
    if (!mounted || !widget.autoDrift) return;
    final newTarget = Offset(
      (_rng.nextDouble() - 0.5) * 60,
      (_rng.nextDouble() - 0.5) * 36,
    );
    setState(() {
      _drift = _driftTarget;
      _driftTarget = newTarget;
    });
    _driftCtrl
      ..duration = Duration(milliseconds: 4500 + _rng.nextInt(3000))
      ..forward(from: 0).whenComplete(_scheduleNextDrift);
  }

  void _scheduleNextBlink() {
    if (!mounted || _blinkScheduled) return;
    _blinkScheduled = true;
    Future.delayed(Duration(milliseconds: 3500 + _rng.nextInt(4000)), () {
      if (!mounted) return;
      _blinkScheduled = false;
      _blink.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        _blink.reverse().whenComplete(_scheduleNextBlink);
      });
    });
  }

  @override
  void dispose() {
    _breath.dispose();
    _aura.dispose();
    _headSway.dispose();
    _blink.dispose();
    _hop.dispose();
    _flip.dispose();
    _driftCtrl.dispose();
    _walkCtrl.dispose();
    super.dispose();
  }

  Color get _auraColor {
    switch (widget.mood) {
      case 'celebrate': return const Color(0xffffd166);
      case 'comfort':   return const Color(0xff7dd3fc);
      case 'think':     return const Color(0xffa78bfa);
      case 'wave':      return const Color(0xffff9a5c);
      case 'sleep':     return const Color(0xffcbd5e1);
      case 'point':     return const Color(0xff10a894);
      default:          return const Color(0xffffb96b);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size * 0.62;
    final h = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breath, _aura, _headSway, _blink, _hop, _flip,
        _driftCtrl, _walkCtrl,
      ]),
      builder: (context, _) {
        // Atmen
        final breathScale = 1 + 0.025 * _breath.value;

        // Kopf-Schwingen (subtil, links-rechts schauen)
        final headSwayDeg = math.sin(_headSway.value * math.pi * 2) * 0.025;

        // Hop-Sprung
        final hopY = -math.sin(_hop.value * math.pi) * 28;
        final hopScale = 1 + 0.04 * math.sin(_hop.value * math.pi);

        // Drift
        final dt = Curves.easeInOutSine.transform(_driftCtrl.value);
        var driftX = _drift.dx + (_driftTarget.dx - _drift.dx) * dt;
        var driftY = _drift.dy + (_driftTarget.dy - _drift.dy) * dt;

        // Walk-to-target ueberschreibt Drift
        if (_walkCtrl.isAnimating || _walkCtrl.value < 1.0 && widget.targetOffset != null) {
          final wt = Curves.easeInOutCubic.transform(_walkCtrl.value);
          driftX = _walkFrom.dx + (_walkTo.dx - _walkFrom.dx) * wt;
          driftY = _walkFrom.dy + (_walkTo.dy - _walkFrom.dy) * wt;
          // Auf-und-ab beim Laufen (kleine Hopser)
          driftY += -math.sin(_walkCtrl.value * math.pi * 4) * 5;
        }

        // Drag dominiert
        final tx = _isDragging ? _dragOffset.dx : driftX;
        final ty = _isDragging ? _dragOffset.dy : driftY + hopY;

        // Spiegelung (Flip-Animation): -1 = nach links, +1 = nach rechts
        final flipBase = _currentFacing == FoxFacing.right ? 1.0 : -1.0;
        final flipFrom = _currentFacing == FoxFacing.right ? -1.0 : 1.0;
        final flipMix = Curves.easeInOutCubic.transform(_flip.value);
        final flipX = flipFrom + (flipBase - flipFrom) * flipMix;

        // Kopf-Tilt (oben/unten schauen)
        final tilt = widget.headTilt.clamp(-1.0, 1.0) * 0.10;

        // Aura-Pulsation
        final aura = 0.55 + 0.45 * _aura.value;

        // Blinzeln (kurze Y-Skalierung des oberen Bereichs - simuliert Augenlider)
        final blinkScale = 1.0 - _blink.value * 0.06;

        return Transform.translate(
          offset: Offset(tx, ty),
          child: Transform.rotate(
            angle: tilt + headSwayDeg,
            child: Transform.scale(
              scaleX: flipX * breathScale * hopScale,
              scaleY: breathScale * hopScale * blinkScale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  widget.onTap?.call();
                  _hop.forward(from: 0);
                },
                onPanStart: widget.draggable
                    ? (_) => setState(() => _isDragging = true)
                    : null,
                onPanUpdate: widget.draggable
                    ? (d) => setState(() => _dragOffset += d.delta)
                    : null,
                onPanEnd: widget.draggable
                    ? (_) {
                        setState(() => _isDragging = false);
                        _drift = _dragOffset;
                        _dragOffset = Offset.zero;
                      }
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Aura
                    Container(
                      width: w * 1.25,
                      height: h * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _auraColor.withOpacity(0.32 * aura),
                            blurRadius: 60,
                            spreadRadius: 14,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.50 * aura),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Bodenschatten
                    Positioned(
                      bottom: 4,
                      child: Container(
                        width: w * 0.78,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(99),
                          gradient: RadialGradient(colors: [
                            Colors.black.withOpacity(0.20),
                            Colors.black.withOpacity(0.0),
                          ]),
                        ),
                      ),
                    ),
                    // Fuchs - 8-Frame-Idle-Animation statt Cartoon-PNG
                    SizedBox(
                      width: w,
                      height: h,
                      child: LumoIdleFox(size: h),
                    ),
                    // Sprechblase: KEIN Mirror (Text muss lesbar bleiben)
                    if (widget.message != null && widget.message!.isNotEmpty)
                      Positioned(
                        top: -10,
                        child: Transform(
                          // Re-flip damit der Text korrekt ausgerichtet bleibt
                          transform: Matrix4.identity()..scale(flipX < 0 ? -1.0 : 1.0, 1.0),
                          alignment: Alignment.center,
                          child: _SpeechBubble(text: widget.message!),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: Color(0xff2d2621),
          ),
        ),
      ),
    );
  }
}
