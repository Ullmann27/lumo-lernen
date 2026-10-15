import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  String signature(LumoTask task) =>
      '${task.prompt.trim().toLowerCase()}|${task.answer.trim().toLowerCase()}';

  for (final grade in [1, 2, 3, 4]) {
    test('mixed grade-$grade lesson avoids duplicate visible questions', () {
      final factory = ExerciseFactory(seed: grade * 73);
      final tasks = factory.buildSession(grade: grade, count: 20);
      expect(tasks, hasLength(20));
      expect(tasks.map(signature).toSet().length, 20);
      expect(tasks.every((t) => t.choices.contains(t.answer)), isTrue);
    });

    test('balanced grade-$grade homework avoids duplicate questions', () {
      final factory = ExerciseFactory(seed: grade * 101);
      final tasks = factory.buildBalancedSchoolwork(
          grade: grade, weakSkills: const {}, count: 14);
      expect(tasks, hasLength(14));
      expect(tasks.map(signature).toSet().length, 14);
    });
  }
}
