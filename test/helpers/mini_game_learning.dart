import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/mini_game_learning_task.dart';
import 'package:lumo_lernen/domain/games/mini_game_round.dart';

/// Let the actual profile/checkpoint writes finish between visible UI actions.
Future<void> settleMiniGame(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> tapMiniGameKey(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await settleMiniGame(tester);
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await settleMiniGame(tester);
}

Future<MiniGameRound> savedMiniGameRound(GameLevel level) async {
  final prefs = await SharedPreferences.getInstance();
  final key = prefs.getKeys().singleWhere((key) =>
      key.startsWith('lumo.games.round.v1.local_lena_1.') &&
      key.endsWith('.${level.id}'));
  final text = prefs.getString(key)!;
  final owner = (jsonDecode(text) as Map<String, dynamic>)['owner'] as String;
  return MiniGameRound.read(text, owner: owner, level: level);
}

/// Select through the real controls; this intentionally does not press Check.
Future<void> selectMiniGameAnswer(
    WidgetTester tester, MiniGameRound round) async {
  final task = round.task;
  if (task.input == MiniGameInput.boxes) {
    for (var i = 0; i < 10; i++) {
      if (round.response.boxes[i] != (i < task.targetCount!)) {
        await tapMiniGameKey(tester, 'color-box-$i');
      }
    }
  } else if (task.input == MiniGameInput.orderedWords) {
    for (final word in task.answer.split(' ')) {
      await tapMiniGameKey(
          tester, 'mini-game-word-${task.choices.indexOf(word)}');
    }
  } else {
    final key = task.input == MiniGameInput.letters
        ? 'letter-choice-${task.answer}'
        : round.level.miniType == GameMiniType.starsPath ||
                round.level.miniType == GameMiniType.numberHouse
            ? 'math-option-${task.choices.indexOf(task.answer)}'
            : 'lesson-answer-${task.answer}';
    await tapMiniGameKey(tester, key);
  }
  expect((await savedMiniGameRound(round.level)).response.attempts, isEmpty,
      reason: 'Selecting a draft must never grade an answer.');
}
