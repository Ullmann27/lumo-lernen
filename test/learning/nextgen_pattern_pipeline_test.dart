import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/checked_task_patterns.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

void main() {
  test('generated checked patterns reach the canonical native payload', () {
    const adapter = LegacyLumoTaskAdapter();
    const quality = TaskQualityGuard();
    for (var grade = 1; grade <= 4; grade++) {
      for (final seed in [0, 1, 5, 13, 34, 89]) {
        final source = ExerciseFactory(seed: seed)
            .nextExact(grade: grade, subject: 'Logik', unit: 'Muster');
        final scope = 'grade=$grade, seed=$seed';
        expect(quality.problems(source), isEmpty, reason: scope);
        expect(adapter.qualityCheckedTask(source), same(source), reason: scope);
        final checked = CheckedShapePattern.fromPrompt(source.prompt)!;
        final task = adapter.toTaskInstance(
          task: source,
          childId: 'synthetic-pattern-pipeline',
          difficulty: source.difficulty,
          now: DateTime.utc(2026, 11, 15),
        );
        expect(task.parameters['legacyId'], source.id, reason: scope);
        expect(task.correctAnswer, source.answer, reason: scope);
        expect(task.visualPayload.data['sequence'], checked.sequence);
        expect(task.visualPayload.data['period'], checked.period);

        final native = NativeLearningActivity.fromTask(task);
        expect(native, isNotNull, reason: scope);
        final payload = jsonDecode(jsonEncode(native!.toLaunchOptions()));
        expect(
            payload,
            {
              'kind': 'pattern',
              'sequence': checked.sequence,
              'choices': source.choices,
              'period': checked.period,
            },
            reason: scope);
        expect(payload.containsKey('patternUnit'), isFalse);
        expect(payload.containsKey('correctAnswer'), isFalse);
        expect(payload.containsKey('childId'), isFalse);
      }
    }
  });
}
