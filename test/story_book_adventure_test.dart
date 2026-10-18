import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All six new plots have twelve readable pages, solved clues and independent book questions', () {
    for (var seed = 0; seed < 6; seed++) {
      final book = LumoStoryGenerator.instance.generateReadingAdventure(
        hero: 'Prinzessin',
        location: 'Weltraum',
        theme: 'Abenteuer',
        gradeLevel: 2,
        variationSeed: seed,
      );
      expect(book.pages, hasLength(12));
      expect(book.pages.map((p) => p.pageNum), orderedEquals(
        List<int>.generate(12, (i) => i + 1)));
      expect(book.pages.every((p) => p.text.length >= 150), isTrue,
        reason: 'Each page contains actual story text, not a caption');
      expect(book.pages[4].exercise!.correctAnswer, 'dem blauen Band');
      expect(book.pages[8].exercise!.correctAnswer, 'der Stern');
      expect(book.pages.where((p) => p.exercise != null), hasLength(2));
      expect(book.pages[2].text, contains('blaues Band'));
      expect(book.pages[6].text, contains('Beim Stern'));
      expect(book.bookQuestions, hasLength(10));
      expect(book.bookQuestions.map((q) => q.evidencePage),
          orderedEquals([1, 1, 2, 2, 6, 6, 10, 10, 11, 12]));
      for (final check in book.bookQuestions) {
        expect(book.pages[check.evidencePage - 1].text,
            contains(check.correctAnswer.split(' ').last),
            reason: 'The answer must be grounded in a real passage');
        expect(check.options, contains(check.correctAnswer));
        expect(check.options.toSet().length, check.options.length);
      }
    }
  });

  test('Old saved eight-page books and new book questions round-trip unchanged', () {
    final oldBook = LumoStoryGenerator.instance.generate(
      hero: 'Drache', location: 'Zauberwald',
      theme: 'Freundschaft', gradeLevel: 2,
    );
    final newBook = LumoStoryGenerator.instance.generateReadingAdventure(
      hero: 'Fuchs', location: 'Zauberwald',
      theme: 'Geheimnis', gradeLevel: 2,
    );
    StoredStory wrap(LumoStory book) => StoredStory(
      id: 'book', story: book,
      createdAt: DateTime.utc(2026, 10, 18),
      timesRead: 1, isFavorite: false,
    );
    final legacy = StoredStory.fromJson(wrap(oldBook).toJson()).story;
    final updated = StoredStory.fromJson(wrap(newBook).toJson()).story;
    expect(legacy.pages.length, 8);
    expect(legacy.bookQuestions, isEmpty);
    expect(updated.pages.length, 12);
    expect(updated.bookQuestions.length, 10);
    expect(updated.bookQuestions[4].evidencePage, 6);
    expect(updated.pages[4].exercise!.type, StoryExerciseType.wordChoice);
  });

  testWidgets('A child can read all pages without the mini-quiz interrupting text',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final voice = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = voice);
    final state = LumoAppState();
    addTearDown(state.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final story = LumoStoryGenerator.instance.generateReadingAdventure(
      hero: 'Fuchs', location: 'Zauberwald',
      theme: 'Geheimnis', gradeLevel: 2,
    );
    await tester.pumpWidget(MaterialApp(
      home: LumoStoryReaderScreen(story: story, appState: state),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('lumo-story-actual-page-text')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lumo-full-book-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('lumo-story-complete-book')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('full-book-page-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('full-book-page-2')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('lumo-return-from-full-book')));
    await tester.pump();
    expect(find.byKey(const ValueKey('lumo-story-actual-page-text')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
