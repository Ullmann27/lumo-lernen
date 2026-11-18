// Fachprüfung 2026-11 (Deutsch, mittlere Befunde): Die Lösung darf nicht an
// der Form der Antworten erkennbar sein, Ablenker müssen zur Frage gehören,
// und die Erklärung muss zur richtigen Antwort passen.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';

void main() {
  GermanTaskTemplate template(String id) =>
      GermanTaskTemplates.templates.firstWhere((item) => item.id == id);

  Iterable<GermanConcreteTask> tasks(String id, {int seeds = 300}) sync* {
    final seen = <String>{};
    for (var seed = 0; seed < seeds; seed++) {
      final task = template(id).concretize(seed);
      if (seen.add('${task.prompt}|${task.answer}')) yield task;
    }
  }

  test('jede Deutsch-Vorlage: eindeutige Antworten, genau eine richtig', () {
    for (final item in GermanTaskTemplates.templates) {
      for (var seed = 0; seed < 300; seed++) {
        final task = item.concretize(seed);
        final reason = '${item.id}: ${task.prompt} ${task.choices}';
        expect(task.choices.length, greaterThanOrEqualTo(3), reason: reason);
        expect(task.choices.map((choice) => choice.toLowerCase()).toSet(),
            hasLength(task.choices.length),
            reason: reason);
        expect(task.choices.where((choice) => choice == task.answer),
            hasLength(1),
            reason: reason);
      }
    }
  });

  test('Verkleinerung: die Lösung ist nicht als einzige an -chen erkennbar',
      () {
    final all = tasks('g2_diminutive').toList();
    expect(all.length, greaterThanOrEqualTo(20));
    for (final task in all) {
      final diminutiveLooking = task.choices
          .where((choice) => choice.endsWith('chen') || choice.endsWith('lein'));
      expect(diminutiveLooking.length, greaterThanOrEqualTo(3),
          reason: '${task.prompt} ${task.choices}');
      expect(task.choices.any((choice) => choice.endsWith('ung')), isFalse,
          reason: 'Unsinn-Ablenker: ${task.choices}');
    }
  });

  test('Vorvergangenheit: hatte/war allein verrät die Lösung nicht', () {
    final all = tasks('g4_plusquam').toList();
    expect(all.length, greaterThanOrEqualTo(20));
    for (final task in all) {
      final withAuxiliary = task.choices.where(
          (choice) => choice.startsWith('hatte ') || choice.startsWith('war '));
      expect(withAuxiliary.length, greaterThanOrEqualTo(3),
          reason: '${task.prompt} ${task.choices}');
      expect(task.choices.any((choice) => choice.startsWith('wird ')), isFalse);
    }
    // „hatte gefahren“ und „hatte gelaufen“ können richtig sein und dürfen
    // deshalb nicht als falsche Antwort stehen.
    for (final task in all) {
      expect(task.choices, isNot(contains('hatte gefahren')));
      expect(task.choices, isNot(contains('hatte gelaufen')));
    }
  });

  test('Großschreibung: die Lösung ist nie die einzige großgeschriebene Wahl',
      () {
    final all = tasks('g3_capitalization').toList();
    expect(all.length, greaterThanOrEqualTo(20));
    for (final task in all) {
      final upper = task.choices
          .where((choice) => choice[0] == choice[0].toUpperCase())
          .length;
      expect(upper, greaterThanOrEqualTo(2),
          reason: '${task.prompt} ${task.choices}');
    }
  });

  test('Umstandswörter: alle Antworten stehen im gezeigten Satz', () {
    final all = tasks('g4_adverbs').toList();
    expect(all.length, greaterThanOrEqualTo(20));
    for (final task in all) {
      final sentence = RegExp('„(.+)“').firstMatch(task.prompt)!.group(1)!;
      final words = sentence
          .replaceAll(RegExp('[.,!?]'), '')
          .split(' ')
          .toSet();
      for (final choice in task.choices) {
        expect(words, contains(choice),
            reason: '„$choice“ steht nicht in: $sentence');
      }
    }
  });

  test('dass/das: die Erklärung passt zur richtigen Antwort', () {
    final all = tasks('g4_dass_das').toList();
    expect(all.length, greaterThanOrEqualTo(20));
    for (final task in all) {
      if (task.answer.toLowerCase().contains('dass')) {
        expect(task.explanation, startsWith('Hier passt weder'),
            reason: task.prompt);
      } else {
        expect(task.explanation, startsWith('Probe:'), reason: task.prompt);
        expect(task.explanation, contains('„das“ mit einem s'));
      }
    }
  });

  test('Artikel: nur Einzahl-Wörter, kein „Erdäpfel“', () {
    expect(PrimarySchoolWordData.articleFor('Erdäpfel'), isNull);
    expect(PrimarySchoolWordData.articleFor('Erdapfel'), 'der');
    expect(PrimarySchoolWordData.syllablesFor('Erdapfel'),
        <String>['Erd', 'ap', 'fel']);
    expect(PrimarySchoolWordData.syllablesFor('Bibliothek'),
        <String>['Bi', 'bli', 'o', 'thek']);
  });

  test('Lautierung fragt einzelne Buchstaben in der Einzahl', () {
    final all = tasks('g1_letter_sound').toList();
    expect(all.length, greaterThanOrEqualTo(12));
    for (final task in all) {
      expect(
          task.prompt.startsWith(task.answer.length == 1
              ? 'Welcher Buchstabe passt'
              : 'Welche Buchstaben passen'),
          isTrue,
          reason: task.prompt);
    }
  });

  test('Synonyme: fröhlich wird nicht mit lustig gleichgesetzt', () {
    for (final task in tasks('g3_synonyms')) {
      if (task.prompt.contains('„fröhlich“')) expect(task.answer, 'heiter');
    }
  });
}
