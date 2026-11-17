import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Test the exact grade/topic contract behind EVERY selectable local core
/// unit. This checks what the generator can really build, not a hand-picked
/// menu sample or a cloud-model answer. Practical subjects use the separate
/// PrimaryActivityCatalog and its widget-navigation regression suite.
void main() {
  const guard = TaskQualityGuard();
  const subjects = <String>[
    'Mathematik',
    'Deutsch',
    'Sachunterricht',
    'Englisch',
    'Lesen',
    'Schreiben',
    'Rechtschreibung',
    'Logik',
  ];
  const seeds = <int>[3, 13, 43, 97, 191, 389];

  for (var grade = 1; grade <= 4; grade++) {
    for (final subject in subjects) {
      test('$grade. Klasse $subject: alle aktuellen Generator-Themen geprüft',
          () {
        final units =
            Curriculum.unitsForGrade(subject, grade, currentGradeOnly: true);
        expect(units, isNotEmpty,
            reason: 'Im Lernhub fehlt der Stoff für $subject/$grade');
        for (final unit in units) {
          for (final seed in seeds) {
            final task = ExerciseFactory(seed: seed).next(
              grade: grade,
              subject: subject,
              unit: unit,
            );
            final path = '$grade/$subject/$unit/seed=$seed';
            expect(task.grade, grade, reason: path);
            expect(task.subject, subject, reason: path);
            expect(task.unit, unit,
                reason: '$path: stiller Themenwechsel ist unzulässig');
            expect(task.prompt.trim(), isNotEmpty, reason: path);
            expect(task.answer.trim(), isNotEmpty, reason: path);
            // Drawing/trace tasks use the real interactive shape renderer,
            // not multiple-choice buttons. An empty choice bank is valid
            // only for this explicit non-MCQ mode (or handwriting tasks).
            if (task.choices.isEmpty) {
              expect(task.handwriting || task.visual == 'shape_trace', isTrue,
                  reason: '$path: keine Antwortoptionen ohne Zeichenrenderer');
              expect(task.answer.trim(), isNotEmpty, reason: path);
            } else {
              expect(task.choices, contains(task.answer), reason: path);
            }
            expect(guard.problems(task), isEmpty,
                reason: '$path: ${task.prompt} / ${task.choices}');
          }
        }
      });
    }
  }
}
