import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_deck.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';

void main() {
  group('LumoCardsDeck', () {
    test('Deck hat erwartete Anzahl Karten (112)', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      // Pro Farbe: 1 (0er) + 18 (1-9 zweimal) + 6 (Skip/Draw2/Reverse je 2x)
      // + 1 (Denkpause) = 26. x4 = 104. Plus 8 schwarz (Wild + WildDraw4).
      expect(deck.length, 112);
    });

    test('Deck enthaelt 19 Zahlenkarten pro Farbe (1x 0er + 2x 1-9)', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      for (final color in LumoCardColor.values) {
        final numberCount = deck
            .where((c) => c.color == color && c.type == LumoCardType.number)
            .length;
        expect(numberCount, 19,
            reason: 'Farbe ${color.name} sollte 19 Zahlenkarten haben');
        final zeros = deck
            .where((c) =>
                c.color == color &&
                c.type == LumoCardType.number &&
                c.number == 0)
            .length;
        expect(zeros, 1, reason: '${color.name} sollte 1 Nuller haben');
      }
    });

    test('Deck enthaelt 4 colorMagic (Wild) gesamt', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      final wildCount = deck
          .where((c) => c.type == LumoCardType.colorMagic)
          .length;
      expect(wildCount, 4);
    });

    test('Deck enthaelt 4 superRain (Wild Draw 4) gesamt', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      final superCount = deck
          .where((c) => c.type == LumoCardType.superRain)
          .length;
      expect(superCount, 4);
    });

    test('Deck enthaelt 2 Skip/Draw2/Reverse pro Farbe + 1 Denkpause', () {
      final deck = LumoCardsDeck.buildDeck(rng: Random(42));
      for (final color in LumoCardColor.values) {
        for (final type in [
          LumoCardType.lumoJump,
          LumoCardType.starRain,
          LumoCardType.whirlwind,
        ]) {
          final count =
              deck.where((c) => c.color == color && c.type == type).length;
          expect(count, 2, reason: '${color.name} ${type.name}');
        }
        final thinkCount = deck
            .where((c) =>
                c.color == color && c.type == LumoCardType.thinkPause)
            .length;
        expect(thinkCount, 1, reason: '${color.name} thinkPause');
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
