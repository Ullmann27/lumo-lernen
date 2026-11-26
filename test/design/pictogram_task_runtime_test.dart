import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/science_quality_extension.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/pictogram_task_prompt.dart';

void main() {
  test('all picture diagrams in the maths and science banks can be drawn', () {
    final charts = [
      ...chartCollectionTasks.map((task) => task.$1),
      ...scienceQualityExtensionQuestions.map((task) => task.prompt),
    ].where((prompt) => prompt.startsWith('Lies das Diagramm.'));
    expect(charts.length, greaterThanOrEqualTo(17));
    expect(charts.every(PictogramTaskPrompt.supports), isTrue);
    expect(
      PictogramTaskPrompt.supports(
        'Lies das Diagramm. Ein 🟦 ist ein Tag.\nKein Schaubild',
      ),
      isFalse,
    );
  });

  for (final (label, dimensions, scale) in [
    ('Smartphone', const Size(360, 800), 1.7),
    ('Fold7 innen', const Size(2176 / 2.25, 1812 / 2.25), 1.3),
  ]) {
    testWidgets(
        'Sachunterricht zeigt eine echte Null und fünf Kästchen · $label',
        (tester) async {
      await tester.binding.setSurfaceSize(dimensions);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final factory = ExerciseFactory(seed: 14);
      final task = Iterable.generate(
        40,
        (_) => factory.nextExact(
          grade: 4,
          subject: 'Sachunterricht',
          unit: 'Diagramme lesen',
        ),
      ).firstWhere((task) => task.prompt.contains('0 (keinen Igel gesehen)'));
      final instance = const LegacyLumoTaskAdapter().toTaskInstance(
        task: task,
        childId: 'diagramm-test',
        difficulty: task.difficulty,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: AdaptiveTaskRenderer(
                  task: instance,
                  reduceMotion: true,
                ),
              ),
            ),
          ),
        ),
      );
      final chart = find.byType(PictogramTaskPrompt);
      expect(chart, findsOneWidget);
      expect(find.text('September'), findsOneWidget);
      final squares =
          find.descendant(of: chart, matching: find.byType(DecoratedBox));
      expect(squares, findsNWidgets(5));
      expect(find.bySemanticsLabel('5 blaue Kästchen'), findsOneWidget);
      expect(find.text('Dezember'), findsOneWidget);
      expect(find.text('0 (keinen Igel gesehen)'), findsOneWidget);
      expect(instance.correctAnswer, 'Sie halten Winterschlaf.');
      expect(tester.takeException(), isNull);
    });
  }
}
