import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  test('grade-specific menus expose every real template and no future topic',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      final math = Curriculum.unitsForGrade('Mathematik', grade);
      final german = Curriculum.unitsForGrade('Deutsch', grade);
      expect(math.toSet().length, math.length);
      expect(german.toSet().length, german.length);
      for (final template in MathTaskTemplates.templates) {
        if (template.grade <= grade) {
          expect(math, contains(template.unit));
        }
      }
      for (final template in GermanTaskTemplates.templates) {
        if (template.grade <= grade) {
          expect(german, contains(template.unit));
        }
      }
    }
    expect(Curriculum.unitsForGrade('Mathematik', 1),
        isNot(contains('Schriftliche Division')));
    expect(
        Curriculum.unitsForGrade('Deutsch', 1), isNot(contains('Die 4 Fälle')));
    expect(Curriculum.unitsForGrade('Sachunterricht', 1),
        isNot(contains('Stromkreise')));
    expect(
        Curriculum.unitsForGrade('Mathematik', 4),
        containsAll([
          'Massen Kilogramm und Gramm',
          'Plus bis 10000',
          'Hohlmaße Liter und Milliliter',
          'Brüche erweitern'
        ]));
  });

  test('an unavailable explicit topic falls back with the actual unit label',
      () {
    final factory = ExerciseFactory(seed: 17);
    for (final subject in ['Mathematik', 'Deutsch', 'Sachunterricht', 'Englisch']) {
      final task =
          factory.next(grade: 1, subject: subject, unit: 'Not a real topic');
      expect(Curriculum.unitsForGrade(subject, 1), contains(task.unit));
      expect(task.unit, isNot('Not a real topic'));
    }
    final task = factory.next(
        grade: 1, subject: 'Mathematik', unit: 'Schriftliche Division');
    expect(Curriculum.unitsForGrade('Mathematik', 1), contains(task.unit));
  });

  test('mixed fourth-grade practice stays strictly in current-grade topics',
      () {
    for (final subject in [
      'Mathematik',
      'Deutsch',
      'Sachunterricht',
      'Englisch',
    ]) {
      final current =
          Curriculum.unitsForGrade(subject, 4, currentGradeOnly: true).toSet();
      final factory = ExerciseFactory(seed: 42);
      for (var i = 0; i < 300; i++) {
        final task = factory.next(grade: 4, subject: subject);
        expect(
          current,
          contains(task.unit),
          reason:
              '$subject Klasse 4 darf ohne bewusste Wiederholung kein altes Thema liefern: ${task.unit}',
        );
      }
    }
  });

  test('fourth-grade math menu does not expose grade-one arithmetic', () {
    final grade4 = Curriculum.unitsForGrade(
      'Mathematik',
      4,
      currentGradeOnly: true,
    );
    expect(grade4, isNot(contains('Plus bis 10')));
    expect(grade4, isNot(contains('Minus bis 10')));
    expect(grade4, isNot(contains('Plus bis 20')));
    expect(grade4, contains('Schriftliche Multiplikation'));
    expect(grade4, contains('Schriftliche Division'));
  });

  test('reading writing and spelling have their own grade menus', () {
    final reading1 =
        Curriculum.unitsForGrade('Lesen', 1, currentGradeOnly: true);
    final reading4 =
        Curriculum.unitsForGrade('Lesen', 4, currentGradeOnly: true);
    final writing1 =
        Curriculum.unitsForGrade('Schreiben', 1, currentGradeOnly: true);
    final writing4 =
        Curriculum.unitsForGrade('Schreiben', 4, currentGradeOnly: true);

    expect(reading1, contains('Woerter lesen'));
    expect(reading4, isNot(contains('Woerter lesen')));
    expect(writing1, contains('Buchstaben nachspuren'));
    expect(writing4, isNot(contains('Buchstaben nachspuren')));

    for (var grade = 1; grade <= 4; grade++) {
      expect(
        Curriculum.unitsForGrade(
          'Rechtschreibung',
          grade,
          currentGradeOnly: true,
        ),
        isNotEmpty,
        reason: 'Rechtschreibung braucht Themen fuer Klasse $grade',
      );
    }
  });

  test('a requested available legacy alias remains usable', () {
    final factory = ExerciseFactory(seed: 2);
    final noun =
        factory.next(grade: 2, subject: 'Deutsch', unit: 'Namenswoerter');
    expect(noun.unit, 'Namenswoerter');
    final house =
        factory.next(grade: 2, subject: 'Mathematik', unit: 'Rechenhaeuser');
    expect(house.subject, 'Mathematik');
    expect(house.unit, 'Plus bis 20');
  });
}
