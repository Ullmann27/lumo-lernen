import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';

void main() {
  const routedUnits = <String, String>{
    'm3_zahlen1000': 'Plus bis 1000',
    'm3_geometrie': 'Umfang',
    'm4_million': 'Zahlenraum bis 1 Million',
    'm4_textaufgaben': 'Sachaufgaben drei Schritte',
    'd4_grammatik': 'Die 4 Fälle',
    's3_oesterreich': 'Bundesländer Österreichs',
    's3_natur': 'Pflanzen',
    's4_europa': 'Kontinente und Ozeane',
  };
  const separatelyImplemented = <String>{
    'd3_geschichten',
    'd4_aufsatz',
  };

  for (final grade in [3, 4]) {
    test('class $grade shows substantial distinct curricular topics', () {
      final current = LumoCurriculum.grades.singleWhere((g) => g.grade == grade);
      for (final subject in current.subjects) {
        expect(subject.topics.length, greaterThanOrEqualTo(5),
            reason: '$grade / ${subject.name} must not be an unfinished menu');
        final ids = subject.topics.map((t) => t.id).toList();
        expect(ids.toSet().length, ids.length);
        final titles = subject.topics.map((t) => t.title).toList();
        expect(titles.toSet().length, titles.length);

        for (final topic in subject.topics) {
          if (LearningModuleRegistry.hasModule(topic.id) ||
              separatelyImplemented.contains(topic.id)) {
            continue;
          }
          final unit = routedUnits[topic.id] ?? topic.title;
          expect(Curriculum.unitsForGrade(subject.name, grade), contains(unit),
              reason: 'Menu card ${topic.id} must resolve to a real '
                  '$grade-grade exercise rather than a generic chat');
        }
      }
    });
  }
}
