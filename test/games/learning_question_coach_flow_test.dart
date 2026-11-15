import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_learning_card_overlay.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/features/learning/widgets/learning_question_coach.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../helpers/lumo_capture.dart';

const _question = LearningQuestion(
    prompt: '8 + 5 = ?',
    options: ['12', '13', '14', '15'],
    correctIndex: 1,
    hint: 'Ergänze zuerst den Zehner.');
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

Future<void> _cards(
    WidgetTester tester, LumoAppState app, ValueChanged<int> onAnswer,
    {LearningQuestion question = _question}) async {
  await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: RepaintBoundary(
        key: const ValueKey('cards-question-capture'),
        child: Scaffold(
            body: Stack(children: [
          LumoLearningCardOverlay(
              appState: app,
              roundId: 'stable-card-round',
              question: question,
              onAnswer: onAnswer),
        ])),
      )));
  await _frames(tester);
}

Future<void> _close(WidgetTester tester, LumoAppState app) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _frames(tester);
  app.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  setUpAll(() async {
    await loadLumoCaptureFonts();
    await loadLumoCaptureEmojiFont();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'lumo_app_settings_v1': jsonEncode(_settings.toJson())});
    LumoVoice.instance.isEnabled = false;
    bus.clearLearningScope();
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets(
      'cards keep exact quantities, one confirmed answer and the original index',
      (tester) async {
    final app = LumoAppState()..updateSettings(_settings);
    final answers = <int>[];
    await _cards(tester, app, answers.add);
    expect(bus.taskContext.value!.prompt, _question.prompt);
    expect(bus.taskContext.value!.answerChoices, _question.options);
    expect(find.byType(InteractiveTaskWorkspace), findsOneWidget);
    final workspace = tester.widget<InteractiveTaskWorkspace>(
        find.byType(InteractiveTaskWorkspace));
    expect(workspace.task.visualPayload.data['left'], 8);
    expect(workspace.task.visualPayload.data['right'], 5);
    final identity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: 'dreizehn vielleicht'),
        isTrue);
    await _frames(tester);
    expect(answers, isEmpty);
    final confirm = find.text('Diese Karte wählen');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _frames(tester);
    expect(answers, isEmpty);
    final input = find.byKey(const ValueKey('game-answer-proposal'));
    await tester.ensureVisible(input);
    await tester.enterText(input, '13');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.tap(confirm, warnIfMissed: false);
    await _frames(tester);
    expect(answers, [1]);
    expect(bus.taskContext.value!.answering, isFalse);
    expect(app.state.stars, 0,
        reason: 'The card controller remains the only reward owner.');
    expect(tester.takeException(), isNull);
    await _close(tester, app);
    expect(bus.taskContext.value, isNull);
  });

  testWidgets(
      'staged card help and repeat preserve the same question; old actions expire',
      (tester) async {
    final app = LumoAppState()..updateSettings(_settings);
    final answers = <int>[];
    await _cards(tester, app, answers.add);
    final first = bus.learningIdentity.value!;
    expect(bus.requestLearningAction(LumoLearningAction.hint, identity: first),
        isTrue);
    await _frames(tester);
    final help = bus.taskContext.value!.explanation;
    expect(help, isNotEmpty);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(
        bus.requestLearningAction(LumoLearningAction.repeat, identity: first),
        isFalse);
    for (final command in [
      LumoLearningAction.repeat,
      LumoLearningAction.slower
    ]) {
      expect(
          bus.requestLearningAction(command,
              identity: bus.learningIdentity.value!),
          isTrue);
      await _frames(tester);
    }
    expect(bus.taskContext.value!.prompt, _question.prompt);
    expect(bus.taskContext.value!.helpLevel, 1);
    final beforeStop = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: beforeStop),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.isExplanation, isFalse);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: beforeStop, candidate: '13'),
        isFalse);
    expect(answers, isEmpty);
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });

  testWidgets(
      'small phone and Fold learning cards keep 48dp controls and real captures',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final display in [
      (320.0, 780.0, 'phone-320'),
      (344.0, 882.0, 'fold-cover'),
      (840.0, 900.0, 'fold-open')
    ]) {
      await tester.binding.setSurfaceSize(Size(display.$1, display.$2));
      final app = LumoAppState()..updateSettings(_settings);
      await _cards(tester, app, (_) {});
      for (var i = 0; i < _question.options.length; i++) {
        final answer = find.byKey(ValueKey('cards-learning-answer-$i'));
        final size = tester.getSize(answer);
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
      for (final element in find.byType(OutlinedButton).evaluate()) {
        final size = tester.getSize(find
            .byElementPredicate((candidate) => identical(candidate, element)));
        expect(size.height, greaterThanOrEqualTo(48));
      }
      await captureLumoBoundary(tester,
          boundaryKey: const ValueKey('cards-question-capture'),
          path:
              'docs/evidence/lumo-nextgen-game-questions/${display.$3}-cards.png');
      expect(tester.takeException(), isNull);
      await _close(tester, app);
    }
  });

  testWidgets(
      'invalid learning card never shows answer buttons or invents a replacement',
      (tester) async {
    final app = LumoAppState()..updateSettings(_settings);
    final answers = <int>[];
    await _cards(tester, app, answers.add,
        question: const LearningQuestion(
            prompt: '8 + 5 = ?',
            options: ['12', '13', '14', '15'],
            correctIndex: 0));
    expect(find.byKey(const ValueKey('cards-learning-answer-0')), findsNothing);
    expect(find.byType(InteractiveTaskWorkspace), findsNothing);
    expect(bus.taskContext.value, isNull);
    expect(answers, isEmpty);
    expect(find.text('8 + 5 = ?'), findsOneWidget);
    await _close(tester, app);
  });

  testWidgets(
      'quiz voice chooses a card without grading and respects saved joker limits',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(344, 882));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState()..updateSettings(_settings);
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: QuizShowContent(appState: app, previewQuestionSeed: 7)));
    await _frames(tester);
    expect(find.byType(LearningQuestionCoach), findsOneWidget);
    final prompt = bus.taskContext.value!.prompt;
    final choice = bus.taskContext.value!.answerChoices.first;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: choice),
        isTrue);
    await _frames(tester);
    final confirm = find.text('Diese Karte wählen');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _frames(tester);
    expect(bus.taskContext.value!.answering, isTrue);
    expect(bus.taskContext.value!.lastCorrect, isNull);
    expect(find.text('Antwort einloggen'), findsOneWidget);
    expect(app.state.stars, 0);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.contains('quiz_round'));
    expect(keys, isNotEmpty);
    final before = {for (final key in keys) key: prefs.getString(key)};
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.prompt, prompt);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect({for (final key in keys) key: prefs.getString(key)}, before,
        reason:
            'Repeating the saved hint does not consume another joker or write an answer.');
    expect(tester.takeException(), isNull);
    await _close(tester, app);
  });
}
