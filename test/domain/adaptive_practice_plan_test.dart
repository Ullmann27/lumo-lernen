import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/school/adaptive_practice_plan.dart';
import 'package:lumo_lernen/domain/school/attempt.dart';

final now = DateTime(2026, 11, 25, 12);

Attempt answer(int n, {String owner = 'a', String subject = 'Mathematik',
    String unit = 'Minus bis 20', String comp = 'Subtraktion mit Zehnerübergang',
    bool correct = true, bool hint = false, int daysAgo = 1}) => Attempt(
  id: '$n', studentId: owner, subject: subject, unit: unit,
  competency: comp, correct: correct, hintUsed: hint,
  at: now.subtract(Duration(days: daysAgo, minutes: n)),
);

AdaptivePracticePlan plan(List<Attempt> answers) =>
    AdaptivePracticePlan.fromAttempts(answers, studentId: 'a', now: now);

void main() {
  test('Keine Daten oder nur Hilfen ergeben keine Kompetenzbehauptung', () {
    expect(plan([]).steps, isEmpty);
    expect(plan([for (var i = 0; i < 12; i++) answer(i, hint: true)]).steps,
        isEmpty);
  });

  test('Eigener Fortschritt bleibt getrennt, Hilfen erhöhen die Quote nicht', () {
    final p = plan([
      for (var i = 0; i < 5; i++) answer(i, correct: i < 2),
      for (var i = 5; i < 15; i++) answer(i, hint: true),
      for (var i = 15; i < 25; i++) answer(i, owner: 'b'),
    ]).steps.single;
    expect(p.focus, PracticeFocus.guidedPractice);
    expect(p.independentAttempts, 5);
    expect(p.independentCorrect, 2);
    expect(p.guidedAttempts, 10);
    expect(p.method, contains('Zehnerfeldern'));
  });

  test('Gleiche Kompetenz in zwei Fächern bleibt getrennt', () {
    final p = plan([
      for (var i = 0; i < 5; i++) answer(i, comp: 'Muster', correct: false),
      for (var i = 5; i < 10; i++)
        answer(i, subject: 'Logik', comp: 'Muster', daysAgo: i.isEven ? 1 : 2),
    ]);
    expect(p.steps.map((x) => x.subject), ['Mathematik', 'Logik']);
    expect(p.steps.first.focus, PracticeFocus.guidedPractice);
    expect(p.steps.last.focus, PracticeFocus.extend);
  });

  test('Mehrere Übungstage vor Steigerung, danach Wiederholung bei Abstand', () {
    expect(plan([for (var i = 0; i < 5; i++) answer(i)]).steps.single.focus,
        PracticeFocus.consolidate);
    expect(plan([
      for (var i = 0; i < 5; i++) answer(i, daysAgo: i.isEven ? 7 : 8),
    ]).steps.single.focus, PracticeFocus.review);
    expect(plan([
      for (var i = 0; i < 5; i++) answer(i, daysAgo: i.isEven ? 1 : 2),
    ]).steps.single.focus, PracticeFocus.extend);
  });

  test('Duplikate, Fremdprofile, Tests und Zukunftszeiten zählen nicht', () {
    final a = answer(0);
    expect(plan([
      a, a, a, a, a,
      for (var i = 1; i < 7; i++) answer(i, owner: 'b'),
      for (var i = 7; i < 13; i++) answer(i, subject: 'IQ-Rätsel'),
      for (var i = 13; i < 19; i++) answer(i, daysAgo: -1),
    ]).steps, isEmpty);
  });

  test('Höchstens drei Ziele, kein Widerspruch im gleichen Thema', () {
    final answers = [
      for (var i = 0; i < 5; i++) answer(i, correct: false),
      for (var i = 5; i < 10; i++)
        answer(i, comp: 'Subtraktion ohne Zehnerübergang',
            daysAgo: i.isEven ? 1 : 2),
      for (var j = 0; j < 4; j++)
        for (var i = 0; i < 5; i++)
          answer(20 + j * 10 + i, unit: 'Thema $j', correct: false),
    ];
    final p = plan(answers);
    expect(p.steps.length, 3);
    expect(p.steps.map((x) => (x.subject, x.unit)).toSet().length, 3);
    expect(p.steps.every((x) => x.focus == PracticeFocus.guidedPractice), isTrue);
  });
}
