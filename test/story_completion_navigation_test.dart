import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';

Future<void> _routeFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  testWidgets(
      'completed story returns through setup to filtered library; cancellation keeps setup',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final oldVoice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = oldVoice);
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);
    state.update(state.state.copyWith(grade: 4));
    await tester.runAsync(LumoStoryLibrary.instance.load);
    await tester.pumpWidget(MaterialApp(
        home: LumoStoryLibraryScreen(appState: state, gradeLevel: 2)));
    await _routeFrames(tester);
    await tester.tap(find.text('Erste Geschichte!'));
    await _routeFrames(tester);
    await tester.tap(find.text('Überraschung!'));
    await _routeFrames(tester);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await _routeFrames(tester);
    expect(find.byType(LumoStorySetupScreen), findsOneWidget);
    expect(LumoStoryLibrary.instance.count, 0);

    await tester.tap(find.text('Überraschung!'));
    await _routeFrames(tester);
    final story = tester
        .widget<LumoStoryReaderScreen>(find.byType(LumoStoryReaderScreen))
        .story;
    expect(story.gradeLevel, 2);
    for (var index = 0; index < story.pages.length; index++) {
      final exercise = story.pages[index].exercise;
      if (exercise != null) {
        final options = exercise.options;
        final label = options == null
            ? 'Wort merken!'
            : exercise.correctAnswer;
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pump();
      }
      final next = find.byKey(const ValueKey('lumo-story-continue'));
      expect(next, findsOneWidget,
          reason: 'Story must expose its next-reading action on page ${index + 1}');
      final nextButton = tester.widget<ElevatedButton>(next);
      expect(nextButton.onPressed, isNotNull,
          reason: 'Story cannot advance until an active clue is solved');
      // This is a route/state regression, not a pointer hit-target test.
      // Calling the live button callback avoids the unrelated desktop-size
      // test-binding hit-test warning in the bottom system inset.
      nextButton.onPressed!.call();
      await _routeFrames(tester);
      if (index + 1 < story.pages.length) {
        expect(find.byKey(ValueKey('lumo-story-scene-${index + 2}')),
          findsOneWidget, reason: 'The next real illustrated page must render');
      }
    }
    if (story.bookQuestions.isNotEmpty) {
      expect(find.byKey(const ValueKey('lumo-book-reading-quiz')),
          findsOneWidget,
          reason: 'The book must open its independent comprehension check');
      for (var questionIndex = 0;
          questionIndex < story.bookQuestions.length;
          questionIndex++) {
        final question = story.bookQuestions[questionIndex];
        await _routeFrames(tester);
        expect(find.byKey(ValueKey('lumo-book-question-$questionIndex')),
            findsOneWidget);
        final correctIndex = question.options.indexOf(question.correctAnswer);
        expect(correctIndex, greaterThanOrEqualTo(0));
        final answer = find.byKey(ValueKey('book-answer-$correctIndex'));
        await tester.ensureVisible(answer);
        await tester.pump();
        await tester.tap(answer);
        await _routeFrames(tester);
        final next = find.byKey(const ValueKey('lumo-book-quiz-next'));
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await _routeFrames(tester);
      }
    }
    if (story.keyPoints.isNotEmpty) {
      await tester.enterText(
          find.byType(TextField), 'Ich habe eine Geschichte gelesen.');
      await tester.ensureVisible(find.text('Bewertung holen'));
      await tester.tap(find.text('Bewertung holen'));
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() => tester.tap(find.text('Fertig!')));
      await _routeFrames(tester);
    }
    expect(find.text('Heft in deine Bibliothek gespeichert!'), findsOneWidget);
    await tester.tap(find.text('Fertig'));
    await _routeFrames(tester);
    expect(find.byType(LumoStoryReaderScreen), findsNothing);
    expect(find.byType(LumoStorySetupScreen), findsNothing);
    expect(find.byType(LumoStoryLibraryScreen), findsOneWidget);
    expect(find.text(story.title), findsOneWidget);
    expect(LumoStoryLibrary.instance.count, 1);
    expect(state.state.grade, 4);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}
