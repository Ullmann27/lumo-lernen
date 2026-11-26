// Fachprüfung 2026-11: Gegenteil-Geschichten ohne kränkende Sätze (D-M15),
// vertauschte Zusammensetzung nicht als falsch (D-M16), keine strittigen
// Grenzmonate (S-M13), „Was bin ich?“ bei Dingen (S-L8).
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/adventure/adventure_word_data.dart';
import 'package:lumo_lernen/core/adventure/lumo_adventure_tasks.dart';

void main() {
  LumoAdventureTasks generator(int seed) =>
      LumoAdventureTasks(Random(seed), childName: 'Mia');

  test('Gegenteil-Geschichten handeln von passenden Dingen, nie vom Kind', () {
    final gen = generator(11);
    final prompts = <String>{};
    for (var i = 0; i < 600; i++) {
      final task = gen.generate(
          subject: 'Deutsch', unit: 'Gegenteil-Geschichten', grade: 2);
      prompts.add(task.prompt);
      expect(task.prompt.contains('Mia'), isFalse, reason: task.prompt);
      expect(task.prompt.contains('gar nicht'), isFalse, reason: task.prompt);
      final shown = RegExp('Gegenteil von „(.+)“')
          .firstMatch(task.prompt)!
          .group(1)!;
      final pair = adventureOpposites
          .firstWhere((entry) => entry.take(2).contains(shown));
      expect(pair.take(2), contains(task.answer), reason: task.prompt);
      expect(task.answer, isNot(shown));
      expect(task.choices, isNot(contains(shown)), reason: task.prompt);
    }
    expect(prompts.length, adventureOpposites.length * 2);
  });

  test('jeder Gegenteil-Satz verneint das eine und meint das andere Wort', () {
    for (final entry in adventureOpposites) {
      expect(entry, hasLength(4));
      // Satz mit Lösung A verneint B und umgekehrt.
      expect(entry[2].contains(entry[1].substring(0, 3)), isTrue,
          reason: entry[2]);
      expect(entry[3].contains(entry[0].substring(0, 3)), isTrue,
          reason: entry[3]);
      for (final sentence in entry.skip(2)) {
        expect(sentence.trim().endsWith('…'), isTrue, reason: sentence);
      }
    }
  });

  test('Zusammensetzungen: die vertauschte Reihenfolge steht nicht zur Wahl',
      () {
    final gen = generator(12);
    for (var i = 0; i < 600; i++) {
      final task = gen.generate(
          subject: 'Deutsch', unit: 'Wörter zusammensetzen', grade: 2);
      if (!task.prompt.startsWith('Aus welchen zwei Wörtern')) continue;
      final parts = task.answer.split(' + ');
      expect(task.choices, isNot(contains('${parts[1]} + ${parts[0]}')),
          reason: task.prompt);
    }
  });

  test('Jahreszeiten-Frage lässt die Grenzmonate aus', () {
    final gen = generator(13);
    var asked = 0;
    for (var i = 0; i < 1500; i++) {
      final task = gen.generate(
          subject: 'Sachunterricht', unit: 'Monate und Wochentage', grade: 3);
      if (!task.prompt.startsWith('In welcher Jahreszeit')) continue;
      asked++;
      for (final month in <String>['März', 'Juni', 'September', 'Dezember']) {
        expect(task.prompt.contains(month), isFalse, reason: task.prompt);
      }
    }
    expect(asked, greaterThan(20));
  });

  test('Rätsel fragen bei Dingen „Was bin ich?“', () {
    final gen = generator(14);
    final things = adventureRiddles
        .where((riddle) => riddle[5] != 'Tier' && riddle[5] != 'Beruf')
        .map((riddle) => riddle[0])
        .toSet();
    for (var i = 0; i < 600; i++) {
      final task = gen.generate(
          subject: 'Sachunterricht', unit: 'Wer bin ich?', grade: 4);
      expect(task.prompt.startsWith('Was bin ich?'),
          things.contains(task.answer),
          reason: task.prompt);
      expect(task.explanation.contains('Gut geraten'), isFalse);
    }
  });

  test('Abenteuer-Wörter in österreichischer Schreibung (D-L6)', () {
    final source =
        File('lib/core/adventure/adventure_word_data.dart').readAsStringSync();
    expect(source, isNot(contains("'Kartoffel'")));
    expect(source, isNot(contains('Pflaume')));
    expect(source, contains("AdventureNoun('der', 'Erdapfel', 'Erd-ap-fel', 2)"));
  });

  test('Österreich-Reise: Steiermark und Burgenland mit Artikel', () {
    // Vorher: „Lumo fliegt mit dem Ballon über Steiermark.“ und
    // „Graz ist die Landeshauptstadt von Steiermark.“
    final seen = <String>{};
    for (var seed = 0; seed < 600; seed++) {
      final task = generator(seed).generate(
          subject: 'Sachunterricht', unit: 'Österreich-Reise', grade: 3);
      final text = '${task.prompt} ${task.explanation}';
      expect(text, isNot(matches(RegExp(
          r'(über|von|in|nach|aus) (Steiermark|Burgenland)\b'))),
          reason: text);
      if (text.contains('Steiermark')) seen.add('Steiermark');
      if (text.contains('Burgenland')) seen.add('Burgenland');
    }
    expect(seen, {'Steiermark', 'Burgenland'});
  });
}
