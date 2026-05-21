// ════════════════════════════════════════════════════════════════════════
// LUMO PLAYER HAND — die Karten des aktiven Spielers
// ════════════════════════════════════════════════════════════════════════
// Faecher-Layout: Karten leicht ueberlappend. Bei sehr vielen Karten
// scrollt es horizontal. Auf Tap wird per Callback an den Controller
// uebergeben.
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
  });

  final List<LumoCard> cards;
  final LumoCard topCard;
  final LumoCardColor selectedColor;
  final void Function(LumoCard) onCardTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'Keine Karten - du gewinnst gleich!',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    // Overlap-Faktor je nach Anzahl Karten - bei vielen Karten staerker
    // ueberlappen, sonst gefaechert.
    final overlap = cards.length > 8 ? -36.0 : -18.0;

    return SizedBox(
      height: 160,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
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
