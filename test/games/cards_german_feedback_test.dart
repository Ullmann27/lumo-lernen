import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_bot_policy.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_game_controller.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_rules.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_session.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_table_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _question = LearningQuestion(
  prompt: 'Wie viel ist zwei plus eins?',
  options: ['Zwei', 'Drei'],
  correctIndex: 1,
  hint: 'Zähle noch eins dazu.',
);

LumoCard _card(LumoCardType type,
        {LumoCardColor color = LumoCardColor.green, String id = 'played'}) =>
    LumoCard(id: id, color: color, type: type,
        number: type == LumoCardType.number ? 2 : null);

LumoCardsGameState _state(LumoCard card, {
  int current = 0,
  List<String> names = const ['Du', 'Lumo'],
  bool lastCard = false,
}) => LumoCardsGameState(
  players: [
    for (var index = 0; index < names.length; index++)
      LumoPlayer(
        id: 'p${index + 1}',
        name: names[index],
        kind: names[index] == 'Lumo' ? LumoPlayerKind.bot : LumoPlayerKind.human,
        stars: index,
        score: 10 + index,
        hand: index == current
            ? [card, if (!lastCard) _card(LumoCardType.number,
                color: LumoCardColor.blue, id: 'spare-$index')]
            : [_card(LumoCardType.number, id: 'other-$index')],
      ),
  ],
  currentPlayerIndex: current,
  drawPile: [
    for (var i = 0; i < 8; i++)
      _card(LumoCardType.number, color: LumoCardColor.blue, id: 'draw-$i'),
  ],
  discardPile: [_card(LumoCardType.number, color: card.color, id: 'top')],
  selectedColor: card.color,
  phase: GamePhase.playing,
);

LumoCardsRound _round(LumoCardsGameState state) => LumoCardsRound(
  id: 'cards-${'1' * 32}', state: state, grade: 1, vsBot: true,
  difficulty: LumoCardsDifficulty.clever, style: LumoCardsStyle.planner,
);

final _observations = <String, Map<String, Object?>>{};

void _record(String name, LumoCardsGameState state) {
  _observations[name] = {
    'message': state.lastActionMessage,
    // Use the production save serializer, not an invented subset of fields.
    'round': _round(state).encode('message-regression-owner'),
  };
}

