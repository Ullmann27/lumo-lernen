// ════════════════════════════════════════════════════════════════════════
// LUMO CARD FLIP — 3D-Aufdeck-Animation um die Y-Achse
// ════════════════════════════════════════════════════════════════════════
// Tier 4 aus dem approvten Plan (Heinz 2026-05-23).
//
// Ein-Schuss-Animation: Karte dreht sich um die Y-Achse, in der Mitte
// (Edge-On) wird das Kind-Widget ausgetauscht (Back -> Front oder
// umgekehrt). Wirkt wie eine echte umgedrehte Spielkarte.
//
// Verwendung:
//
//   LumoCardFlip(
//     front: LumoPlayingCard(card: topCard),
//     back:  LumoPlayingCard(card: cardBack, faceDown: true),
//     startWithBack: true,   // erst Rueckseite, dann flip zur Front
//     duration: Duration(milliseconds: 720),
//   )
//
// Sicher: ein einziger AnimationController, dispose-stabil. Kein
// AnimatedSwitcher (das hat in frueheren Builds Crashes verursacht).
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/material.dart';

class LumoCardFlip extends StatefulWidget {
  const LumoCardFlip({
    super.key,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 720),
    this.startWithBack = true,
    this.autoplay = true,
  });

  /// Das Widget das am Ende der Animation sichtbar ist (z.B. die echte
  /// Karte).
  final Widget front;

  /// Das Widget das am Anfang sichtbar ist (z.B. Card-Back).
  final Widget back;

  /// Wenn true: bei mount steht die Rueckseite, dann animiert zur Front.
  /// Wenn false: bei mount steht die Front, keine Animation.
  final bool startWithBack;

  /// Wenn true: Animation laeuft sofort beim Mount.
  /// Wenn false: Animation muss manuell ausgeloest werden (via Key + Rebuild).
  final bool autoplay;

  final Duration duration;

  @override
  State<LumoCardFlip> createState() => _LumoCardFlipState();
}

class _LumoCardFlipState extends State<LumoCardFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.startWithBack && widget.autoplay) {
      _ctrl.forward();
    } else {
      _ctrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeInOutCubic.transform(_ctrl.value);
        // Erste Haelfte (0 - 0.5): Rueckseite dreht 0 -> +pi/2 (zur Edge).
        // Zweite Haelfte (0.5 - 1): Vorderseite dreht von -pi/2 -> 0.
        // Genau bei t=0.5 ist die Karte 'auf der Kante' und wir tauschen
        // das Kind aus -> wirkt wie ein echter Flip.
        final showBack = t < 0.5;
        final angle = showBack ? t * math.pi : (t - 1) * math.pi;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: showBack ? widget.back : widget.front,
        );
      },
    );
  }
}
