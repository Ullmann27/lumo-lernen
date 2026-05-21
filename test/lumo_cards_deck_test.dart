import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_deck.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';

void main() {
  group('LumoCardsDeck', () {
    test('Deck hat erwartete Anzahl Karten', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      // 4 Farben × (18 Zahlen + 4 Spezial + 1 Wild) = 4 × 23 = 92
      expect(deck.length, 92);
    });

    test('Deck enthaelt 18 Zahlenkarten pro Farbe', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      for (final color in LumoCardColor.values) {
        final numberCount = deck
            .where((c) => c.color == color && c.type == LumoCardType.number)
            .length;
        expect(numberCount, 18,
            reason: 'Farbe ${color.name} sollte 18 Zahlen haben');
      }
    });

    test('Deck enthaelt 1 colorMagic-Karte pro Farbe', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      for (final color in LumoCardColor.values) {
        final wildCount = deck
            .where((c) => c.color == color && c.type == LumoCardType.colorMagic)
            .length;
        expect(wildCount, 1);
      }
    });

    test('Deck enthaelt 1 Spezialkarte pro Typ und Farbe', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      for (final color in LumoCardColor.values) {
        for (final type in [
          LumoCardType.lumoJump,
          LumoCardType.starRain,
          LumoCardType.whirlwind,
          LumoCardType.thinkPause,
        ]) {
          final count =
              deck.where((c) => c.color == color && c.type == type).length;
          expect(count, 1, reason: '${color.name} ${type.name}');
        }
      }
    });

    test('Alle Karten haben eindeutige IDs', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      final ids = deck.map((c) => c.id).toSet();
      expect(ids.length, deck.length);
    });

    test('Deck ist gemischt (zwei Decks mit unterschiedlichem Seed weichen ab)',
        () {
      final a = LumoCardsDeck.buildDeck(rng: Random(1));
      final b = LumoCardsDeck.buildDeck(rng: Random(2));
      // Mindestens an einer Stelle muss sich die Reihenfolge unterscheiden.
      var diff = 0;
      for (int i = 0; i < a.length; i++) {
        if (a[i].id != b[i].id) diff++;
      }
      expect(diff, greaterThan(0));
    });

    test('draw zieht korrekte Anzahl', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      final (drawn, rest) = LumoCardsDeck.draw(deck, 7);
      expect(drawn.length, 7);
      expect(rest.length, deck.length - 7);
    });

    test('reshuffle bei leerem drawPile holt Discard zurueck', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      final discard = deck.take(10).toList();
      final (newDraw, newDiscard) = LumoCardsDeck.reshuffle(
        drawPile: const [],
        discardPile: discard,
        rng: Random(99),
      );
      // 9 zurueck-gemischt, 1 (top) bleibt in Discard
      expect(newDraw.length, 9);
      expect(newDiscard.length, 1);
      expect(newDiscard.single.id, discard.last.id);
    });
  });
}
