import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/core/learning_profile_engine.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';

void main() {
  test(
      'logic topics are available by grade and all generated options are unique',
      () {
    const guard = TaskQualityGuard();
    for (var grade = 1; grade <= 4; grade++) {
      final factory = ExerciseFactory(seed: grade);
      final units = Curriculum.unitsForGrade('Logik', grade);
      expect(units, isNotEmpty);
      expect(units.contains('Regeln kombinieren'), grade == 4);
      expect(units.contains('Schlussfolgern'), grade >= 3);
      expect(units.contains('Zahlenmuster'), grade >= 2);
      for (final unit in units) {
        for (var i = 0; i < 100; i++) {
          final task = factory.next(grade: grade, subject: 'Logik', unit: unit);
          expect(task.subject, 'Logik');
          expect(task.unit, unit);
          expect(guard.problems(task), isEmpty, reason: task.prompt);
          expect(task.choices.where((c) => c == task.answer), hasLength(1));
          if (unit == 'Zahlenmuster') {
            final sequence = RegExp(r'\d+')
                .allMatches(task.prompt)
                .map((m) => int.parse(m[0]!))
                .toList();
            expect(sequence, hasLength(4));
            final step = sequence[1] - sequence[0];
            expect(step, greaterThan(0));
            expect(sequence[2] - sequence[1], step);
            expect(sequence[3] - sequence[2], step);
            expect(int.parse(task.answer), sequence.last + step);
          }
          if (unit == 'Regeln kombinieren') {
            final limits = RegExp(r'\d+')
                .allMatches(task.prompt)
                .map((m) => int.parse(m[0]!))
                .toList();
            final matching = task.choices
                .map(int.parse)
                .where((n) => n > limits[0] && n < limits[1] && n.isEven);
            expect(matching.toList(), [int.parse(task.answer)]);
          }
        }
      }
    }
  });

  test(
      'logic attempts and hints are saved and restored under their own subject',
      () async {
    SharedPreferences.setMockInitialValues({});
    final profile = LearningProfileEngine();
    await profile.load();
    await profile.recordAnswer(
        subject: 'Logik', unit: 'Muster', isCorrect: false);
    await profile.recordAnswer(
        subject: 'Logik', unit: 'Muster', isCorrect: true, hintUsed: true);
    final restarted = LearningProfileEngine();
    await restarted.load();
    final skill = restarted.skills.values.single;
    expect(skill.subject, 'Logik');
    expect(skill.correct, 1);
    expect(skill.wrong, 1);
    expect(skill.hintCount, 1);
    expect(restarted.lastTopics['Logik'], 'Muster');
    expect(restarted.dailyDone(), 1);
  });

  testWidgets(
      'logic renders and scores its actual answer in the existing task screen',
      (tester) async {
    final task = ExerciseFactory(seed: 31)
        .next(grade: 3, subject: 'Logik', unit: 'Schlussfolgern');
    final instance = const LegacyLumoTaskAdapter().toTaskInstance(
        task: task, childId: 'neutral-local-test', difficulty: 3);
    expect(instance.subject, LearningSubject.logik);
    AdaptiveTaskAnswer? result;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: AdaptiveTaskRenderer(
      task: instance,
      onAnswered: (answer) => result = answer,
    )))));
    expect(find.text('Logik'), findsOneWidget);
    await tester.tap(find.text(task.answer));
    await tester.pump();
    expect(result?.correct, isTrue);
    expect(result?.answer, instance.correctAnswer);
    expect(tester.takeException(), isNull);
  });
}
