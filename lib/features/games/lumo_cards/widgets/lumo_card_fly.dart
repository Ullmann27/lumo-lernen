// ════════════════════════════════════════════════════════════════════════
// LUMO CARD FLY — animierter Karten-Flug von Hand zur Discard-Pile
// ════════════════════════════════════════════════════════════════════════
// Tier 6 Karten-Polish (Heinz 2026-05-25): wenn das Kind eine Karte
// tippt, fliegt eine sichtbare Kopie von der Tap-Position zur Discard-
// Pile - mit Bezier-Bogen, leichter Rotation und sanftem easeOut.
//
// Architektur:
//   - Overlay-Widget (im Stack der Screen) mit IgnorePointer
//   - SingleTickerProviderStateMixin, EIN Controller, dispose-stabil
//   - Bezier-Kurve: Steuerpunkt liegt mittig oberhalb der Verbindungs-
//     linie -> Karte schwingt nach oben, dann auf den Stapel
//   - onDone-Callback nach Animation: Parent kann den Fly-State leeren
//   - Render-Card ist eine LumoPlayingCard (gleiche Optik wie in Hand)
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import 'lumo_playing_card.dart';

class LumoCardFly extends StatefulWidget {
  const LumoCardFly({
    super.key,
    required this.card,
    required this.start,
    required this.end,
    this.duration = const Duration(milliseconds: 360),
    this.cardWidth = 96,
    this.cardHeight = 140,
    this.onDone,
  });

  final LumoCard card;

  /// Globale Start-Position (Kartenzentrum), z.B. Tap-Position des Kindes.
  final Offset start;

  /// Globale End-Position (Zentrum der Discard-Pile).
  final Offset end;

  final Duration duration;
  final double cardWidth;
  final double cardHeight;
  final VoidCallback? onDone;

  @override
  State<LumoCardFly> createState() => _LumoCardFlyState();
}

class _LumoCardFlyState extends State<LumoCardFly>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _completedSignaled = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _ctrl.forward().whenComplete(() {
      if (_completedSignaled || !mounted) return;
      _completedSignaled = true;
      widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // WICHTIG: kein IgnorePointer / kein RenderObjectWidget zwischen
    // Positioned und dem umschliessenden Stack des Screens! Positioned
    // muss seinen Stack-Ancestor finden koennen, nur durch reine
    // Stateless/Stateful-Widgets hindurch (AnimatedBuilder ist OK).
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        // Quadratische Bezier: P(t) = (1-t)^2*A + 2(1-t)*t*C + t^2*B
        // Steuerpunkt C liegt mittig oberhalb der direkten Linie -
        // 'oberhalb' im Sinn von kleiner Y (Screen-Koord). Kurzer
        // Bogen = ca. 22% der Wegstrecke nach oben.
        final mid = Offset(
          (widget.start.dx + widget.end.dx) / 2,
          (widget.start.dy + widget.end.dy) / 2 -
              (widget.start - widget.end).distance * 0.22,
        );
        final omt = 1 - t;
        final pos = Offset(
          omt * omt * widget.start.dx +
              2 * omt * t * mid.dx +
              t * t * widget.end.dx,
          omt * omt * widget.start.dy +
              2 * omt * t * mid.dy +
              t * t * widget.end.dy,
        );
        // Slight scale-down beim Landen + leichte Rotation fuer 'Wurf'-
        // Optik. Skalierung 1.0 -> 0.85, Rotation +0.5 rad ueber den
        // Bogen.
        final scale = 1.0 - 0.15 * t;
        final angle = 0.5 * t;
        return Positioned(
          left: pos.dx - widget.cardWidth / 2,
          top: pos.dy - widget.cardHeight / 2,
          child: IgnorePointer(
            child: Transform.rotate(
              angle: angle,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: 1.0 - 0.15 * t,
                  child: SizedBox(
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    child: LumoPlayingCard(
                      card: widget.card,
                      width: widget.cardWidth,
                      height: widget.cardHeight,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
