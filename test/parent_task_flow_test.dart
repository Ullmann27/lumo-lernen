import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/parent_task_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/learning/parent_authored_task.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/parent_tasks/parent_task_practice_screen.dart';
import 'package:lumo_lernen/features/parent_tasks/parent_task_workspace_controller.dart';
import 'package:lumo_lernen/features/parent_tasks/parent_tasks_editor_card.dart';
import 'package:lumo_lernen/features/parent_tasks/parent_tasks_entry_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

ParentTaskDraft _draft() => ParentTaskDraft(
    subject: LearningSubject.mathematik,
    grade: 2,
    prompt: 'Wie viele Beine haben zwei Katzen?',
    correctAnswer: '8 Beine',
    options: ['8 Beine', '4 Beine', '6 Beine'],
    explanation: 'Jede Katze hat vier Beine: vier plus vier sind acht.');

class _ControlledStore extends InMemorySharedPreferencesStore {
  _ControlledStore()
      : super.withData({
          'flutter.${LegacyLearningDataRepository.localIdKey}':
              'local-parent-test',
        });
  bool rejectCompletion = false;
  Completer<void>? logEntered;
  Completer<void>? releaseLog;

  @override
  Future<bool> setValue(String type, String key, Object value) async {
    if (rejectCompletion &&
        key.contains(ParentTaskRepository.storageBase) &&
        (jsonDecode(value as String) as Map)['activeAttempt']?['completed'] ==
            true) {
      return false;
    }
    if (key == 'flutter.lumo_attempt_log_v1' &&
        logEntered != null &&
        !logEntered!.isCompleted) {
      logEntered!.complete();
      await releaseLog!.future;
    }
    return super.setValue(type, key, value);
  }
}

Future<LumoAppState> _app() async {
  final app = LumoAppState(walletRepository: RewardWalletRepository());
  await app.ensureSettingsLoaded();
  await app.loadLearningProfile();
  await app.hydrateFromWallet();
  return app;
}

