import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  test('stories stay visible in every primary-school grade', () {
    for (final grade in LumoCurriculum.grades) {
      final deutsch =
          grade.subjects.firstWhere((subject) => subject.name == 'Deutsch');
      expect(
        deutsch.topics.any(
          (topic) =>
              topic.unitKey == '__stories__' &&
              topic.title == 'Geschichten · Lesen & verstehen',
        ),
        isTrue,
        reason: '${grade.grade}. Klasse braucht den sichtbaren Geschichten-Pfad',
      );
    }
  });

  test('writing special paths remain visible without bringing chat back', () {
    final grade1 = LumoCurriculum.grades
        .firstWhere((grade) => grade.grade == 1);
    final writing1 =
        grade1.subjects.firstWhere((subject) => subject.name == 'Schreiben');

    expect(
      writing1.topics.any((topic) => topic.unitKey == '__writing_coach__'),
      isTrue,
    );

    for (final grade in LumoCurriculum.grades) {
      final writing =
          grade.subjects.firstWhere((subject) => subject.name == 'Schreiben');
      expect(
        writing.topics.any((topic) => topic.unitKey == '__word_coach__'),
        isTrue,
        reason: '${grade.grade}. Klasse braucht Wörter schreiben',
      );
      expect(
        writing.topics.any(
          (topic) =>
              topic.unitKey.contains('chat') ||
              topic.title.toLowerCase().contains('chat'),
        ),
        isFalse,
      );
    }
  });

  test('grade-two science special modules stay registered', () {
    for (final id in <String>[
      's2_jahreszeiten',
      's2_wetter',
      's2_verkehr',
    ]) {
      expect(
        LearningModuleRegistry.hasModule(id),
        isTrue,
        reason: '$id darf beim Curriculum-Umbau nicht verloren gehen',
      );
    }
  });
}
