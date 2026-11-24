import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

void main() {
  for (var grade = 1; grade <= 4; grade++) {
    for (final subject in ['Lesen', 'Rechtschreibung']) {
      testWidgets('$subject exposes each real unit in grade $grade',
          (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final opened = <String>[];
        var readingOpened = 0;
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: LumoLearningHub(
            grade: grade,
            onStartUnit: (s, u) => opened.add('$s/$u'),
            onReading: () => readingOpened++,
            onPracticalSubject: (_) {},
            onAdvanced: () {},
          ),
        )));
        final scroll = find.byType(Scrollable).first;
        final extra =
            find.byKey(const PageStorageKey<String>('learning-other-subjects'));
        await tester.scrollUntilVisible(extra, 240, scrollable: scroll);
        await tester.tap(extra);
        await tester.pumpAndSettle();
        final subjectTile = find.byKey(ValueKey('learning-extra-$subject'));
        await tester.scrollUntilVisible(subjectTile.hitTestable(), 150,
            scrollable: scroll, maxScrolls: 30);
        await tester.pumpAndSettle();
        expect(subjectTile.hitTestable(), findsOneWidget);
        await tester.tap(subjectTile);
        await tester.pumpAndSettle();
        expect(readingOpened, 0,
            reason: 'Browsing reading must not skip its five task units.');
        for (final unit in Curriculum.unitsForGrade(subject, grade,
            currentGradeOnly: true)) {
          final tile = find.byKey(ValueKey('learning-unit-$subject-$unit'));
          await tester.scrollUntilVisible(tile.hitTestable(), 160,
              scrollable: find.byType(Scrollable).first, maxScrolls: 30);
          await tester.pumpAndSettle();
          await tester.tap(tile);
          await tester.pump();
          expect(opened.last, '$subject/$unit');
        }
        if (subject == 'Lesen') {
          final active = find.byKey(const ValueKey('learning-active-reading'));
          await tester.scrollUntilVisible(active.hitTestable(), -240,
              scrollable: find.byType(Scrollable).first, maxScrolls: 30);
          await tester.pumpAndSettle();
          await tester.tap(active);
          expect(readingOpened, 1);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
