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
    expect(guard.problems(task),
        contains('nomen_choices_missing_wordclass_distractor'));
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

  // Fachprüfung 2026-11 (D-S2): Dieser Test verlangte früher, dass „Hund“
  // als Wort mit Endlaut t gilt. Das Wort steht geschrieben da und wird mit d
  // geschrieben; die Aufgabe übte „Hunt“ ein. Solche Aufgaben werden jetzt
  // abgewiesen, Wörter ohne Auslautverhärtung bleiben gültig.
  test('rejects Hund as a word ending in t, accepts Heft', () {
    const hund = LumoTask(
      id: 'bad_end_sound_hund',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Endlaute',
      prompt: 'Welches Wort endet mit t?',
      choices: <String>['Hase', 'Mama', 'Hund'],
      answer: 'Hund',
      explanation: 'Sprich jedes Wort langsam.',
    );
    expect(guard.validate(hund), isFalse);
    expect(guard.problems(hund), contains('answer_wrong_ending'));

    const heft = LumoTask(
      id: 'good_end_sound_heft',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Endlaute',
      prompt: 'Welches Wort endet mit t?',
      choices: <String>['Hase', 'Mama', 'Heft'],
      answer: 'Heft',
      explanation: 'Sprich jedes Wort langsam.',
    );
    expect(guard.validate(heft), isTrue);
  });

  test('accepts generated final-sound letter question', () {
    const task = LumoTask(
      id: 'good_final_sound',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Endlaute',
      prompt: 'Mit welchem Laut endet Stift?',
      choices: <String>['t', 'A', 'B'],
      answer: 't',
      explanation: 'Sprich Stift langsam. Der letzte Laut ist t.',
    );

    expect(guard.validate(task), isTrue);
  });

  test('rejects wrong article for known noun', () {
    const task = LumoTask(
      id: 'bad_article',
      grade: 1,
      subject: 'Deutsch',
      unit: 'Artikel',
      prompt: 'Welcher Artikel passt zu Schule?',
      choices: <String>['der', 'die', 'das'],
      answer: 'der',
      explanation: 'Sprich Artikel und Wort zusammen.',
    );

    expect(guard.validate(task), isFalse);
    expect(guard.problems(task), contains('article_answer_wrong_for_noun'));
  });
}
