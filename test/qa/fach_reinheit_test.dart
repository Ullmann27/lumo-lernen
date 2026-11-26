import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

/// Fachreinheit: Eine Aufgabe gehört in das Fach, dessen Kompetenz sie
/// verlangt (Lehrplan der Volksschule, BGBl. II Nr. 1/2023, Anlage A).
///
/// Bekannter Fehlertyp (PR #554): Im Mathe-Test tauchten Jahreszeiten- und
/// Tagesablauf-Fragen aus dem Sachunterricht auf. Wochentage, Monate und
/// Tageszeiten der Reihe nach sind Sachunterricht („Jahr und Zeit“ in der
/// 1. Schulstufe, „Kalender und Uhr“ in der 2. Schulstufe). Mathematik
/// rechnet mit Zeitspannen und liest Uhrzeiten ab.
void main() {
  const seeds = 300;

  final calendarKnowledge = RegExp(
    r'Welcher (Tag|Monat|Wochentag)\b|Welche Tageszeit|Jahreszeit|'
    r'Was bedeutet (morgen|gestern|heute)|Heute ist (Montag|Dienstag|'
    r'Mittwoch|Donnerstag|Freitag|Samstag|Sonntag)\.|frühstückst|'
    r'gehst du schlafen|letzte im Jahr|nach dem (Winter|Sommer|Herbst|'
    r'Frühling|Jänner)',
    caseSensitive: false,
  );

  group('Mathematik enthält kein Sachunterrichts-Kalenderwissen', () {
    for (var grade = 1; grade <= 4; grade++) {
      test('Klasse $grade: alle Mathe-Einheiten, je $seeds Startwerte', () {
        final units = Curriculum.unitsForGrade('Mathematik', grade);
        expect(units, isNotEmpty);
        for (final unit in units) {
          for (var seed = 0; seed < seeds; seed++) {
            final task = ExerciseFactory(seed: seed * 7919 + grade)
                .nextExact(grade: grade, subject: 'Mathematik', unit: unit);
            expect(task.subject, 'Mathematik');
            expect(task.prompt, isNot(matches(calendarKnowledge)),
                reason: '$grade/$unit: ${task.prompt}');
          }
        }
      });

      test('Klasse $grade: Mathe-Test (alle Stufen) ohne Kalenderwissen', () {
        for (var seed = 0; seed < 60; seed++) {
          final tasks = ExerciseFactory(seed: seed * 31 + grade)
              .buildSession(grade: grade, count: 10, subject: 'Mathematik');
          for (final task in tasks) {
            expect(task.subject, 'Mathematik');
            expect(task.prompt, isNot(matches(calendarKnowledge)),
                reason: '$grade/${task.unit}: ${task.prompt}');
          }
        }
      });
    }

    test('der Kalenderstoff bleibt im Sachunterricht erhalten', () {
      // Die aus Mathematik entfernten Fragen sind dort nicht verloren.
      final prompts = <String>{};
      final factory = ExerciseFactory(seed: 5);
      for (var i = 0; i < 200; i++) {
        prompts.add(factory
            .nextExact(grade: 1, subject: 'Sachunterricht',
                unit: 'Zeit und Kalender')
            .prompt);
      }
      expect(prompts, contains('Was bedeutet morgen?'));
      expect(prompts.where(calendarKnowledge.hasMatch), isNotEmpty);
    });
  });

  group('Schwächen mit gleichem Einheitsnamen wechseln nicht das Fach', () {
    // Schwächen werden nur unter dem Einheitsnamen gespeichert. „Tiere“,
    // „Körper“ und „Wetter“ gibt es in Englisch und im Sachunterricht.
    // Früher landete jede solche Schwäche fast immer im Englisch.
    for (var grade = 1; grade <= 4; grade++) {
      test('Klasse $grade: gemischte Übung verteilt geteilte Schwächen fair',
          () {
        final counts = <String, int>{};
        for (var seed = 0; seed < 1500; seed++) {
          final task = ExerciseFactory(seed: seed * 37 + grade).next(
            grade: grade,
            weakSkills: const {'Tiere': 5},
          );
          if (task.unit == 'Tiere') {
            counts[task.subject] = (counts[task.subject] ?? 0) + 1;
          }
        }
        final english = counts['Englisch'] ?? 0;
        final science = counts['Sachunterricht'] ?? 0;
        expect(english + science, greaterThan(40), reason: '$counts');
        // Beide Fächer bieten „Tiere“ an: keines darf dominieren. (Vorher
        // Klasse 1: 130 × Englisch, 7 × Sachunterricht.)
        expect(science, greaterThan((english + science) * .2),
            reason: 'Sachunterricht-Schwäche wird nicht geübt: $counts');
        expect(english, greaterThan((english + science) * .2),
            reason: '$counts');
      });
    }
  });
}
