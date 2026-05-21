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
  /// Aufbau (insgesamt 76 Karten):
  ///   - 4 Farben × Zahlen 1..9 zweimal = 4 × 18 = 72 Zahlenkarten
  ///   - colorMagic 4× (eine je Farbe als Default-Anzeige)
  ///
  /// Wir lassen Lumo-Sprung, Sternenregen, Wirbelwind und Denkpause
  /// jeweils pro Farbe 1× zu - insgesamt also +16 Spezialkarten -> 92.
  ///
  /// Hinweis: das ist BEWUSST kleiner als das volle Mattel-UNO-Deck und
  /// hat andere Karten-Verteilung. Eigenes Lumo-Spiel.
  static List<LumoCard> buildDeck({Random? rng}) {
    final cards = <LumoCard>[];
    var idCounter = 0;
    String nextId(String prefix) => '$prefix-${idCounter++}';
    String pickSymbol(int i) => _decoSymbols[i % _decoSymbols.length];

    for (final color in LumoCardColor.values) {
      // Zahlenkarten 1..9 jeweils zweimal.
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
      // Spezialkarten je Farbe einmal.
      cards
        ..add(LumoCard(
            id: nextId('jump'), color: color, type: LumoCardType.lumoJump))
        ..add(LumoCard(
            id: nextId('rain'), color: color, type: LumoCardType.starRain))
        ..add(LumoCard(
            id: nextId('wind'), color: color, type: LumoCardType.whirlwind))
        ..add(LumoCard(
            id: nextId('think'), color: color, type: LumoCardType.thinkPause));
      // Farbzauber-Karte (Wild) je Farbe als Default-Anzeige - bei Wahl
      // setzt der Spieler die neue selectedColor.
      cards.add(LumoCard(
          id: nextId('wild'), color: color, type: LumoCardType.colorMagic));
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
