import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math/lumo_rechentricks.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

/// Befunde S5 und L10 der Fachprüfung Mathematik (17.11.2026): Der dritte
/// Tipp zeigte bei Brüchen und Kommazahlen falsche Rechnungen
/// („1/9 + 3/9 = ?“ → „Also: 9 + 3 = 49“, „8,4 + 6,7 = ?“ → „6 + 4 = 151“).
/// Jeder gezeigte Rechenschritt muss stimmen, und ein Trick erscheint nur
/// bei reinen Rechnungen mit ganzen Zahlen.
void main() {
  const tricks = LumoRechentricks();
  final equation =
      RegExp(r'^(?:[A-Za-zäöüÄÖÜ ]+: )?(\d+) ([+\-×:]) (\d+) = (\d+)');

  /// Prüft jede Zeile der Form „a op b = c“, die im Trick vorkommt.
  void expectStepsTrue(RechentricksExplanation shown, String reason) {
    for (final line in [...shown.steps, shown.resultText]) {
      final m = equation.firstMatch(line);
      if (m == null) continue;
      final a = int.parse(m[1]!), b = int.parse(m[3]!), c = int.parse(m[4]!);
      final value = switch (m[2]) {
        '+' => a + b,
        '-' => a - b,
        '×' => a * b,
        _ => b == 0 ? -1 : (a % b == 0 ? a ~/ b : -1),
      };
      expect(value, c, reason: '$reason: „$line“');
    }
  }

  test('keine Tricks bei Brüchen, Kommazahlen und Sätzen mit Zahlen', () {
    for (final (prompt, answer) in const [
      ('1/9 + 3/9 = ?', '4/9'),
      ('2/7 + 4/7 = ?', '6/7'),
      ('8,4 + 6,7 = ?', '15,1'),
      ('9,1 + 9,3 = ?', '18,4'),
      ('Welches Zeichen gehört in die Lücke? 4 + 5 ⬜ 9', '='),
      ('Rechne im Kopf: (3 + 4) × 2 = ?', '14'),
      ('124 : 4 = ?', '31'),
    ]) {
      expect(tricks.explain(prompt: prompt, correctAnswer: answer, grade: 4),
          isNull,
          reason: prompt);
    }
  });

  test('kein Trick, wenn die Rechnung nicht die Lösung ergibt', () {
    expect(tricks.explain(prompt: '8 + 7 = ?', correctAnswer: '16', grade: 1),
        isNull);
  });

  test('Einmaleins-Tricks nur im kleinen Einmaleins', () {
    expect(
        tricks.explain(
            prompt: 'Schriftlich: 436 × 3 = ?',
            correctAnswer: '1308',
            grade: 4),
        isNull);
    expect(tricks.explain(prompt: '4 × 8 = ?', correctAnswer: '32', grade: 3),
        isNotNull);
  });

  test('Vereinfachen nur nahe am vollen Hunderter, keine Schritte mit 0', () {
    final far =
        tricks.explain(prompt: '387 + 337 = ?', correctAnswer: '724', grade: 3);
    expect(far?.mentor.kind, isNot(RechentricksKind.simplify));
    final near = tricks.explain(
        prompt: '387 + 298 = ?', correctAnswer: '685', grade: 3)!;
    expect(near.mentor.kind, RechentricksKind.simplify);
    expect(near.steps.last, '385 + 300 = 685');
    final minus = tricks.explain(
        prompt: '445 - 300 = ?', correctAnswer: '145', grade: 3)!;
    for (final step in minus.steps) {
      expect(step, isNot(contains('- 0 =')), reason: step);
    }
  });

  test('alle Vorlagen: jeder gezeigte Rechenschritt stimmt', () {
    var shownCount = 0;
    for (final template in MathTaskTemplates.templates) {
      for (var i = 0; i < 120; i++) {
        final task = template.concretize(i * 7919 + 13);
        for (var grade = 1; grade <= 4; grade++) {
          final shown = tricks.explain(
              prompt: task.prompt, correctAnswer: task.answer, grade: grade);
          if (shown == null) continue;
          shownCount++;
          final reason = '${template.id}: ${task.prompt} = ${task.answer}';
          expect(RegExp(r'^\d+$').hasMatch(task.answer), isTrue,
              reason: '$reason: Trick nur bei ganzzahliger Lösung');
          expect(task.prompt, isNot(contains('/')), reason: reason);
          expect(task.prompt, isNot(contains(',')), reason: reason);
          expectStepsTrue(shown, reason);
          // Der Trick nennt am Ende genau die Lösung.
          expect(shown.resultText, contains(task.answer), reason: reason);
        }
      }
    }
    expect(shownCount, greaterThan(500));
  });
}
