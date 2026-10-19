import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

void main() {
  testWidgets('Book questions point to real evidence pages without spoilers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final initialVoice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = initialVoice);
    await tester.binding.setSurfaceSize(const Size(412, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState();
    addTearDown(state.dispose);

    const story = LumoStory(
      title: 'Lumo findet Hinweise',
      heroName: 'Lumo',
      location: 'Bibliothek',
      theme: 'Lesen',
      gradeLevel: 2,
      newWords: [],
      pages: [
        LumoStoryPage(
            pageNum: 1,
            text: 'Lumo entdeckte einen blauen Schlüssel.',
            imagePrompt: ''),
        LumoStoryPage(
            pageNum: 2,
            text: 'Am Ende lag ein Buch auf einem Tisch.',
            imagePrompt: ''),
      ],
      bookQuestions: [
        StoryBookQuestion('Welche Farbe hatte der Schlüssel?',
            'blau', ['rot', 'blau', 'grün'], 1),
        StoryBookQuestion('Wo lag das Buch?', 'auf einem Tisch',
            ['im Wasser', 'auf einem Tisch', 'unter dem Bett'], 2),
      ],
    );
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: LumoStoryReaderScreen(story: story, appState: state)),
    ));
    await tester.pump();
    final continueButton =
        find.byKey(const ValueKey('lumo-story-continue'));
    for (var page = 0; page < 2; page++) {
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
    }
    expect(find.text('Welche Farbe hatte der Schlüssel?'), findsOneWidget);
    const hintKey = ValueKey('lumo-book-evidence-page-hint');
    const toggleKey = ValueKey('lumo-book-evidence-hint-toggle');
    expect(find.byKey(hintKey), findsNothing);
    await tester.ensureVisible(find.byKey(toggleKey));
    await tester.tap(find.byKey(toggleKey));
    await tester.pump();
    final firstHint = tester.widget<Text>(find.byKey(hintKey)).data!;
    expect(firstHint, contains('Seite 1'));
    expect(firstHint, isNot(contains('blau')));

    await tester.tap(find.byKey(toggleKey));
    await tester.pump();
    expect(find.byKey(hintKey), findsNothing);

    await tester.tap(find.byKey(toggleKey));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('book-answer-1')));
    await tester.tap(find.byKey(const ValueKey('book-answer-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lumo-book-quiz-next')));
    await tester.pump();
    expect(find.text('Wo lag das Buch?'), findsOneWidget);
    expect(find.byKey(hintKey), findsNothing,
        reason: 'The hint for the previous question must not leak');
    await tester.ensureVisible(find.byKey(toggleKey));
    await tester.tap(find.byKey(toggleKey));
    await tester.pump();
    final secondHint = tester.widget<Text>(find.byKey(hintKey)).data!;
    expect(secondHint, contains('Seite 2'));
    expect(secondHint, isNot(contains('auf einem Tisch')));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
