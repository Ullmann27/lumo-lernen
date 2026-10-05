import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

/// AT-Lehrplan 2023 Volksschule: Zahlenraum 20 in Klasse 1, Zahlenraum 100 und
/// kleines Einmaleins in Klasse 2. Ergebnisse bleiben im jeweiligen Zahlenraum.
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.firstWhere((t) => t.id == id);

  test('Klasse 1 rechnet bis 20, Klasse 2 bis 100 und das Einmaleins', () {
    expect(MathTaskTemplates.supportsUnit(1, 'Plus bis 20'), isTrue);
    expect(MathTaskTemplates.supportsUnit(1, 'Minus bis 20'), isTrue);
    expect(MathTaskTemplates.supportsUnit(2, 'Plus bis 100'), isTrue);
    expect(MathTaskTemplates.supportsUnit(2, 'Minus bis 100'), isTrue);
    expect(MathTaskTemplates.supportsUnit(2, 'Einmaleins'), isTrue);
  });

  test('Ergebnisse bleiben im Zahlenraum der Klasse', () {
    const limits = {
      'g1_add_20': 20, 'g1_sub_20': 20, 'g2_add_100': 100, 'g2_sub_100': 100, 'g2_tables': 100,
    };
    limits.forEach((id, limit) {
      for (var seed = 1; seed <= 200; seed++) {
        final task = byId(id).concretize(seed * 31);
        final value = int.parse(task.answer);
        expect(value, inInclusiveRange(0, limit), reason: '$id: ${task.prompt}');
      }
    });
  });
}
