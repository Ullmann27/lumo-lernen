import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

/// Befunde M15 und M2 (Division) der Fachprüfung Mathematik: Die schriftliche
/// Multiplikation hatte in 27 % der Aufgaben den Faktor 10, 11 oder 12, zu
/// dem die Erklärung nicht passte. Die schriftliche Division hatte nie einen
/// Rest, kein „Schriftlich:“ und in 18 % der Aufgaben die Lösung 99.
void main() {
  MathTaskTemplate byId(String id) =>
      MathTaskTemplates.templates.singleWhere((item) => item.id == id);
  List<int> numbers(String text) => RegExp(r'\d+')
      .allMatches(text)
      .map((match) => int.parse(match.group(0)!))
      .toList();

  test('schriftliche Multiplikation: einstelliger Faktor, Rechenweg mit Ergebnis',
      () {
    final factors = <int>{};
    for (var i = 0; i < 400; i++) {
      final task = byId('g4_written_mul').concretize(i * 7919 + 13);
      final parts = numbers(task.prompt);
      final a = parts[0], b = parts[1];
      factors.add(b);
      expect(b, inInclusiveRange(2, 9), reason: task.prompt);
      expect(task.answer, '${a * b}');
      expect(task.explanation, startsWith('Beginne bei den Einern: '));
      expect(task.explanation, endsWith('Ergebnis: $a · $b = ${a * b}.'));
      expect(task.explanation, isNot(contains('Multipliziere jede Stelle')));
      // Ein Schritt je Stelle.
      expect(RegExp(r'schreibe').allMatches(task.explanation).length,
          '$a'.length,
          reason: task.explanation);
    }
    expect(factors, {2, 3, 4, 5, 6, 7, 8, 9});
  });

  test('Rechenweg der Multiplikation stimmt Stelle für Stelle', () {
    // 435 · 8: 5·8=40 (0, merke 4), 3·8=24+4=28 (8, merke 2), 4·8=32+2=34.
    for (var seed = 0; seed < 200000; seed++) {
      final task = byId('g4_written_mul').concretize(seed);
      if (task.prompt != 'Schriftlich: 435 × 8 = ?') continue;
      expect(
          task.explanation,
          'Beginne bei den Einern: 5 · 8 = 40, schreibe 0, merke 4. '
          '3 · 8 = 24, plus 4 = 28, schreibe 8, merke 2. '
          '4 · 8 = 32, plus 2 = 34, schreibe 34. '
          'Ergebnis: 435 · 8 = 3480.');
      return;
    }
    fail('435 × 8 wurde nicht erzeugt');
  });

  test('schriftliche Division: mit und ohne Rest, immer genau eine Lösung', () {
    var withRest = 0;
    final quotients = <int, int>{};
    const count = 600;
    for (var i = 0; i < count; i++) {
      final task = byId('g4_written_div').concretize(i * 7919 + 13);
      expect(task.prompt, startsWith('Schriftlich: '), reason: task.prompt);
      final parts = numbers(task.prompt);
      final dividend = parts[0], divisor = parts[1];
      expect(dividend, inInclusiveRange(100, 999), reason: task.prompt);
      expect(divisor, inInclusiveRange(2, 9), reason: task.prompt);
      final quotient = dividend ~/ divisor, rest = dividend % divisor;
      final expected = rest == 0 ? '$quotient' : '$quotient Rest $rest';
      expect(task.answer, expected, reason: task.prompt);
      if (rest > 0) withRest++;
      quotients[quotient] = (quotients[quotient] ?? 0) + 1;

      expect(task.choices, hasLength(4), reason: '${task.prompt} ${task.choices}');
      expect(task.choices.toSet(), hasLength(4));
      expect(task.choices.where((card) => card == expected), hasLength(1));
      // Die Form der Karten verrät nicht, ob die Aufgabe aufgeht.
      expect(task.choices.where((card) => card.contains('Rest')), hasLength(2),
          reason: '${task.prompt} ${task.choices}');
      for (final card in task.choices.where((card) => card != expected)) {
        final values = numbers(card);
        final value = values[0] * divisor + (values.length > 1 ? values[1] : 0);
        final restOk = values.length == 1 || values[1] < divisor;
        expect(value == dividend && restOk, isFalse,
            reason: 'zweite richtige Karte $card bei ${task.prompt}');
      }
      expect(task.explanation,
          contains('Probe: $quotient · $divisor${rest > 0 ? ' + $rest' : ''} = $dividend.'));
    }
    expect(withRest / count, inInclusiveRange(.2, .45));
    // Früher war 99 in 18 % der Aufgaben die Lösung.
    expect(quotients.values.every((n) => n / count < .03), isTrue);
  });

  test('typischer Fehler „Rest ignoriert“ ist als Karte dabei', () {
    for (var i = 0; i < 300; i++) {
      final task = byId('g4_written_div').concretize(i * 131 + 3);
      if (!task.answer.contains('Rest')) continue;
      final quotient = numbers(task.answer).first;
      expect(task.choices, contains('$quotient'), reason: task.prompt);
    }
  });

  test('Division einstellig: Dividend bis 100, Quotienten breit gestreut', () {
    final quotients = <int, int>{};
    for (var i = 0; i < 600; i++) {
      final task = byId('g3_division_basic').concretize(i * 7919 + 13);
      final parts = numbers(task.prompt);
      expect(parts[0], lessThanOrEqualTo(100), reason: task.prompt);
      expect(parts[1], inInclusiveRange(2, 9), reason: task.prompt);
      expect(parts[0] % parts[1], 0, reason: task.prompt);
      expect(task.answer, '${parts[0] ~/ parts[1]}');
      final q = parts[0] ~/ parts[1];
      quotients[q] = (quotients[q] ?? 0) + 1;
    }
    expect(quotients.values.every((n) => n / 600 < .15), isTrue,
        reason: '$quotients');
  });

  test('Qualitätsprüfung rechnet die Probe für Aufgaben mit Rest nach', () {
    LumoTask task(String answer, List<String> choices) => LumoTask(
          id: 'division-rest',
          grade: 4,
          subject: 'Mathematik',
          unit: 'Schriftliche Division',
          prompt: 'Schriftlich: 499 : 4 = ?',
          answer: answer,
          choices: choices,
          explanation: 'Probe: 124 · 4 + 3 = 499.',
          visual: 'division',
        );
    const guard = TaskQualityGuard();
    expect(guard.problems(task('124 Rest 3', ['124 Rest 3', '124', '125', '124 Rest 1'])),
        isEmpty);
    expect(guard.problems(task('124 Rest 5', ['124 Rest 5', '124', '125', '124 Rest 1'])),
        contains('division_remainder_wrong'));
    expect(guard.problems(task('123 Rest 7', ['123 Rest 7', '124', '125', '124 Rest 1'])),
        contains('division_remainder_wrong'));
    expect(guard.problems(task('124', ['124 Rest 3', '124', '125', '124 Rest 1'])),
        isNotEmpty);

    // Alle erzeugten Aufgaben bestehen die Prüfung im echten Aufgabenweg.
    final factory = ExerciseFactory(seed: 9);
    var rests = 0;
    for (var i = 0; i < 200; i++) {
      final generated = factory.nextExact(
          grade: 4, subject: 'Mathematik', unit: 'Schriftliche Division');
      expect(guard.problems(generated), isEmpty, reason: generated.prompt);
      if (generated.answer.contains('Rest')) rests++;
    }
    expect(rests, greaterThan(30));
  });
}
