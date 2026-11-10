import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../core/legacy_learning_data.dart';
import 'lumo_cards_bot_policy.dart';
import 'lumo_cards_deck.dart';
import 'lumo_cards_models.dart';

/// One local round. Card IDs reference the existing, unchanged 112-card deck.
class LumoCardsRound {
  const LumoCardsRound({
    required this.id,
    required this.state,
    required this.grade,
    required this.vsBot,
    required this.difficulty,
    required this.style,
    this.callRewarded = false,
    this.rewardedLearningStars = 0,
    this.callRewardSettled = false,
  });

  final String id;
  final LumoCardsGameState state;
  final int grade;
  final bool vsBot;
  final LumoCardsDifficulty difficulty;
  final LumoCardsStyle style;
  final bool callRewarded;
  final int rewardedLearningStars;
  final bool callRewardSettled;

  static String newId() {
    final random = Random.secure();
    return 'cards-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }

  Map<String, Object?> encode(String owner) => {
        'version': 1,
        'deckVersion': 1,
        'owner': owner,
        'id': id,
        'grade': grade,
        'vsBot': vsBot,
        'difficulty': difficulty.name,
        'style': style.name,
        'callRewarded': callRewarded,
        'rewardedLearningStars': rewardedLearningStars,
        'callRewardSettled': callRewardSettled,
        'current': state.currentPlayerIndex,
        'direction': state.direction,
        'phase': state.phase.name,
        'color': state.selectedColor.name,
        'winner': state.winnerIndex,
        'players': [
          for (final p in state.players)
            {
              'id': p.id,
              'kind': p.kind.name,
              'stars': p.stars,
              'score': p.score,
              'hand': [for (final card in p.hand) card.id],
            }
        ],
        'draw': [for (final card in state.drawPile) card.id],
        'discard': [for (final card in state.discardPile) card.id],
        'question': state.pendingLearningQuestion == null
            ? null
            : {
                'prompt': state.pendingLearningQuestion!.prompt,
                'options': state.pendingLearningQuestion!.options,
                'correct': state.pendingLearningQuestion!.correctIndex,
                'hint': state.pendingLearningQuestion!.hint,
              },
      };

  static LumoCardsRound? decode(
    String raw, {
    required String owner,
    required int grade,
    required bool vsBot,
    required String player1Name,
    required String player2Name,
  }) {
    // Reject before parsing to bound corrupted local input, including lists.
    if (raw.length > 65536) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['version'] != 1 ||
          j['deckVersion'] != 1 ||
          j['owner'] != owner ||
          j['grade'] != grade ||
          j['vsBot'] != vsBot ||
          j['callRewarded'] is! bool ||
          j['id'] is! String ||
          !RegExp(r'^cards-[a-f0-9]{32}$').hasMatch(j['id'] as String)) {
        return null;
      }
      final deck = {
        for (final c in LumoCardsDeck.buildDeck(rng: Random(0))) c.id: c
      };
      final used = <String>{};
      List<LumoCard> cards(dynamic value) {
        if (value is! List || value.length > 112) throw const FormatException();
        return [
          for (final id in value)
            (() {
              if (id is! String || !deck.containsKey(id) || !used.add(id)) {
                throw const FormatException();
              }
              return deck[id]!;
            })()
        ];
      }

      int bounded(dynamic value, int maximum) {
        if (value is! int || value < 0 || value > maximum) {
          throw const FormatException();
        }
        return value;
      }

      final playersJson = j['players'] as List;
      if (playersJson.length != 2) return null;
      final players = <LumoPlayer>[];
      for (var i = 0; i < 2; i++) {
        final p = playersJson[i] as Map;
        final kind =
            vsBot && i == 1 ? LumoPlayerKind.bot : LumoPlayerKind.human;
        if (p['id'] != 'p${i + 1}' || p['kind'] != kind.name) return null;
        players.add(LumoPlayer(
            id: 'p${i + 1}',
            name: i == 0 ? player1Name : player2Name,
            kind: kind,
            hand: cards(p['hand']),
            stars: bounded(p['stars'], 9999),
            score: bounded(p['score'], 999999)));
      }
      final rewardedLearning =
          bounded(j['rewardedLearningStars'], players[0].stars);
      if (j['callRewardSettled'] is! bool ||
          (j['callRewardSettled'] == true && j['callRewarded'] != true)) {
        return null;
      }
      final draw = cards(j['draw']);
      final discard = cards(j['discard']);
      if (used.length != 112 || discard.isEmpty) return null;
      final current = bounded(j['current'], 1);
      final phase = GamePhase.values.byName(j['phase'] as String);
      final direction = j['direction'];
      if (direction != 1 && direction != -1) return null;
      final winner = j['winner'];
      if (phase == GamePhase.gameOver) {
        if (winner is! int ||
            winner < 0 ||
            winner > 1 ||
            winner != current ||
            players[winner].hand.isNotEmpty ||
            players[1 - winner].hand.isEmpty) {
          return null;
        }
      } else if (winner != null || players.any((p) => p.hand.isEmpty)) {
        return null;
      }
      LearningQuestion? question;
      if (phase == GamePhase.learningQuestion) {
        if (discard.last.type != LumoCardType.thinkPause) return null;
        final q = j['question'] as Map;
        final options = (q['options'] as List).cast<String>();
        if (options.length < 2 ||
            options.length > 4 ||
            options.toSet().length != options.length ||
            options.any((text) => text.isEmpty || text.length > 400)) {
          return null;
        }
        final prompt = q['prompt'] as String;
        final hint = q['hint'] as String?;
        if (prompt.isEmpty ||
            prompt.length > 2000 ||
            (hint?.length ?? 0) > 2000) {
          return null;
        }
        question = LearningQuestion(
            prompt: prompt,
            options: options,
            correctIndex: bounded(q['correct'], options.length - 1),
            hint: hint);
      } else if (j['question'] != null) {
        return null;
      }
      if (phase == GamePhase.chooseColor && !discard.last.isWild) return null;
      final color = LumoCardColor.values.byName(j['color'] as String);
      if (!discard.last.isWild && color != discard.last.color) return null;
      return LumoCardsRound(
          id: j['id'] as String,
          grade: grade,
          vsBot: vsBot,
          difficulty:
              LumoCardsDifficulty.values.byName(j['difficulty'] as String),
          style: LumoCardsStyle.values.byName(j['style'] as String),
          callRewarded: j['callRewarded'] as bool,
          rewardedLearningStars: rewardedLearning,
          callRewardSettled: j['callRewardSettled'] as bool,
          state: LumoCardsGameState(
              players: players,
              currentPlayerIndex: current,
              drawPile: draw,
              discardPile: discard,
              selectedColor: color,
              phase: phase,
              direction: direction as int,
              winnerIndex: winner as int?,
              lastActionMessage: 'Deine gespeicherte Runde ist wieder da.',
              pendingLearningQuestion: question));
    } catch (_) {
      return null;
    }
  }
}

