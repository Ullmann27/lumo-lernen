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
}
