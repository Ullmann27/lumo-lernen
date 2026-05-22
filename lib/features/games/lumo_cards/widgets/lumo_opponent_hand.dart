// ════════════════════════════════════════════════════════════════════════
// LUMO OPPONENT HAND — Karten des Gegners als verdeckter Faecher oben
// ════════════════════════════════════════════════════════════════════════
// Heinz 2026-05-22: 'Vom Gegner sollte man auch [die Karten] sehen'.
//
// Eine Reihe von verdeckten Karten-Rueckseiten oben am Bildschirm,
// leicht gefaechert. Die Anzahl entspricht der Hand-Groesse des
// Gegners. Wir zeigen maximal 9 Karten visuell, bei mehr nur "+N".
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import 'lumo_playing_card.dart';
import '../lumo_cards_models.dart';

class LumoOpponentHand extends StatelessWidget {
  const LumoOpponentHand({
    super.key,
    required this.cardCount,
    this.cardWidth = 56,
    this.cardHeight = 80,
  });

  final int cardCount;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    if (cardCount <= 0) {
      return SizedBox(height: cardHeight);
    }
    final visible = cardCount.clamp(0, 9);
    final extra = cardCount - visible;
    final overlap = visible > 5 ? -28.0 : -14.0;
    final dummyCard = _dummyCard;

    return SizedBox(
      height: cardHeight + 8,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < visible; i++)
              Padding(
                key: ValueKey('opp-$i'),
                padding: EdgeInsets.only(left: i == 0 ? 0 : overlap),
                child: LumoPlayingCard(
                  card: dummyCard,
                  faceDown: true,
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
            if (extra > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 1),
                ),
                child: Text(
                  '+$extra',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Dummy-Karte fuer das Rueckseiten-Rendering. Die LumoPlayingCard
  // braucht ein card-Objekt, das wir hier aber nie auswerten (faceDown=true).
  static const LumoCard _dummyCard = LumoCard(
    id: '__opp_back__',
    color: LumoCardColor.orange,
    type: LumoCardType.number,
    number: 0,
  );
}
