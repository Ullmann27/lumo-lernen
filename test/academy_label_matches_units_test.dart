import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/curriculum/academy_topic_units.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

/// Heinz (24.11.2026): Jede Akademie-Kachel übt genau das, was ihr Titel
/// verspricht. „Grammatik“ darf nicht nur die 4 Fälle üben, „Natur“ nicht
/// nur Pflanzen. Abweichende Titel stehen hier geprüft mit Begründung.
const Map<String, String> _reviewedSynonyms = <String, String>{
  // Kachel-ID: geübte Einheit — gleicher Inhalt, kindgerechter Titel.
  'm1_formen': 'Geometrie Formen',
  'm1_zahlen10': 'Mengenvergleich', // nur Klassenwechsel; eigenes Modul sonst
  'd1_buchstaben_alle': 'Buchstaben-Lautierung',
  'd1_woerter': 'Wort-Bild-Zuordnung',
  'en1_3': 'Begruessung',
  's1_koerper': 'Körper',
  'm2_einmaleins': 'Einmaleins Vorbereitung',
  'm2_uhr': 'Uhrzeit',
  'm2_geld': 'Geld wechseln',
  'd2_saetze': 'Erste Sätze',
  'd2_artikel': 'Artikel',
  'd2_mehrzahl': 'Einzahl und Mehrzahl',
  'm3_einmaleins_voll': 'Einmaleins',
  's3_oesterreich': 'Bundesländer Österreichs',
  'm4_million': 'Zahlenraum bis 1 Million',
  'm4_bruch': 'Bruchrechnen einfach',
  'm4_textaufgaben': 'Sachaufgaben drei Schritte',
};

/// Sammeltitel, die nie auf eine einzelne Teileinheit zeigen dürfen.
const Set<String> _umbrellaTitles = <String>{
  'Grammatik', 'Natur', 'Geometrie', 'Rechnen', 'Deutsch', 'Mathematik',
  'Sachunterricht', 'Österreich',
};

String _norm(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-zäöüß0-9]'), '');

void main() {
  test('jede Akademie-Kachel übt genau ihren Titel', () {
    var checked = 0;
    final problems = <String>[];
    for (final grade in LumoCurriculum.grades) {
      for (final subject in grade.subjects) {
        for (final topic in subject.topics) {
          final unit = AcademyTopicUnits.exerciseUnit(
            topicId: topic.id,
            title: topic.title,
            subject: subject.name,
            grade: grade.grade,
          );
          final scope = '${grade.grade}. Klasse/${subject.name}/${topic.id} „${topic.title}“';
          if (_umbrellaTitles.contains(topic.title.trim())) {
            problems.add('$scope: Sammeltitel');
          }
          if (unit == null) continue;
          checked++;
          final sameName = _norm(topic.title) == _norm(unit) ||
              _norm(topic.title) == _norm(Curriculum.prettifyUnit(unit));
          if (!sameName && _reviewedSynonyms[topic.id] != unit) {
            problems.add('$scope übt „$unit“');
          }
        }
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
    expect(checked, greaterThanOrEqualTo(40));
  });

  test('Schreibcoach wird nie als Lautierungs-Quiz aufgelöst', () {
    expect(
      AcademyTopicUnits.exerciseUnit(
          topicId: 'd1_schreibcoach', title: '✨ Schreibcoach LIVE', subject: 'Deutsch', grade: 1),
      isNull,
    );
  });

  test('Natur-Bereich der 3. Klasse übt Pflanzen und Tiere getrennt', () {
    final g3 = LumoCurriculum.grades.singleWhere((g) => g.grade == 3);
    final su = g3.subjects.singleWhere((s) => s.name == 'Sachunterricht');
    final units = {
      for (final t in su.topics)
        AcademyTopicUnits.exerciseUnit(topicId: t.id, title: t.title, subject: su.name, grade: 3)
    };
    expect(units, containsAll(<String>['Pflanzen', 'Tiere']));
  });
}
