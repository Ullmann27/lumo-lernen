import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_deck.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_save.dart';

void main() {
  LumoCardsGameState sample() {
    final deck = LumoCardsDeck.buildDeck(rng: Random(1));
    final (h1, r1) = LumoCardsDeck.draw(deck, 7);
    final (h2, r2) = LumoCardsDeck.draw(r1, 7);
    return LumoCardsGameState(
      players: [
        LumoPlayer(id: 'p1', name: 'Du', hand: h1),
        LumoPlayer(
            id: 'p2', name: 'Lumo', hand: h2, kind: LumoPlayerKind.bot),
      ],
      currentPlayerIndex: 0,
      drawPile: r2.sublist(1),
      discardPile: [r2.first],
      selectedColor: LumoCardColor.blue,
      phase: GamePhase.playing,
    );
  }

  test('Roundtrip erhaelt Haende, Stapel, Farbe', () {
    final s = sample();
    final back = LumoCardsSave.decode(LumoCardsSave.encode(s))!;
    expect(back.players[0].hand, s.players[0].hand);
    expect(back.players[1].isBot, isTrue);
    expect(back.drawPile.length, s.drawPile.length);
    expect(back.topCard, s.topCard);
    expect(back.selectedColor, LumoCardColor.blue);
    expect(LumoCardsSave.isSavable(back), isTrue);
  });

  test('Kaputte Daten ergeben null', () {
    expect(LumoCardsSave.decode('kaputt'), isNull);
    expect(LumoCardsSave.decode('{"players":[]}'), isNull);
  });

  test('Bot-Zug und Spielende werden nicht gespeichert', () {
    final s = sample();
    expect(LumoCardsSave.isSavable(s.copyWith(currentPlayerIndex: 1)), isFalse);
    expect(LumoCardsSave.isSavable(s.copyWith(phase: GamePhase.gameOver)),
        isFalse);
  });
}