LumoCardsGameState _play(String tag, LumoCardsGameState state, LumoCard card) {
  final result = LumoCardsRules.applyPlay(
    state: state, card: card, rng: Random(5), questionPicker: (_) => _question);
  _record(tag, result);
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  tearDownAll(() {
    final destination = Platform.environment['LUMO_CARDS_MESSAGE_EVIDENCE'];
    if (destination != null) {
      File(destination).writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(_observations) + '\n');
    }
  });

  test('API35 original number message uses the existing German card name', () {
    final card = _card(LumoCardType.number);
    final result = _play('api35-green-two',
        _state(card, current: 1), card);
    expect(result.lastActionMessage, 'Lumo legt Grün 2.');
    expect(result.topCard, same(card));
    expect(result.players[1].hand.length, 1);
  });

  test('API37 original whirlwind message addresses the child correctly', () {
    final card = _card(LumoCardType.whirlwind);
    final result = _play('api37-whirlwind',
        _state(card, current: 1), card);
    expect(result.lastActionMessage, 'Wirbelwind! Du ziehst 1 Karte.');
    expect(result.players[0].hand.length, 2);
    expect(result.drawPile.length, 7);
  });

  test('Number messages distinguish Du from named human and bot for all colors', () {
    for (final name in ['Du', 'Mila', 'Lumo']) {
      for (final color in LumoCardColor.values) {
        final card = _card(LumoCardType.number, color: color);
        final result = _play('number-$name-${color.name}',
            _state(card, names: [name, 'Zoey']), card);
        final verb = name == 'Du' ? 'legst' : 'legt';
        expect(result.lastActionMessage, '$name $verb ${color.displayName} 2.');
      }
    }
  });

  test('Draw message uses second person only for the actual display pronoun', () {
    final card = _card(LumoCardType.number);
    for (final name in ['Du', 'Mila', 'Lumo']) {
      final result = LumoCardsRules.applyDraw(
          state: _state(card, names: [name, 'Zoey']), rng: Random(5));
      _record('draw-$name', result);
      expect(result.lastActionMessage,
          '$name ${name == 'Du' ? 'ziehst' : 'zieht'} eine Karte.');
      expect(result.players[0].hand.length, 3);
    }
  });

  test('Rain and super rain conjugate the actual recipient without changing draw counts', () {
    for (final type in [LumoCardType.starRain, LumoCardType.superRain]) {
      for (final name in ['Du', 'Mila', 'Lumo']) {
        final card = _card(type);
        final result = _play('${type.name}-$name',
            _state(card, names: ['Zoey', name]), card);
        final count = type == LumoCardType.starRain ? 2 : 4;
        final prefix = type == LumoCardType.starRain
            ? 'Sternenregen!' : 'Super-Sternenregen!';
        final suffix = type == LumoCardType.superRain ? ' - jetzt Farbe wählen.' : '.';
        expect(result.lastActionMessage,
            '$prefix $name ${name == 'Du' ? 'ziehst' : 'zieht'} $count Karten$suffix');
        expect(result.players[1].hand.length, 1 + count);
        expect(result.drawPile.length, 8 - count);
      }
    }
  });

  test('Whirlwind also names human and bot recipients in third person', () {
    final card = _card(LumoCardType.whirlwind);
    for (final name in ['Mila', 'Lumo']) {
      final result = _play('whirlwind-$name',
          _state(card, names: ['Zoey', name]), card);
      expect(result.lastActionMessage, 'Wirbelwind! $name zieht 1 Karte.');
    }
  });

  test('Wild prompt and chosen color use proper German without changing enum IDs', () {
    for (final name in ['Du', 'Mila', 'Lumo']) {
      final card = _card(LumoCardType.colorMagic);
      final prompt = _play('wild-prompt-$name',
          _state(card, names: [name, 'Zoey']), card);
      expect(prompt.lastActionMessage,
          'Farbzauber! $name ${name == 'Du' ? 'wählst' : 'wählt'} eine Farbe.');
      for (final color in LumoCardColor.values) {
        final result = LumoCardsRules.applyColorChoice(
            state: prompt, chosen: color);
        _record('color-$name-${color.name}', result);
        expect(result.lastActionMessage,
            '$name ${name == 'Du' ? 'wählst' : 'wählt'} ${color.displayName}.');
        expect(_round(result).encode('owner')['color'], color.name);
      }
    }
  });

  test('Winning feedback conjugates Du and named winners correctly', () {
    final card = _card(LumoCardType.number);
    for (final name in ['Du', 'Mila', 'Lumo']) {
      final result = _play('win-$name',
          _state(card, names: [name, 'Zoey'], lastCard: true), card);
      expect(result.lastActionMessage,
          '$name ${name == 'Du' ? 'hast' : 'hat'} alle Karten abgelegt!');
      expect(result.winnerIndex, 0);
      expect(result.phase, GamePhase.gameOver);
    }
  });

  test('Learning prompt uses dich and preserves the actual question', () {
    final card = _card(LumoCardType.thinkPause);
    for (final name in ['Du', 'Mila', 'Lumo']) {
      final result = _play('question-$name',
          _state(card, names: [name, 'Zoey']), card);
      expect(result.lastActionMessage,
          'Denkpause! Lumo hat eine kleine Frage für ${name == 'Du' ? 'dich' : name}.');
      expect(result.pendingLearningQuestion, same(_question));
    }
  });

  test('Correct answer feedback agrees in both verbs and keeps exactly one star', () {
    final card = _card(LumoCardType.thinkPause);
    for (final name in ['Du', 'Mila', 'Lumo']) {
      final question = LumoCardsRules.applyPlay(
          state: _state(card, names: [name, 'Zoey']),
          card: card, questionPicker: (_) => _question);
      final result = LumoCardsRules.applyLearningAnswer(
          state: question, chosenIndex: 1);
      _record('correct-$name', result);
      expect(result.lastActionMessage, name == 'Du'
          ? 'Richtig! Du bekommst einen Stern und darfst nochmal.'
          : 'Richtig! $name bekommt einen Stern und darf nochmal.');
      expect(result.currentPlayer.stars, 1);
      expect(result.pendingLearningQuestion, isNull);
    }
  });

  test('Native public view forwards corrected messages while machine color stays green', () {
    final controller = LumoCardsGameController(
        player1Name: 'Du', player2Name: 'Lumo',
        vsBot: true, enableVoice: false, seed: 5);
    addTearDown(controller.dispose);
    for (final type in [LumoCardType.number, LumoCardType.whirlwind]) {
      final card = _card(type);
      final result = _play('native-view-${type.name}',
          _state(card, current: 1), card);
      controller.restoreRound(_round(result));
      final view = cardsTableView(controller,
          token: 'a' * 32, revision: 3, ack: 1);
      expect(view['message'], type == LumoCardType.number
          ? 'Lumo legt Grün 2.' : 'Wirbelwind! Du ziehst 1 Karte.');
      expect(view['selectedColor'], 'green');
      expect((view['top'] as Map)['color'], 'green');
      expect((view['top'] as Map)['id'], 'played');
      expect(view.containsKey('drawPile'), isFalse);
    }
  });

  test('Saved rounds never serialize presentation messages', () {
    final controller = LumoCardsGameController(
        player1Name: 'Du', player2Name: 'Lumo',
        vsBot: true, enableVoice: false, seed: 5);
    addTearDown(controller.dispose);
    final round = controller.snapshot();
    final before = round.encode('persistent-owner');
    final changed = LumoCardsRound(
        id: round.id,
        state: round.state.copyWith(lastActionMessage: 'Nur sichtbarer Text.'),
        grade: round.grade, vsBot: round.vsBot,
        difficulty: round.difficulty, style: round.style);
    expect(changed.encode('persistent-owner'), before);
    expect(before.containsKey('lastActionMessage'), isFalse);
    final restored = LumoCardsRound.decode(jsonEncode(before),
        owner: 'persistent-owner', grade: 1, vsBot: true,
        player1Name: 'Du', player2Name: 'Lumo');
    expect(restored, isNotNull);
    expect(restored!.encode('persistent-owner'), before);
  });
}

