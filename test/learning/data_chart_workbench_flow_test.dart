import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/data_chart_exercise.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/data_chart_workbench.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_mistake_help_card.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

const _unit = 'Datenwerkstatt';
const _quiet = AppSettings(
  soundEnabled: false,
  voiceEnabled: false,
  autoReadEnabled: false,
  aiProxyEnabled: false,
  reduceAnimations: true,
);
const _captureKey = ValueKey('data-workbench-capture');

LumoTask _draw(ExerciseFactory factory) => factory.nextExact(
      grade: 2,
      subject: 'Mathematik',
      unit: _unit,
      currentGradeOnly: true,
    );

TaskInstance _task(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer)).task;

Future<void> _settle(WidgetTester tester, [int passes = 5]) async {
  for (var i = 0; i < passes; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pump();
}

Future<void> _button(WidgetTester tester, String key) =>
    _tap(tester, find.byKey(ValueKey('data-chart-$key')));

Future<void> _advance(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 7));
  await _settle(tester);
}

Future<List<Attempt>> _attempts(WidgetTester tester, LumoAppState app) async {
  var finished = false;
  unawaited(app.flushLearningProgress().whenComplete(() => finished = true));
  for (var i = 0; i < 600 && !finished; i++) {
    await _settle(tester, 1);
  }
  expect(finished, isTrue);
  return (await tester.runAsync(() => app.attemptLog.load()))!;
}

Future<void> _capture(WidgetTester tester, String name) async {
  final output = Platform.environment['LUMO_DATA_CHART_CAPTURES'];
  if (output != null) {
    await captureLumoBoundary(tester, _captureKey, '$output/$name.png');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(LumoCompanionRequests.instance.clearLearningScope);

  test('grade 2 uses both formats and orientations with real data and zeros',
      () {
    expect(Curriculum.unitsForGrade('Mathematik', 1, currentGradeOnly: true),
        isNot(contains(_unit)));
    expect(Curriculum.unitsForGrade('Mathematik', 2, currentGradeOnly: true),
        contains(_unit));
    expect(Curriculum.unitsForGrade('Mathematik', 4, currentGradeOnly: true),
        contains('Diagramme lesen'));
    final combinations = <(bool, bool)>{};
    final counts = <int>{};
    var missing = false;
    final factory = ExerciseFactory(seed: 242);
    for (var i = 0; i < 128; i++) {
      final task = _draw(factory);
      final chart = task.dataChart!;
      expect(const TaskQualityGuard().problems(task), isEmpty);
      expect(task.answer, '${chart.requested.value}');
      expect(task.prompt, contains('„${chart.requested.label}“'));
      combinations.add((chart.pictogram, chart.horizontal));
      counts.add(chart.requested.value!);
      missing |= chart.rows.any((row) => row.value == null);
    }
    expect(combinations, hasLength(4));
    expect(counts, {0, 1, 2, 3, 4, 5});
    expect(missing, isTrue);
  });

  testWidgets('Fold cover reaches the real grade 2 lesson from mathematics',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2026, 11, 26);
    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: AppShell(
        profile: UserProfile(
            id: 'chart-route',
            name: 'Mia',
            age: 8,
            grade: 2,
            createdAt: date,
            lastActiveAt: date),
        initialSection: LumoSection.learn,
      ),
    ));
    await _settle(tester);
    await _tap(
        tester, find.byKey(const ValueKey('learning-subject-Mathematik')));
    await _settle(tester);
    final unit = find.byKey(const ValueKey('learning-unit-Mathematik-$_unit'));
    await tester.scrollUntilVisible(unit, 160,
        scrollable: find.descendant(
          of: find.byType(LumoLearningHub),
          matching: find.byType(Scrollable),
        ));
    await _tap(tester, unit);
    await _settle(tester);
    expect(_task(tester).parameters['unit'], _unit);
    expect(find.byType(DataChartObservations), findsOneWidget);
    expect(find.byType(DataChartAnswer), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester);
  });

  testWidgets(
      'independent transfer follows guided repair and logs only submitted choices',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final seed = Iterable.generate(300).firstWhere((seed) {
      final chart = _draw(ExerciseFactory(seed: seed)).dataChart!;
      return chart.pictogram &&
          chart.requested.value == 0 &&
          chart.rows.any((row) => row.value == null);
    });
    late LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
      app.updateSettings(_quiet);
      app.update(app.state.copyWith(
          childName: 'Mia',
          grade: 2,
          subject: 'Mathematik',
          unit: _unit,
          sessionKind: LumoSessionKind.quickPractice));
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
      app.dispose();
    });
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: LumoAppTheme.light(),
      home: RepaintBoundary(
          key: _captureKey,
          child: Scaffold(
            body: LearningContent(appState: app, taskSeed: seed),
          )),
    ));
    await _settle(tester);
    final source = _task(tester);
    final data = source.visualPayload.data['dataChart']! as DataChartExercise;
    expect(source.correctAnswer, 0);
    expect(find.text('Fehlt'), findsWidgets);
    expect(find.textContaining('offen'), findsWidgets);
    final submit = find.byKey(const ValueKey('data-chart-submit'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    final before = (app.state.stars, app.state.xp);
    await _button(tester, 'add');
    expect(await _attempts(tester, app), isEmpty);
    expect((app.state.stars, app.state.xp), before);
    await _button(tester, 'submit');
    expect(find.textContaining('Suche die Zeile'), findsWidgets);
    await _button(tester, 'add');
    await _button(tester, 'submit');
    expect(find.textContaining('Zähle nur die Kästchen'), findsWidgets);
    expect(find.textContaining('trage ausdrücklich Null ein'), findsWidgets);
    await _capture(tester, 'datenwerkstatt-fehlerhilfe-344dp');
    await _button(tester, 'zero');
    expect(find.text('Dein Eintrag für ${data.requested.label}: 0'),
        findsOneWidget);
    await _button(tester, 'submit');
    await _advance(tester);
    await _submitRealCount(tester, _task(tester).correctAnswer as int);
    await _advance(tester);
    expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
    final twin = _task(tester);
    final sameSkill =
        twin.visualPayload.data['dataChart']! as DataChartExercise;
    expect(twin.prompt, isNot(source.prompt));
    expect(twin.correctAnswer, isNot(source.correctAnswer));
    expect(sameSkill.pictogram, data.pictogram);
    expect(sameSkill.horizontal, data.horizontal);
    expect(find.textContaining('offen'), findsWidgets);
    await _capture(tester, 'datenwerkstatt-eigenstaendig-344dp');
    await _submitRealCount(tester, twin.correctAnswer as int);
    final attempts = await _attempts(tester, app);
    expect(attempts, hasLength(5));
    final original =
        attempts.where((attempt) => attempt.prompt == source.prompt);
    expect(
        original.where((attempt) => attempt.correct).single.hintUsed, isTrue);
    final comparison = attempts
        .singleWhere((attempt) => attempt.check == Attempt.vergleichNachHilfe);
    expect(comparison.prompt, twin.prompt);
    expect(comparison.reference, source.prompt);
    expect(comparison.confirmsAfterHelp, isTrue);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _submitRealCount(WidgetTester tester, int count) async {
  if (count == 0) await _button(tester, 'zero');
  for (var i = 0; i < count; i++) {
    await _button(tester, 'add');
  }
  await _button(tester, 'submit');
}
