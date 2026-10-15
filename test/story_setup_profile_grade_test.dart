import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/story/lumo_story_setup_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final grade in [1, 2, 3, 4]) {
    testWidgets('story setup starts with profile grade $grade', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final appState = LumoAppState();
      addTearDown(appState.dispose);
      appState.update(appState.state.copyWith(grade: grade));

      await tester.pumpWidget(MaterialApp(
        home: LumoStorySetupScreen(appState: appState),
      ));
      await tester.pump();

      for (final candidate in [1, 2, 3, 4]) {
        _expectGradeSelection(tester, candidate, selected: candidate == grade);
      }
      expect(appState.state.grade, grade);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('free story grade selection does not change profile grade',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final appState = LumoAppState();
    addTearDown(appState.dispose);
    appState.update(appState.state.copyWith(grade: 3));

    await tester.pumpWidget(MaterialApp(
      home: LumoStorySetupScreen(appState: appState),
    ));
    await tester.pump();
    await tester.ensureVisible(find.text('2. Klasse'));
    await tester.tap(find.text('2. Klasse'));
    await tester.pump(const Duration(milliseconds: 250));

    _expectGradeSelection(tester, 2, selected: true);
    _expectGradeSelection(tester, 3, selected: false);
    expect(appState.state.grade, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

void _expectGradeSelection(
  WidgetTester tester,
  int grade, {
  required bool selected,
}) {
  // The hologlass palette deliberately uses identical high-contrast text
  // colors for active and inactive grades; check the real accessibility state.
  final selectedGrade = find.ancestor(
    of: find.text('$grade. Klasse'),
    matching: find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.selected != null,
    ),
  );
  expect(selectedGrade, findsOneWidget);
  expect(tester.widget<Semantics>(selectedGrade).properties.selected, selected);
}
