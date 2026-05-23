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

  // ════════════════════════════════════════════════════════════════════
  // N-Spieler-Regeln (3 + 4 Spieler)
  // ════════════════════════════════════════════════════════════════════
  // Heinz 2026-05-22 'cleverer + 4 Spieler'. Die 2-Spieler-Tests oben
  // bleiben grün, weil applyPlay in jedem Special-Card-Handler bei
  // `players.length == 2` den alten Branch nimmt.

  LumoCardsGameState stateN({
    required List<List<LumoCard>> hands,
    required List<LumoCard> draw,
    required LumoCard top,
    int currentIdx = 0,
    int direction = 1,
    LumoCardColor? selected,
    GamePhase phase = GamePhase.playing,
  }) {
    final players = <LumoPlayer>[];
    for (int i = 0; i < hands.length; i++) {
      players.add(LumoPlayer(id: 'p$i', name: 'P$i', hand: hands[i]));
    }
    return LumoCardsGameState(
      players: players,
      currentPlayerIndex: currentIdx,
      drawPile: draw,
      discardPile: [top],
      selectedColor: selected ?? top.color,
      phase: phase,
      direction: direction,
    );
  }

  group('3-Spieler-Regeln', () {
    test('Skip ueberspringt naechsten Spieler (0 -> 2)', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.lumoJump, id: 'jump3');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1)],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.currentPlayerIndex, 2,
          reason: 'naechster Spieler 1 wird uebersprungen');
      expect(next.phase, GamePhase.passDevice);
      expect(next.direction, 1, reason: 'Skip aendert Richtung nicht');
    });

    test('Reverse flippt Richtung (0 -> 2, direction wird -1)', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.whirlwind, id: 'rev3');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.direction, -1, reason: 'Reverse flippt direction');
      expect(next.currentPlayerIndex, 2,
          reason: '1 Schritt rueckwaerts: 0 -> 2 (mod 3)');
      expect(next.phase, GamePhase.passDevice);
    });

    test('Reverse zweimal -> Richtung wieder 1', () {
      final card1 =
          _spec(LumoCardColor.orange, LumoCardType.whirlwind, id: 'rev3a');
      final card2 =
          _spec(LumoCardColor.orange, LumoCardType.whirlwind, id: 'rev3b');
      // Player 0 hat card1 + Filler (sonst gameOver beim Abspielen).
      // Player 2 hat card2 + Filler.
      final st = stateN(
        hands: [
          [card1, _num(LumoCardColor.orange, 2, id: 'f0')],
          const <LumoCard>[],
          [card2, _num(LumoCardColor.orange, 1, id: 'f2')],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final mid =
          LumoCardsRules.applyPlay(state: st, card: card1);
      expect(mid.direction, -1);
      expect(mid.currentPlayerIndex, 2);
      // Bevor Player 2 spielen kann muss confirmHandover laufen.
      final ready =
          LumoCardsRules.confirmHandover(mid);
      final next = LumoCardsRules.applyPlay(state: ready, card: card2);
      expect(next.direction, 1, reason: 'doppeltes Reverse = direction 1');
      expect(next.currentPlayerIndex, 0,
          reason: 'Schritt vorwaerts ab idx 2: -> 0 (mod 3)');
    });

    test('+2 Opfer zieht 2 UND ueberspringt seinen Zug', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.starRain, id: 'rain3');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: [
          _num(LumoCardColor.blue, 1, id: 'd1'),
          _num(LumoCardColor.blue, 2, id: 'd2'),
          _num(LumoCardColor.blue, 3, id: 'd3'),
        ],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(1),
      );
      expect(next.players[1].hand.length, 2,
          reason: 'Opfer (idx 1) zieht 2 Karten');
      expect(next.currentPlayerIndex, 2,
          reason: 'Opfer skippt -> idx 2 ist dran');
      expect(next.phase, GamePhase.passDevice);
    });

    test('+4 Opfer zieht 4 + chooseColor + steps=2 nach Farbwahl', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.superRain, id: 'sup3');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: [
          _num(LumoCardColor.blue, 1, id: 'd1'),
          _num(LumoCardColor.blue, 2, id: 'd2'),
          _num(LumoCardColor.blue, 3, id: 'd3'),
          _num(LumoCardColor.blue, 4, id: 'd4'),
          _num(LumoCardColor.blue, 5, id: 'd5'),
        ],
        top: _num(LumoCardColor.purple, 5),
        selected: LumoCardColor.purple,
      );
      final played = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(7),
      );
      expect(played.players[1].hand.length, 4,
          reason: 'Opfer (idx 1) zieht 4 Karten');
      expect(played.phase, GamePhase.chooseColor);
      expect(played.currentPlayerIndex, 0,
          reason: 'aktueller Spieler waehlt Farbe');

      final chosen = LumoCardsRules.applyColorChoice(
        state: played,
        chosen: LumoCardColor.blue,
      );
      expect(chosen.selectedColor, LumoCardColor.blue);
      expect(chosen.currentPlayerIndex, 2,
          reason: '+4-Opfer skippt -> idx 2 ist dran');
      expect(chosen.phase, GamePhase.passDevice);
    });

    test('Wild (colorMagic) ohne Skip nach Farbwahl', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.colorMagic, id: 'wld3');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1)],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.purple, 5),
        selected: LumoCardColor.purple,
      );
      final played = LumoCardsRules.applyPlay(state: st, card: card);
      expect(played.phase, GamePhase.chooseColor);

      final chosen = LumoCardsRules.applyColorChoice(
        state: played,
        chosen: LumoCardColor.blue,
      );
      expect(chosen.currentPlayerIndex, 1,
          reason: 'normales Wild = 1 Schritt weiter (kein Skip)');
    });
  });

  group('4-Spieler-Regeln', () {
    test('Skip ueberspringt naechsten Spieler (0 -> 2)', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.lumoJump, id: 'jump4');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1)],
          const <LumoCard>[],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.currentPlayerIndex, 2);
    });

    test('Reverse flippt Richtung (0 -> 3, direction=-1)', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.whirlwind, id: 'rev4');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.direction, -1);
      expect(next.currentPlayerIndex, 3,
          reason: '1 Schritt rueckwaerts: 0 -> 3 (mod 4)');
    });

    test('+2 in 4P: Opfer (idx 1) zieht 2, idx 2 ist dran', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.starRain, id: 'rain4');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: [
          _num(LumoCardColor.blue, 1, id: 'a'),
          _num(LumoCardColor.blue, 2, id: 'b'),
          _num(LumoCardColor.blue, 3, id: 'c'),
        ],
        top: _num(LumoCardColor.orange, 5),
      );
      final next = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(2),
      );
      expect(next.players[1].hand.length, 2);
      expect(next.currentPlayerIndex, 2);
    });

    test('+4 in 4P: Opfer (idx 1) zieht 4, idx 2 nach Farbwahl', () {
      final card =
          _spec(LumoCardColor.orange, LumoCardType.superRain, id: 'sup4');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: [
          _num(LumoCardColor.blue, 1, id: 'a'),
          _num(LumoCardColor.blue, 2, id: 'b'),
          _num(LumoCardColor.blue, 3, id: 'c'),
          _num(LumoCardColor.blue, 4, id: 'd'),
          _num(LumoCardColor.blue, 5, id: 'e'),
        ],
        top: _num(LumoCardColor.purple, 5),
        selected: LumoCardColor.purple,
      );
      final played = LumoCardsRules.applyPlay(
        state: st,
        card: card,
        rng: Random(3),
      );
      expect(played.players[1].hand.length, 4);
      expect(played.phase, GamePhase.chooseColor);

      final chosen = LumoCardsRules.applyColorChoice(
        state: played,
        chosen: LumoCardColor.blue,
      );
      expect(chosen.currentPlayerIndex, 2);
    });

    test('Skip mit direction=-1 ab idx 0: -> idx 2 (mod 4 backwards)', () {
      // direction=-1, currentIdx=0, Skip -> steps=2 rueckwaerts
      // (0 + 2*-1 + 16) % 4 = 14 % 4 = 2
      final card =
          _spec(LumoCardColor.orange, LumoCardType.lumoJump, id: 'jumpD');
      final st = stateN(
        hands: [
          [card, _num(LumoCardColor.orange, 1, id: 'f0')],
          const <LumoCard>[],
          const <LumoCard>[],
          const <LumoCard>[],
        ],
        draw: const [],
        top: _num(LumoCardColor.orange, 5),
        direction: -1,
      );
      final next = LumoCardsRules.applyPlay(state: st, card: card);
      expect(next.currentPlayerIndex, 2);
      expect(next.direction, -1, reason: 'Skip aendert direction nicht');
    });
  });
}
