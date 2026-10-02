import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';
import 'package:lumo_lernen/core/writing_target_parser.dart';
import 'package:lumo_lernen/features/learning/adapters/legacy_lumo_task_adapter.dart';

void main() {
  const guard = TaskQualityGuard();
  const adapter = LegacyLumoTaskAdapter();

  test(
      'all listed non-math/German tasks survive actual validation without relabelling',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final subject in [
        'Rechtschreibung',
        'Schreiben',
        'Lesen',
        'Englisch'
      ]) {
        for (final unit in Curriculum.unitsForGrade(subject, grade)) {
          for (var seed = 0; seed < 20; seed++) {
            final task = ExerciseFactory(seed: seed)
                .next(grade: grade, subject: subject, unit: unit);
            final label = '$grade/$subject/$unit seed=$seed';
            expect(guard.problems(task), isEmpty,
                reason: '$label ${task.prompt} ${task.choices}');
            final checked = adapter.qualityCheckedTask(task);
            expect(checked.subject, subject, reason: label);
            expect(checked.unit, unit, reason: label);
            expect(checked.prompt, task.prompt, reason: label);
            expect(checked.answer, task.answer, reason: label);
            expect(checked.choices, task.choices, reason: label);
            expect(task.choices, contains(task.answer), reason: label);
            if (!task.handwriting) {
              expect(task.choices.length, greaterThanOrEqualTo(3),
                  reason: label);
            }
          }
        }
      }
    }
  });

  test('first-grade English school supplies stay within school supplies', () {
    final observed = <String>{};
    for (var seed = 0; seed < 40; seed++) {
      final task = ExerciseFactory(seed: seed)
          .next(grade: 1, subject: 'Englisch', unit: 'Schulsachen');
      observed.add(task.answer);
      expect(['Buch', 'Stift', 'Tasche', 'Lineal'], contains(task.answer));
      expect(task.choices.every(['Buch', 'Stift', 'Tasche', 'Lineal'].contains),
          isTrue);
    }
    expect(observed.length, greaterThan(1));
  });

  test('unknown English units honestly report the topic actually generated',
      () {
    final task = ExerciseFactory(seed: 22)
        .next(grade: 1, subject: 'Englisch', unit: 'unbekannt');
    expect(task.unit, isNot('unbekannt'));
    expect(Curriculum.subjects['Englisch'], contains(task.unit));
  });

  test(
      'reading tasks contain their evidence and never ask about an absent picture',
      () {
    for (var grade = 1; grade <= 4; grade++) {
      for (final unit in Curriculum.subjects['Lesen']!) {
        final task = ExerciseFactory(seed: 13)
            .next(grade: grade, subject: 'Lesen', unit: unit);
        expect(task.prompt, isNot(contains('Welcher Artikel')));
        expect(task.prompt, isNot(contains('ist im Bild')));
        if (unit == 'Bild und Wort') {
          expect(task.prompt, startsWith('Schau genau:'));
        }
        if (unit == 'Reihenfolge') {
          expect(task.prompt, contains('Was passiert'));
        }
      }
    }
  });

  test('writing target matches the chosen activity and available number range',
      () {
    final factory = ExerciseFactory(seed: 33);
    for (var grade = 1; grade <= 4; grade++) {
      for (var i = 0; i < 25; i++) {
        final letter = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Buchstaben nachspuren');
        expect(WritingTargetParser.parse(letter.prompt),
            matches(RegExp(r'^[A-Z]$')));
        final number = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Zahlen schreiben');
        expect(int.parse(WritingTargetParser.parse(number.prompt)),
            inInclusiveRange(0, 20));
        final sentence = factory.next(
            grade: grade, subject: 'Schreiben', unit: 'Satz abschreiben');
        expect(WritingTargetParser.parse(sentence.prompt).split(' ').length,
            greaterThanOrEqualTo(2));
      }
      final wave = factory.next(
          grade: grade, subject: 'Schreiben', unit: 'Schwunguebung');
      expect(WritingTargetParser.parse(wave.prompt), '∿');
    }
  });

  test(
      'capitalization has a meaningful choice contrast without generic fillers',
      () {
    final task = ExerciseFactory(seed: 11)
        .next(grade: 1, subject: 'Rechtschreibung', unit: 'Gross und klein');
    expect(task.answer, startsWith('Großer Anfang:'));
    expect(task.choices.any((choice) => choice.startsWith('Alles klein:')),
        isTrue);
    expect(
        task.choices.any((choice) => choice.startsWith('Alles groß:')), isTrue);
    expect(task.choices.any(['ja', 'nein', 'vielleicht', 'anderes'].contains),
        isFalse);
  });

  test('Dehnungen and Wortende teach their named spelling pattern', () {
    final factory = ExerciseFactory(seed: 45);
    for (var i = 0; i < 20; i++) {
      final dehnung =
          factory.next(grade: 2, subject: 'Rechtschreibung', unit: 'Dehnungen');
      expect(dehnung.answer.contains('h') || dehnung.answer.contains('ie'),
          isTrue);
      final ending =
          factory.next(grade: 2, subject: 'Rechtschreibung', unit: 'Wortende');
      expect(ending.prompt, startsWith('Verlängere das Wort:'));
      expect(ending.answer.length, 1);
    }
  });
}
