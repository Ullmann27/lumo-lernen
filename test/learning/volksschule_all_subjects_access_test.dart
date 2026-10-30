import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/features/sections/lumo_learning_hub.dart';

void main() {
  const practicalSubjects = <String>[
    'Bewegung und Sport',
    'Verkehrs- und Mobilitätsbildung',
  ];

  for (var grade = 1; grade <= 4; grade++) {
    test('$grade. Klasse: Sport und Mobilität haben echte Tätigkeiten', () {
      for (final subject in practicalSubjects) {
        final activities =
            PrimaryActivityCatalog.forGrade(grade, subject: subject);
        expect(activities.length, greaterThanOrEqualTo(2),
            reason: '$subject darf kein leeres Fach in Klasse $grade sein');
        expect(activities.every((activity) => activity.grade == grade), isTrue);
        expect(activities.every((activity) => activity.subject == subject), isTrue);
      }
    });

    for (final width in <double>[344, 850]) {
      testWidgets(
          '$grade. Klasse: beide Fächer über Akademie auf ${width.toInt()}dp erreichbar',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final visited = <String>[];
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: LumoLearningHub(
              grade: grade,
              onStartUnit: (_, __) {},
              onReading: () {},
              onPracticalSubject: visited.add,
              onAdvanced: () {},
            ),
          ),
        ));
        final expansion = find.byKey(
          const PageStorageKey<String>('learning-other-subjects'),
        );
        await tester.ensureVisible(expansion);
        await tester.tap(expansion);
        await tester.pumpAndSettle();

        for (final subject in practicalSubjects) {
          final tile = find.byKey(ValueKey('learning-extra-$subject'));
          await tester.ensureVisible(tile);
          await tester.pump();
          expect(tile.hitTestable(), findsOneWidget);
          await tester.tap(tile);
          await tester.pump();
        }
        expect(visited, practicalSubjects);
        expect(tester.takeException(), isNull,
            reason: 'Kein Touch- oder Layoutfehler auf ${width.toInt()}dp');
      });
    }
  }
}
