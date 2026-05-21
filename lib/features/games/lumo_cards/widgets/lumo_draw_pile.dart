// ════════════════════════════════════════════════════════════════════════
// LUMO DRAW PILE — Ziehstapel
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import 'lumo_playing_card.dart';

class LumoDrawPile extends StatelessWidget {
  const LumoDrawPile({
    super.key,
    required this.cardsLeft,
    required this.onDraw,
  });

  final int cardsLeft;
  final VoidCallback? onDraw;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pseudo-Stapel: 3 ueberlagerte Rueckseiten.
        SizedBox(
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
                    onTap: onDraw,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$cardsLeft Karten',
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
