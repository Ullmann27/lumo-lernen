import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_story_library.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';

void main() {
  testWidgets('optional grade filter preserves all stored stories and free library',
      (tester) async {
    final stored = [
      for (final grade in [1, 2, 3, 4])
        StoredStory(
          id: 'filter-fixture-$grade',
          story: LumoStory(
            title: 'Filter-Geschichte $grade',
            heroName: 'Lumo',
            location: 'Wald',
            theme: 'Freundschaft',
            gradeLevel: grade,
            newWords: const ['Mut'],
            pages: const [
              LumoStoryPage(
                pageNum: 1,
                text: 'Lumo findet einen Freund.',
                imagePrompt: 'friendly fox in forest',
              ),
            ],
          ),
          createdAt: DateTime(2026, 10, 13),
          timesRead: 0,
          isFavorite: grade == 3,
        ),
    ];
    final raw = jsonEncode(stored.map((story) => story.toJson()).toList());
    SharedPreferences.setMockInitialValues({'lumo_story_library_v1': raw});
    await tester.runAsync(() => LumoStoryLibrary.instance.load());

    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 4));

    for (final grade in [1, 2, 3, 4]) {
      await tester.pumpWidget(MaterialApp(
        home: LumoStoryLibraryScreen(
          key: ValueKey(grade),
          appState: appState,
          gradeLevel: grade,
        ),
      ));
      await tester.pump();
      expect(find.text('Geschichten · Lesen & verstehen'), findsOneWidget);
      expect(find.text('$grade. Klasse · 1 Hefte'), findsOneWidget);
      for (final candidate in [1, 2, 3, 4]) {
        expect(find.text('Filter-Geschichte $candidate'),
            candidate == grade ? findsOneWidget : findsNothing);
      }
      expect(LumoStoryLibrary.instance.count, 4);
      expect(appState.state.grade, 4);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(MaterialApp(
      home: LumoStoryLibraryScreen(
        key: const ValueKey('free-library'),
        appState: appState,
      ),
    ));
    await tester.pump();
    expect(find.text('Meine Geschichten'), findsOneWidget);
    expect(find.text('4 Hefte erschaffen'), findsOneWidget);
    for (final grade in [1, 2, 3, 4]) {
      expect(find.text('Filter-Geschichte $grade'), findsOneWidget);
    }
    expect(LumoStoryLibrary.instance.favorites, hasLength(1));
    expect(appState.state.grade, 4);
    await tester.runAsync(() async {
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('lumo_story_library_v1'), raw);
    });
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
