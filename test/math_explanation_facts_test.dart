import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

/// Sachlich falsche oder irreführende Erklärtexte aus der Fachprüfung
/// Mathematik (17.11.2026). Jeder Test nennt den Befund, den er verhindert.
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.singleWhere((item) => item.id == id);

  test('S9: Ein Rechteck hat vier Seiten, nicht „2 verschieden lange“', () {
    final task = byId('g2_trace_rectangle').concretize(1);
    expect(task.answer, 'Rechteck');
    expect(task.explanation, contains('4 Ecken und 4 Seiten'));
    expect(task.explanation, contains('Gegenüberliegende Seiten sind gleich lang'));
    expect(task.explanation, isNot(contains('2 verschieden lange Seiten')));
  });

  test('S11: Zahlenvergleich zählt zuerst die Stellen', () {
    // „Vergleiche von links nach rechts“ führt bei 9 ? 45 zum falschen
    // Zeichen: Wer 9 mit 4 vergleicht, wählt „>“.
    for (final id in ['g4_compare', 'g4_compare_1mio']) {
      for (var seed = 0; seed < 50; seed++) {
        final task = byId(id).concretize(seed * 41 + 3);
        expect(task.explanation, isNot('Vergleiche von links nach rechts.'));
        expect(task.explanation, contains('Zähle zuerst die Stellen'));
        expect(task.explanation, contains('mehr Stellen ist größer'));
      }
    }
  });
}
