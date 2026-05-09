import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('GermanTaskTemplates', () {
    test('all grades expose age-appropriate Deutsch templates', () {
      expect(GermanTaskTemplates.templatesForGrade(1), hasLength(greaterThanOrEqualTo(7)));
      expect(GermanTaskTemplates.templatesForGrade(2), hasLength(greaterThanOrEqualTo(14)));
      expect(GermanTaskTemplates.templatesForGrade(3), hasLength(greaterThanOrEqualTo(19)));
      expect(GermanTaskTemplates.templatesForGrade(4), hasLength(greaterThanOrEqualTo(23)));
    });

    test('generated tasks include answer and distinct choices', () {
      for (final template in GermanTaskTemplates.templates) {
        for (var seed = 1; seed <= 10; seed++) {
          final task = template.concretize(seed * 29);
          expect(task.prompt.trim(), isNotEmpty, reason: template.id);
          expect(task.answer.trim(), isNotEmpty, reason: template.id);
          expect(task.choices, contains(task.answer), reason: template.id);
          expect(task.choices.toSet(), hasLength(task.choices.length), reason: template.id);
          expect(task.explanation.trim(), isNotEmpty, reason: template.id);
        }
      }
    });

    test('word type pools separate nouns, verbs and adjectives', () {
      final noun = PrimarySchoolWordData.nounForGrade(3, 7);
      final verb = PrimarySchoolWordData.verbForGrade(3, 8);
      final adjective = PrimarySchoolWordData.adjectiveForGrade(3, 9);

      expect(PrimarySchoolWordData.articleFor(noun), isNotNull);
      expect(PrimarySchoolWordData.articleFor(verb), isNull);
      expect(PrimarySchoolWordData.articleFor(adjective), isNull);
      expect(PrimarySchoolWordData.verbsForGrade(3), contains(verb));
      expect(PrimarySchoolWordData.adjectivesForGrade(3), contains(adjective));
    });

    test('grammar templates contain checked plural, comparison and verb forms', () {
      final plural = GermanTaskTemplates.generate(grade: 2, unit: 'Einzahl und Mehrzahl', seed: 3);
      final comparison = GermanTaskTemplates.generate(grade: 3, unit: 'Steigerung', seed: 5);
      final verbForm = GermanTaskTemplates.generate(grade: 3, unit: 'Verbformen', seed: 7);

      expect(plural.answer.trim(), isNotEmpty);
      expect(comparison.answer, contains(','));
      expect(verbForm.prompt, contains('_____'));
      expect(verbForm.choices, contains(verbForm.answer));
    });

    test('legacy generator keeps German units valid', () {
      final factory = ExerciseFactory(seed: 27);
      for (final unit in <String>[
        'Anfangslaute',
        'Endlaute',
        'Silben',
        'Reime',
        'Wortschatz',
        'Satz verstehen',
        'Artikel',
        'Namenwoerter',
        'Namenswoerter',
        'Hauptwoerter',
        'Tunwoerter',
        'Wiewoerter',
        'Satz bauen',
        'Einzahl und Mehrzahl',
        'Wort-Bild schreiben',
      ]) {
        final task = factory.next(grade: 2, subject: 'Deutsch', unit: unit);
        expect(task.subject, 'Deutsch', reason: unit);
        expect(task.choices, contains(task.answer), reason: unit);
        expect(task.prompt.trim(), isNotEmpty, reason: unit);
      }
    });
  });
}
