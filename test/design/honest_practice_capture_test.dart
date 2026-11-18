import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_mistake_help_card.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

/// "Ehrlich üben" on a phone (390×844) with the real fonts: the help after
/// the first and the second wrong answer, the returning similar task, the
/// session summary and a topic tile "Am Anfang".
///
/// The layout is always checked. PNGs are only written when
/// `LUMO_L1_CAPTURES` names a folder.
const _boundary = ValueKey('honest-practice-capture');
const _size = Size(390, 844);

Future<void> _settle(WidgetTester tester, [int rounds = 6]) async {
  for (var i = 0; i < rounds; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull, reason: name);
  final out = Platform.environment['LUMO_L1_CAPTURES'];
  if (out != null) {
    await captureLumoBoundary(tester, _boundary, '$out/$name.png');
  }
}

Widget _phone(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: true,
          padding: const EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: page!,
      ),
      home: RepaintBoundary(
        key: _boundary,
        child: Scaffold(
          backgroundColor: const Color(0xFF061A3D),
          body: SafeArea(child: child),
        ),
      ),
    );

AdaptiveTaskRenderer _renderer(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));

String _value(AnswerOption option) => '${option.payload ?? option.label}';

Future<void> _tapOption(WidgetTester tester, AnswerOption option) async {
  final target = find
      .descendant(
          of: find.byType(AdaptiveTaskRenderer),
          matching: find.text(option.label))
      .last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _solve(WidgetTester tester) async {
  final renderer = _renderer(tester);
  renderer.onAnswered!(AdaptiveTaskAnswer(
      task: renderer.task, answer: renderer.task.correctAnswer, correct: true));
  await tester.pump();
  await tester.pump(const Duration(seconds: 7));
  await tester.pump(const Duration(milliseconds: 400));
  await _settle(tester, 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.clearLearningScope();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('help after a mistake, the similar task and the summary',
      (tester) async {
    await tester.binding.setSurfaceSize(_size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    late LumoAppState app;
    await tester.runAsync(() async {
      app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
      app.updateSettings(const AppSettings(
        aiProxyEnabled: false,
        voiceEnabled: false,
        autoReadEnabled: false,
        soundEnabled: false,
        reduceAnimations: true,
      ));
      app.update(app.state.copyWith(
        childName: 'Mia',
        grade: 1,
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        sessionKind: LumoSessionKind.quickPractice,
      ));
    });
    await tester.pumpWidget(_phone(LearningContent(appState: app)));
    await _settle(tester);

    // Task 1: a recognisable mistake (one off), then a second mistake.
    final task = _renderer(tester).task;
    final correct = int.parse('${task.correctAnswer}');
    final wrong = task.options
        .where((option) => _value(option) != '${task.correctAnswer}')
        .toList()
      ..sort((a, b) => (int.parse(_value(a)) - correct)
          .abs()
          .compareTo((int.parse(_value(b)) - correct).abs()));
    await _tapOption(tester, wrong.first);
    expect(find.byType(LumoMistakeFeedbackCard), findsOneWidget);
    await _shot(tester, '01-erster-fehler-rueckmeldung');

    await _tapOption(tester, wrong[1]);
    expect(find.byType(LumoWorkedSolutionCard), findsOneWidget);
    await _shot(tester, '02-zweiter-fehler-loesungsweg');

    await _tapOption(
        tester,
        task.options
            .firstWhere((option) => _value(option) == '${task.correctAnswer}'));
    await _shot(tester, '03-gemeinsam-geloest');
    await tester.pump(const Duration(seconds: 7));
    await tester.pump(const Duration(milliseconds: 400));
    await _settle(tester, 2);

    // Task 2 is something else; task 3 is the similar task.
    await _solve(tester);
    expect(find.byType(LumoTwinTaskBanner), findsOneWidget);
    await tester.ensureVisible(find.byType(LumoTwinTaskBanner));
    await tester.pump(const Duration(milliseconds: 400));
    await _shot(tester, '04-zwillingsaufgabe-ankuendigung');

    while (find.byType(AdaptiveTaskRenderer).evaluate().isNotEmpty) {
      await _solve(tester);
    }
    expect(find.text('Einheit beendet'), findsOneWidget);
    await _shot(tester, '05-einheit-zusammenfassung');

    // Let the background saving finish before the app goes away.
    var saved = false;
    app
        .flushLearningProgress()
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => saved = true);
    for (var i = 0; i < 600 && !saved; i++) {
      await _settle(tester, 1);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await _settle(tester, 4);
    app.dispose();
  });

  testWidgets('topic tiles say "Am Anfang", "In Übung" or "Sicher"',
      (tester) async {
    await tester.binding.setSurfaceSize(_size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final units =
        Curriculum.unitsForGrade('Mathematik', 1, currentGradeOnly: true);
    SkillRecord record(String unit,
            {required int correct, int wrong = 0, List<String> days = const []}) =>
        SkillRecord(
          skillId: SkillRecord.makeId('Mathematik', unit),
          subject: 'Mathematik',
          unit: unit,
          correct: correct,
          wrong: wrong,
          independentDays: days,
        );
    final records = [
      record(units[0], correct: 2, wrong: 1),
      record(units[1], correct: 5, wrong: 3),
      record(units[2],
          correct: 9, wrong: 1, days: ['2026-11-15', '2026-11-17']),
    ];
    await tester.pumpWidget(_phone(LumoLearningHub(
      grade: 1,
      skills: {for (final r in records) r.skillId: r},
      onStartUnit: (_, __) {},
      onReading: () {},
      onPracticalSubject: (_) {},
      onAdvanced: () {},
    )));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('learning-subject-Mathematik')));
    await tester.pump(const Duration(milliseconds: 400));

    String status(String unit) => tester
        .widget<Text>(
            find.byKey(ValueKey('learning-unit-progress-Mathematik-$unit')))
        .data!;
    expect(status(units[0]), 'Am Anfang (3 von 5) · 2 Aufgaben allein gelöst');
    expect(status(units[1]), 'In Übung · 5 Aufgaben allein gelöst');
    expect(status(units[2]), 'Sicher · 9 Aufgaben allein gelöst an 2 Tagen');
    expect(find.textContaining('% sicher'), findsNothing,
        reason: 'no percentage on a topic tile');
    await tester.ensureVisible(
        find.byKey(ValueKey('learning-unit-Mathematik-${units[0]}')));
    await tester.pump(const Duration(milliseconds: 200));
    await _shot(tester, '06-themenkachel-am-anfang');
  });
}
