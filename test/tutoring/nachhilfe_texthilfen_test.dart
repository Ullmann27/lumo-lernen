import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/task_hint_service.dart';

/// Texthilfen der Aufgabe (Stufen 1–3 von „Hilf mir“): konkret mit den Zahlen
/// der Aufgabe, kindgerecht, ohne das Ergebnis zu nennen.
LumoTask _aufgabe(String prompt, String answer, {String unit = 'Üben'}) =>
    LumoTask(
      id: 't',
      grade: 2,
      subject: 'Mathematik',
      unit: unit,
      prompt: prompt,
      answer: answer,
      choices: const [],
      explanation: '',
    );

void main() {
  const hints = TaskHintService();

  test('kleines Einmaleins: Punktefeld, Kernaufgabe, nie das Ergebnis', () {
    for (var a = 1; a <= 10; a++) {
      for (var b = 1; b <= 10; b++) {
        for (final zeichen in ['·', '×']) {
          final task = _aufgabe('$a $zeichen $b = ?', '${a * b}',
              unit: 'Einmaleins');
          for (var level = 1; level <= 3; level++) {
            final text = hints.explain(task, level: level);
            final label = '$a$zeichen$b L$level: $text';
            expect(RegExp('=\\s*${a * b}(?!\\d)').hasMatch(text), isFalse,
                reason: label);
            expect(text.contains(', ${a * b},'), isFalse, reason: label);
            if (level != 2) {
              expect(text, contains('$a $zeichen $b'), reason: label);
            }
            expect(text, isNot(contains('je 1 Punkten')), reason: label);
            expect(text.length, lessThan(260), reason: label);
          }
        }
      }
    }
    expect(hints.explain(_aufgabe('6 · 7 = ?', '42')),
        '6 · 7 heißt: 6 Reihen mit je 7 Punkten. '
        '6 · 7 ist eine Reihe mehr als 5 · 7. Kennst du 5 · 7?');
    expect(hints.explain(_aufgabe('6 · 7 = ?', '42'), level: 2),
        contains('5 · 7 = 35. Dann kommt noch eine Reihe mit 7 dazu.'));
    expect(hints.explain(_aufgabe('9 × 4 = ?', '36'), level: 2),
        contains('10 × 4 = 40'));
    expect(hints.explain(_aufgabe('6 · 7 = ?', '42'), level: 3),
        contains('7er-Schritten: 7, 14, 21'));
  });

  test('Plus und Minus bis 100: erster Tipp nennt die Zahlen der Aufgabe', () {
    expect(hints.explain(_aufgabe('37 + 25 = ?', '62')),
        'Beginne mit der ersten Menge: 37. Lege dann 25 dazu. '
        'Zerlege die 25 in 20 und 5: erst die Zehner, dann die Einer.');
    expect(hints.explain(_aufgabe('8 + 5 = ?', '13')),
        contains('Mach zuerst den nächsten Zehner voll'));
    expect(hints.explain(_aufgabe('62 − 25 = ?', '37')),
        contains('Nimm zuerst die Zehner weg, dann die Einer.'));
    expect(hints.explain(_aufgabe('13 - 5 = ?', '8')),
        contains('Geh zuerst zurück bis zum Zehner 10'));
    for (final (p, e) in [
      ('37 + 25 = ?', 62),
      ('8 + 5 = ?', 13),
      ('62 − 25 = ?', 37),
      ('13 - 5 = ?', 8),
    ]) {
      expect(RegExp('\\b$e\\b').hasMatch(hints.explain(_aufgabe(p, '$e'))),
          isFalse,
          reason: p);
    }
    // Schriftliches Rechnen und Textaufgaben behalten ihre eigenen Tipps.
    expect(hints.explain(_aufgabe('Schriftlich: 467 + 258 = ?', '725')),
        isNot(contains('Beginne mit der ersten Menge: 467')));
  });

  LumoTask deutsch(String prompt, String answer, List<String> choices) =>
      LumoTask(
        id: 'd',
        grade: 2,
        subject: 'Deutsch',
        unit: 'Rechtschreibung',
        prompt: prompt,
        answer: answer,
        choices: choices,
        explanation: '',
      );

  test('Silben: hörbar klatschen, Kinn spüren, Bögen an einem anderen Wort',
      () {
    final task = deutsch('Wie viele Silben hat Banane?', '3', ['3', '2', '4']);
    final stufen = [for (var l = 1; l <= 3; l++) hints.explain(task, level: l)];
    expect(stufen[0], contains('klatsche'));
    expect(stufen[0], contains('„Banane“'));
    expect(stufen[1], contains('Kinn'));
    expect(stufen[2], contains('Bögen'));
    expect(stufen[2], isNot(contains('Ba – na – ne')),
        reason: 'Lumo teilt ein anderes Wort, nicht das gefragte.');
    expect(stufen[2], isNot(contains('drei')),
        reason: 'Das andere Wort hat eine andere Silbenzahl.');
    for (final text in stufen) {
      expect(RegExp(r'\b3\b').hasMatch(text), isFalse, reason: text);
    }
  });

  test('Rechtschreibung: Regel statt Lösung', () {
    final faelle = [
      (deutsch('Welche Schreibweise ist richtig?', 'kommen',
          ['kommen', 'komen', 'komenn']), 'kurzen'),
      (deutsch('Welche Schreibweise ist richtig?', 'Biene',
          ['Biene', 'Bine', 'Bihne']), 'ie'),
      (deutsch('Welche Schreibweise ist richtig?', 'Hund',
          ['Hund', 'Hunt', 'Hundt']), 'Verlängere'),
      (deutsch('Welche Schreibweise ist richtig?', 'Decke',
          ['Decke', 'Deke', 'Dekke']), 'ck'),
      (deutsch('Welche Schreibweise ist richtig?', 'Bäume',
          ['Bäume', 'Beume', 'Bäüme']), 'Ableiten'),
      (deutsch('Welche Schreibweise ist richtig?', 'Tisch',
          ['Tisch', 'tisch', 'Tich']), 'der, die oder das'),
    ];
    for (final (task, regel) in faelle) {
      final zweite = hints.explain(task, level: 2);
      expect(zweite, contains(regel), reason: task.answer);
      for (var level = 1; level <= 3; level++) {
        final text = hints.explain(task, level: level);
        expect(text.toLowerCase(), isNot(contains(task.answer.toLowerCase())),
            reason: '${task.answer} L$level: $text');
      }
    }
  });
}
