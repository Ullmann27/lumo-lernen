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

  List<int> numbers(String text) => RegExp(r'\d+')
      .allMatches(text)
      .map((match) => int.parse(match.group(0)!))
      .toList();

  test('M34: Plus- und Minus-Erklärungen passen zum Zahlenraum und nennen das Ergebnis',
      () {
    for (final id in [
      'g1_add_10', 'g1_add_20', 'g2_add_20', 'g2_add_100', 'g3_add_100',
      'g3_add_1000', 'g4_add_10000', 'g3_written_add',
    ]) {
      for (var seed = 0; seed < 200; seed++) {
        final task = byId(id).concretize(seed * 97 + 5);
        final parts = numbers(task.prompt);
        expect(task.explanation,
            endsWith('${parts[0]} + ${parts[1]} = ${task.answer}.'),
            reason: '${task.prompt} → ${task.explanation}');
        if (parts[0] + parts[1] > 100) {
          expect(task.explanation, isNot(contains('Lege zuerst')));
          expect(task.explanation,
              anyOf(contains('Stelle'), contains('Einer unter Einer')));
        }
      }
    }
    for (final id in [
      'g1_sub_10', 'g1_sub_20', 'g2_sub_20', 'g2_sub_100', 'g3_sub_100',
      'g3_sub_1000', 'g4_sub_10000', 'g3_written_sub',
    ]) {
      for (var seed = 0; seed < 200; seed++) {
        final task = byId(id).concretize(seed * 97 + 5);
        final parts = numbers(task.prompt);
        expect(task.explanation,
            endsWith('${parts[0]} − ${parts[1]} = ${task.answer}.'),
            reason: '${task.prompt} → ${task.explanation}');
        // „gehe 263 Schritte zurück“ hilft bei großen Zahlen nicht.
        if (parts[0] > 20) {
          expect(task.explanation, isNot(contains('Schritte zurück')));
        }
        // L1: „gehe 1 Schritte zurück“.
        expect(task.explanation, isNot(contains(' 1 Schritte')));
      }
    }
  });

  test('M34: Zwischenschritte der Erklärungen sind richtig gerechnet', () {
    final step = RegExp(r'(\d+) ([+−]) (\d+) = (\d+)');
    for (final template in MathTaskTemplates.templates.where((item) =>
        item.kind == MathTemplateKind.addition ||
        item.kind == MathTemplateKind.subtraction)) {
      for (var seed = 0; seed < 300; seed++) {
        final task = template.concretize(seed * 131 + 7);
        for (final match in step.allMatches(task.explanation)) {
          final a = int.parse(match[1]!), b = int.parse(match[3]!);
          expect(match[2] == '+' ? a + b : a - b, int.parse(match[4]!),
              reason: '${task.prompt} → ${task.explanation}');
        }
      }
    }
  });

  test('L5: schriftliche Subtraktion erklärt das Ergänzen, nicht „tauschen“', () {
    final task = byId('g3_written_sub').concretize(7);
    expect(task.explanation, contains('Ergänze von der unteren zur oberen Ziffer'));
    expect(task.explanation, isNot(contains('tausche')));
  });

  test('M5: „Wie oft passt 5 in 50?“ statt „Wie oft 5 ist 50?“', () {
    for (var seed = 0; seed < 100; seed++) {
      final task = byId('g2_times_prep').concretize(seed * 13 + 1);
      expect(RegExp(r'^Wie oft passt \d+ in \d+\?$').hasMatch(task.prompt), isTrue,
          reason: task.prompt);
      final parts = numbers(task.prompt);
      expect(int.parse(task.answer) * parts[0], parts[1]);
    }
  });

  test('L14: gerade/ungerade hat zwei Karten und eine Erklärung je Fall', () {
    var even = 0, odd = 0;
    for (var seed = 0; seed < 200; seed++) {
      final task = byId('g2_even_odd').concretize(seed * 17 + 3);
      expect(task.choices, ['gerade', 'ungerade']);
      final number = numbers(task.prompt).single;
      if (number.isEven) {
        even++;
        expect(task.answer, 'gerade');
        expect(task.explanation, contains('nichts bleibt übrig'));
      } else {
        odd++;
        expect(task.answer, 'ungerade');
        expect(task.explanation, contains('bleibt eins übrig'));
        expect(task.explanation, endsWith('ist ungerade.'));
      }
      expect(task.explanation, contains('endet auf ${number % 10}'));
    }
    expect(even, greaterThan(50));
    expect(odd, greaterThan(50));
  });

  test('L15: Zahlwort-Erklärung zeigt den Aufbau des Wortes', () {
    final seen = <String, String>{};
    for (var seed = 0; seed < 600; seed++) {
      final task = byId('g1_number_word').concretize(seed * 29 + 11);
      seen[task.answer] = task.explanation;
      expect(task.explanation, isNot('Zahlwörter liest man wie normale Wörter.'));
      expect(task.explanation, contains('„${task.answer}“'));
      expect(task.choices, hasLength(4), reason: '${task.prompt} ${task.choices}');
    }
    expect(seen['vierzehn'], contains('zuerst die 4 und dann die 10'));
    expect(seen['sechzehn'], contains('„sech“'));
    expect(seen['zwanzig'], contains('zwei Zehner'));
  });

  test('L17: Mengenvergleich fragt nach Äpfeln und kennt „gleich viele“', () {
    final answers = <String>{};
    for (var seed = 0; seed < 300; seed++) {
      final task = byId('g1_quantity_compare').concretize(seed * 23 + 9);
      answers.add(task.answer);
      expect(task.prompt, endsWith('– wo sind mehr Äpfel?'));
      expect(task.choices, ['links', 'rechts', 'gleich viele']);
      expect(task.explanation, startsWith('Zähle beide Seiten: '));
      expect(task.explanation, isNot(contains('Länge der Zeile')));
      final left = '🍎'.allMatches(task.prompt.split(' oder ')[0]).length;
      final right = '🍎'.allMatches(task.prompt.split(' oder ')[1]).length;
      expect(task.answer,
          left == right ? 'gleich viele' : left > right ? 'links' : 'rechts');
    }
    expect(answers, {'links', 'rechts', 'gleich viele'});
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
