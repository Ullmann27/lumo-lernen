import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';
import 'package:lumo_lernen/core/curriculum/primary_curriculum_support.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

void main() {
  group('Österreichischer Volksschulrahmen 1-4', () {
    const mandatory = <String>[
      'Religion',
      'Deutsch',
      'Sachunterricht',
      'Mathematik',
      'Musik',
      'Kunst und Gestaltung',
      'Technik und Design',
      'Bewegung und Sport',
      'Verkehrs- und Mobilitätsbildung',
    ];

    for (var grade = 1; grade <= 4; grade++) {
      test('$grade. Klasse: jeder gesetzliche Bereich hat einen Lumo-Liefermodus',
          () {
        final official = Curriculum.officialSubjectsForGrade(grade);
        expect(official, containsAll(mandatory));
        expect(
          official,
          contains(grade <= 2
              ? 'Lebende Fremdsprache (verbindliche Übung)'
              : 'Lebende Fremdsprache'),
        );

        final support = PrimaryCurriculumSupport.forGrade(grade);
        final names = support.map((e) => e.subject).toSet();
        expect(names, containsAll(mandatory));
        expect(
          names,
          contains(grade <= 2
              ? 'Lebende Fremdsprache (verbindliche Übung)'
              : 'Lebende Fremdsprache'),
        );
        expect(
          support.singleWhere((e) => e.subject == 'Religion').delivery,
          CurriculumDelivery.schoolManaged,
        );
      });

      test('$grade. Klasse: Kernfächer erzeugen echte Aufgaben', () {
        for (final subject in const <String>[
          'Mathematik',
          'Deutsch',
          'Sachunterricht',
          'Englisch',
        ]) {
          final units = Curriculum.unitsForGrade(
            subject,
            grade,
            currentGradeOnly: true,
          );
          expect(units, isNotEmpty,
              reason: '$subject braucht Stoff in Klasse $grade');
        }
      });

      test('$grade. Klasse: praktische Pflichtbereiche haben Aufgaben', () {
        for (final subject in const <String>[
          'Musik',
          'Kunst und Gestaltung',
          'Technik und Design',
          'Bewegung und Sport',
          'Verkehrs- und Mobilitätsbildung',
        ]) {
          final activities =
              PrimaryActivityCatalog.forGrade(grade, subject: subject);
          expect(activities.length, greaterThanOrEqualTo(2),
              reason: '$subject braucht mindestens zwei echte Aktivitäten');
        }

        expect(
          PrimaryActivityCatalog.forGrade(grade, subject: 'Deutsch'),
          isNotEmpty,
        );
        expect(
          PrimaryActivityCatalog.forGrade(grade, subject: 'Englisch').length,
          greaterThanOrEqualTo(2),
        );
        expect(
          PrimaryActivityCatalog.forGrade(grade, subject: 'Sachunterricht')
              .length,
          greaterThanOrEqualTo(2),
        );
      });
    }
  });

  test('Aktivitäts-IDs sind eindeutig', () {
    final ids = PrimaryActivityCatalog.all.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  group('Mathematik deckt die vier Kompetenzbereiche je Stufe ab', () {
    bool hasAny(List<String> units, List<String> needles) =>
        needles.any((n) => units.any((u) => u.contains(n)));

    final expectations = <int, Map<String, List<String>>>{
      1: {
        'Zahlen und Daten': ['Zahlenstrahl', 'Mengenvergleich', 'Zahl in Worten'],
        'Operationen': ['Plus bis 20', 'Minus bis 20'],
        'Größen': ['Geld', 'Zeit'],
        'Ebene und Raum': ['Geometrie Formen', 'Symmetrie', 'Formen Nachzeichnen'],
      },
      2: {
        'Zahlen und Daten': ['Zehner und Einer', 'Gerade und ungerade'],
        'Operationen': ['Plus bis 100', 'Minus bis 100', 'Einmaleins'],
        'Größen': ['Geld', 'Uhrzeit', 'Längen'],
        'Ebene und Raum': ['Formen Nachzeichnen'],
      },
      3: {
        'Zahlen und Daten': ['Plus bis 1000', 'Minus bis 1000'],
        'Operationen': ['Schriftliche Addition', 'Schriftliche Subtraktion', 'Division'],
        'Größen': ['Geld bis 100 Euro', 'Massen'],
        'Ebene und Raum': ['Umfang'],
      },
      4: {
        'Zahlen und Daten': ['Zahlenraum bis 1 Million', 'Diagramme', 'Bruch'],
        'Operationen': ['Schriftliche Multiplikation', 'Schriftliche Division'],
        'Größen': ['Zeit Minuten', 'Hohlmaße'],
        'Ebene und Raum': ['Flächeninhalt', 'Symmetrieachsen'],
      },
    };

    for (var grade = 1; grade <= 4; grade++) {
      test('$grade. Klasse: alle vier Mathebereiche erreichbar', () {
        final units = Curriculum.unitsForGrade(
          'Mathematik',
          grade,
          currentGradeOnly: true,
        );
        for (final entry in expectations[grade]!.entries) {
          expect(
            hasAny(units, entry.value),
            isTrue,
            reason:
                'Mathematik $grade: ${entry.key} fehlt. Units: $units',
          );
        }
      });
    }
  });
}