Future<void> _ready(ParentTaskWorkspaceController controller) async {
  for (var i = 0; i < 200 && !controller.ready; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(controller.error, isNull);
  expect(controller.ready, isTrue);
}

AdaptiveTaskAnswer _answer(ParentTaskWorkspaceController controller,
    {bool correct = true}) {
  final attempt = controller.activeAttempt!;
  return AdaptiveTaskAnswer(
      task: attempt.task
          .toTaskInstance(attemptId: attempt.id, startedAt: attempt.startedAt),
      answer: correct ? '8 Beine' : '4 Beine',
      correct: correct);
}

Future<void> _pumpIo(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 17));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({
      LegacyLearningDataRepository.localIdKey: 'local-parent-test',
    });
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  test(
      'double submit logs once, uses canonical reward and leaves curriculum unchanged',
      () async {
    final app = await _app();
    final controller = ParentTaskWorkspaceController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    await controller.save(_draft());
    await controller.start(controller.workspace!.tasks.single.id);
    final firstId = controller.activeAttempt!.id;
    final before = app.learningDailyDone();
    final answer = _answer(controller);
    final results = await Future.wait(
        [controller.answer(answer), controller.answer(answer)]);
    expect(results, [true, false]);
    expect(controller.activeAttempt!.completed, isTrue);
    expect(app.state.stars, 6);
    expect(app.state.xp, 25);
    final attempts = await app.attemptLog.load(studentId: 'self');
    expect(attempts.single.id, firstId);
    expect(attempts.single.subject, 'Elternaufgaben');
    expect(attempts.single.unit, 'Mathematik · Klasse 2');
    expect(app.learningDailyDone(), before);
    expect(app.state.solved, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(
        prefs
            .getKeys()
            .where((key) => key.startsWith('lumo_progress_skills::')),
        isEmpty);
    expect(
        prefs
            .getKeys()
            .where((key) => key.startsWith('lumo_daily_mission_v1::')),
        isEmpty);
    await controller.leaveAttempt();
    await controller.start(controller.workspace!.tasks.single.id);
    expect(controller.activeAttempt!.id, isNot(firstId));
    await controller.answer(_answer(controller, correct: false));
    expect((await app.attemptLog.load(studentId: 'self')).length, 2);
    expect(app.state.stars, 6);
    expect(app.state.xp, 25);
  });

  test('restart after wallet success and failed receipt never pays twice',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    var app = await _app();
    var controller = ParentTaskWorkspaceController(app);
    await _ready(controller);
    await controller.save(_draft());
    await controller.start(controller.workspace!.tasks.single.id);
    final id = controller.activeAttempt!.id;
    store.rejectCompletion = true;
    expect(await controller.answer(_answer(controller)), isFalse);
    expect(controller.hasPendingResult, isTrue);
    expect(app.state.stars, 6);
    expect((await app.attemptLog.load()).length, 1);
    controller.dispose();
    app.dispose();
    store.rejectCompletion = false;
    app = await _app();
    controller = ParentTaskWorkspaceController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await _ready(controller);
    expect(controller.activeAttempt!.id, id);
    expect(controller.activeAttempt!.completed, isFalse);
    expect(await controller.retryResult(), isTrue);
    expect(controller.activeAttempt!.completed, isTrue);
    expect(app.state.stars, 6);
    expect(app.state.xp, 25);
    expect((await app.attemptLog.load()).single.id, id);
    final wallet = await RewardWalletRepository().load();
    expect(wallet.gameResultIds.where((value) => value == id).length, 1);
  });

  test('profile switch during accepted answer hides A and resumes only under A',
      () async {
    final store = _ControlledStore();
    SharedPreferencesStorePlatform.instance = store;
    final app = await _app();
    final controller = ParentTaskWorkspaceController(app);
    addTearDown(() {
      controller.dispose();
      app.dispose();
    });
    await app.school.setActiveStudent('child-a');
    await _ready(controller);
    await controller.save(_draft());
    await controller.start(controller.workspace!.tasks.single.id);
    final id = controller.activeAttempt!.id;
    store.logEntered = Completer<void>();
    store.releaseLog = Completer<void>();
    final submitting = controller.answer(_answer(controller));
    await store.logEntered!.future;
    await app.school.setActiveStudent('child-b');
    expect(controller.workspace, isNull);
    expect(controller.activeAttempt, isNull);
    store.releaseLog!.complete();
    expect(await submitting, isFalse);
    await _ready(controller);
    expect(controller.lease!.studentId, 'child-b');
    expect(controller.workspace!.hasChildContent, isFalse);
    expect(app.state.stars, 0);
    expect(await app.attemptLog.load(studentId: 'child-b'), isEmpty);
    await app.school.setActiveStudent('child-a');
    await _ready(controller);
    expect(controller.activeAttempt!.id, id);
    expect(await controller.retryResult(), isTrue);
    expect((await app.attemptLog.load(studentId: 'child-a')).single.id, id);
    expect(app.state.stars, 6);
  });

  testWidgets(
      'parent creates task, restart exposes Home entry and real renderer saves answer',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var app = (await tester.runAsync(_app))!;
    Widget shell() => MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
          ParentTasksEditorCard(appState: app),
          ParentTasksEntryCard(appState: app),
        ]))));
    await tester.pumpWidget(shell());
    await _pumpIo(tester);
    expect(find.byKey(const ValueKey('parent-tasks-home-entry')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('parent-task-add')));
    await _pumpIo(tester, 4);
    await tester.enterText(
        find.byKey(const ValueKey('parent-task-question')), _draft().prompt);
    await tester.enterText(
        find.byKey(const ValueKey('parent-task-correct')), '8 Beine');
    await tester.enterText(
        find.byKey(const ValueKey('parent-task-other-answers')),
        '4 Beine\n6 Beine');
    await tester.enterText(
        find.byKey(const ValueKey('parent-task-explanation')),
        _draft().explanation);
    await tester.ensureVisible(find.byKey(const ValueKey('parent-task-save')));
    await tester.tap(find.byKey(const ValueKey('parent-task-save')));
    await _pumpIo(tester);
    expect(find.byKey(const ValueKey('parent-task-save')), findsNothing);
    expect(
        find.byKey(const ValueKey('parent-tasks-home-entry')), findsOneWidget);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('parent-tasks-home-entry')))
            .height,
        greaterThanOrEqualTo(48));
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    app = (await tester.runAsync(_app))!;
    await tester.pumpWidget(shell());
    await _pumpIo(tester);
    final task = (await tester.runAsync(
            () => ParentTaskRepository(studentId: 'local-parent-test').load()))!
        .tasks
        .single;
    await tester
        .ensureVisible(find.byKey(const ValueKey('parent-tasks-home-entry')));
    await tester.tap(find.byKey(const ValueKey('parent-tasks-home-entry')));
    await _pumpIo(tester);
    expect(find.byType(ParentTaskPracticeScreen), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('parent-task-start-${task.id}')));
    await _pumpIo(tester);
    expect(find.byType(AdaptiveTaskRenderer), findsOneWidget);
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    expect(renderer.task.prompt, task.content.prompt);
    final option = find
        .descendant(
            of: find.byType(AdaptiveTaskRenderer),
            matching: find.text('8 Beine'))
        .last;
    await tester.ensureVisible(option);
    await tester.tap(option);
    await _pumpIo(tester);
    expect(find.byKey(const ValueKey('parent-task-result')), findsOneWidget);
    expect(find.text(_draft().explanation), findsOneWidget);
    expect(find.text('6 Sterne · 25 XP'), findsOneWidget);
    final attempts =
        (await tester.runAsync(() => app.attemptLog.load(studentId: 'self')))!;
    expect(attempts.single.subject, 'Elternaufgaben');
    expect(attempts.single.given, '8 Beine');
    expect(attempts.single.correct, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets(
      'profile switch closes stale editor and hides previous child Home entry',
      (tester) async {
    final app = (await tester.runAsync(_app))!;
    await tester.runAsync(() async {
      await app.school.setActiveStudent('child-a');
      await ParentTaskRepository(studentId: 'child-a').save(_draft());
    });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
      ParentTasksEditorCard(appState: app),
      ParentTasksEntryCard(appState: app)
    ])))));
    await _pumpIo(tester);
    await tester.tap(find.byKey(const ValueKey('parent-task-add')));
    await _pumpIo(tester, 3);
    await tester.enterText(
        find.byKey(const ValueKey('parent-task-question')), 'Nur für A');
    await tester.runAsync(() => app.school.setActiveStudent('child-b'));
    await _pumpIo(tester);
    expect(find.byKey(const ValueKey('parent-task-question')), findsNothing);
    expect(find.byKey(const ValueKey('parent-task-save')), findsNothing);
    expect(find.textContaining('Das Kinderprofil wurde gewechselt.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('parent-tasks-home-entry')), findsNothing);
    expect(
        (await tester.runAsync(
                () => ParentTaskRepository(studentId: 'child-b').load()))!
            .tasks,
        isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
    expect(tester.takeException(), isNull);
  });
}
