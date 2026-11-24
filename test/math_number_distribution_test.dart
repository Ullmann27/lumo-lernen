import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/adventure/lumo_adventure_tasks.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

/// Befunde M2 und M32 der Fachprüfung Mathematik: Weil der zweite Summand
/// auf „Grenze − a“ und der Subtrahend auf den Minuenden gekürzt wurden,
/// häuften sich Lösungen an der Zahlenraumgrenze und bei 0 (Schriftliche
/// Addition: 40 % mit Lösung 1000, Minus bis 100: 18 % mit Lösung 0).
/// „Plus bis 10“ kannte nur die Summanden 1 bis 6.
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.singleWhere((item) => item.id == id);

  Map<String, int> answers(String id, {int count = 600}) {
    final seen = <String, int>{};
    for (var i = 0; i < count; i++) {
      final answer = byId(id).concretize(i * 7919 + 13).answer;
      seen[answer] = (seen[answer] ?? 0) + 1;
    }
    return seen;
  }

  test('M2: keine Häufung an der Zahlenraumgrenze oder bei 0', () {
    const limits = <String, (String, double)>{
      // Vorlage: (früher gehäufte Lösung, höchstens erlaubter Anteil)
      'g1_add_10': ('10', .20),
      'g2_add_20': ('20', .12),
      'g3_add_100': ('100', .06),
      'g3_written_add': ('1000', .03),
      // Bis 10 gibt es nur wenige Aufgaben; 7 − 7 = 0 gehört dazu.
      'g1_sub_10': ('0', .12),
      'g2_sub_20': ('0', .08),
      'g3_sub_100': ('0', .04),
      'g3_sub_1000': ('0', .02),
    };
    limits.forEach((id, limit) {
      final seen = answers(id);
      final share = (seen[limit.$1] ?? 0) / 600;
      expect(share, lessThanOrEqualTo(limit.$2),
          reason: '$id: Lösung ${limit.$1} in ${(share * 100).round()} %');
      // Keine einzelne Lösung beherrscht die Einheit.
      final top = seen.values.reduce(max) / 600;
      expect(top, lessThanOrEqualTo(.20), reason: '$id: $seen');
    });
  });

  test('M2: Ergebnisse bleiben trotzdem im Zahlenraum', () {
    const spaces = <String, int>{
      'g1_add_10': 10,
      'g1_add_20': 20,
      'g2_add_20': 20,
      'g2_add_100': 100,
      'g3_add_100': 100,
      'g3_add_1000': 1000,
      'g3_written_add': 1000,
      'g4_add_10000': 10000,
    };
    spaces.forEach((id, space) {
      for (var i = 0; i < 400; i++) {
        final task = byId(id).concretize(i * 97 + 5);
        final numbers = RegExp(r'\d+')
            .allMatches(task.prompt)
            .map((match) => int.parse(match.group(0)!))
            .toList();
        expect(numbers[0] + numbers[1], int.parse(task.answer),
            reason: task.prompt);
        expect(int.parse(task.answer), inInclusiveRange(0, space),
            reason: task.prompt);
      }
    });
    for (final id in [
      'g1_sub_10',
      'g1_sub_20',
      'g2_sub_20',
      'g2_sub_100',
      'g3_sub_100',
      'g3_sub_1000',
      'g4_sub_10000',
    ]) {
      for (var i = 0; i < 400; i++) {
        final task = byId(id).concretize(i * 97 + 5);
        final numbers = RegExp(r'\d+')
            .allMatches(task.prompt)
            .map((match) => int.parse(match.group(0)!))
            .toList();
        expect(numbers[0] - numbers[1], int.parse(task.answer),
            reason: task.prompt);
        expect(int.parse(task.answer), greaterThanOrEqualTo(0),
            reason: task.prompt);
        expect(numbers[1], greaterThanOrEqualTo(1), reason: task.prompt);
      }
    }
  });

  test('M32: Plus bis 10 kennt alle Aufgaben, auch mit 0 und großem Summanden',
      () {
    final prompts = <String>{};
    for (var i = 0; i < 4000; i++) {
      prompts.add(byId('g1_add_10').concretize(i * 31 + 7).prompt);
    }
    for (final wanted in [
      '7 + 2 = ?',
      '8 + 1 = ?',
      '9 + 1 = ?',
      '7 + 3 = ?',
      '0 + 5 = ?',
      '5 + 0 = ?',
      '10 + 0 = ?',
    ]) {
      expect(prompts, contains(wanted));
    }
    expect(prompts, isNot(contains('0 + 0 = ?')));
    // 66 Paare mit a + b ≤ 10, ohne 0 + 0.
    expect(prompts.length, 65);
  });

  test('M2: Marktstand Klasse 1 ergibt nicht meistens 10 €', () {
    final tasks = LumoAdventureTasks(Random(5));
    final totals = <String, int>{};
    for (var i = 0; i < 600; i++) {
      final task =
          tasks.generate(subject: 'Mathematik', unit: 'Marktstand', grade: 1);
      totals[task.answer] = (totals[task.answer] ?? 0) + 1;
      final prices = RegExp(r'(\d+) €')
          .allMatches(task.prompt)
          .map((match) => int.parse(match.group(1)!))
          .toList();
      expect('${prices[0] + prices[1]} €', task.answer, reason: task.prompt);
    }
    expect((totals['10 €'] ?? 0) / 600, lessThan(.20), reason: '$totals');
    expect(totals.length, 9);
  });
}
