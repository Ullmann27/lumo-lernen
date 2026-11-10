import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_bot_policy.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_deck.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';

const _top = LumoCard(
  id: 'top',
  color: LumoCardColor.blue,
  type: LumoCardType.number,
  number: 3,
);

LumoCard _card(
  String id,
  LumoCardColor color,
  LumoCardType type, [
  int? number,
]) => LumoCard(id: id, color: color, type: type, number: number);

LumoCard? _choose(
  List<LumoCard> hand, {
  LumoCardsDifficulty level = LumoCardsDifficulty.expert,
  LumoCardsStyle style = LumoCardsStyle.planner,
  int opponent = 6,
  int seed = 1,
  int grade = 1,
}) => LumoCardsBotPolicy.select(
  ownHand: hand,
  topCard: _top,
  selectedColor: _top.color,
  opponentCardCount: opponent,
  grade: grade,
  rng: Random(seed),
  difficulty: level,
  style: style,
);

void main() {
  test(
    'Expert finds a cross-colour Skip chain without seeing hidden cards',
    () {
      final hand = [
        _card('number', LumoCardColor.blue, LumoCardType.number, 9),
        _card('jump-blue', LumoCardColor.blue, LumoCardType.lumoJump),
        _card('jump-green', LumoCardColor.green, LumoCardType.lumoJump),
        _card('green', LumoCardColor.green, LumoCardType.number, 7),
      ];
      for (var seed = 0; seed < 25; seed++) {
        expect(_choose(hand, seed: seed)!.id, 'jump-blue');
      }
    },
  );

  test('Styles make different legal plans with identical cards', () {
    final hand = [
      _card('green-three', LumoCardColor.green, LumoCardType.number, 3),
      _card('green-four', LumoCardColor.green, LumoCardType.number, 4),
      _card('green-five', LumoCardColor.green, LumoCardType.number, 5),
      _card('green-six', LumoCardColor.green, LumoCardType.number, 6),
      _card('rain', LumoCardColor.blue, LumoCardType.starRain),
      _card('blue-nine', LumoCardColor.blue, LumoCardType.number, 9),
    ];
    expect(_choose(hand, style: LumoCardsStyle.collector)!.id, 'green-three');
    expect(_choose(hand, style: LumoCardsStyle.adventurous)!.id, 'rain');
  });

  test('Expert reacts to public one-card danger using actual draw effects', () {
    final hand = [
      _card('number', LumoCardColor.blue, LumoCardType.number, 9),
      _card('blue', LumoCardColor.blue, LumoCardType.number, 4),
      _card('wild', LumoCardColor.orange, LumoCardType.superRain),
    ];
    expect(_choose(hand, opponent: 1)!.id, 'wild');
    expect(_choose(hand, opponent: 7)!.id, 'number');
  });

  test('Playing difficulty is separate from the school year', () {
    final hand = [
      _card('number', LumoCardColor.blue, LumoCardType.number, 9),
      _card('rain', LumoCardColor.blue, LumoCardType.starRain),
      _card('wild', LumoCardColor.orange, LumoCardType.colorMagic),
    ];
    for (final level in LumoCardsDifficulty.values) {
      for (var seed = 0; seed < 60; seed++) {
        expect(
          _choose(hand, level: level, grade: 1, seed: seed),
          _choose(hand, level: level, grade: 4, seed: seed),
        );
      }
    }
  });

  test(
    'All nine configurations finish real rules-engine rounds without losing cards',
    () {
      for (final level in LumoCardsDifficulty.values) {
        for (final style in LumoCardsStyle.values) {
          for (var seed = 0; seed < 12; seed++) {
            final result = _round(seed, level, style);
            expect(
              result.phase,
              GamePhase.gameOver,
              reason: '${level.name}/${style.name}/seed $seed',
            );
            expect(result.players[result.winnerIndex!].hand, isEmpty);
          }
        }
      }
    },
  );
}

LumoCardsGameState _round(
  int seed,
  LumoCardsDifficulty level,
  LumoCardsStyle style,
) {
  final rng = Random(seed);
  final deck = LumoCardsDeck.buildDeck(rng: rng);
  final topIndex = deck.indexWhere((card) => !card.isWild, 14);
  final top = deck.removeAt(topIndex);
  var state = LumoCardsGameState(
    players: [
      LumoPlayer(id: 'one', name: 'Eins', hand: deck.sublist(0, 7)),
      LumoPlayer(id: 'two', name: 'Zwei', hand: deck.sublist(7, 14)),
    ],
    currentPlayerIndex: seed % 2,
    drawPile: deck.sublist(14),
    discardPile: [top],
    selectedColor: top.color,
    phase: GamePhase.playing,
  );
  for (var step = 0; step < 2500 && state.phase != GamePhase.gameOver; step++) {
    switch (state.phase) {
      case GamePhase.playing:
        final card = LumoCardsBotPolicy.select(
          ownHand: state.currentPlayer.hand,
          topCard: state.topCard!,
          selectedColor: state.selectedColor,
          opponentCardCount: state.otherPlayer.hand.length,
          grade: 2,
          rng: rng,
          difficulty: level,
          style: style,
        );
        if (card != null) {
          expect(
            state.currentPlayer.hand.any((held) => identical(held, card)),
            isTrue,
          );
          expect(
            LumoCardsRules.isPlayable(
              card: card,
              topCard: state.topCard!,
              selectedColor: state.selectedColor,
            ),
            isTrue,
          );
          state = LumoCardsRules.applyPlay(state: state, card: card, rng: rng);
        } else {
          state = LumoCardsRules.applyDraw(
            state: state,
            rng: rng,
            playIfPossible: true,
          );
        }
        break;
      case GamePhase.chooseColor:
        state = LumoCardsRules.applyColorChoice(
          state: state,
          chosen: LumoCardsBotPolicy.selectColor(
            ownHand: state.currentPlayer.hand,
            rng: rng,
          ),
        );
        break;
      case GamePhase.learningQuestion:
        final question = state.pendingLearningQuestion!;
        state = LumoCardsRules.applyLearningAnswer(
          state: state,
          chosenIndex: rng.nextBool()
              ? question.correctIndex
              : (question.correctIndex + 1) % question.options.length,
        );
        break;
      case GamePhase.passDevice:
        state = LumoCardsRules.confirmHandover(state);
        break;
      case GamePhase.gameOver:
        break;
    }
    final all = [
      ...state.drawPile,
      ...state.discardPile,
      for (final player in state.players) ...player.hand,
    ];
    expect(all, hasLength(112));
    expect(all.map((card) => card.id).toSet(), hasLength(112));
  }
  return state;
}
