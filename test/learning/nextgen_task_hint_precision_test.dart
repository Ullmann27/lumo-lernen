import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';

LumoTask _task(
  String prompt, {
  String unit = 'Üben',
  String visual = 'auto',
}) =>
    LumoTask(
      id: 'visible-givens-only',
      grade: 4,
      subject: 'Mathematik',
      unit: unit,
      prompt: prompt,
      answer: 'Do not use the stored answer in a hint.',
      choices: const [],
      explanation: 'Do not reuse the worked solution as the first hint.',
      visual: visual,
    );

void main() {
  const hints = TaskHintService();

  test('mixed decimal and integer operands retain their actual place value',
      () {
    final value = _task('1,5 + 2 = ?', unit: 'Dezimalzahlen');
    final first = hints.explain(value);
    final second = hints.explain(value, level: 2);
    final third = hints.explain(value, level: 3);
    expect(first, contains('Zehntel'));
    expect(second, contains('1,5 und 2,0'));
    expect(third, contains('15 + 20 in Zehntel'));
    expect(third, isNot(contains('3,5')));
    for (final hint in [first, second, third]) {
      expect(hint, isNot(contains('Starte bei 5')));
      expect(hint, isNot(contains('Zähle 2 weiter')));
      expect(hint, isNot(contains(value.answer)));
    }
    expect({first, second, third}, hasLength(3));
  });

  test('decimal precision and subtraction survive prefixes and punctuation',
      () {
    final mixed = hints.explain(
      _task('Schriftlich: 1,25 + 2,5 = ?'),
      level: 2,
    );
    expect(mixed, contains('1,25 und 2,50'));
    expect(
      hints.explain(_task('Rechne 1.25 + 2.5.'), level: 3),
      contains('125 + 250 in Hundertstel'),
    );
    final subtraction = hints.explain(
      _task('1,2 − 2,3 = ?'),
      level: 3,
    );
    expect(subtraction, contains('12 − 23 in Zehntel'));
    expect(subtraction, isNot(contains('−1,1')));
  });

  test('embedded or fractional formulas never become whole-number groups', () {
    for (final prompt in [
      'Vergleiche 1,5 + 2 = ? mit einer anderen Rechnung.',
      '1/4 + 3/4 = ?',
      '0,5 + ? = 2,5',
      'Vergleiche 5 + ? = 12 mit der nächsten Zeile.',
    ]) {
      for (var level = 1; level <= 3; level++) {
        final hint = hints.explain(_task(prompt), level: level);
        expect(hint, isNot(contains('Starte bei 5')), reason: prompt);
        expect(hint, isNot(contains('Starte bei 4')), reason: prompt);
        expect(hint, isNot(contains('Hier fehlt eine Zahl')), reason: prompt);
      }
    }
  });

  test('fraction addition counts like-sized parts and leaves the result open',
      () {
    final value = _task(
      '1/4 + 2/4 = ?',
      unit: 'Bruchrechnen einfach',
      visual: 'fraction_add',
    );
    expect(hints.explain(value), contains('denselben Nenner'));
    expect(hints.explain(value, level: 2), contains('1 Teil hin. Lege dann 2'));
    expect(hints.explain(value, level: 3), contains('1 + 2'));
    for (var level = 1; level <= 3; level++) {
      final hint = hints.explain(value, level: level);
      expect(hint, isNot(contains('Hälfte')));
      expect(hint, isNot(contains('3/4')));
    }
  });

  test('unlike denominators are converted before the numerators are added', () {
    final value = _task('1/3 + 1/4 = ?', unit: 'Bruchrechnen einfach');
    expect(hints.explain(value), contains('Nenner sind verschieden'));
    expect(hints.explain(value, level: 2), contains('ersten Bruch mit 4'));
    expect(hints.explain(value, level: 2), contains('zweiten mit 3'));
    expect(hints.explain(value, level: 3), contains('3 · 4'));
    expect(hints.explain(value, level: 3), isNot(contains('7/12')));
  });

  test('fraction expansion uses the requested factor for both numbers', () {
    final value = _task(
      'Erweitere den Bruch 1/2 mit 3. Wie heißt der neue Bruch?',
      unit: 'Brüche erweitern',
      visual: 'fraction_expand',
    );
    expect(hints.explain(value), contains('Zähler UND Nenner'));
    expect(hints.explain(value, level: 2), contains('oben 1 · 3'));
    expect(hints.explain(value, level: 2), contains('unten 2 · 3'));
    expect(hints.explain(value, level: 3), contains('nochmals in 3 gleiche'));
    for (var level = 1; level <= 3; level++) {
      expect(hints.explain(value, level: level), isNot(contains('3/6')));
      expect(hints.explain(value, level: level), isNot(contains('Hälfte')));
    }
  });

  test('only a visible half question receives the half instruction', () {
    final general = _task('Zeige 5/4.', unit: 'Brüche', visual: 'fraction');
    expect(hints.explain(general), contains('Nenner'));
    expect(hints.explain(general, level: 2), contains('mehrere Ganze'));
    expect(hints.explain(general), isNot(contains('Hälfte')));
    final half = _task(
      'Was ist die Hälfte von 18?',
      unit: 'Brüche Vorbereitung',
      visual: 'fraction_half',
    );
    expect(hints.explain(half), contains('zwei gleich große Gruppen'));
    expect(hints.explain(half, level: 2), contains('18 Dinge'));
    expect(hints.explain(half, level: 3), contains('insgesamt 18'));
    expect(hints.explain(half, level: 3), isNot(contains('9')));
  });

  test('a written-operation label is never mistaken for division', () {
    final addition = _task(
      'Schriftlich: 245 + 87 = ?',
      unit: 'Schriftliche Addition',
    );
    expect(hints.explain(addition), contains('lege die zweite dazu'));
    expect(hints.explain(addition), isNot(contains('Verteile')));
    final subtraction = _task(
      'Schriftlich: 245 - 87 = ?',
      unit: 'Schriftliche Subtraktion',
    );
    expect(hints.explain(subtraction), contains('nimm die zweite Menge weg'));
    final division = _task('12 : 3 = ?');
    expect(hints.explain(division), startsWith('Verteile'));
    expect(hints.explain(division, level: 2), contains('12 Dinge auf 3'));
  });

  test('all active fractional families receive three task-specific stages', () {
    for (final unit in [
      'Brüche Vorbereitung',
      'Bruchrechnen einfach',
      'Brüche erweitern',
      'Dezimalzahlen',
    ]) {
      for (var seed = 0; seed < 32; seed++) {
        final value = ExerciseFactory(seed: seed).nextExact(
          grade: 4,
          subject: 'Mathematik',
          unit: unit,
        );
        final stages = [
          for (var level = 1; level <= 3; level++)
            hints.explain(value, level: level),
        ];
        expect(stages.toSet(), hasLength(3), reason: value.prompt);
        for (final stage in stages) {
          expect(stage, isNot(value.explanation), reason: value.prompt);
          expect(stage, isNot(startsWith('Starte bei')), reason: value.prompt);
          if (unit == 'Dezimalzahlen') {
            expect(
                stage, anyOf(contains('Komma'), contains('Nachkommastellen')));
          } else if (unit != 'Brüche Vorbereitung') {
            expect(stage, isNot(contains('Hälfte')), reason: value.prompt);
          }
        }
      }
    }
  });
}
