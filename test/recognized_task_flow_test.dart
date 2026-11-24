import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/recognized_task_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/recognized_task.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/recognition/lumo_task_recognition_screen.dart';
import 'package:lumo_lernen/features/recognition/recognized_task_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _Store extends InMemorySharedPreferencesStore {
  _Store()
      : super.withData({
          'flutter.${LegacyLearningDataRepository.localIdKey}':
              'local-recognized'
        });
  bool rejectReceipt = false;
  Completer<void>? logEntered, releaseLog;
  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (key == 'flutter.lumo_attempt_log_v1' &&
        logEntered != null &&
        !logEntered!.isCompleted) {
      logEntered!.complete();
      await releaseLog!.future;
    }
    if (rejectReceipt && key.contains(RecognizedTaskRepository.storageBase)) {
      final saved = jsonDecode(value as String) as Map;
      if (saved['attempt'] is Map &&
          (saved['attempt'] as Map)['completed'] == true) {
        return false;
      }
    }
    return super.setValue(type, key, value);
  }
}

class _HeldWallet extends RewardWalletRepository {
  final entered = Completer<void>(), release = Completer<void>();
  @override
  Future<RewardWallet> applyRewardDelta(
      {int starsDelta = 0, int xpDelta = 0, String? ownerId}) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    return super.applyRewardDelta(
        starsDelta: starsDelta, xpDelta: xpDelta, ownerId: ownerId);
  }
}

Future<LumoAppState> _app({RewardWalletRepository? wallet}) async {
  final app =
      LumoAppState(walletRepository: wallet ?? RewardWalletRepository());
  await app.ensureSettingsLoaded();
  await app.loadLearningProfile();
  await app.hydrateFromWallet();
  return app;
}

