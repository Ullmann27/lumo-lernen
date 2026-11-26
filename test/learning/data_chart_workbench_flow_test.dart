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
const _tallyUnit = 'Strichlisten und Tabellen';
const _quiet = AppSettings(
  soundEnabled: false,
  voiceEnabled: false,
  autoReadEnabled: false,
  aiProxyEnabled: false,
  reduceAnimations: true,
);
const _captureKey = ValueKey('data-workbench-capture');

LumoTask _draw(ExerciseFactory factory, {int grade = 2}) => factory.nextExact(
      grade: grade,
      subject: 'Mathematik',
      unit: grade == 1 ? _tallyUnit : _unit,
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

  test(
      'grade 1 has one named tally lesson and keeps missing data out of scoring',
      () {
    expect(Curriculum.unitsForGrade('Mathematik', 1, currentGradeOnly: true),
        contains(_tallyUnit));
    final counts = <int>{};
    final factory = ExerciseFactory(seed: 19);
    for (var i = 0; i < 96; i++) {
      final task = _draw(factory, grade: 1);
      final transfer = task.dataChart!;
      expect(transfer.tallyToTable, isTrue);
      expect(task.prompt.length, lessThan(62));
      expect(const TaskQualityGuard().problems(task), isEmpty);
      expect(task.answer, '${transfer.requested.value}');
      counts.add(transfer.requested.value!);
    }
    expect(counts, {0, 1, 2, 3, 4, 5});
  });

  for (final (grade, lesson) in [(1, _tallyUnit), (2, _unit)]) {
    testWidgets(
        'Fold cover reaches the real grade $grade lesson from mathematics',
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
              age: 6 + grade,
              grade: grade,
              createdAt: date,
              lastActiveAt: date),
          initialSection: LumoSection.learn,
        ),
      ));
      await _settle(tester);
      await _tap(
          tester, find.byKey(const ValueKey('learning-subject-Mathematik')));
      await _settle(tester);
      final unit = find.byKey(ValueKey('learning-unit-Mathematik-$lesson'));
      await tester.scrollUntilVisible(unit, 160,
          scrollable: find.descendant(
            of: find.byType(LumoLearningHub),
            matching: find.byType(Scrollable),
          ));
      await _tap(tester, unit);
      await _settle(tester);
      expect(_task(tester).parameters['unit'], lesson);
      expect(_task(tester).options.map((option) => option.payload), [0, 1, 2, 3, 4, 5]);
      expect(find.byType(DataChartObservations), findsOneWidget);
      expect(find.byType(DataChartAnswer), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await _settle(tester);
    });

    testWidgets(
        'grade $grade independent transfer follows guided repair and logs only submitted choices',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(344, 882));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final tally = grade == 1;
      final seed = Iterable.generate(300).firstWhere((seed) {
        final chart =
            _draw(ExerciseFactory(seed: seed), grade: grade).dataChart!;
        return (tally
                ? chart.rows.any((row) => row.value == 5)
                : chart.pictogram) &&
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
            grade: grade,
            subject: 'Mathematik',
            unit: lesson,
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
      expect(data.tallyToTable, tally);
      expect(find.text(tally ? 'Nicht gezählt' : 'Fehlt'), findsWidgets);
      expect(find.textContaining(tally ? 'Offen' : 'offen'), findsWidgets);
      if (tally) {
        final observed =
            find.byKey(ValueKey('data-observation-${data.requested.label}'));
        expect(tester.widget<Text>(observed).data, '0');
        expect(find.bySemanticsLabel(RegExp('Schrägstrich')), findsOneWidget);
      }
      final submit = find.byKey(const ValueKey('data-chart-submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);
      final before = (app.state.stars, app.state.xp);
      await _setRealCount(tester, 1, tally: tally);
      expect(await _attempts(tester, app), isEmpty);
      expect((app.state.stars, app.state.xp), before);
      await _button(tester, 'submit');
      expect(find.textContaining(tally ? 'Such die Zeile' : 'Suche die Zeile'),
          findsWidgets);
      final workbench = find.byType(DataChartAnswer);
      expect(tester.widget<DataChartAnswer>(workbench).rejectedValues, {'1'});
      if (tally) {
        await _setRealCount(tester, 2, tally: true);
        final answerCell =
            find.byKey(ValueKey('data-table-${data.requested.label}'));
        expect(tester.widget<Text>(answerCell).data, '2');
        expect(tester.getRect(answerCell).right,
            tester.getRect(find.text('Anzahl')).right);
      } else {
        await _button(tester, 'add');
        expect(find.text('Dein Eintrag für ${data.requested.label}: 2'),
            findsOneWidget);
      }
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
      await _button(tester, 'submit');
      await _settle(tester);
      final worked = find.byType(LumoWorkedSolutionCard);
      expect(worked, findsOneWidget);
      expect(
          tester.widget<LumoWorkedSolutionCard>(worked).steps.first,
          startsWith(tally
              ? 'Zähle die Striche'
              : data.pictogram
                  ? 'Zähle nur die Kästchen'
                  : 'Lies die Zahl rechts'));

      expect(
          find.textContaining(tally
              ? 'Gezählt und nichts gefunden'
              : 'trage ausdrücklich Null ein'),
          findsWidgets);
      final prefix = tally ? 'strichliste' : 'datenwerkstatt';
      await _capture(tester, '$prefix-fehlerhilfe-344dp');
      await _setRealCount(tester, 0, tally: tally);
      if (tally) {
        final answerCell =
            find.byKey(ValueKey('data-table-${data.requested.label}'));
        expect(tester.widget<Text>(answerCell).data, '0');
      } else {
        expect(find.text('Dein Eintrag für ${data.requested.label}: 0'),
            findsOneWidget);
      }
      await _button(tester, 'submit');
      await _advance(tester);
      await _setRealCount(tester, _task(tester).correctAnswer as int,
          tally: tally);
      await _button(tester, 'submit');
      await _advance(tester);
      expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
      final twin = _task(tester);
      final sameSkill =
          twin.visualPayload.data['dataChart']! as DataChartExercise;
      expect(twin.prompt, isNot(source.prompt));
      expect(twin.correctAnswer, isNot(source.correctAnswer));
      expect(sameSkill.pictogram, data.pictogram);
      expect(sameSkill.horizontal, data.horizontal);
      expect(sameSkill.tallyToTable, data.tallyToTable);
      expect(find.textContaining(tally ? 'Offen' : 'offen'), findsWidgets);
      await _capture(tester, '$prefix-eigenstaendig-344dp');
      await _setRealCount(tester, twin.correctAnswer as int, tally: tally);
      await _button(tester, 'submit');
      final attempts = await _attempts(tester, app);
      expect(attempts, hasLength(5));
      final original =
          attempts.where((attempt) => attempt.prompt == source.prompt);
      expect(
          original.where((attempt) => attempt.correct).single.hintUsed, isTrue);
      final comparison = attempts.singleWhere(
          (attempt) => attempt.check == Attempt.vergleichNachHilfe);
      expect(comparison.prompt, twin.prompt);
      expect(comparison.reference, source.prompt);
      expect(comparison.confirmsAfterHelp, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}

Future<void> _setRealCount(WidgetTester tester, int count,
    {required bool tally}) async {
  if (tally) {
    final choice = find.byKey(ValueKey('data-table-choice-$count'));
    expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
    await _tap(tester, choice);
    return;
  }
  if (count == 0) await _button(tester, 'zero');
  for (var i = 0; i < count; i++) {
    await _button(tester, 'add');
  }
}
