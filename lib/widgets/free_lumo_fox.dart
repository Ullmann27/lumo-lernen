import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'embedded_lumo_fox.dart';

/// FreeLumoFox – ein frei beweglicher, animierter Lernfuchs.
///
/// Er driftet sanft autonom über den ihm zugewiesenen Bereich,
/// reagiert auf Tap (springt, schaltet Stimmung), kann gezogen werden
/// und atmet sichtbar (Idle-Animation).
///
/// Der Fuchs verwendet `assets/images/lumo_fox.png` (transparent),
/// fällt bei Asset-Fehlern auf [EmbeddedLumoFox] zurück.
class FreeLumoFox extends StatefulWidget {
  const FreeLumoFox({
    super.key,
    this.size = 220,
    this.mood = 'greet',
    this.onTap,
    this.message,
    this.autoDrift = true,
    this.draggable = true,
  });

  /// Höhe des Fuchses in logischen Pixeln (Breite ~ size * 0.55).
  final double size;

  /// Stimmungs-Tag. Beeinflusst Idle-Bewegung und Glow-Farbe.
  /// Erlaubt: 'greet', 'celebrate', 'comfort', 'think', 'wave', 'sleep'.
  final String mood;

  /// Callback bei Tap. Wird vor der internen Sprung-Animation gerufen.
  final VoidCallback? onTap;

  /// Optionale Sprechblase, die über dem Fuchs schwebt.
  final String? message;

  /// Soll der Fuchs autonom über den Bereich driften?
  final bool autoDrift;

  /// Darf das Kind den Fuchs ziehen?
  final bool draggable;

  @override
  State<FreeLumoFox> createState() => _FreeLumoFoxState();
}

class _FreeLumoFoxState extends State<FreeLumoFox>
    with TickerProviderStateMixin {
  // Idle-Atmung
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1850),
  )..repeat(reverse: true);

  // Wedeln/Schwingen
  late final AnimationController _sway = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat(reverse: true);

  // Glow / Aura
  late final AnimationController _aura = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  // Sprung-Animation (einmalig auf Tap)
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  // Drift über den Bereich
  Offset _drift = Offset.zero;
  Offset _driftTarget = Offset.zero;
  late final AnimationController _driftCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  final _rng = math.Random();

  // Drag-Position (relativ zum Bereich)
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoDrift) _scheduleNextDrift();
  }

  void _scheduleNextDrift() {
    if (!mounted) return;
    final newTarget = Offset(
      (_rng.nextDouble() - 0.5) * 60, // ±30 px
      (_rng.nextDouble() - 0.5) * 36, // ±18 px
    );
    setState(() {
      _drift = _driftTarget;
      _driftTarget = newTarget;
    });
    _driftCtrl
      ..duration = Duration(milliseconds: 4500 + _rng.nextInt(3000))
      ..forward(from: 0).whenComplete(_scheduleNextDrift);
  }

  @override
  void dispose() {
    _breath.dispose();
    _sway.dispose();
    _aura.dispose();
    _hop.dispose();
    _driftCtrl.dispose();
    super.dispose();
  }

  Color get _auraColor {
    switch (widget.mood) {
      case 'celebrate':
        return const Color(0xffffd166);
      case 'comfort':
        return const Color(0xff7dd3fc);
      case 'think':
        return const Color(0xffa78bfa);
      case 'wave':
        return const Color(0xffff9a5c);
      case 'sleep':
        return const Color(0xffcbd5e1);
      default:
        return const Color(0xffffb96b);
    }
  }

  void _handleTap() {
    widget.onTap?.call();
    _hop.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size * 0.62;
    final h = widget.size;

    return AnimatedBuilder(
      animation: Listenable.merge([_breath, _sway, _aura, _hop, _driftCtrl]),
      builder: (context, _) {
        // Idle-Atmen: 1.0 → 1.025
        final breathScale = 1 + 0.025 * _breath.value;

        // Sanftes Wiegen (Rotation winzig)
        final swayRot = math.sin(_sway.value * math.pi * 2) * 0.018;

        // Sprung: Sinus-Bogen, max 28 px hoch
        final hopY = -math.sin(_hop.value * math.pi) * 28;
        final hopScale = 1 + 0.04 * math.sin(_hop.value * math.pi);

        // Drift interpolieren
        final t = Curves.easeInOutSine.transform(_driftCtrl.value);
        final driftX = _drift.dx + (_driftTarget.dx - _drift.dx) * t;
        final driftY = _drift.dy + (_driftTarget.dy - _drift.dy) * t;

        // Drag dominiert, falls aktiv
        final tx = _isDragging ? _dragOffset.dx : driftX;
        final ty = _isDragging ? _dragOffset.dy : driftY + hopY;

        // Aura-Pulsation
        final aura = 0.55 + 0.45 * _aura.value;

        return Transform.translate(
          offset: Offset(tx, ty),
          child: Transform.rotate(
            angle: swayRot,
            child: Transform.scale(
              scale: breathScale * hopScale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _handleTap,
                onPanStart: widget.draggable ? (_) => setState(() => _isDragging = true) : null,
                onPanUpdate: widget.draggable
                    ? (d) => setState(() => _dragOffset += d.delta)
                    : null,
                onPanEnd: widget.draggable
                    ? (_) {
                        setState(() => _isDragging = false);
                        // Sanft zurück zur Ausgangs-Drift
                        _drift = _dragOffset;
                        _dragOffset = Offset.zero;
                      }
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Glow / Aura
                    Container(
                      width: w * 1.25,
                      height: h * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _auraColor.withOpacity(0.35 * aura),
                            blurRadius: 60,
                            spreadRadius: 14,
                          ),
                          BoxShadow(
                            color: Colors.white.withOpacity(0.55 * aura),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    // Bodenschatten
                    Positioned(
                      bottom: 6,
                      child: Container(
                        width: w * 0.78,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(99),
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withOpacity(0.22),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Fuchs-Bild
                    SizedBox(
                      width: w,
                      height: h,
                      child: Image.asset(
                        'assets/images/lumo_fox.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            EmbeddedLumoFox(size: widget.size),
                      ),
                    ),
                    // Sprechblase (optional)
                    if (widget.message != null && widget.message!.isNotEmpty)
                      Positioned(
                        top: -18,
                        child: _SpeechBubble(text: widget.message!),
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
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
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
