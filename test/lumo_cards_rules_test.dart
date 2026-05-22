import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';

LumoCard _num(LumoCardColor c, int n, {String id = ''}) => LumoCard(
      id: id.isEmpty ? '$c-$n' : id,
      color: c,
      type: LumoCardType.number,
      number: n,
    );

LumoCard _spec(LumoCardColor c, LumoCardType t, {String id = ''}) => LumoCard(
      id: id.isEmpty ? '$c-${t.name}' : id,
      color: c,
      type: t,
    );

LumoCardsGameState _state({
  required List<LumoCard> handA,
  required List<LumoCard> handB,
  required List<LumoCard> draw,
  required LumoCard top,
  LumoCardColor? selected,
  int currentIdx = 0,
  GamePhase phase = GamePhase.playing,
}) =>
    LumoCardsGameState(
      players: [
        LumoPlayer(id: 'a', name: 'Alex', hand: handA),
        LumoPlayer(id: 'b', name: 'Beti', hand: handB),
      ],
      currentPlayerIndex: currentIdx,
      drawPile: draw,
      discardPile: [top],
      selectedColor: selected ?? top.color,
      phase: phase,
    );

void main() {
  group('isPlayable', () {
    test('gleiche Farbe -> spielbar', () {
      expect(
        LumoCardsRules.isPlayable(
          card: _num(LumoCardColor.orange, 5),
          topCard: _num(LumoCardColor.orange, 2),
          selectedColor: LumoCardColor.orange,
        ),
        isTrue,
      );
    });

    test('gleiche Zahl andere Farbe -> spielbar', () {
      expect(
        LumoCardsRules.isPlayable(
          card: _num(LumoCardColor.purple, 5),
          topCard: _num(LumoCardColor.orange, 5),
          selectedColor: LumoCardColor.orange,
        ),
        isTrue,
      );
    });

    test('falsche Farbe und Zahl -> NICHT spielbar', () {
      expect(
        LumoCardsRules.isPlayable(
          card: _num(LumoCardColor.purple, 3),
          topCard: _num(LumoCardColor.orange, 5),
          selectedColor: LumoCardColor.orange,
        ),
        isFalse,
      );
    });

    test('colorMagic (Wild) -> immer spielbar', () {
      expect(
        LumoCardsRules.isPlayable(
          card: _spec(LumoCardColor.blue, LumoCardType.colorMagic),
          topCard: _num(LumoCardColor.orange, 5),
          selectedColor: LumoCardColor.orange,
        ),
        isTrue,
      );
    });

    test('Spezialkarte auf gleichen Spezialtyp andere Farbe -> spielbar', () {
      expect(
        LumoCardsRules.isPlayable(
          card: _spec(LumoCardColor.green, LumoCardType.starRain),
          topCard: _spec(LumoCardColor.orange, LumoCardType.starRain),
          selectedColor: LumoCardColor.orange,
        ),
        isTrue,
      );
    });

    test('selectedColor nach Farbzauber zaehlt, nicht topCard.color', () {
      // Top ist orange-5, aber selectedColor wurde auf blue gesetzt.
      expect(
        LumoCardsRules.isPlayable(
          card: _num(LumoCardColor.blue, 9),
          topCard: _num(LumoCardColor.orange, 5),
          selectedColor: LumoCardColor.blue,
        ),
        isTrue,
      );
    });
  });

  group('applyPlay - normale Zahlenkarte', () {
    test('legt Karte ab und wechselt Zug ueber passDevice', () {
      final card = _num(LumoCardColor.orange, 3, id: 'play');
      final st = _state(
        handA: [card, _num(LumoCardColor.blue, 7)],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.players[0].hand.length, 1);
      expect(next.discardPile.last.id, 'play');
      expect(next.phase, GamePhase.passDevice);
      expect(next.currentPlayerIndex, 1);
    });

    test('unspielbare Karte wird abgelehnt - State bleibt', () {
      final card = _num(LumoCardColor.purple, 3);
      final st = _state(
        handA: [card],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.players[0].hand.length, 1);
      expect(next.phase, GamePhase.playing);
      expect(next.currentPlayerIndex, 0);
    });
  });

  group('applyPlay - Spezialkarten', () {
    test('Lumo-Sprung -> aktueller Spieler bleibt dran', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.lumoJump, id: 'jump');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.currentPlayerIndex, 0);
      expect(next.phase, GamePhase.playing);
    });

    test('Sternenregen -> Gegner zieht 2 Karten und Zug wechselt', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.starRain, id: 'rain');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: [
          _num(LumoCardColor.green, 1, id: 'd1'),
          _num(LumoCardColor.green, 2, id: 'd2'),
          _num(LumoCardColor.green, 3, id: 'd3'),
        ],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(1),
      );
      expect(next.players[1].hand.length, 2);
      expect(next.drawPile.length, 1);
      expect(next.currentPlayerIndex, 1);
      expect(next.phase, GamePhase.passDevice);
    });

    test('Farbzauber -> phase = chooseColor, Zug nicht gewechselt', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.colorMagic, id: 'wild');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.purple, 5),
        selected: LumoCardColor.purple,
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.phase, GamePhase.chooseColor);
      expect(next.currentPlayerIndex, 0);
    });

    test('applyColorChoice -> selectedColor uebernommen und Zug wechselt', () {
      final st = LumoCardsGameState(
        players: [
          LumoPlayer(
              id: 'a',
              name: 'Alex',
              hand: [_num(LumoCardColor.orange, 1)]),
          LumoPlayer(id: 'b', name: 'Beti', hand: const []),
        ],
        currentPlayerIndex: 0,
        drawPile: const [],
        discardPile: [_spec(LumoCardColor.orange, LumoCardType.colorMagic)],
        selectedColor: LumoCardColor.orange,
        phase: GamePhase.chooseColor,
      );
      final next = LumoCardsRules.applyColorChoice(
          state: st, chosen: LumoCardColor.blue);
      expect(next.selectedColor, LumoCardColor.blue);
      expect(next.phase, GamePhase.passDevice);
      expect(next.currentPlayerIndex, 1);
    });

    test('Wirbelwind -> Gegner zieht 1, Zug wechselt', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.whirlwind, id: 'wind');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: [_num(LumoCardColor.blue, 4, id: 'd1')],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.players[1].hand.length, 1);
      expect(next.currentPlayerIndex, 1);
    });

    test('Super-Sternenregen -> Gegner zieht 4 + Farbwahl', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.superRain, id: 'super');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: [
          _num(LumoCardColor.green, 1, id: 'd1'),
          _num(LumoCardColor.green, 2, id: 'd2'),
          _num(LumoCardColor.green, 3, id: 'd3'),
          _num(LumoCardColor.green, 4, id: 'd4'),
          _num(LumoCardColor.green, 5, id: 'd5'),
        ],
        top: _num(LumoCardColor.purple, 5),
        selected: LumoCardColor.purple,
      );
      final next = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(7),
      );
      expect(next.players[1].hand.length, 4);
      expect(next.drawPile.length, 1);
      expect(next.phase, GamePhase.chooseColor);
      expect(next.currentPlayerIndex, 0);
    });

    test('Super-Sternenregen ist immer spielbar (wie Wild)', () {
      final superCard =
          _spec(LumoCardColor.orange, LumoCardType.superRain);
      expect(
        LumoCardsRules.isPlayable(
          card: superCard,
          topCard: _num(LumoCardColor.purple, 5),
          selectedColor: LumoCardColor.purple,
        ),
        isTrue,
      );
    });

    test('Denkpause -> phase = learningQuestion mit Frage', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.thinkPause, id: 'think');
      final st = _state(
        handA: [card, _num(LumoCardColor.orange, 1)],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.phase, GamePhase.learningQuestion);
      expect(next.pendingLearningQuestion, isNotNull);
    });

    test('Lernfrage richtig -> +1 Stern, Spieler darf weiter', () {
      final st = LumoCardsGameState(
        players: const [
          LumoPlayer(id: 'a', name: 'Alex', hand: [], stars: 0),
          LumoPlayer(id: 'b', name: 'Beti', hand: []),
        ],
        currentPlayerIndex: 0,
        drawPile: const [],
        discardPile: [_spec(LumoCardColor.orange, LumoCardType.thinkPause)],
        selectedColor: LumoCardColor.orange,
        phase: GamePhase.learningQuestion,
        pendingLearningQuestion: const LearningQuestion(
          prompt: 'Test?',
          options: ['A', 'B', 'C'],
          correctIndex: 1,
        ),
      );
      final next = LumoCardsRules.applyLearningAnswer(
          state: st, chosenIndex: 1);
      expect(next.players[0].stars, 1);
      expect(next.phase, GamePhase.playing);
      expect(next.currentPlayerIndex, 0);
    });

    test('Lernfrage falsch -> kein Stern, Zug wechselt', () {
      final st = LumoCardsGameState(
        players: const [
          LumoPlayer(id: 'a', name: 'Alex', hand: [], stars: 0),
          LumoPlayer(id: 'b', name: 'Beti', hand: []),
        ],
        currentPlayerIndex: 0,
        drawPile: const [],
        discardPile: [_spec(LumoCardColor.orange, LumoCardType.thinkPause)],
        selectedColor: LumoCardColor.orange,
        phase: GamePhase.learningQuestion,
        pendingLearningQuestion: const LearningQuestion(
          prompt: 'Test?',
          options: ['A', 'B', 'C'],
          correctIndex: 1,
        ),
      );
      final next = LumoCardsRules.applyLearningAnswer(
          state: st, chosenIndex: 0);
      expect(next.players[0].stars, 0);
      expect(next.phase, GamePhase.passDevice);
      expect(next.currentPlayerIndex, 1);
    });
  });

  group('Sieg', () {
    test('Letzte Karte abgelegt -> gameOver mit winner', () {
      final card = _num(LumoCardColor.orange, 3, id: 'win');
      final st = _state(
        handA: [card],
        handB: [_num(LumoCardColor.blue, 1)],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.phase, GamePhase.gameOver);
      expect(next.winnerIndex, 0);
    });
  });

  group('Draw', () {
    test('applyDraw fuegt Karte zur Hand und wechselt Zug', () {
      final st = _state(
        handA: const [],
        handB: const [],
        draw: [_num(LumoCardColor.blue, 4, id: 'd1')],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyDraw(state: st, rng: Random(1));
      expect(next.players[0].hand.length, 1);
      expect(next.currentPlayerIndex, 1);
    });
  });

  group('Handover', () {
    test('confirmHandover -> phase = playing', () {
      final st = _state(
        handA: const [],
        handB: const [],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
        phase: GamePhase.passDevice,
        currentIdx: 1,
      );
      final next = LumoCardsRules.confirmHandover(st);
      expect(next.phase, GamePhase.playing);
      expect(next.currentPlayerIndex, 1);
    });
  });
}
