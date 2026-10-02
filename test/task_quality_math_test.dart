import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

LumoTask task(String prompt, String answer, List<String> choices,
        {String subject = 'Mathematik'}) =>
    LumoTask(
      id: 'check',
      grade: 4,
      subject: subject,
      unit: 'Üben',
      prompt: prompt,
      answer: answer,
      choices: choices,
      explanation: 'Prüfe genau.',
    );

void main() {
  const guard = TaskQualityGuard();
  test('guard checks multiplication, division, decimals and fractions exactly',
      () {
    for (final item in [
      task('7 × 8 = ?', '56', ['56', '54', '63']),
      task('24 : 6 = ?', '4', ['4', '6', '3']),
      task('0,1 + 0,2 = ?', '0,3', ['0,3', '0,4', '0,2']),
      task('1/4 + 2/4 = ?', '3/4', ['3/4', '2/4', '4/4']),
    ]) {
      expect(guard.problems(item), isEmpty, reason: item.prompt);
    }
    for (final item in [
      task('7 × 8 = ?', '54', ['54', '56', '63']),
      task('24 : 6 = ?', '6', ['4', '6', '3']),
      task('0,1 + 0,2 = ?', '0,4', ['0,3', '0,4', '0,2']),
      task('1/4 + 2/4 = ?', '2/4', ['3/4', '2/4', '4/4']),
    ]) {
      expect(guard.problems(item), contains('numeric_answer_wrong_result'),
          reason: item.prompt);
    }
  });

  test('equivalent fractions, decimals and clock times are duplicate answers',
      () {
    for (final item in [
      task('Welche Zahl?', '1/2', ['1/2', '2/4', '3/4']),
      task('Welche Zahl?', '0,5', ['0,5', '0.50', '1']),
      task('Welche Uhrzeit?', '3 Uhr', ['3 Uhr', '3:00 Uhr', '4 Uhr']),
    ]) {
      expect(guard.problems(item), contains('duplicate_choices'));
    }
  });

  test(
      'single-card multiple choice is rejected, real capitalization is retained',
      () {
    expect(guard.problems(task('2 + 3 = ?', '5', ['5'])),
        contains('not_enough_choices'));
    expect(
        guard.problems(task(
            'Wie schreibt man das Namenwort?', 'Haus', ['Haus', 'haus'],
            subject: 'Rechtschreibung')),
        isEmpty);
  });

  test('sound checks distinguish phonemes from the last written letter', () {
    expect(
        guard.problems(task(
            'Mit welchem Laut endet Hund?', 'T', ['T', 'D', 'N'],
            subject: 'Deutsch')),
        isEmpty);
    expect(
        guard.problems(task(
            'Mit welchem Laut endet Hund?', 'D', ['T', 'D', 'N'],
            subject: 'Deutsch')),
        contains('answer_wrong_final_sound'));
    expect(
        guard.problems(task(
            'Mit welchem Laut beginnt Schule?', 'Sch', ['Sch', 'S', 'K'],
            subject: 'Deutsch')),
        isEmpty);
  });
}
