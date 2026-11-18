import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

/// Befunde M3, M9 und L1 der Fachprüfung Mathematik: Sachaufgaben ohne
/// Umlaute („Aepfel“, „bluehen“, „Hupfkaestchen“), immer derselbe Rechenweg
/// („a + b − 3“, „(a + b) · 2 − 4“) und falsche Mehrzahl bei 1 („1 Kekse“).
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.singleWhere((item) => item.id == id);
  List<int> numbers(String text) => RegExp(r'\d+')
      .allMatches(text)
      .map((match) => int.parse(match.group(0)!))
      .toList();

  const storyIds = [
    'g1_word_problem',
    'g2_word_problem',
    'g2_sub_story',
    'g3_two_step',
    'g4_three_step',
  ];

  test('M3: alle Sachaufgaben schreiben Umlaute und ß richtig', () {
    // ae/oe/ue als Ersatz für Umlaute; erlaubt sind echte Wörter wie
    // „neue“, „Feuer“, „Frauen“, „zuerst“, „Steuer“, „dauert“, „Bauer“.
    final replaced = RegExp(
        r'Aepfel|aepfel|Ae|Oe|Ue|aehl|uehl|ueck|uess|uer |uebr|ueche|uers|uest|oess|gross|Fuss|naechst|Maedchen|bluehen|pflueck|Stueck|Gemuese|Wuerst|kaest|raeum|zurueck|Fuer ');
    for (final id in storyIds) {
      for (var i = 0; i < 400; i++) {
        final task = byId(id).concretize(i * 7919 + 13);
        for (final text in [task.prompt, task.explanation]) {
          expect(replaced.hasMatch(text), isFalse, reason: '$id: $text');
        }
      }
    }
  });

  test('L1: keine Geschichte zählt „1“ Dinge in der Mehrzahl', () {
    for (final id in storyIds) {
      for (var i = 0; i < 400; i++) {
        final task = byId(id).concretize(i * 7919 + 13);
        expect(RegExp(r'(?<![\d,])1 [A-ZÄÖÜa-zäöü]').hasMatch(task.prompt), isFalse,
            reason: '$id: ${task.prompt}');
      }
    }
  });

  test('M9: zwei Schritte haben wechselnde Rechenwege und dritte Zahlen', () {
    final ways = <String>{};
    final thirds = <int>{};
    final prompts = <String>{};
    for (var i = 0; i < 600; i++) {
      final task = byId('g3_two_step').concretize(i * 7919 + 13);
      prompts.add(task.prompt);
      expect(int.parse(task.answer), greaterThan(0), reason: task.prompt);
      expect(task.explanation, startsWith('Zwei Schritte: '));
      expect(task.explanation, endsWith('= ${task.answer}.'),
          reason: task.explanation);
      // Rechenzeichen der beiden Schritte, z. B. „+−“ oder „·+“.
      ways.add(RegExp(r' ([+−·:]) ')
          .allMatches(task.explanation)
          .map((match) => match.group(1))
          .join());
      final given = numbers(task.prompt);
      thirds.add(given.last);
      expect(task.prompt, isNot(contains('Sauna')));
    }
    expect(ways.length, greaterThanOrEqualTo(5), reason: '$ways');
    // Früher wurden immer genau 3 weggenommen.
    expect(thirds.length, greaterThan(6), reason: '$thirds');
    expect(prompts.length, greaterThan(400));
  });

  test('M9: drei Schritte haben wechselnde Rechenwege', () {
    final ways = <String>{};
    for (var i = 0; i < 600; i++) {
      final task = byId('g4_three_step').concretize(i * 7919 + 13);
      expect(int.parse(task.answer), greaterThan(0), reason: task.prompt);
      expect(task.explanation, contains('Drei Schritte: '));
      expect(task.explanation, endsWith('= ${task.answer}.'),
          reason: task.explanation);
      ways.add(RegExp(r' ([+−·:]) ')
          .allMatches(task.explanation)
          .map((match) => match.group(1))
          .join());
    }
    expect(ways.length, greaterThanOrEqualTo(6), reason: '$ways');
  });

  test('Rechenwege in der Erklärung stimmen Schritt für Schritt', () {
    final step = RegExp(r'(\d+) ([+−·:]) (\d+) = (\d+)');
    for (final id in ['g3_two_step', 'g4_three_step']) {
      for (var i = 0; i < 600; i++) {
        final task = byId(id).concretize(i * 131 + 5);
        final steps = step.allMatches(task.explanation).toList();
        expect(steps.length, greaterThanOrEqualTo(2), reason: task.explanation);
        for (final match in steps) {
          final a = int.parse(match[1]!), b = int.parse(match[3]!);
          final result = switch (match[2]) {
            '+' => a + b,
            '−' => a - b,
            '·' => a * b,
            _ => a ~/ b,
          };
          expect(result, int.parse(match[4]!), reason: task.explanation);
          expect(result, greaterThanOrEqualTo(0), reason: task.explanation);
        }
        expect(steps.last[4], task.answer, reason: task.explanation);
      }
    }
  });
}
