import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/lumo_premium_visuals.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/lumo3d/lumo3d_launcher.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

TaskInstance task(String prompt, String answer, String visual,
        {List<String>? choices}) =>
    const LegacyLumoTaskAdapter().toTaskInstance(
      task: LumoTask(
        id: 'studio-current-task',
        grade: 3,
        subject: 'Mathematik',
        unit: 'Mathematik',
        prompt: prompt,
        answer: answer,
        choices: choices ?? [answer, '97', '98'],
        explanation: 'Wir probieren dieselbe Aufgabe mit Objekten.',
        visual: visual,
      ),
      childId: 'synthetic-studio-child',
      difficulty: 2,
    );

TaskInstance typed(Map<String, Object?> data, Object answer) => TaskInstance(
      taskInstanceId: 'typed-studio',
      templateId: 'typed-studio',
      childId: 'synthetic',
      seedHash: 'studio',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('division'),
      taskType: TaskType.multipleChoice,
      difficulty: 2,
      parameters: const {},
      prompt: 'Aktuelle Aufgabe',
      options: const [],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: VisualType.divisionGroups, data: data),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 11, 13),
    );

class _LearningLaunchState extends LumoAppState {
  @override
  Future<void> flushRewards() async {}
  @override
  Future<void> ensureSettingsLoaded() async {}
  @override
  bool get canPlayToday => false;
}

Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(child: SizedBox(width: 390, child: child)),
    ));

