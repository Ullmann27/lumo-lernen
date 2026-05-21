// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYER HAND — die Karten des aktiven Spielers
// ════════════════════════════════════════════════════════════════════════
// Heinz Bug 2026-05-21: Hand wurde nicht angezeigt + ErrorWidget zeigte
// 'Hier hat Lumo eine Pause gebraucht'. Ursache: komplexe Faecher-
// Transform mit int/double-Mix + math.pow konnte beim Render crashen.
//
// Jetzt: einfache horizontale Reihe mit leichter Ueberlappung. Robust,
// rendert immer. Premium-Optik kommt aus der LumoPlayingCard selber.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../lumo_cards_models.dart';
import '../lumo_cards_rules.dart';
import 'lumo_playing_card.dart';

class LumoPlayerHand extends StatelessWidget {
  const LumoPlayerHand({
    super.key,
    required this.cards,
    required this.topCard,
    required this.selectedColor,
    required this.onCardTap,
    this.height = 162,
  });

  final List<LumoCard> cards;
  final LumoCard topCard;
  final LumoCardColor selectedColor;
  final void Function(LumoCard) onCardTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            'Keine Karten - du gewinnst gleich!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF7C2D12),
            ),
          ),
        ),
      );
    }

    // Overlap-Faktor je nach Anzahl Karten - bei vielen Karten staerker
    // ueberlappen damit sie alle reinpassen, sonst nur leicht.
    final double overlap = cards.length > 8 ? -36.0 : -16.0;

    return SizedBox(
      height: height,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < cards.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : overlap),
                child: _buildHandCard(cards[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandCard(LumoCard card) {
    final playable = LumoCardsRules.isPlayable(
      card: card,
      topCard: topCard,
      selectedColor: selectedColor,
    );
    return LumoPlayingCard(
      card: card,
      playable: playable,
      dimmed: !playable,
      onTap: playable ? () => onCardTap(card) : null,
    );
  }
}
