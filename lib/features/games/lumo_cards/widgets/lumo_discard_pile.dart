// ════════════════════════════════════════════════════════════════════════
// LUMO DISCARD PILE — Ablagestapel mit aktueller Top-Karte
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import 'lumo_playing_card.dart';

class LumoDiscardPile extends StatelessWidget {
  const LumoDiscardPile({
    super.key,
    required this.topCard,
    required this.selectedColor,
  });

  final LumoCard topCard;
  final LumoCardColor selectedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 96,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Kleiner Stapel-Effekt im Hintergrund.
              Positioned(
                left: -3,
                top: 4,
                child: Container(
                  width: 92,
                  height: 132,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5B07A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              LumoPlayingCard(card: topCard),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _colorOf(selectedColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _labelOf(selectedColor),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF7C2D12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Color _colorOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return const Color(0xFFFF4D4F); // Rot
      case LumoCardColor.purple:
        return const Color(0xFFFFC83D); // Gelb
      case LumoCardColor.blue:
        return const Color(0xFF2D7BFF); // Blau
      case LumoCardColor.green:
        return const Color(0xFF35C759); // Gruen
    }
  }

  static String _labelOf(LumoCardColor c) {
    switch (c) {
      case LumoCardColor.orange:
        return 'Orange';
      case LumoCardColor.purple:
        return 'Lila';
      case LumoCardColor.blue:
        return 'Blau';
      case LumoCardColor.green:
        return 'Gruen';
    }
  }
}
