import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

Future<void> _frames(WidgetTester tester, [int count = 90]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

String _prompt(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .singleWhere((text) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(text));

int _correct(WidgetTester tester) => RegExp(r'\d+')
    .allMatches(_prompt(tester))
    .map((match) => int.parse(match[0]!))
    .reduce((a, b) => a + b);

Finder _answer(int value) =>
    find.descendant(of: find.byType(GridView), matching: find.text('$value'));

Future<LumoAppState> _open(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(480, 1100));
  final app = LumoAppState();
  app.setSection(LumoSection.learn);
  app.updateSettings(
      const AppSettings(voiceEnabled: false, reduceAnimations: true));
  await tester.runAsync(() async {
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
  });
  await tester.pumpWidget(MaterialApp(home: PlusBis10Screen(appState: app)));
  await _frames(tester);
  return app;
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  app.dispose();
  await tester.binding.setSurfaceSize(null);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  final requests = LumoCompanionRequests.instance;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    requests.clearLearningScope();
  });
  tearDown(requests.clearLearningScope);

  testWidgets(
      'actual Plus controls report answers and offer alternative local hints',
      (tester) async {
    final app = await _open(tester);
    final original = _prompt(tester);
    final taskId = requests.taskContext.value!.taskId;
    expect(taskId, matches(r'^plus10-\d+-\d+$'));
    expect(requests.taskContext.value!.prompt, original);
    final correct = _correct(tester);
    final wrong = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(GridView), matching: find.byType(Text)))
        .map((text) => int.parse(text.data!))
        .firstWhere((value) => value != correct);
    await tester.ensureVisible(_answer(wrong));
    await tester.tap(_answer(wrong));
    await _frames(tester);
    expect(_prompt(tester), original);
    expect(requests.taskContext.value!.lastCorrect, isFalse);
    expect(requests.taskContext.value!.lastAnswer, '$wrong');
    expect(requests.learningEvents.value.last.kind,
        LumoLearningEventKind.answerIncorrect);
    expect(app.learningDailyDone(), 0);

    await tester.ensureVisible(find.text('Tipp'));
    await tester.tap(find.text('Tipp'));
    await _frames(tester, 10);
    final firstHint = tester
        .widget<Text>(
            find.byKey(const ValueKey('plus10-actual-companion-hint')))
        .data!;
    expect(firstHint, contains('jeden Apfel nur einmal'));
    expect(firstHint, isNot(contains('= $correct')));
    expect(requests.learningEvents.value.last.kind,
        LumoLearningEventKind.hintAccepted);
    await tester.ensureVisible(find.text('Anderer Tipp'));
    await tester.tap(find.text('Anderer Tipp'));
    await _frames(tester, 10);
    final alternative = tester
        .widget<Text>(
            find.byKey(const ValueKey('plus10-actual-companion-hint')))
        .data!;
    expect(alternative, isNot(firstHint));
    expect(_prompt(tester), original);

    await tester.ensureVisible(_answer(correct));
    await tester.tap(_answer(correct));
    await _frames(tester);
    expect(app.learningDailyDone(), 1);
    final correctEvent = requests.learningEvents.value.lastWhere(
        (event) => event.kind == LumoLearningEventKind.answerCorrect);
    expect(correctEvent.taskId, taskId);
    expect(correctEvent.attempt, 2);
    expect(requests.taskContext.value!.taskId, isNot(taskId));
    final stored = app.learningSkills()['mathematik::plus bis 10']!;
    expect(stored.correct, 1);
    expect(stored.wrong, 1);
    expect(stored.hintCount, 1);
    await _close(tester, app);
  });

  testWidgets('global help requests stay in the actual Plus task',
      (tester) async {
    final app = await _open(tester);
    final prompt = _prompt(tester);
    requests.requestTaskHelp();
    await _frames(tester, 10);
    expect(find.byKey(const ValueKey('plus10-actual-companion-hint')),
        findsOneWidget);
    expect(_prompt(tester), prompt);
    expect(requests.taskContext.value!.helpLevel, 1);
    expect(app.learningDailyDone(), 0);
    await _close(tester, app);
  });

  testWidgets(
      'a switched child cannot continue the old module or use its hints',
      (tester) async {
    final app = await _open(tester);
    await tester.runAsync(() async {
      await app.school.setActiveStudent('different-child');
      await app.loadLearningProfile();
    });
    await _frames(tester, 10);
    expect(find.text('Das Kinderprofil wurde gewechselt.'), findsOneWidget);
    requests.requestTaskHelp();
    await _frames(tester, 10);
    expect(requests.taskContext.value, isNull);
    expect(app.learningSkills(), isEmpty);
    expect(app.learningDailyDone(), 0);
    await _close(tester, app);
  });
}
