import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/teacher_mode/lumo_akademie_screen.dart';
import 'package:lumo_lernen/features/teacher_mode/topic_curriculum.dart';

void main() {
  test('Klasse 1 bis 4 haben gefuellte Kernfaecher und eindeutige Themen', () {
    expect(LumoCurriculum.grades.map((g) => g.grade), [1, 2, 3, 4]);

    final ids = <String>{};
    for (final grade in LumoCurriculum.grades) {
      final names = grade.subjects.map((s) => s.name).toSet();
      expect(names, containsAll(<String>{
        'Mathematik',
        'Deutsch',
        'Sachkunde',
      }), reason: '${grade.grade}. Klasse');

      for (final subject in grade.subjects) {
        expect(subject.topics, isNotEmpty,
            reason: '${grade.grade}. Klasse / ${subject.name}');
        for (final topic in subject.topics) {
          expect(topic.id.trim(), isNotEmpty);
          expect(topic.title.trim(), isNotEmpty);
          expect(topic.shortDesc.trim(), isNotEmpty);
          expect(ids.add(topic.id), isTrue,
              reason: 'Doppelte Topic-ID: ${topic.id}');
        }
      }
    }
  });

  test('Sachkunde Klasse 2 besteht aus drei echten Lernmodulen', () {
    final grade2 = LumoCurriculum.grades.singleWhere((g) => g.grade == 2);
    final sachkunde =
        grade2.subjects.singleWhere((s) => s.name == 'Sachkunde');

    expect(
      sachkunde.topics.map((t) => t.id).toSet(),
      <String>{'s2_jahreszeiten', 's2_wetter', 's2_verkehr'},
    );
    for (final topic in sachkunde.topics) {
      expect(LearningModuleRegistry.hasModule(topic.id), isTrue,
          reason: topic.id);
    }
  });

  test('jedes Lehrplanthema hat Modul, Spezialroute oder Themenkontext', () {
    const specialRoutes = <String>{
      'd1_schreibcoach',
      'd1_buchstaben_alle',
      'd1_woerter',
      'd1_geschichten',
      'd2_geschichten',
      'd3_geschichten',
      'd4_geschichten',
    };

    for (final grade in LumoCurriculum.grades) {
      for (final subject in grade.subjects) {
        for (final topic in subject.topics) {
          final routed = LearningModuleRegistry.hasModule(topic.id) ||
              specialRoutes.contains(topic.id) ||
              TopicCurriculum.of(topic.id) != null;
          expect(routed, isTrue,
              reason:
                  'Keine Lernroute fuer ${grade.grade}. Klasse / ${subject.name} / ${topic.id}');
        }
      }
    }
  });
}
