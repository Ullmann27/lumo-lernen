// L1 "Ehrlich üben" in the Akademie modules:
//  * Minus bis 10 and the Einmaleins no longer skip a task after two wrong
//    answers; they give feedback, then a worked solution.
//  * Thirty-task modules run in rounds of ten with a stopping point and
//    open at the saved round the next time.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_mistake_help_card.dart';
import 'package:lumo_lernen/features/learning_modules/einmaleins/einmaleins_screen.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/widgets/design/lumo_answer_crystal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/native_storage_fixture.dart';

typedef _Screen = Widget Function(LumoAppState);

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(microseconds: 16667));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _host(WidgetTester tester, LumoAppState app, _Screen screen) =>
    tester.pumpWidget(MaterialApp(
      home: Builder(
          builder: (context) => Scaffold(
                  body: TextButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => screen(app))),
                child: const Text('Modul öffnen'),
              ))),
    ));

Future<LumoAppState> _open(WidgetTester tester, _Screen screen) async {
  await tester.binding.setSurfaceSize(const Size(480, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = await nativeStorageFixture(tester,
      () => LumoAppState(walletRepository: RewardWalletRepository()));
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await _host(tester, app, screen);
  await tester.tap(find.text('Modul öffnen'));
  await _frames(tester);
  return app;
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await _frames(tester, 60);
  await tester.pumpWidget(const SizedBox());
  await _frames(tester, 10);
  app.dispose();
  expect(tester.takeException(), isNull);
}

/// The visible problem, e.g. "7 − 3 = ?" or "5 × 4 = ?".
(int a, String op, int b) _problem(WidgetTester tester) {
  final pattern = RegExp(r'^(\d+) (−|×) (\d+) = \?$');
  final match = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => pattern.firstMatch(text.data ?? ''))
      .whereType<RegExpMatch>()
      .first;
  return (int.parse(match[1]!), match[2]!, int.parse(match[3]!));
}

int _correct(WidgetTester tester) {
  final (a, op, b) = _problem(tester);
  return op == '−' ? a - b : a * b;
}

List<LumoAnswerCrystal> _crystals(WidgetTester tester) =>
    tester.widgetList<LumoAnswerCrystal>(find.byType(LumoAnswerCrystal)).toList();

List<int> _wrongChoices(WidgetTester tester) => _crystals(tester)
    .map((crystal) => int.parse(crystal.label))
    .where((value) => value != _correct(tester))
    .toList();

Future<void> _tap(WidgetTester tester, int answer, {int frames = 170}) async {
  final target = find.descendant(
      of: find.byType(LumoAnswerCrystal), matching: find.text('$answer'));
  await tester.ensureVisible(target.first);
  await tester.pump();
  await tester.tap(target.first);
  await _frames(tester, frames);
}

String _taskLabel(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .firstWhere((label) => label.startsWith('Aufgabe '));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final (name, unit, screen) in <(String, String, _Screen)>[
    ('Minus bis 10', 'Minus bis 10', (app) => MinusBis10Screen(appState: app)),
    ('Kleines 1×1', 'Kleines 1×1', (app) => EinmaleinsScreen(appState: app)),
  ]) {
    testWidgets('$name: two wrong answers get help in two steps, no skip',
        (tester) async {
      final app = await _open(tester, screen);
      final problem = _problem(tester);
      final answer = _correct(tester);
      final wrong = _wrongChoices(tester);
      expect(_taskLabel(tester), startsWith('Aufgabe 1 /'));

      // First mistake: feedback that fits, the answer stays hidden.
      await _tap(tester, wrong[0]);
      expect(find.byType(LumoMistakeFeedbackCard), findsOneWidget);
      expect(find.byType(LumoWorkedSolutionCard), findsNothing);
      expect(_problem(tester), problem);
      final afterFirst = _crystals(tester);
      expect(
          afterFirst.singleWhere((c) => c.label == '$answer').state,
          LumoCrystalState.neutral,
          reason: 'the first mistake must not reveal the solution');
      expect(
          afterFirst.singleWhere((c) => c.label == '${wrong[0]}').onPressed,
          isNull,
          reason: 'the tried answer is not offered again');
      expect(find.textContaining('Fast'), findsNothing);

      // Second mistake: the worked solution, and still the same task.
      await _tap(tester, wrong[1]);
      expect(find.byType(LumoWorkedSolutionCard), findsOneWidget);
      expect(find.byType(LumoMistakeFeedbackCard), findsNothing);
      expect(_problem(tester), problem);
      expect(_taskLabel(tester), startsWith('Aufgabe 1 /'));
      expect(find.text('Tippe jetzt die $answer an.'), findsOneWidget);
      // Every answer can be tapped again: no last one left.
      expect(_crystals(tester).every((c) => c.onPressed != null), isTrue);

      // Formerly the module moved on by itself after about four seconds.
      await _frames(tester, 400);
      expect(_problem(tester), problem, reason: 'the task is never skipped');

      // A wrong tap inside the worked solution only points back to it.
      await _tap(tester, wrong[2], frames: 30);
      expect(_problem(tester), problem);
      expect(find.textContaining('Schau auf Schritt'), findsOneWidget);

      // The child taps the explained answer: solved together, then on.
      await _tap(tester, answer);
      expect(_taskLabel(tester), startsWith('Aufgabe 2 /'));
      expect(
          tester
              .widget<Text>(
                  find.byKey(const ValueKey('learning-module-correct-count')))
              .data,
          '0 richtig',
          reason: 'only tasks solved alone count as "richtig"');

      await _frames(tester, 60);
      final record =
          app.learningSkills()[SkillRecord.makeId('Mathematik', unit)]!;
      expect(record.correct, 1);
      expect(record.wrong, 2);
      expect(record.assessed.correct, 0,
          reason: 'solved together is not independent evidence');
      expect(record.assessed.wrong, 1);
      // The module's small reward for a finished task is unchanged.
      expect(app.state.stars, 1);
      await _close(tester, app);
    });
  }

  testWidgets('Minus bis 10 runs in rounds of ten and resumes at the round',
      (tester) async {
    Widget screen(LumoAppState app) => MinusBis10Screen(appState: app);
    final app = await _open(tester, screen);
    expect(find.text('Runde 1 von 3'), findsOneWidget);
    // The familiar header pattern stays: "Aufgabe N / M".
    expect(_taskLabel(tester), 'Aufgabe 1 / 30');

    for (var task = 1; task <= 10; task++) {
      expect(_taskLabel(tester), 'Aufgabe $task / 30');
      await _tap(tester, _correct(tester));
    }

    // A clear, positive stopping point after the first round.
    expect(find.byKey(const ValueKey('module-round-break')), findsOneWidget);
    expect(find.text('Runde 1 von 3 geschafft!'), findsOneWidget);
    final stop = find.byKey(const ValueKey('module-round-stop'));
    expect(tester.getSize(stop).height, greaterThanOrEqualTo(48));
    await tester.tap(stop);
    await _frames(tester);
    expect(find.text('Modul öffnen'), findsOneWidget);
    expect(find.byType(MinusBis10Screen), findsNothing);

    // The next visit opens at round 2 and keeps the count of round 1.
    await tester.tap(find.text('Modul öffnen'));
    await _frames(tester);
    expect(find.text('Runde 2 von 3'), findsOneWidget);
    expect(_taskLabel(tester), 'Aufgabe 11 / 30');
    expect(
        tester
            .widget<Text>(
                find.byKey(const ValueKey('learning-module-correct-count')))
            .data,
        '10 richtig');

    for (var task = 1; task <= 10; task++) {
      await _tap(tester, _correct(tester));
    }
    expect(find.text('Runde 2 von 3 geschafft!'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('module-round-continue')));
    await _frames(tester);
    expect(find.text('Runde 3 von 3'), findsOneWidget);
    expect(_taskLabel(tester), 'Aufgabe 21 / 30');
    await _close(tester, app);
  });
}
