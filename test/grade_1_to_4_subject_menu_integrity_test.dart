import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  test('AT Volksschule keeps Sachunterricht in grades 3 and 4', () {
    for (var grade = 1; grade <= 4; grade++) {
      final subjects = Curriculum.officialSubjectsForGrade(grade);
      expect(subjects, contains('Sachunterricht'));
      final academy = LumoCurriculum.grades.singleWhere((g) => g.grade == grade);
      expect(academy.subjects.map((s) => s.name), contains('Sachunterricht'));
      expect(academy.subjects.where((s) => s.name == 'Sachunterricht').length,
          1);
      expect(academy.subjects.map((s) => s.name), contains('Englisch'));
      expect(academy.subjects.where((s) => s.name == 'Englisch').length, 1);
      final preview = Curriculum.exerciseSubjectsForGrade(grade);
      expect(preview, containsAll(['Sachunterricht', 'Englisch']));
    }
    expect(Curriculum.officialSubjectsForGrade(1),
        contains('Lebende Fremdsprache (verbindliche Übung)'));
    expect(Curriculum.officialSubjectsForGrade(4),
        contains('Lebende Fremdsprache'));
  });

  test('every visible English/Sachunterricht grade topic starts real work',
      () {
    const topicMappings = <String, String>{
      's1_koerper': 'Körper',
      'en1_3': 'Begruessung',
      's3_oesterreich': 'Bundesländer Österreichs',
      's3_natur': 'Pflanzen',
      's4_europa': 'Kontinente und Ozeane',
    };
    const quality = TaskQualityGuard();
    for (final gradeInfo in LumoCurriculum.grades) {
      for (final subject in gradeInfo.subjects.where(
          (s) => s.name == 'Sachunterricht' || s.name == 'Englisch')) {
        for (final topic in subject.topics) {
          final unit = topicMappings[topic.id] ?? topic.title;
          final context = '${gradeInfo.grade}/${subject.name}/$unit';
          final selectable =
              Curriculum.unitsForGrade(subject.name, gradeInfo.grade);
          expect(selectable, contains(unit), reason: context);
          for (var seed = 0; seed < 12; seed++) {
            final task = ExerciseFactory(seed: seed).next(
              grade: gradeInfo.grade, subject: subject.name, unit: unit,
            );
            expect(task.subject, subject.name, reason: context);
            expect(task.unit, unit, reason: context);
            expect(task.prompt.trim().length, greaterThan(8),
                reason: '$context: empty prompt');
            expect(task.answer.trim(), isNotEmpty, reason: context);
            expect(task.choices, contains(task.answer), reason: context);
            expect(quality.problems(task), isEmpty,
                reason: '$context seed $seed: ${task.prompt}');
          }
        }
      }
    }
  });

  test('every upper-grade Math/German academy tile is backed by tasks',
      () {
    const resolved = <String, String>{
      'm3_zahlen1000': 'Plus bis 1000',
      'm3_einmaleins_voll': 'Einmaleins',
      'm3_geometrie': 'Umfang',
      'm4_million': 'Zahlenraum bis 1 Million',
      'm4_bruch': 'Bruchrechnen einfach',
      'm4_textaufgaben': 'Sachaufgaben drei Schritte',
      'd3_wortarten': 'Wortarten',
      'd3_zeitformen': 'Zeitformen',
      'd4_grammatik': 'Die 4 Fälle',
    };
    for (final grade in [3, 4]) {
      final academia = LumoCurriculum.grades
          .singleWhere((g) => g.grade == grade);
      for (final subject in academia.subjects.where(
          (x) => x.name == 'Mathematik' || x.name == 'Deutsch')) {
        for (final topic in subject.topics) {
          if (topic.id == 'd3_geschichten' ||
              topic.id == 'd4_aufsatz') continue;
          final unit = resolved[topic.id] ?? topic.title;
          expect(Curriculum.unitsForGrade(subject.name, grade),
              contains(unit), reason: '${subject.name}/${topic.id}');
          final task = ExerciseFactory(seed: 314).next(
            grade: grade, subject: subject.name, unit: unit,
          );
          expect(task.subject, subject.name);
          expect(task.unit, unit);
          expect(task.prompt.trim().length, greaterThan(8));
          expect(task.choices, contains(task.answer));
        }
      }
    }
  });

  test('higher classes have their own content, not only grade-one topics',
      () {
    for (final subject in ['Mathematik', 'Deutsch', 'Sachunterricht', 'Englisch']) {
      final third =
          Curriculum.unitsForGrade(subject, 3, currentGradeOnly: true);
      final fourth =
          Curriculum.unitsForGrade(subject, 4, currentGradeOnly: true);
      expect(third, isNotEmpty, reason: '$subject grade 3');
      expect(fourth, isNotEmpty, reason: '$subject grade 4');
      expect(third.toSet(), isNot(equals(fourth.toSet())),
          reason: '$subject 3./4. Klasse must be distinguishable');
    }
    final three = Curriculum.unitsForGrade('Sachunterricht', 3,
        currentGradeOnly: true);
    expect(three, contains('Bundesländer Österreichs'));
    final four = Curriculum.unitsForGrade('Sachunterricht', 4,
        currentGradeOnly: true);
    expect(four, contains('Kontinente und Ozeane'));
  });

  test('mixed schoolwork includes real English in every grade', () {
    for (var grade = 1; grade <= 4; grade++) {
      final tasks = ExerciseFactory(seed: grade).buildBalancedSchoolwork(
        grade: grade, weakSkills: const {}, count: 14,
      );
      expect(tasks.map((t) => t.subject), contains('Englisch'),
          reason: 'grade $grade');
      expect(tasks.map((t) => t.subject), contains('Sachunterricht'));
      for (final task in tasks) {
        expect(task.prompt.trim(), isNotEmpty);
        expect(task.choices, contains(task.answer));
      }
    }
  });
}
