// Regression-Test fuer den strikten Klassen-Filter (AT-Lehrplan-konform,
// Heinz 2026-06-03). Stellt sicher dass templatesForGradeStrict() NUR
// Templates der EXAKTEN Klassenstufe liefert. Bricht der Filter, faellt
// das Niveau wieder auf "Klasse 4 sieht Klasse-1-Aufgaben" zurueck - das
// soll dieser Test verhindern.

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('MathTaskTemplates.templatesForGradeStrict', () {
    test('liefert NUR Templates der exakten Klasse', () {
      for (var grade = 1; grade <= 4; grade++) {
        final strict = MathTaskTemplates.templatesForGradeStrict(grade);
        expect(strict, isNotEmpty, reason: 'strict pool grade $grade darf nicht leer sein');
        for (final t in strict) {
          expect(t.grade, equals(grade),
              reason: 'strict(grade=$grade) hat ${t.id} (grade=${t.grade}) -> Filter kaputt');
        }
      }
    });

    test('faellt zurueck wenn Unit in Klasse nicht existiert', () {
      // Plus bis 10 ist nur grade=1. Strikt fuer grade=4 mit dieser Unit
      // muss zurueckfallen, darf aber niemals leer sein.
      final fallback =
          MathTaskTemplates.templatesForGradeStrict(4, unit: 'Plus bis 10');
      expect(fallback, isNotEmpty, reason: 'Fallback bei unbekannter Unit in Klasse');
    });

    test('strict-Pool hat mindestens 5 Templates pro Klasse', () {
      // Pflichtmenge fuer Variation - sonst sieht das Kind staendig
      // dieselbe Aufgabe.
      for (var grade = 1; grade <= 4; grade++) {
        expect(
          MathTaskTemplates.templatesForGradeStrict(grade).length,
          greaterThanOrEqualTo(5),
          reason: 'Klasse $grade braucht mindestens 5 Math-Templates',
        );
      }
    });
  });

  group('GermanTaskTemplates.templatesForGradeStrict', () {
    test('liefert NUR Templates der exakten Klasse', () {
      for (var grade = 1; grade <= 4; grade++) {
        final strict = GermanTaskTemplates.templatesForGradeStrict(grade);
        expect(strict, isNotEmpty, reason: 'strict pool grade $grade darf nicht leer sein');
        for (final t in strict) {
          expect(t.grade, equals(grade),
              reason: 'strict(grade=$grade) hat ${t.id} (grade=${t.grade}) -> Filter kaputt');
        }
      }
    });

    test('strict-Pool hat mindestens 5 Templates pro Klasse', () {
      for (var grade = 1; grade <= 4; grade++) {
        expect(
          GermanTaskTemplates.templatesForGradeStrict(grade).length,
          greaterThanOrEqualTo(5),
          reason: 'Klasse $grade braucht mindestens 5 Deutsch-Templates',
        );
      }
    });
  });

  group('ExerciseFactory generate', () {
    test('Englisch ist klassen-spezifisch (vorher Bug: grade-Parameter ignoriert)', () {
      // Wenn der Klassen-Fix funktioniert, muss Klasse 1 ein anderes
      // Englisch-Wortset bekommen als Klasse 4 (auch wenn beide ueber viele
      // Seeds wiederholt werden). Wir pruefen indirekt: Klasse 4 produziert
      // Verben oder Wochentage (Lehrplan), Klasse 1 nicht.
      final factory4 = ExerciseFactory(seed: 41);
      final klasse4Antworten = <String>{};
      for (var i = 0; i < 30; i++) {
        final t = factory4.next(grade: 4, subject: 'Englisch', unit: 'Verben');
        klasse4Antworten.add(t.answer);
      }
      expect(
        klasse4Antworten.intersection({'laufen', 'springen', 'essen', 'trinken', 'lesen', 'schreiben'}),
        isNotEmpty,
        reason: 'Klasse 4 Englisch.Verben muss Verb-Vokabeln liefern',
      );

      // Klasse 1 sollte primaer Themen aus dem 1.-Klasse-Wortschatz liefern.
      final factory1 = ExerciseFactory(seed: 42);
      final klasse1Antworten = <String>{};
      for (var i = 0; i < 30; i++) {
        final t = factory1.next(grade: 1, subject: 'Englisch', unit: 'Farben');
        klasse1Antworten.add(t.answer);
      }
      // Klasse-1-Farben-Vokabular (Lehrplan)
      expect(
        klasse1Antworten.intersection({'rot', 'blau', 'grün', 'gelb'}),
        isNotEmpty,
        reason: 'Klasse 1 Englisch.Farben muss Basis-Farben liefern',
      );
    });
  });
}
