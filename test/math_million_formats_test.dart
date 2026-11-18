import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Befund M7 der Fachprüfung Mathematik (17.11.2026): „Zahlenraum bis
/// 1 Million“ bestand nur aus Vergleichen. Jetzt auch Stellenwert und
/// Runden auf Tausender, jeweils nachgerechnet.
void main() {
  test('Zahlenraum bis 1 Million: drei Aufgabenarten, alle geprüft', () {
    const guard = TaskQualityGuard();
    const hints = TaskHintService();
    final template = MathTaskTemplates.templates
        .singleWhere((t) => t.id == 'g4_compare_1mio');
    var compare = 0, place = 0, round = 0;
    for (var i = 0; i < 300; i++) {
      final concrete = template.concretize(i * 7919 + 13);
      final task = LumoTask(
          id: 'x',
          grade: 4,
          subject: 'Mathematik',
          unit: concrete.unit,
          prompt: concrete.prompt,
          choices: concrete.choices,
          answer: concrete.answer,
          explanation: concrete.explanation,
          difficulty: 4);
      expect(guard.problems(task), isEmpty,
          reason: '${task.prompt} → ${task.answer} ${task.choices}');
      expect(task.choices.toSet(), hasLength(task.choices.length));
      expect(task.choices.length, greaterThanOrEqualTo(3), reason: task.prompt);
      if (task.prompt.startsWith('Welches Zeichen')) {
        compare++;
      } else if (task.prompt.startsWith('Welchen Wert')) {
        place++;
        expect(hints.explain(task), contains('Stellenwerttafel'));
      } else {
        round++;
        expect(task.prompt, startsWith('Runde '));
        expect(hints.explain(task, level: 2), contains('Hunderterziffer'));
      }
      // Die Lösung steht nicht in der Frage.
      expect(task.prompt.contains(' ${task.answer}?'), isFalse);
    }
    expect(compare, greaterThan(100));
    expect(place, greaterThan(40));
    expect(round, greaterThan(40));
  });

  test('Prüfung lehnt falsche Stellenwerte und Rundungen ab', () {
    const guard = TaskQualityGuard();
    LumoTask t(String prompt, String answer) => LumoTask(
        id: 'x',
        grade: 4,
        subject: 'Mathematik',
        unit: 'Zahlenraum bis 1 Million',
        prompt: prompt,
        choices: <String>[answer, '1', '2', '3'],
        answer: answer,
        explanation: '-',
        difficulty: 4);
    expect(guard.problems(t('Welchen Wert hat die Ziffer 7 in 375 412?', '70 000')), isEmpty);
    expect(guard.problems(t('Welchen Wert hat die Ziffer 7 in 375 412?', '7000')), isNotEmpty);
    expect(guard.problems(t('Runde 375 512 auf Tausender.', '376 000')), isEmpty);
    expect(guard.problems(t('Runde 375 412 auf Tausender.', '376 000')), isNotEmpty);
  });
}
