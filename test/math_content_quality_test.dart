import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';

MathTaskTemplate template(String id) =>
    MathTaskTemplates.templates.singleWhere((item) => item.id == id);

List<int> numbers(String text) => RegExp(r'\d+')
    .allMatches(text)
    .map((match) => int.parse(match.group(0)!))
    .toList();

void main() {
  test('all mathematical families can actually be selected at every grade', () {
    for (var grade = 1; grade <= 4; grade++) {
      final reached = <String>{};
      for (var seed = 0; seed < 5000; seed++) {
        final task = MathTaskTemplates.generate(
          grade: grade,
          unit: 'Alle',
          seed: seed,
        );
        expect(task.difficulty, lessThanOrEqualTo(grade));
        reached.add(task.promptPattern);
      }
      for (final item in MathTaskTemplates.templatesForGrade(grade)) {
        expect(reached, contains(item.promptPattern), reason: item.id);
      }
    }
  });

  test('clocks have exactly one correct time, including whole hours', () {
    final seenTimes = <String>{};
    for (var seed = 0; seed < 600; seed++) {
      final task = template('g2_clock').concretize(seed);
      final values = task.choices.map((choice) {
        final parts = numbers(choice);
        return parts[0] * 60 + (parts.length == 1 ? 0 : parts[1]);
      }).toList();
      expect(values.toSet().length, values.length, reason: task.prompt);
      // Fachprüfung Mathematik M4: Die Frage nannte früher Stunde und
      // Minute („Stunde 7 und Minute 30“) und damit die Lösung. Jetzt steht
      // die Uhrzeit nur auf der Uhr im Bild; die Frage enthält keine Zahl.
      expect(task.prompt, 'Wie spät ist es?');
      expect(numbers(task.prompt), isEmpty);
      expect(task.choices, hasLength(4), reason: '${task.choices}');
      expect(task.choices.where((choice) => choice == task.answer),
          hasLength(1));
      final answer = numbers(task.answer);
      expect(answer[0], inInclusiveRange(1, 12));
      expect(const [0, 15, 30, 45], contains(answer[1]));
      expect(task.explanation, endsWith('Auf der Uhr steht ${task.answer}.'));
      seenTimes.add(task.answer);
    }
    // Alle 48 Uhrzeiten (12 Stunden mal 4 Viertelstunden) kommen vor.
    expect(seenTimes, hasLength(48));
  });

  test('grade one number lines never extend beyond 20', () {
    for (var seed = 0; seed < 300; seed++) {
      final task = template('g1_number_line').concretize(seed);
      expect(numbers(task.prompt).every((number) => number <= 20), isTrue);
      expect(int.parse(task.answer), inInclusiveRange(0, 20));
    }
  });

  test('equal quantities and equal prices are genuine possible answers', () {
    for (final id in ['g1_quantity_compare', 'g1_money_more']) {
      final answers = {
        for (var seed = 0; seed < 300; seed++)
          template(id).concretize(seed).answer,
      };
      // „gleich viele“ statt „gleich“: Die Frage heißt jetzt „wo sind mehr
      // Äpfel?“, darauf passt nur „gleich viele“ (Fachprüfung L17).
      expect(answers,
          contains(id == 'g1_money_more' ? 'gleich viel' : 'gleich viele'));
    }
  });

  test('changing money covers denominations with correct item counts', () {
    for (final id in ['g2_money_change', 'g3_money_change_100']) {
      final prompts = <String>{};
      var highestAmount = 0;
      for (var seed = 0; seed < 1000; seed++) {
        final task = template(id).concretize(seed);
        prompts.add(task.prompt);
        final amounts = numbers(task.prompt);
        final count = numbers(task.answer).single;
        expect(count * amounts[0], amounts[1], reason: task.prompt);
        if (amounts[1] > highestAmount) highestAmount = amounts[1];
      }
      expect(prompts.length, greaterThanOrEqualTo(25));
      if (id == 'g3_money_change_100') expect(highestAmount, 100);
    }
  });

  test('measurement conversion uses the whole amount and varied inputs', () {
    for (final entry in {
      'g2_length': 100,
      'g3_mass': 1000,
      'g4_volume': 1000,
      'g4_time_minutes': 60,
    }.entries) {
      final prompts = <String>{};
      final occurrences = <String, int>{};
      for (var seed = 0; seed < 1000; seed++) {
        // „Längen“ rechnet in Klasse 2 jetzt im Zahlenraum 100 (Fachprüfung
        // M12); die Umrechnung mehrerer Meter gilt ab Klasse 3.
        final task = template(entry.key)
            .concretize(seed, forGrade: entry.key == 'g2_length' ? 3 : null);
        prompts.add(task.prompt);
        occurrences[task.prompt] = (occurrences[task.prompt] ?? 0) + 1;
        final parts = numbers(task.prompt);
        expect(int.parse(task.answer),
            parts[0] * entry.value + (parts.length == 2 ? parts[1] : 0));
      }
      expect(prompts.length, greaterThanOrEqualTo(20), reason: entry.key);
      // The old clamp made almost every larger seed repeat the maximum.
      expect(occurrences.values.every((count) => count < 100), isTrue,
          reason: entry.key);
    }
  });

  test(
      'fraction addition varies both summands and has no equivalent distractors',
      () {
    final distancesFromWhole = <int>{};
    for (var seed = 0; seed < 500; seed++) {
      final task = template('g4_fraction_add').concretize(seed);
      final parts = numbers(task.prompt);
      final answer = numbers(task.answer);
      expect(parts[1], parts[3]);
      expect(answer[0], parts[0] + parts[2]);
      expect(answer[1], parts[1]);
      expect(answer[0], lessThan(answer[1]));
      distancesFromWhole.add(answer[1] - answer[0]);
      for (final choice
          in task.choices.where((value) => value != task.answer)) {
        final wrong = numbers(choice);
        expect(wrong[0] * answer[1], isNot(answer[0] * wrong[1]));
      }
    }
    expect(distancesFromWhole.length, greaterThan(3));
  });

  test('fourth-grade symmetry asks for axes rather than reusing yes/no tasks',
      () {
    // Fachprüfung Mathematik M14: Früher gab es nur vier Figuren. Die Liste
    // ist jetzt länger; die vier alten Figuren behalten ihre Lösung.
    final expected = {
      for (final entry in symmetryAxisExamples) entry.$1: '${entry.$2}',
    };
    expect(expected['ein Quadrat'], '4');
    expect(expected['ein Rechteck, das kein Quadrat ist'], '2');
    expect(expected['ein gleichseitiges Dreieck'], '3');
    expect(
        expected['ein gleichschenkliges Dreieck, das nicht gleichseitig ist'],
        '1');
    expect(expected.length, greaterThanOrEqualTo(20));
    final seen = <String>{};
    for (var seed = 0; seed < 400; seed++) {
      final task = template('g4_symmetry_lines').concretize(seed);
      final key = expected.keys.singleWhere(
          (shape) => task.prompt == 'Wie viele Symmetrieachsen hat $shape?');
      expect(task.answer, expected[key]);
      seen.add(key);
    }
    expect(seen.length, expected.length);
  });
}
