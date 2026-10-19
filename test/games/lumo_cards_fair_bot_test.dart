import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/game_world.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_bot_policy.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';

const top = LumoCard(
    id: 'discard', type: LumoCardType.number, color: LumoCardColor.blue, number: 3);
const own = <LumoCard>[
  LumoCard(id: 'a', type: LumoCardType.number,
      color: LumoCardColor.blue, number: 4),
  LumoCard(id: 'b', type: LumoCardType.number,
      color: LumoCardColor.blue, number: 8),
  LumoCard(id: 'c', type: LumoCardType.number,
      color: LumoCardColor.green, number: 3),
  LumoCard(id: 'd', type: LumoCardType.starRain,
      color: LumoCardColor.blue),
  LumoCard(id: 'e', type: LumoCardType.colorMagic,
      color: LumoCardColor.orange),
  LumoCard(id: 'f', type: LumoCardType.number,
      color: LumoCardColor.green, number: 7),
];

void main() {
  group('Fairer Lumo-Cards-Bot', () {
    test('Across school years 1–4 every chosen move is genuinely legal', () {
      for (var grade = 1; grade <= 4; grade++) {
        for (var seed = 0; seed < 150; seed++) {
          final chosen = LumoCardsBotPolicy.select(
            ownHand: own, topCard: top,
            selectedColor: LumoCardColor.blue,
            opponentCardCount: 2, grade: grade, rng: Random(seed),
          )!;
          expect(own.contains(chosen), isTrue);
          expect(LumoCardsRules.isPlayable(
            card: chosen, topCard: top,
            selectedColor: LumoCardColor.blue), isTrue);
        }
      }
    });

    test('The child can never be forced to lose by a predetermined result', () {
      final kinds = <String>{};
      for (var seed = 0; seed < 150; seed++) {
        final chosen = LumoCardsBotPolicy.select(
          ownHand: own, topCard: top,
          selectedColor: LumoCardColor.blue,
          opponentCardCount: 2, grade: 4, rng: Random(seed));
        kinds.add(chosen!.id);
      }
      expect(kinds.length, greaterThan(1),
          reason: 'Same visible tactical position must admit different legal moves');
    });

    test('Hidden cards cannot influence a move: policy only takes public count', () {
      final first = LumoCardsBotPolicy.select(
        ownHand: own, topCard: top,
        selectedColor: LumoCardColor.blue, opponentCardCount: 3,
        grade: 3, rng: Random(44),
      );
      final second = LumoCardsBotPolicy.select(
        ownHand: own, topCard: top,
        selectedColor: LumoCardColor.blue, opponentCardCount: 3,
        grade: 3, rng: Random(44),
      );
      expect(first!.id, second!.id);
    });

    test('A blocked bot draws rather than breaking the card rules', () {
      final blocked = [
        const LumoCard(id: 'other', type: LumoCardType.number,
            color: LumoCardColor.green, number: 7),
      ];
      expect(LumoCardsBotPolicy.select(
        ownHand: blocked, topCard: top, grade: 2,
        selectedColor: LumoCardColor.blue,
        opponentCardCount: 1, rng: Random(3),
      ), isNull);
    });

    test('Color ties vary, yet nonwild colors in own hand are preferred', () {
      final colors = <LumoCardColor>{};
      for (var seed = 0; seed < 60; seed++) {
        colors.add(LumoCardsBotPolicy.selectColor(
          ownHand: own, rng: Random(seed)));
      }
      expect(colors, contains(LumoCardColor.blue));
      expect(colors.length, greaterThan(1));
      expect(colors, isNot(contains(LumoCardColor.orange)));
    });

    test('Grade-aware difficulty increases without making opponent infallible', () {
      expect(LumoCardsBotPolicy.answerProbability(1), lessThan(
          LumoCardsBotPolicy.answerProbability(2)));
      expect(LumoCardsBotPolicy.answerProbability(2), lessThan(
          LumoCardsBotPolicy.answerProbability(3)));
      expect(LumoCardsBotPolicy.answerProbability(3), lessThan(
          LumoCardsBotPolicy.answerProbability(4)));
      expect(LumoCardsBotPolicy.answerProbability(4), lessThan(1.0));
    });

    test('Unfinished Bauwelt stays visible but not playable; other games remain', () {
      expect(GameCatalog.byId(GameId.build).availability,
          GameAvailability.comingSoon);
      expect(GameCatalog.byId(GameId.cards).availability,
          GameAvailability.playable);
      expect(GameCatalog.byId(GameId.kart).availability,
          GameAvailability.playable);
    });
  });
}