Future<void> frames(WidgetTester tester, [int count = 30]) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('actual current division and multiplication reach exact native objects',
      () {
    final sharing = task('12 : 3 = ?', '4', 'division');
    expect(sharing.visualPayload.data,
        {'operation': 'division', 'left': 12, 'right': 3});
    expect(NativeLearningActivity.fromTask(sharing)!.toLaunchOptions(),
        {'kind': 'equal_sharing', 'a': 12, 'b': 3});
    expect(
        NativeLearningActivity.fromTask(task('3 × 4 = ?', '12', 'times_table'))!
            .toLaunchOptions(),
        {'kind': 'equal_groups', 'a': 3, 'b': 4});
  });

  test('fraction addition keeps rational answers and both real operands', () {
    final fraction = task('1/4 + 2/4 = ?', '3/4', 'fraction_add',
        choices: ['3/4', '1/23', '12/3']);
    expect(fraction.correctAnswer, '3/4');
    expect(fraction.options.map((option) => option.payload).toSet(),
        {'3/4', '1/23', '12/3'});
    expect(fraction.visualPayload.data, {
      'operation': 'fraction_addition',
      'numerator': 1,
      'denominator': 4,
      'extra': 2,
    });
    expect(NativeLearningActivity.fromTask(fraction)!.toLaunchOptions(),
        {'kind': 'fraction_parts', 'a': 1, 'b': 4, 'extra': 2});
    expect(
        NativeLearningActivity.fromTask(typed({
          'operation': 'fraction_addition',
          'numerator': 1,
          'denominator': 4,
          'extra': 1,
        }, '1/2'))!
            .kind,
        'fraction_parts');
  });

  test('new descriptors reject fractional, oversized and mismatched tasks', () {
    for (final scenario in [
      ({'operation': 'division', 'left': 13, 'right': 3}, 4),
      ({'operation': 'division', 'left': 12.5, 'right': 3}, 4),
      ({'operation': 'division', 'left': 12, 'right': 3}, 5),
      ({'operation': 'division', 'left': 12, 'right': 0}, 4),
      ({'operation': 'division', 'left': 42, 'right': 6}, 7),
      ({'operation': 'multiplication', 'left': 7, 'right': 6}, 42),
      (
        {
          'operation': 'fraction_addition',
          'numerator': 3,
          'denominator': 4,
          'extra': 2
        },
        '5/4'
      ),
      (
        {
          'operation': 'fraction_addition',
          'numerator': 1,
          'denominator': 4,
          'extra': 2
        },
        '2/4'
      ),
    ]) {
      expect(NativeLearningActivity.fromTask(typed(scenario.$1, scenario.$2)),
          isNull,
          reason: '$scenario');
    }
    expect(
        NativeLearningActivity.fromTask(task(
            '1/4 + 1/3 = ?', '7/12', 'fraction_add',
            choices: ['7/12', '2/7', '1/7'])),
        isNull);
  });

  test(
      'real local generator families reach native learning without replacement',
      () {
    for (final id in ['g2_tables', 'g3_division_basic', 'g4_fraction_add']) {
      final template =
          MathTaskTemplates.templates.singleWhere((item) => item.id == id);
      var reached = 0;
      for (var seed = 0; seed < 180; seed++) {
        final generated = template.concretize(seed);
        final adapted = task(
            generated.prompt, generated.answer, generated.visual,
            choices: generated.choices);
        final descriptor = NativeLearningActivity.fromTask(adapted);
        expect(adapted.prompt, generated.prompt);
        if (descriptor != null) {
          reached++;
          expect(
              descriptor.kind,
              switch (id) {
                'g2_tables' => 'equal_groups',
                'g3_division_basic' => 'equal_sharing',
                _ => 'fraction_parts',
              });
        }
      }
      expect(reached, greaterThan(0), reason: id);
    }
  });

  testWidgets('all eight groups and 72 units are shown for 72 divided by 8',
      (tester) async {
    await tester.pumpWidget(
        wrap(DivisionGroupsVisual(task: task('72 : 8 = ?', '9', 'division'))));
    for (var group = 0; group < 8; group++) {
      expect(find.byKey(ValueKey('division-group-$group')), findsOneWidget);
      for (var unit = 0; unit < 9; unit++) {
        expect(
            find.byKey(ValueKey('division-one-$group-$unit')), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('large exact quantities use counted bundles in every group',
      (tester) async {
    await tester.pumpWidget(wrap(
        DivisionGroupsVisual(task: task('240 : 12 = ?', '20', 'division'))));
    for (var group = 0; group < 12; group++) {
      expect(find.text('Gruppe ${group + 1} · 20'), findsOneWidget);
      for (var bundle = 0; bundle < 2; bundle++) {
        expect(find.byKey(ValueKey('division-ten-$group-$bundle')),
            findsOneWidget);
      }
      expect(find.byKey(ValueKey('division-one-$group-0')), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('fraction addition displays plus rather than false equality',
      (tester) async {
    await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: task('1/4 + 2/4 = ?', '3/4', 'fraction_add',
            choices: ['3/4', '2/4', '4/4']))));
    expect(find.text('+'), findsOneWidget);
    expect(find.text('='), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'real fraction help returns to the task and stores assisted evidence',
      (tester) async {
    const channel = MethodChannel('lumo_lernen/bridge');
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'studio-fraction-profile'});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'learn'};
    });
    LumoAppState? app;
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1000));
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        app!.update(app!.state.copyWith(
            grade: 4,
            subject: 'Mathematik',
            unit: 'Bruchrechnen einfach',
            sessionKind: LumoSessionKind.quickPractice,
            section: LumoSection.learn));
        await app!.school.setActiveStudent('synthetic-studio-fraction-child');
        await app!.hydrateFromWallet();
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            reduceAnimations: true));
      });
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: LearningContent(appState: app!))));
      await frames(tester, 40);
      final current = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(current.correctAnswer, isA<String>());
      expect('${current.correctAnswer}', contains('/'));
      final activity = NativeLearningActivity.fromTask(current)!;
      expect(activity.kind, 'fraction_parts');
      final help = find.byKey(const ValueKey('adaptive-open-3d'));
      await tester.ensureVisible(help);
      await tester.tap(help);
      await frames(tester, 40);
      expect(calls, hasLength(1));
      expect((calls.single.arguments as Map)['learning'],
          activity.toLaunchOptions());
      expect(
          tester
              .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
              .task
              .taskInstanceId,
          current.taskInstanceId);
      expect(LumoCompanionRequests.instance.taskContext.value!.helpLevel, 1);
      expect(app!.state.stars, 0,
          reason:
              'Returning from a 3D explanation is not an answer or reward.');
      final beforeWeak = Map<String, int>.from(app!.state.weakSkills);
      final wrong = current.options
          .firstWhere((option) => option.payload != current.correctAnswer);
      final answer = find
          .descendant(
              of: find.byType(AdaptiveTaskRenderer),
              matching: find.text(wrong.label))
          .last;
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await frames(tester);
      var saved = false;
      app!.flushLearningProgress().then((_) => saved = true);
      for (var frame = 0; frame < 100 && !saved; frame++) {
        await frames(tester, 1);
      }
      expect(saved, isTrue);
      expect(app!.state.weakSkills, beforeWeak);
      await tester.runAsync(() async {
        final history = await app!.attemptLog.load();
        final recorded =
            history.lastWhere((entry) => entry.prompt == current.prompt);
        expect(recorded.correct, isFalse);
        expect(recorded.hintUsed, isTrue);
        expect(recorded.given, wrong.label);
      });
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  testWidgets(
      'all new current-task descriptors reach the existing Android launcher',
      (tester) async {
    const channel = MethodChannel('lumo_lernen/bridge');
    SharedPreferences.setMockInitialValues(
        {'lumo_3d_save_salt_v1': 'studio-native-test'});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, Object?>{'destination': 'learn'};
    });
    final app = _LearningLaunchState();
    try {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (current) {
        context = current;
        return const Scaffold(body: Text('Aktuelle Aufgabe'));
      })));
      for (final current in [
        task('12 : 3 = ?', '4', 'division'),
        task('3 × 4 = ?', '12', 'times_table'),
        task('1/4 + 2/4 = ?', '3/4', 'fraction_add',
            choices: ['3/4', '2/4', '4/4']),
      ]) {
        final activity = NativeLearningActivity.fromTask(current)!;
        final launched = launchLumo3D(context,
            scene: 'learning', appState: app, learning: activity);
        for (var frame = 0; frame < 30; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        }
        expect(await launched, isTrue);
        final options = calls.last.arguments as Map;
        expect(options['scene'], 'learning');
        expect(options['learning'], activity.toLaunchOptions());
        expect(options['childKey'], matches(r'^p_[a-f0-9]{32}$'));
        expect(app.state.stars, 0);
      }
      expect(calls, hasLength(3));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });
}
