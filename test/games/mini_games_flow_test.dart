import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/game_progress_repository.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/domain/games/game_level_model.dart';
import 'package:lumo_lernen/domain/games/mini_game_learning_task.dart';
import 'package:lumo_lernen/domain/games/mini_game_round.dart';
import 'package:lumo_lernen/features/games/mini_games/stars_path_game.dart';
import 'package:lumo_lernen/features/games/mini_games/number_house_game.dart';
import 'package:lumo_lernen/features/games/mini_games/color_boxes_game.dart';
import 'package:lumo_lernen/features/games/mini_games/letter_fill_game.dart';
import 'package:lumo_lernen/features/games/mini_games/lesson_trail_game.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

const _settings = AppSettings(
    voiceEnabled: false,
    soundEnabled: false,
    microphoneEnabled: false,
    calmMode: true);

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await _frames(tester);
  await tester.tap(finder);
  await _frames(tester);
}

Future<MiniGameRound> _saved(GameLevel level) async {
  final prefs = await SharedPreferences.getInstance();
  final key = prefs.getKeys().singleWhere((key) =>
      key.startsWith('lumo.games.round.v1.local_lena_1.') &&
      key.endsWith('.${level.id}'));
  final text = prefs.getString(key)!;
  final owner = (jsonDecode(text) as Map<String, dynamic>)['owner'] as String;
  return MiniGameRound.read(text, owner: owner, level: level);
}

Widget _route(LumoAppState app, GameLevel level) => switch (level.miniType) {
      GameMiniType.starsPath => StarsPathGame(appState: app, level: level),
      GameMiniType.numberHouse => NumberHouseGame(appState: app, level: level),
      GameMiniType.colorBoxes => ColorBoxesGame(appState: app, level: level),
      GameMiniType.letterFill => LetterFillGame(appState: app, level: level),
      _ => LessonTrailGame(appState: app, level: level),
    };

Future<void> _answer(WidgetTester tester, MiniGameRound round) async {
  final task = round.task;
  if (task.input == MiniGameInput.boxes) {
    // Operate the visible ten-field; the persisted draft must follow each tap.
    for (var i = 0; i < 10; i++) {
      final desired = i < task.targetCount!;
      if (round.response.boxes[i] != desired) {
        await _tap(tester, 'color-box-$i');
      }
    }
  } else if (task.input == MiniGameInput.orderedWords) {
    for (final word in task.answer.split(' ')) {
      await _tap(tester, 'mini-game-word-${task.choices.indexOf(word)}');
    }
  } else {
    final key = task.input == MiniGameInput.letters
        ? 'letter-choice-${task.answer}'
        : round.level.miniType == GameMiniType.starsPath ||
                round.level.miniType == GameMiniType.numberHouse
            ? 'math-option-${task.choices.indexOf(task.answer)}'
            : 'lesson-answer-${task.answer}';
    await _tap(tester, key);
  }
  // Selecting, painting or ordering is a draft. Only this explicit action grades.
  expect((await _saved(round.level)).response.attempts, isEmpty);
  await _tap(tester, 'mini-game-check');
  expect((await _saved(round.level)).response.solved(task), isTrue);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
  });

  for (final (id, stars, xp) in [
    (42, 3, 40),
    (7, 3, 40),
    (2, 5, 25),
    (25, 5, 48),
    (13, 3, 80),
  ]) {
    testWidgets(
        'existing route $id confirms every task and saves one original reward',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository())
        ..updateSettings(_settings);
      await app.hydrateFromWallet();
      final level = GameLevelCatalog.byId(id)!;
      await tester.pumpWidget(MaterialApp(home: _route(app, level)));
      await _frames(tester);
      final initial = await _saved(level);
      final seen = <String>{};
      for (var i = 0; i < initial.tasks.length; i++) {
        final before = await _saved(level);
        expect(before.index, i);
        expect(before.rewarded, isFalse);
        expect(app.state.stars, 0);
        seen.add(before.task.id);
        await _answer(tester, before);
        await _tap(tester, 'mini-game-check');
      }
      final completed = await _saved(level);
      expect(seen.length, initial.tasks.length);
      expect(completed.complete, isTrue);
      expect(completed.rewarded, isTrue);
      expect(find.text('Geschafft!'), findsOneWidget);
      expect(app.state.stars, stars);
      expect(completed.xp, xp);
      await app.flushRewards();
      expect((await RewardWalletRepository().load()).stars, stars);
      expect(
          (await const GameProgressRepository().loadStars('local_lena_1'))[id],
          stars.clamp(0, level.maxStars));
      expect(tester.takeException(), isNull);
      // Reopening the acknowledged round must not grant its reward twice.
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
      await tester.pumpWidget(MaterialApp(home: _route(app, level)));
      await _frames(tester);
      expect((await _saved(level)).rewarded, isTrue);
      expect(app.state.stars, stars);
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester);
      app.dispose();
    });
  }

  testWidgets('wrong answer stays on task and Stop discards a spoken candidate',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState()..updateSettings(_settings);
    final level = GameLevelCatalog.byId(7)!;
    await tester.pumpWidget(MaterialApp(home: _route(app, level)));
    await _frames(tester);
    final round = await _saved(level);
    final wrong = round.task.choices.indexWhere((c) => c != round.task.answer);
    await _tap(tester, 'math-option-$wrong');
    await _tap(tester, 'mini-game-check');
    final afterWrong = await _saved(level);
    expect(afterWrong.index, 0);
    expect(afterWrong.response.solved(afterWrong.task), isFalse);
    expect(app.state.stars, 0);
    final bus = LumoCompanionRequests.instance;
    final identity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: round.task.answer),
        isTrue);
    await _frames(tester);
    expect(find.byKey(const ValueKey('mini-game-answer-proposal')),
        findsOneWidget);
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    expect(
        find.byKey(const ValueKey('mini-game-answer-proposal')), findsNothing);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: round.task.answer),
        isFalse);
    expect((await _saved(level)).response.attempts.length, 1);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    app.dispose();
  });
}
