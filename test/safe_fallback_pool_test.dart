import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/safe_fallback_pool.dart';

void main() {
  const pool = SafeFallbackPool();

  test('math fallback stays math', () {
    final task = pool.pick(
      subject: 'Mathematik',
      grade: 1,
      counter: 0,
      unit: 'Plus bis 10',
      difficulty: 1,
    );

    expect(task.subject, 'Mathematik');
    expect(task.answer, isNotEmpty);
    expect(task.choices, contains(task.answer));
  });

  test('legacy Deutsch fallback restores obvious English unit', () {
    final task = pool.pick(
      subject: 'Deutsch',
      grade: 1,
      counter: 0,
      unit: 'Farben',
      difficulty: 1,
    );

    expect(task.subject, 'Englisch');
    expect(task.prompt, contains('heißt'));
    expect(task.choices, contains(task.answer));
  });

  test('legacy Deutsch fallback restores obvious Sachunterricht unit', () {
    final task = pool.pick(
      subject: 'Deutsch',
      grade: 2,
      counter: 0,
      unit: 'Pflanzen',
      difficulty: 1,
    );

    expect(task.subject, 'Sachunterricht');
    expect(task.choices, contains(task.answer));
  });

  test('spelling fallback uses spelling variants, not unrelated correct words', () {
    final task = pool.pick(
      subject: 'Rechtschreibung',
      grade: 1,
      counter: 0,
      unit: 'Dehnungen',
      difficulty: 1,
    );

    expect(task.prompt, 'Welche Schreibweise ist richtig?');
    expect(task.choices, contains(task.answer));
    expect(task.choices, isNot(containsAll(<String>['Ball', 'Blume', 'Kerze'])));
  });
}
