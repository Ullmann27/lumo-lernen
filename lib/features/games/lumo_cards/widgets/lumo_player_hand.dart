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

    // Heinz Crash 2026-05-22: 'padding.isNonNegative is not true'.
    // Ursache: EdgeInsets.only(left: overlap) mit NEGATIVEM overlap zum
    // Ueberlappen. Negatives Padding ist in Flutter verboten.
    // Fix: Stack + Positioned mit fester Gesamtbreite. Karten ueberlappen
    // sauber ueber left-Offset (step = Kartenbreite + overlap), kein
    // negatives Padding mehr. Vertikal zentriert via top/bottom + Center.
    const double cardW = 96.0;
    final double step = cardW + overlap; // overlap negativ -> step < cardW
    final double totalW =
        cards.isEmpty ? 0 : (cards.length - 1) * step + cardW;

    // Premium-Faecher: jede Karte leicht rotiert (Mitte gerade, aussen
    // gekippt) + aeussere Karten minimal tiefer fuer einen Bogen. Alle
    // Werte sauber als double -> kein int/double-Crash wie frueher.
    final int n = cards.length;
    final double mid = (n - 1) / 2.0;

    return SizedBox(
      height: height,
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: totalW,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = 0; i < cards.length; i++)
                  Positioned(
                    left: i * step,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Transform.translate(
                        // quadratischer Bogen: aeussere Karten leicht tiefer
                        offset: Offset(0, ((i - mid) * (i - mid)) * 1.4),
                        child: Transform.rotate(
                          // ~3.4 Grad pro Karte ab der Mitte
                          angle: (i - mid) * 0.06,
                          alignment: Alignment.bottomCenter,
                          child: KeyedSubtree(
                            key: ValueKey('hand-${cards[i].id}'),
                            child: _buildHandCard(cards[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
