// ════════════════════════════════════════════════════════════════════════
// LUMO DRAW PILE — Ziehstapel mit Pulse-Animation beim Ziehen
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-05-22: 'Animationen'. Bei jedem Karten-Ziehen ruckelt der
// Stapel kurz - visuelles Feedback dass eine Karte abgezogen wurde.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import 'lumo_playing_card.dart';

class LumoDrawPile extends StatefulWidget {
  const LumoDrawPile({
    super.key,
    required this.cardsLeft,
    required this.onDraw,
  });

  final int cardsLeft;
  final VoidCallback? onDraw;

  @override
  State<LumoDrawPile> createState() => _LumoDrawPileState();
}

class _LumoDrawPileState extends State<LumoDrawPile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late int _prevCardsLeft;

  @override
  void initState() {
    super.initState();
    _prevCardsLeft = widget.cardsLeft;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void didUpdateWidget(LumoDrawPile old) {
    super.didUpdateWidget(old);
    // Nur bei Abnahme animieren (eine Karte wurde gezogen).
    if (widget.cardsLeft < _prevCardsLeft) {
      _pulseCtrl.forward(from: 0.0);
    }
    _prevCardsLeft = widget.cardsLeft;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pseudo-Stapel: 3 ueberlagerte Rueckseiten.
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) {
            // Die oberste Karte hebt sich kurz, kippt leicht, kommt zurueck.
            final t = _pulseCtrl.value;
            // Bell-curve: 0 -> 1 -> 0
            final lift = (t < 0.5 ? t * 2 : (1 - t) * 2);
            final dy = -lift * 14; // bis 14 px hoch
            final rot = -lift * 0.10; // leichte Drehung links
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.rotate(angle: rot, child: child),
            );
          },
          child: SizedBox(
            width: 96,
            height: 140,
            child: Stack(
              children: [
                for (int i = 0; i < 3; i++)
                  Positioned(
                    left: i * 2.0,
                    top: i * 2.0,
                    child: const LumoPlayingCard(
                      card: LumoCard(
                        id: 'back',
                        color: LumoCardColor.orange,
                        type: LumoCardType.number,
                      ),
                      faceDown: true,
                    ),
                  ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onDraw,
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${widget.cardsLeft} Karten',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
          ),
        ),
      ],
    );
  }
}