Future<void> _ready(RecognizedTaskController controller) async {
  for (var i = 0; i < 300 && !controller.ready; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(controller.error, isNull);
  expect(controller.ready, true);
}

AdaptiveTaskAnswer _answer(RecognizedTaskController controller,
    {bool correct = true}) {
  final attempt = controller.active!;
  return AdaptiveTaskAnswer(
      task: attempt.task.toTaskInstance(
          attemptId: attempt.id,
          ownerId: attempt.ownerId,
          startedAt: attempt.startedAt),
      answer: correct
          ? attempt.task.answer
          : attempt.task.options.firstWhere((v) => v != attempt.task.answer),
      correct: correct);
}

Future<void> _frames(WidgetTester tester, [int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 17));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {LegacyLearningDataRepository.localIdKey: 'local-recognized'});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  test('double submit uses one durable ID and no curriculum or mission credit',
      () async {
    final app = await _app();
    final controller = RecognizedTaskController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    expect(controller.recognize('3 - 8'), true);
    await controller.startPreview();
    final attempt = controller.active!;
    expect(
        await Future.wait([
          controller.answer(_answer(controller)),
          controller.answer(_answer(controller))
        ]),
        [true, false]);
    expect(controller.active!.completed, true);
    final logs = await app.attemptLog.load(studentId: 'self');
    expect(logs, hasLength(1));
    expect(logs.single.id, attempt.id);
    expect(logs.single.subject, 'Eigene Textaufgaben');
    expect(logs.single.expected, '-5');
    expect(app.learningSkills(), isEmpty);
    expect(app.learningDailyDone(), 0);
    await app.loadDailyMission();
    expect(app.dailyMission!.completedCount, 0);
    final wallet = await app.loadRewardShopWallet(lease: controller.lease!);
    expect(wallet.stars, 6);
    expect(wallet.xp, 25);
    expect(wallet.earnedStarsByOwner, {'local-recognized': 6});
    expect(wallet.gameResultIds.where((id) => id == attempt.id), hasLength(1));
  });

  test('incorrect answer is logged without awarding a positive result',
      () async {
    final app = await _app();
    final controller = RecognizedTaskController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    controller.recognize('Anfangsbuchstabe Mama');
    await controller.startPreview();
    expect(await controller.answer(_answer(controller, correct: false)), true);
    expect(app.state.stars, 0);
    expect(app.state.xp, 0);
    expect((await app.attemptLog.load()).single.correct, false);
  });

  test('restart after wallet success before receipt does not pay twice',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    var app = await _app();
    var controller = RecognizedTaskController(app);
    await _ready(controller);
    controller.recognize('2, 4, 6, ?');
    await controller.startPreview();
    final id = controller.active!.id;
    store.rejectReceipt = true;
    expect(await controller.answer(_answer(controller)), false);
    expect(app.state.stars, 6);
    expect(controller.active!.completed, false);
    controller.dispose();
    app.dispose();
    store.rejectReceipt = false;
    app = await _app();
    controller = RecognizedTaskController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    expect(controller.active!.id, id);
    expect(await controller.retryResult(), true);
    expect(app.state.stars, 6);
    expect(app.state.xp, 25);
    expect((await app.attemptLog.load()).map((v) => v.id), [id]);
  });

  test('profile switch during saved answer preserves A and never credits B',
      () async {
    final store = _Store();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    await app.school.setActiveStudent('recognized-a');
    final controller = RecognizedTaskController(app);
    addTearDown(() {
      if (store.releaseLog != null && !store.releaseLog!.isCompleted) {
        store.releaseLog!.complete();
      }
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    controller.recognize('12 + 7');
    await controller.startPreview();
    final id = controller.active!.id;
    store.logEntered = Completer();
    store.releaseLog = Completer();
    final saving = controller.answer(_answer(controller));
    await store.logEntered!.future;
    await app.school.setActiveStudent('recognized-b');
    expect(controller.active, isNull);
    expect(controller.preview, isNull);
    store.releaseLog!.complete();
    expect(await saving, false);
    await _ready(controller);
    expect(controller.active, isNull);
    expect(app.state.stars, 0);
    expect(await app.attemptLog.load(studentId: 'recognized-b'), isEmpty);
    await app.school.setActiveStudent('recognized-a');
    await _ready(controller);
    expect(controller.active!.id, id);
    expect(await controller.retryResult(), true);
    final wallet = await app.loadRewardShopWallet(lease: controller.lease!);
    expect(wallet.earnedStarsByOwner, {'recognized-a': 6});
    expect(
        (await app.attemptLog.load(studentId: 'recognized-a')).single.id, id);
  });

  test('queued legacy reward keeps its captured owner while selection changes',
      () async {
    final wallet = _HeldWallet();
    final app = await _app(wallet: wallet);
    addTearDown(() {
      if (!wallet.release.isCompleted) wallet.release.complete();
      app.dispose();
    });
    await app.school.setActiveStudent('reward-a');
    await app.loadLearningProfile();
    app.addRewards(stars: 7, xp: 10);
    await wallet.entered.future;
    await app.school.setActiveStudent('reward-b');
    wallet.release.complete();
    await app.flushRewards();
    expect((await wallet.load()).earnedStarsByOwner, {'reward-a': 7});
  });

  for (final input in ['3 − 8', 'Anfangsbuchstabe Mama', '2, 4, 6, ?']) {
    testWidgets(
        '390dp text to preview to identical renderer and real result: $input',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = (await tester.runAsync(_app))!;
      addTearDown(app.dispose);
      await tester.pumpWidget(
          MaterialApp(home: LumoTaskRecognitionScreen(appState: app)));
      await _frames(tester);
      await tester.enterText(
          find.byKey(const ValueKey('recognition-input')), input);
      await tester
          .ensureVisible(find.byKey(const ValueKey('recognition-parse')));
      await tester.tap(find.byKey(const ValueKey('recognition-parse')));
      await _frames(tester, 4);
      final parsed = RecognizedTask.parse(input);
      expect(
          tester
              .widget<Text>(find.byKey(const ValueKey('recognition-preview')))
              .data,
          parsed.prompt);
      final start = find.byKey(const ValueKey('recognition-start'));
      await tester.ensureVisible(start);
      expect(tester.getSize(start).height, greaterThanOrEqualTo(48));
      await tester.tap(start);
      await _frames(tester);
      final renderer = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
      expect(renderer.task.prompt, parsed.prompt);
      expect(renderer.task.correctAnswer, parsed.answer);
      final option = find
          .descendant(
              of: find.byType(AdaptiveTaskRenderer),
              matching: find.text(parsed.answer))
          .last;
      await tester.ensureVisible(option);
      await tester.tap(option);
      await _frames(tester);
      expect(find.byKey(const ValueKey('recognition-result')), findsOneWidget);
      expect(find.text('6 Sterne · 25 XP'), findsOneWidget);
      expect(
          (await tester.runAsync(() => app.attemptLog.load()))!.single.prompt,
          parsed.prompt);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'invalid input and editing or switching profile cannot launch a stale preview',
      (tester) async {
    final app = (await tester.runAsync(_app))!;
    addTearDown(app.dispose);
    await tester.pumpWidget(
        MaterialApp(home: LumoTaskRecognitionScreen(appState: app)));
    await _frames(tester);
    final field = find.byKey(const ValueKey('recognition-input'));
    await tester.enterText(field, '1, 2, 4, ?');
    await tester.tap(find.byKey(const ValueKey('recognition-parse')));
    await _frames(tester, 4);
    expect(find.byKey(const ValueKey('recognition-error')), findsOneWidget);
    expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
    await tester.enterText(field, '12+7');
    await tester.ensureVisible(find.byKey(const ValueKey('recognition-parse')));
    await tester.tap(find.byKey(const ValueKey('recognition-parse')));
    await _frames(tester, 4);
    expect(find.byKey(const ValueKey('recognition-preview')), findsOneWidget);
    await tester.enterText(field, '6×3');
    await _frames(tester, 2);
    expect(find.byKey(const ValueKey('recognition-start')), findsNothing);
    await tester.runAsync(() => app.school.setActiveStudent('other-child'));
    await _frames(tester);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
