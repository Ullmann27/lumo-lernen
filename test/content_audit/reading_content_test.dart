// Fachprüfung 2026-11 (Lesen): zwei passende Wörter im Lückensatz (D-M14),
// Erwachsenensprache in Klasse-4-Texten (D-M13), immer dieselben Ablenker bei
// „Bild und Wort“ (D-M12), Text und Frage passen zusammen (D-L9).
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/reading_comprehension_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/deutsch/deutsch_gap_sentences.dart';

void main() {
  test('jede Lesefrage hat genau eine richtige und zwei falsche Antworten', () {
    readingPassages.forEach((grade, passages) {
      expect(passages.length, greaterThanOrEqualTo(12),
          reason: 'Klasse $grade');
      for (final passage in passages) {
        for (final check in passage.checks) {
          final options = <String>[check.answer, ...check.wrong];
          expect(options.toSet(), hasLength(3), reason: check.question);
          expect(check.question.trim().endsWith('?'), isTrue);
        }
      }
    });
  });

  test('Klasse-4-Lesetexte sind in Kindersprache geschrieben', () {
    const adultWords = <String>[
      'Verallgemeinerung',
      'prüfbare Angaben',
      'widersprüchliche',
      'Werbebehauptung',
      'unterstützt nur eine der Angaben',
    ];
    for (final passage in readingPassages[4]!) {
      final text = <String>[
        passage.text,
        for (final check in passage.checks) ...<String>[
          check.question,
          check.answer,
          ...check.wrong,
        ],
      ].join(' ');
      for (final word in adultWords) {
        expect(text.contains(word), isFalse, reason: '$word in: $text');
      }
    }
  });

  test('Text und Frage passen zusammen (Sand, Lampe)', () {
    final all = readingPassages.values.expand((list) => list);
    final sand = all.firstWhere((p) => p.text.contains('Turm'));
    expect(sand.text, contains('aus Sand'));
    expect(all.any((p) => p.text.contains('findet beim Radfahren')), isFalse);
    expect(all.any((p) => p.text.contains('Kassenbon')), isFalse);
  });

  test('Lückensätze: nur ein Wort passt, Klasse 3–4 übt Bindewörter', () {
    for (final sentence in DeutschGapSentences.all) {
      expect(sentence.options.toSet(), hasLength(4), reason: sentence.before);
      expect(sentence.options.where((option) => option == sentence.answer),
          hasLength(1));
    }
    final hund = DeutschGapSentences.all
        .firstWhere((s) => s.before == 'Der Hund spielt im');
    expect(hund.options, isNot(contains('Haus')));
    final vogel = DeutschGapSentences.all
        .firstWhere((s) => s.before == 'Der Vogel sitzt auf dem');
    expect(vogel.options, isNot(contains('Tisch')));
    expect(vogel.options, isNot(contains('Teller')));
    final connectors = DeutschGapSentences.forGrade(4).where(
        (s) => <String>{'weil', 'aber', 'dass', 'oder'}.contains(s.answer));
    expect(connectors.length, greaterThanOrEqualTo(4));
  });

  test('Bild und Wort: die Ablenker wechseln', () {
    final factory = ExerciseFactory(seed: 21);
    final distractorSets = <String>{};
    for (var i = 0; i < 200; i++) {
      final task =
          factory.next(grade: 1, subject: 'Lesen', unit: 'Bild und Wort');
      expect(task.choices.toSet(), hasLength(4));
      final wrong = task.choices.where((c) => c != task.answer).toList()
        ..sort();
      distractorSets.add(wrong.join(','));
    }
    expect(distractorSets.length, greaterThan(20));
  });

  test('Lesesinn hat eigene Schlussfolgerungs-Fragen, nicht „Sätze lesen“', () {
    readingInferences.forEach((grade, passages) {
      expect(passages.length, greaterThanOrEqualTo(12), reason: 'Klasse $grade');
      for (final passage in passages) {
        for (final check in passage.checks) {
          final options = <String>[check.answer, ...check.wrong];
          expect(options.toSet(), hasLength(3), reason: check.question);
          expect(check.question.trim().endsWith('?'), isTrue);
          // Schließen statt Abschreiben: die Antwort steht nicht im Text.
          expect(passage.text.toLowerCase(),
              isNot(contains(check.answer.toLowerCase())),
              reason: check.question);
        }
      }
    });
    final factory = ExerciseFactory(seed: 5);
    final literalTexts = <String>{
      for (final list in readingPassages.values)
        for (final passage in list) passage.text,
    };
    for (var grade = 1; grade <= 4; grade++) {
      for (var i = 0; i < 40; i++) {
        final task =
            factory.next(grade: grade, subject: 'Lesen', unit: 'Lesesinn');
        expect(literalTexts.any(task.prompt.startsWith), isFalse,
            reason: task.prompt);
      }
    }
  });

  test('Reihenfolge: die Sätze stehen durcheinander', () {
    final factory = ExerciseFactory(seed: 9);
    for (var i = 0; i < 120; i++) {
      final task =
          factory.next(grade: 2, subject: 'Lesen', unit: 'Reihenfolge');
      final sequence = readingSequences.firstWhere(
          (s) => s.every((sentence) => task.choices.contains(sentence)));
      expect(task.prompt, isNot(contains(sequence.join(' '))),
          reason: task.prompt);
      expect(task.choices.toSet(), hasLength(3));
    }
  });

  test('Wörter lesen: genug Rätsel je Klasse', () {
    final factory = ExerciseFactory(seed: 3);
    for (final entry in <int, int>{1: 17, 2: 22, 4: 24}.entries) {
      final prompts = <String>{};
      for (var i = 0; i < 600; i++) {
        final task = factory.next(
            grade: entry.key, subject: 'Lesen', unit: 'Woerter lesen');
        expect(task.choices.toSet(), hasLength(task.choices.length));
        prompts.add(task.prompt);
      }
      expect(prompts.length, entry.value, reason: 'Klasse ${entry.key}');
    }
  });
}
