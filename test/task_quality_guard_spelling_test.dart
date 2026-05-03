import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_quality_guard.dart';

void main() {
  const guard = TaskQualityGuard();

  test('rejects spelling question with unrelated correct words', () {
    const task = LumoTask(
      id: 'bad_spelling',
      grade: 1,
      subject: 'Rechtschreibung',
      unit: 'Dehnungen',
      prompt: 'Welche Schreibweise ist richtig?',
      choices: <String>['Ball', 'Blume', 'Kerze'],
      answer: 'Ball',
      explanation: 'Schau jeden Buchstaben langsam an.',
    );

    expect(guard.validate(task), isFalse);
    expect(guard.problems(task), contains('spelling_distractor_not_variant'));
  });

  test('accepts spelling question with misspelled variants', () {
    const task = LumoTask(
      id: 'good_spelling',
      grade: 1,
      subject: 'Rechtschreibung',
      unit: 'Doppelmitlaut',
      prompt: 'Welche Schreibweise ist richtig?',
      choices: <String>['Ball', 'Bal', 'Bahl'],
      answer: 'Ball',
      explanation: 'Ball schreibt man mit ll.',
    );

    expect(guard.validate(task), isTrue);
  });

  test('rejects wrong math result', () {
    const task = LumoTask(
      id: 'bad_math',
      grade: 1,
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      prompt: '2 + 3 = ?',
      choices: <String>['4', '5', '6'],
      answer: '4',
      explanation: '2 plus 3 ist 5.',
    );

    expect(guard.validate(task), isFalse);
    expect(guard.problems(task), contains('numeric_answer_wrong_result'));
  });

  test('rejects category question without contrasting word classes', () {
    const task = LumoTask(
      id: 'bad_noun',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Namenwoerter',
      prompt: 'Welches Wort ist ein Namenswort?',
      choices: <String>['Ball', 'Blume', 'Kerze'],
      answer: 'Ball',
      explanation: 'Namenswörter sind Dinge, Personen oder Tiere.',
    );

    expect(guard.validate(task), isFalse);
    expect(guard.problems(task), contains('nomen_choices_missing_wordclass_distractor'));
  });

  test('accepts category question with noun verb adjective contrast', () {
    const task = LumoTask(
      id: 'good_noun',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Namenwoerter',
      prompt: 'Welches Wort ist ein Namenswort?',
      choices: <String>['Ball', 'lesen', 'rot'],
      answer: 'Ball',
      explanation: 'Ball ist ein Ding und wird groß geschrieben.',
    );

    expect(guard.validate(task), isTrue);
  });
}
