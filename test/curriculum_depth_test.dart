import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

void main() {
  const grammarUnits = {
    2: [
      'Wortfamilien',
      'Einzahl und Mehrzahl',
      'Verkleinerungsform',
      'Gegenteile',
      'Oberbegriffe'
    ],
    3: [
      'Synonyme',
      'Zeitformen',
      'Steigerung',
      'Verbformen',
      'Wer-Fall und Wen-Fall',
      'Großschreibung',
      'ie oder i'
    ],
    4: [
      'Satzglieder',
      'Direkte Rede',
      'Kommas in Aufzählungen',
      'Zusammensetzungen',
      'Die 4 Fälle',
      'dass oder das',
      'Umstandswörter',
      'Vorvergangenheit'
    ],
  };
  for (final entry in grammarUnits.entries) {
    for (final unit in entry.value) {
      test('grade ${entry.key} $unit has 20 distinct grammatical problems', () {
        final f = ExerciseFactory(seed: 1938);
        final problems = <String>{};
        for (var i = 0; i < 400; i++) {
          final t = f.next(grade: entry.key, subject: 'Deutsch', unit: unit);
          expect(const TaskQualityGuard().problems(t), isEmpty,
              reason: t.prompt);
          expect(t.unit, unit);
          problems.add('${t.prompt}|${t.answer}');
        }
        expect(problems.length, greaterThanOrEqualTo(20), reason: unit);
      });
    }
  }
  for (var grade = 1; grade <= 4; grade++) {
    test(
        'grade $grade spelling uses at least 20 actual contextual problems per topic',
        () {
      for (final unit in [
        'Haeufige Woerter',
        'Doppelmitlaut',
        'Dehnungen',
        'Satzzeichen',
        'Wortende'
      ]) {
        final f = ExerciseFactory(seed: 1938);
        final prompts = <String>{};
        for (var i = 0; i < 400; i++) {
          final t =
              f.next(grade: grade, subject: 'Rechtschreibung', unit: unit);
          expect(const TaskQualityGuard().problems(t), isEmpty,
              reason: '$grade $unit ${t.prompt}');
          prompts.add('${t.prompt}|${t.answer}');
        }
        expect(prompts.length, greaterThanOrEqualTo(20),
            reason: '$grade $unit');
      }
    });
    test(
        'grade $grade English has a broader real vocabulary in every current topic',
        () {
      for (final unit in Curriculum.unitsForGrade('Englisch', grade,
          currentGradeOnly: true)) {
        final f = ExerciseFactory(seed: 1938);
        final prompts = <String>{};
        for (var i = 0; i < 400; i++) {
          final t = f.next(grade: grade, subject: 'Englisch', unit: unit);
          expect(const TaskQualityGuard().problems(t), isEmpty,
              reason: t.prompt);
          expect(t.unit, unit);
          expect(t.choices.length, inInclusiveRange(3, 4));
          prompts.add('${t.prompt}|${t.answer}');
        }
        expect(prompts.length, greaterThanOrEqualTo(10),
            reason: '$grade $unit');
      }
    });
  }
}
