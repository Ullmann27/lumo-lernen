// ════════════════════════════════════════════════════════════════════════
// LUMO CARDS — Deck-Builder
// ════════════════════════════════════════════════════════════════════════
// Erzeugt das initiale Deck und mischt es. Reine Funktion, deterministisch
// per Seed im Test.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math';

import 'lumo_cards_models.dart';

/// Dekorative Symbole - wechseln pro Karte fuer optische Vielfalt.
/// Nur visuell, keine Regel-Bedeutung.
const List<String> _decoSymbols = [
  '⭐', // Stern
  '🌸', // Blume
  '📖', // Buch
  '✏️', // Stift
  '🌙', // Mond
  '❤️', // Herz
  '🐾', // Fuchs-Pfote
];

class LumoCardsDeck {
  /// Baut ein komplettes Lumo-Cards-Deck.
  ///
  /// Aufbau (insgesamt 112 Karten):
  ///   Pro Farbe (4 Farben):
  ///     - 1× 0er
  ///     - 2× von 1 bis 9 = 18 Karten
  ///     - 2× lumoJump (Skip)
  ///     - 2× starRain (Draw 2)
  ///     - 2× whirlwind (Reverse / bei 2P: Draw 1)
  ///     - 1× thinkPause (Lumo-USP: Lernfrage)
  ///   Schwarz (Wild):
  ///     - 4× colorMagic (Wild - Farbe waehlen)
  ///     - 4× superRain (Wild Draw 4 - Gegner zieht 4 + Farbe waehlen)
  ///
  /// Total pro Farbe: 26, x4 = 104, plus 8 schwarz = 112.
  static List<LumoCard> buildDeck({Random? rng}) {
    final cards = <LumoCard>[];
    var idCounter = 0;
    String nextId(String prefix) => '$prefix-${idCounter++}';
    String pickSymbol(int i) => _decoSymbols[i % _decoSymbols.length];

    for (final color in LumoCardColor.values) {
      // 1× 0er-Karte
      cards.add(LumoCard(
        id: nextId('num'),
        color: color,
        type: LumoCardType.number,
        number: 0,
        symbol: pickSymbol(0),
      ));
      // 2× Zahlen 1..9
      for (int n = 1; n <= 9; n++) {
        cards.add(LumoCard(
          id: nextId('num'),
          color: color,
          type: LumoCardType.number,
          number: n,
          symbol: pickSymbol(n),
        ));
        cards.add(LumoCard(
          id: nextId('num'),
          color: color,
          type: LumoCardType.number,
          number: n,
          symbol: pickSymbol(n + 1),
        ));
      }
      // 2× Skip / Draw 2 / Reverse
      for (int i = 0; i < 2; i++) {
        cards
          ..add(LumoCard(
              id: nextId('jump'), color: color, type: LumoCardType.lumoJump))
          ..add(LumoCard(
              id: nextId('rain'), color: color, type: LumoCardType.starRain))
          ..add(LumoCard(
              id: nextId('wind'), color: color, type: LumoCardType.whirlwind));
      }
      // 1× Lumo-USP: Denkpause
      cards.add(LumoCard(
          id: nextId('think'), color: color, type: LumoCardType.thinkPause));
    }
    // 4× Wild (colorMagic) und 4× Wild Draw 4 (superRain) - "schwarze"
    // Karten, color hier nur als Default fuer das Sortieren; visuell
    // schwarz mit 4 Quadranten.
    for (int i = 0; i < 4; i++) {
      cards
        ..add(LumoCard(
            id: nextId('wild'),
            color: LumoCardColor.orange, // Wert egal, Karte ist Wild
            type: LumoCardType.colorMagic))
        ..add(LumoCard(
            id: nextId('super'),
            color: LumoCardColor.orange,
            type: LumoCardType.superRain));
    }

    final r = rng ?? Random();
    cards.shuffle(r);
    return cards;
  }

  /// Zieht `count` Karten von oben des Decks. Liefert die gezogenen
  /// Karten und das verbleibende Deck.
  static (List<LumoCard>, List<LumoCard>) draw(
      List<LumoCard> deck, int count) {
    if (count <= 0) return (<LumoCard>[], deck);
    final take = count.clamp(0, deck.length);
    final drawn = deck.sublist(0, take);
    final rest = deck.sublist(take);
    return (drawn, rest);
  }

  /// Wenn der Ziehstapel leer ist: alle Karten aus dem Ablagestapel
  /// (ausser der obersten) zurueck in den Ziehstapel und mischen.
  static (List<LumoCard>, List<LumoCard>) reshuffle({
    required List<LumoCard> drawPile,
    required List<LumoCard> discardPile,
    Random? rng,
  }) {
    if (drawPile.isNotEmpty || discardPile.length <= 1) {
      return (drawPile, discardPile);
    }
    final top = discardPile.last;
    final newDraw = discardPile.sublist(0, discardPile.length - 1)
      ..shuffle(rng ?? Random());
    return (newDraw, <LumoCard>[top]);
  }
}
