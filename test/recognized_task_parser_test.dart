import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/recognized_task_repository.dart';
import 'package:lumo_lernen/domain/learning/recognized_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final example in <String, String>{
    '12 + 7': '19',
    '3 − 8': '-5',
    '-8 + -7': '-15',
    '6 × -2': '-12',
    '-4--6': '2',
    '999 * 10 = ?': '9990',
    'Anfangsbuchstabe Mama': 'M',
    'Anfangsbuchstabe von Äpfel': 'Ä',
    'Mit welchem Buchstaben beginnt Schule?': 'S',
    'Hund Anfangsbuchstabe': 'H',
    '2, 4, 6, ?': '8',
    '9 6 3 ?': '0',
    '-2, -5, -8, ?': '-11',
    '0, 0, 0, ?': '0',
    '9996, 9997, 9998, ?': '9999',
    '-9996, -9997, -9998, ?': '-9999',
  }.entries) {
    test(
        'recognizes the entire input and preserves the exact answer: ${example.key}',
        () {
      final task = RecognizedTask.parse(example.key);
      expect(task.answer, example.value);
      expect(task.options, hasLength(4));
      expect(task.options.toSet(), hasLength(4));
      expect(task.options.where((value) => value == task.answer), hasLength(1));
      final attempt = RecognizedTaskAttempt.begin('child-a', task);
      final rendered = task.toTaskInstance(
          attemptId: attempt.id,
          ownerId: attempt.ownerId,
          startedAt: attempt.startedAt);
      expect(rendered.prompt, task.prompt);
      expect(rendered.correctAnswer, example.value);
      expect(rendered.options.map((option) => option.payload),
          contains(example.value));
      expect(
          RecognizedTask.fromJson(jsonDecode(jsonEncode(task.toJson())))
              .toJson(),
          task.toJson());
    });
  }

  for (final input in [
    '1 + 2 + 3',
    '1 + 2 = 3',
    '1 / 2',
    '1.5 + 2',
    'Rechne 1+2 und 3+4',
    '1, 2, 4, ?',
    '1, 2, 3, 7, ?',
    '1,,2,3,?',
    '1,2,?',
    '1,2,3,4,5,6,7,8,9,?',
    '9997,9998,9999,?',
    '1000 + 1',
    '999 × 999',
    'Anfangsbuchstabe Mama Papa',
    'Anfangsbuchstabe ßa',
    '',
    '<script>2+3</script>'
  ]) {
    test('rejects unsupported, oversized or ambiguous input: $input', () {
      expect(() => RecognizedTask.parse(input), throwsFormatException);
    });
  }

  test('input length and control characters are bounded', () {
    expect(() => RecognizedTask.parse('1' * 241), throwsFormatException);
    expect(() => RecognizedTask.parse('1+2\u0000'), throwsFormatException);
  });
  test('a changed stored solution is rejected before it can be rendered', () {
    final value = RecognizedTask.parse('12+7').toJson();
    value['answer'] = '20';
    expect(() => RecognizedTask.fromJson(value), throwsFormatException);
  });
  test('damaged or newer stored state is retained and cannot be overwritten',
      () async {
    final repository = RecognizedTaskRepository(ownerId: 'child-a');
    const damaged = '{"version":99,"ownerId":"child-a","attempt":{}}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(repository.storageKey, damaged);
    await expectLater(
        repository.begin(RecognizedTask.parse('2+3')), throwsFormatException);
    expect(prefs.getString(repository.storageKey), damaged);
  });
}
