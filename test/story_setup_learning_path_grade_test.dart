import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/features/story/lumo_story_library_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final grade in [1, 2, 3, 4]) {
    testWidgets('learning path fixes story setup to grade $grade',
        (tester) async {
      final profileGrade = grade == 4 ? 3 : 4;
      final appState = LumoAppState();
      addTearDown(appState.dispose);
      appState.update(appState.state.copyWith(grade: profileGrade));

      await tester.pumpWidget(MaterialApp(
        home: LumoStorySetupScreen(
          appState: appState,
          initialGrade: grade,
        ),
      ));
      await tester.pump();

      expect(find.text('$grade. Klasse'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      for (final otherGrade in [1, 2, 3, 4].where((value) => value != grade)) {
        expect(find.text('$otherGrade. Klasse'), findsNothing);
      }

      await tester.tap(find.text('Überraschung!'));
      await _pumpRoute(tester);
      final reader = tester.widget<LumoStoryReaderScreen>(
        find.byType(LumoStoryReaderScreen),
      );
      expect(reader.story.gradeLevel, grade);
      expect(appState.state.grade, profileGrade);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('manual story creation uses the pinned learning path grade',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 1));

    await tester.pumpWidget(MaterialApp(
      home: LumoStorySetupScreen(
        appState: appState,
        initialGrade: 3,
      ),
    ));
    await tester.pump();

    for (final option in [
      LumoStoryGenerator.instance.heroOptions.first,
      LumoStoryGenerator.instance.locationOptions.first,
      LumoStoryGenerator.instance.themeOptions.first,
    ]) {
      await tester.ensureVisible(find.text(option));
      await tester.tap(find.text(option));
      await tester.pump();
    }

    await tester.ensureVisible(find.text('Geschichte starten!'));
    await tester.tap(find.text('Geschichte starten!'));
    await _pumpRoute(tester);

    final reader = tester.widget<LumoStoryReaderScreen>(
      find.byType(LumoStoryReaderScreen),
    );
    expect(reader.story.gradeLevel, 3);
    expect(appState.state.grade, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library forwards its grade to the fixed story setup',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 4));

    await tester.pumpWidget(MaterialApp(
      home: LumoStoryLibraryScreen(
        appState: appState,
        gradeLevel: 2,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The illustrated 1939 library is taller than the old empty-state view.
    // At the default 800×600 test surface the real CTA is below the viewport;
    // first scroll it into the hit-test area, rather than pretending the tap
    // succeeded. Keep the navigation/grade assertions unchanged.
    final firstStory = find.text('Erste Geschichte!');
    await tester.ensureVisible(firstStory);
    await tester.pump();
    expect(tester.getCenter(firstStory).dy, inInclusiveRange(0.0, 600.0));
    await tester.tap(firstStory);
    await _pumpRoute(tester);

    final setup = tester.widget<LumoStorySetupScreen>(
      find.byType(LumoStorySetupScreen),
    );
    expect(setup.initialGrade, 2);
    expect(find.text('2. Klasse'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(appState.state.grade, 4);
    expect(tester.takeException(), isNull);
  });

  for (final grade in [0, 5]) {
    testWidgets('learning path grade $grade is clamped to 1–4', (tester) async {
      final appState = LumoAppState();
      addTearDown(appState.dispose);

      await tester.pumpWidget(MaterialApp(
        home: LumoStorySetupScreen(
          appState: appState,
          initialGrade: grade,
        ),
      ));
      await tester.pump();

      final clampedGrade = grade == 0 ? 1 : 4;
      expect(find.text('$clampedGrade. Klasse'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('free story setup keeps profile default and manual grade choice',
      (tester) async {
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 3));

    await tester.pumpWidget(MaterialApp(
      home: LumoStorySetupScreen(appState: appState),
    ));
    await tester.pump();

    for (final grade in [1, 2, 3, 4]) {
      expect(find.text('$grade. Klasse'), findsOneWidget);
    }
    expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    await tester.ensureVisible(find.text('2. Klasse'));
    await tester.tap(find.text('2. Klasse'));
    await tester.pump(const Duration(milliseconds: 250));

    // The hologlass theme uses the same readable text color for every grade.
    // Selection must be communicated by accessible state, not text pigment.
    _expectGradeSelection(tester, 2, selected: true);
    _expectGradeSelection(tester, 3, selected: false);
    expect(appState.state.grade, 3);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectGradeSelection(
  WidgetTester tester,
  int grade, {
  required bool selected,
}) {
  final selectedGrade = find.ancestor(
    of: find.text('$grade. Klasse'),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.selected != null,
    ),
  );
  expect(selectedGrade, findsOneWidget);
  expect(tester.widget<Semantics>(selectedGrade).properties.selected, selected);
}