/// Uses the existing ordered local storage, including its failed-write reload.
/// Each school/local child, grade and play mode has an independent slot.
class LumoCardsSessionRepository {
  LumoCardsSessionRepository(
      {required String studentId, required this.grade, required this.vsBot})
      : owner = sha256.convert(utf8.encode(studentId)).toString();

  final String owner;
  final int grade;
  final bool vsBot;
  String get storageKey =>
      'lumo.cards.round.v1.$owner.$grade.${vsBot ? 'solo' : 'local'}';

  Future<LumoCardsRound?> load(
          {required String player1Name, required String player2Name}) =>
      LearningStorage.run((prefs) async {
        final raw = prefs.get(storageKey);
        if (raw is! String) return null;
        return LumoCardsRound.decode(raw,
            owner: owner,
            grade: grade,
            vsBot: vsBot,
            player1Name: player1Name,
            player2Name: player2Name);
      });

  Future<void> save(LumoCardsRound round, {bool Function()? canWrite}) {
    if (round.grade != grade || round.vsBot != vsBot) {
      return Future.error(ArgumentError('Cards session owner mismatch'));
    }
    final raw = jsonEncode(round.encode(owner));
    return LearningStorage.run((prefs) async {
      if (canWrite != null && !canWrite()) return;
      await LearningStorage.write(prefs, storageKey, raw);
    });
  }
}
