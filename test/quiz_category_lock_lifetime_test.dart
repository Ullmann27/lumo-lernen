import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/domain/quiz/quiz_question_bank.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

const _seed = 17;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final reducedMotion in [true, false]) {
    final delay = Duration(milliseconds: reducedMotion ? 750 : 1600);
    final mode = reducedMotion ? 'reduced motion' : 'full animation';

    testWidgets('Category change discards an unanswered old lock ($mode)',
        (tester) async {
      final app = await _openQuiz(tester, reducedMotion);
      final starsBefore = app.state.stars;
      await _lockAnswer(tester, 0);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Lumo prüft deine Antwort …'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('quiz-category-Mathe')));
      await tester.pump();
      expect(find.text('Lumo prüft deine Antwort …'), findsNothing,
          reason: 'The new category must be immediately ready for an answer');
      await tester.pump(delay);

      expect(find.text('Neue Quizrunde starten'), findsNothing);
      expect(find.text('Nächste Frage'), findsNothing);
      expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
      expect(find.text('Antwort einloggen'), findsOneWidget);
      expect(find.text('Frage 1 / 20'), findsOneWidget);
      expect(app.state.stars, starsBefore);

      final question = const QuizQuestionBank()
          .generateGameQuestions(
            grade: app.state.grade,
            random: math.Random(_seed),
            preferSubject: 'Mathe',
          )
          .first;
      expect(find.text(question.prompt), findsOneWidget);
      await _lockAnswer(tester, question.correctIndex);
      await tester.pump(delay);
      expect(find.text('Nächste Frage'), findsOneWidget);
      expect(find.text('Neue Quizrunde starten'), findsNothing);
      await _closeQuiz(tester);
    });

    testWidgets('Old deadline cannot resolve a new category lock ($mode)',
        (tester) async {
      final app = await _openQuiz(tester, reducedMotion);
      await _lockAnswer(tester, 0);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('quiz-category-Mathe')));
      await tester.pump();
      expect(find.text('Antwort einloggen'), findsOneWidget,
          reason: 'A category change must cancel the previous lock');
      final question = const QuizQuestionBank()
          .generateGameQuestions(
            grade: app.state.grade,
            random: math.Random(_seed),
            preferSubject: 'Mathe',
          )
          .first;
      await _lockAnswer(tester, question.correctIndex);
      await tester.pump(delay - const Duration(milliseconds: 150));
      // The old timer has expired, but this answer still owns 150 ms.
      expect(find.text('Lumo prüft deine Antwort …'), findsOneWidget);
      expect(find.text('Nächste Frage'), findsNothing);
      expect(find.text('Neue Quizrunde starten'), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('Nächste Frage'), findsOneWidget);
      expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
      await _closeQuiz(tester);
    });

    testWidgets(
        'Disposal cancels pending answer without changing rewards ($mode)',
        (tester) async {
      final app = await _openQuiz(tester, reducedMotion);
      final starsBefore = app.state.stars;
      await _lockAnswer(tester, 0);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(delay);
      expect(app.state.stars, starsBefore);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Restart opens a fresh round with its own answer deadline ($mode)',
        (tester) async {
      final app = await _openQuiz(tester, reducedMotion);
      final question = const QuizQuestionBank()
          .generateGameQuestions(
            grade: app.state.grade,
            random: math.Random(_seed),
          )
          .first;
      await _lockAnswer(tester, (question.correctIndex + 1) % 4);
      await tester.pump(delay);
      final restart = find.text('Neue Quizrunde starten');
      expect(restart, findsOneWidget);
      await tester.ensureVisible(restart);
      await tester.tap(restart);
      await tester.pump();
      expect(find.text('Frage 1 / 20'), findsOneWidget);
      expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
      await _lockAnswer(tester, question.correctIndex);
      await tester.pump(delay - const Duration(milliseconds: 1));
      expect(find.text('Nächste Frage'), findsNothing);
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.text('Nächste Frage'), findsOneWidget);
      await _closeQuiz(tester);
    });
  }
}

Future<LumoAppState> _openQuiz(WidgetTester tester, bool reducedMotion) async {
  await tester.binding.setSurfaceSize(const Size(720, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  app.updateSettings(app.state.settings.copyWith(soundEnabled: false));
  addTearDown(app.dispose);
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: QuizShowContent(appState: app, previewQuestionSeed: _seed),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 260));
  return app;
}

Future<void> _lockAnswer(WidgetTester tester, int index) async {
  final answer = find.byKey(ValueKey('lumo-meister-answer-$index'));
  await tester.ensureVisible(answer);
  await tester.pump();
  await tester.tap(answer);
  await tester.pump();
  final submit = find.text('Antwort einloggen');
  await tester.ensureVisible(submit);
  await tester.pump();
  await tester.tap(submit);
  await tester.pump();
}

Future<void> _closeQuiz(WidgetTester tester) async {
  expect(tester.takeException(), isNull);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}
