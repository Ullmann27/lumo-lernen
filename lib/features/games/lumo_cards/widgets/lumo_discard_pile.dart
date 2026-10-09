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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1F4C86), Color(0xFF061839)],
                    ),
                    border: Border.all(color: const Color(0xFF53DDFD)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              // Lege-Animation: bei jeder neuen Top-Karte (ID-Wechsel)
              // bekommt der TweenAnimationBuilder einen frischen Key und
              // animiert die Karte 0->1 mit Slide-von-oben + Scale +
              // Opacity (easeOutBack). Wirkt wie "Karte schwebt rein und
              // klatscht auf den Tisch".
              // Sicher, kein AnimatedSwitcher (der war frueher die
              // Crash-Quelle).
              TweenAnimationBuilder<double>(
                key: ValueKey('discard-${topCard.id}'),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (_, t, child) {
                  // Slide: faengt 70 px ueber dem Ziel an, kommt runter.
                  final dy = (1 - t) * -70;
                  // Scale 0.6 -> 1.0 mit easeOutBack-Schwung
                  final scale = 0.6 + t * 0.4;
                  // Drehung leicht rotierend reinkommen
                  final rot = (1 - t) * -0.18;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: rot,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: child,
                        ),
                      ),
                    ),
                  );
                },
                child: LumoPlayingCard(card: topCard),
              ),
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
                boxShadow: [
                  BoxShadow(
                    color: _colorOf(selectedColor).withOpacity(0.60),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _labelOf(selectedColor),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF7FBFF),
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
        return 'Rot';
      case LumoCardColor.purple:
        return 'Gelb';
      case LumoCardColor.blue:
        return 'Blau';
      case LumoCardColor.green:
        return 'Grün';
    }
  }
}
