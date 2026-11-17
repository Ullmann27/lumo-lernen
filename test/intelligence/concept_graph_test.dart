import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/domain/learning_intelligence/concept_graph.dart';

void main() {
  test(
      'every reference concept has at least one reachable real curriculum task',
      () {
    final graph = LumoConceptGraph.reference();
    final bindings = [
      for (var grade = 1; grade <= 4; grade++) ...graph.bindingsForGrade(grade)
    ];
    for (final node in graph.nodes) {
      expect(bindings.any((binding) => binding.conceptId == node.id), isTrue,
          reason: '${node.id} must link to an actual task, not a legacy alias');
    }
  });
  test('reference graph has a real counting to addition prerequisite chain',
      () {
    final graph = LumoConceptGraph.reference();
    expect(
        graph.prerequisitesOf('math.multi_digit_addition'),
        containsAll([
          'math.counting',
          'math.bundling',
          'math.tens_ones',
          'math.place_value',
          'math.cross_ten'
        ]));
    expect(graph.forTask('Mathematik', 'Zehner und Einer').map((n) => n.id),
        contains('math.tens_ones'));
    for (var grade = 1; grade <= 4; grade++) {
      for (final binding in graph.bindingsForGrade(grade)) {
        expect(
            Curriculum.unitsForGrade(binding.subject, grade)
                .contains(binding.unit),
            isTrue);
      }
    }
    expect(graph.forTask('Unbekannt', 'Erfundene Kompetenz'), isEmpty);
    expect(
        graph.nodes.map((n) => n.subject).toSet(),
        containsAll([
          'Mathematik',
          'Deutsch',
          'Lesen',
          'Rechtschreibung',
          'Sachunterricht'
        ]));
  });
  test('cycles and undefined prerequisites fail at construction', () {
    expect(
        () => LumoConceptGraph([
              const LumoConcept(
                  id: 'a',
                  subject: 'Mathematik',
                  units: ['Plus bis 10'],
                  prerequisites: ['b']),
              const LumoConcept(
                  id: 'b',
                  subject: 'Mathematik',
                  units: ['Minus bis 10'],
                  prerequisites: ['a']),
            ]),
        throwsArgumentError);
    expect(
        () => LumoConceptGraph([
              const LumoConcept(
                  id: 'a',
                  subject: 'Mathematik',
                  units: [],
                  prerequisites: ['absent']),
            ]),
        throwsArgumentError);
  });
}
