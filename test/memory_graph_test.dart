import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/services/memory_graph.dart';

void main() {
  group('MemoryGraph', () {
    test('has initial skills', () {
      final mg = MemoryGraph();
      expect(mg.skills, isNotEmpty);
    });

    test('updateSkill increases skill value', () {
      final mg = MemoryGraph();
      final before = mg.skills['Addition']!;
      mg.updateSkill('Addition', 0.1);
      expect(mg.skills['Addition'], greaterThan(before));
    });

    test('skill value clamped to 1.0', () {
      final mg = MemoryGraph();
      mg.updateSkill('Addition', 100.0);
      expect(mg.skills['Addition'], equals(1.0));
    });

    test('skill value clamped to 0.0', () {
      final mg = MemoryGraph();
      mg.updateSkill('Addition', -100.0);
      expect(mg.skills['Addition'], equals(0.0));
    });

    test('weakSkills returns skills below 0.5', () {
      final mg = MemoryGraph();
      final weak = mg.weakSkills;
      for (final skill in weak) {
        expect(mg.skills[skill]!, lessThan(0.5));
      }
    });

    test('addSkill adds new skill', () {
      final mg = MemoryGraph();
      mg.addSkill('Geometrie');
      expect(mg.skills.containsKey('Geometrie'), isTrue);
    });
  });
}
