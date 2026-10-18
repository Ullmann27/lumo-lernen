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
      final label = index + 1 == story.pages.length
          ? story.bookQuestions.isNotEmpty
              ? 'Fragen zum ganzen Buch'
              : 'Erzähl mir die Geschichte!'
          : 'Weiterlesen';
      await tester.runAsync(() => tester.tap(find.text(label)));
      await _routeFrames(tester);
    }
    if (story.bookQuestions.isNotEmpty) {
      for (final question in story.bookQuestions) {
        await _routeFrames(tester);
        final answer = find.text(question.correctAnswer);
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        await _routeFrames(tester);
        await tester.tap(find.byKey(const ValueKey('lumo-book-quiz-next')));
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
