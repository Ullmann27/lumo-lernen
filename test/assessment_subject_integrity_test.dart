import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

void main() {
  const subjects = [
    'Mathematik', 'Deutsch', 'Sachunterricht', 'Englisch', 'Logik', 'Alle',
  ];
  const guard = TaskQualityGuard();
  // All school test menu combinations, including review and next-grade levels.
  for (var childGrade = 1; childGrade <= 4; childGrade++) {
    for (var level = -1; level <= 1; level++) {
      final grade = (childGrade + level).clamp(1, 4).toInt();
      for (final subject in subjects) {
        test('Test $subject Klasse $childGrade Stufe $level', () {
          for (final seed in [3, 19, 103, 271]) {
            final tasks = ExerciseFactory(seed: seed).buildSession(
              grade: grade, count: 10, subject: subject,
            );
            expect(tasks, hasLength(10));
            for (final task in tasks) {
              final context = '$subject/$grade: ${task.prompt}';
              if (subject == 'Alle') {
                expect(Curriculum.exerciseSubjectsForGrade(grade),
                    contains(task.subject), reason: context);
              } else {
                expect(task.subject, subject, reason: context);
              }
              expect(task.grade, grade, reason: context);
              expect(task.difficulty, inInclusiveRange(1, grade),
                  reason: context);
              expect(guard.problems(task), isEmpty, reason: context);
              if (task.subject == 'Mathematik') {
                expect(task.prompt, isNot(matches(RegExp(
                  r'Welche Jahreszeit kommt|Wie viele Jahreszeiten|frühstückst|gehst du schlafen',
                  caseSensitive: false,
                ))), reason: context);
              }
            }
          }
        });
      }
    }
  }
}
