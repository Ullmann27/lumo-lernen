// Fachprüfung 2026-11 (Sachunterricht): falsche Erklärung zu Frost (S-S1),
// alberne Ablenker (S-M11), Dubletten (S-M12), an der Form erkennbare
// Berufsantworten (S-M7), fehlende Österreich-Bezüge im Verkehr (S-M10).
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

class _Seen {
  _Seen(this.grade, this.unit, this.prompt, this.answer, this.choices,
      this.explanation);
  final int grade;
  final String unit;
  final String prompt;
  final String answer;
  final List<String> choices;
  final String explanation;
}

/// Zieht den ganzen Sachunterricht-Bestand einer Klasse über die Fabrik.
List<_Seen> _bank(int grade) {
  final factory = ExerciseFactory(seed: 900 + grade);
  final seen = <String, _Seen>{};
  for (var i = 0; i < 1500; i++) {
    final task =
        factory.next(grade: grade, subject: 'Sachunterricht', unit: 'Alle');
    if (task.subject != 'Sachunterricht' || task.visual != 'science') continue;
    // Abenteuer-Einheiten haben eigene Tests (adventure_tasks_test.dart).
    if (_adventureUnits.contains(task.unit)) continue;
    seen['${task.prompt}|${task.answer}'] = _Seen(task.difficulty, task.unit,
        task.prompt, task.answer, task.choices, task.explanation);
  }
  return seen.values.toList();
}

const _adventureUnits = <String>{
  'Wer bin ich?',
  'Monate und Wochentage',
  'Österreich-Reise',
};

String _norm(String value) => value
    .toLowerCase()
    .replaceAll('direkt ', '')
    .replaceAll(RegExp('[^a-zäöüß0-9 ]'), '')
    .trim();

void main() {
  final banks = <int, List<_Seen>>{
    for (var grade = 1; grade <= 4; grade++) grade: _bank(grade),
  };
  // Höhere Klassen wiederholen manchmal Fragen früherer Klassen; jede Frage
  // zählt hier nur einmal.
  final all = <String, _Seen>{
    for (final question in banks.values.expand((bank) => bank))
      '${question.prompt}|${question.answer}': question,
  }.values.toList();

  test('jede Sachfrage hat vier verschiedene Antworten, genau eine richtig',
      () {
    expect(all.length, greaterThanOrEqualTo(240));
    for (final question in all) {
      final reason = 'Klasse ${question.grade} ${question.unit}: '
          '${question.prompt} ${question.choices}';
      expect(question.choices, hasLength(4), reason: reason);
      expect(question.choices.map(_norm).toSet(), hasLength(4), reason: reason);
      expect(question.choices.where((choice) => choice == question.answer),
          hasLength(1),
          reason: reason);
      expect(question.explanation.trim(), isNotEmpty, reason: reason);
      expect(question.prompt.trim().endsWith('?'), isTrue, reason: reason);
    }
  });

  test('keine Frage kommt in einer Klasse doppelt vor', () {
    banks.forEach((grade, bank) {
      final prompts = <String, String>{};
      for (final question in bank.where((q) => q.grade == grade)) {
        final key = _norm(question.prompt);
        expect(prompts.containsKey(key), isFalse,
            reason: 'Klasse $grade doppelt: ${question.prompt}');
        prompts[key] = question.prompt;
      }
    });
  });

  test('gemeldete Dubletten und Wiederholungen sind ersetzt', () {
    final prompts = all.map((question) => question.prompt).toSet();
    for (final gone in <String>[
      'Welcher Tag kommt nach Montag?',
      'Wer löscht Brände?',
      'Welches Organ pumpt Blut?',
      'Welcher große Fluss fließt durch Wien?',
      'Was ist eine Zeitleiste?',
      'Ein Kalenderjahr beginnt mit welchem Monat?',
      'Wer repariert häufig kaputte Wasserleitungen?',
      'Welche Hymne gehört zu Österreich?',
      'In welchem Bundesland liegt Gänserndorf?',
    ]) {
      expect(prompts, isNot(contains(gone)));
    }
  });

  test('Frost, Wolken, Stängel und Haut sind sachlich richtig', () {
    _Seen byPrompt(String prompt) =>
        all.firstWhere((question) => question.prompt == prompt);
    final frost = byPrompt('Was bedeutet Frost?');
    expect(frost.answer, 'Temperaturen unter 0 Grad');
    expect(frost.explanation, contains('0 Grad'));
    expect(all.any((q) => q.answer.contains('gefrorene Feuchtigkeit')), isFalse);
    expect(byPrompt('Woraus bestehen Wolken?').answer,
        'aus winzigen Wassertröpfchen');
    expect(all.any((q) => q.answer == 'Wasserdampf' && q.prompt.contains('Wolken')),
        isFalse);
    expect(byPrompt('Welcher Teil einer Blume trägt Blätter und Blüten?').answer,
        'Stängel');
    expect(byPrompt('Was bedeckt und schützt deinen ganzen Körper?').answer,
        'die Haut');
    expect(byPrompt('Was zeigt ein Säulendiagramm?').answer, 'Werte als Säulen');
    expect(byPrompt('Was braucht ein einfacher Stromkreis?').answer,
        'Batterie, Kabel und Lampe');
  });

  test('Natur- und Ernährungsfragen haben keine albernen Ablenker', () {
    const sillyInNature = <String>{
      'Hammer', 'Schuh', 'Kabel', 'Sackerl', 'Fernseher', 'Schere', 'Helm',
      'Rad', 'Ball', 'Auto', 'Steine', 'Plastik', 'Batterien', 'Reifen',
      'Buch', 'Münze', 'Knopf', 'Topf', 'Tisch', 'Heft', 'Lampe',
    };
    const sillyPlaces = <String>{
      'im Topfen', 'im Federpennal', 'im Heft', 'im Schuh', 'im Bus',
      'im Glas', 'in ein Heft', 'in eine Lampe', 'in ein Sackerl',
    };
    for (final question in all) {
      final wrong =
          question.choices.where((choice) => choice != question.answer);
      if (<String>{'Pflanzen', 'Ernährung', 'Tag und Nacht', 'Wetter'}
          .contains(question.unit)) {
        expect(wrong.where(sillyInNature.contains), isEmpty,
            reason: question.prompt);
      }
      expect(wrong.where(sillyPlaces.contains), isEmpty,
          reason: question.prompt);
    }
  });

  test('Berufsfragen: alle Antworten sind gleich gebaut', () {
    final jobs = all.where((question) => question.unit == 'Berufe');
    expect(jobs, isNotEmpty);
    for (final question in jobs) {
      if (!question.answer.contains(' oder ')) continue;
      expect(question.choices.every((choice) => choice.contains(' oder ')),
          isTrue,
          reason: '${question.prompt} ${question.choices}');
    }
    for (final maleOnly in <String>['Maurer', 'Schlosser', 'ein Installateur']) {
      expect(all.any((question) => question.answer == maleOnly), isFalse,
          reason: maleOnly);
    }
  });

  test('Verkehr nennt Schutzweg und die Begleitregel beim Radfahren', () {
    final traffic = all.where((question) => question.unit == 'Verkehr');
    expect(
        traffic.any((question) =>
            '${question.answer} ${question.explanation}'.contains('Schutzweg')),
        isTrue);
    final turning = traffic.where((question) =>
        question.prompt.contains('abbiegen') &&
        (question.prompt.contains('Rad') || question.prompt.contains('Fahrrad')));
    expect(turning, hasLength(2));
    for (final question in turning) {
      expect(question.explanation, contains('Begleitperson'),
          reason: question.prompt);
      expect(question.explanation, contains('Radfahrausweis'),
          reason: question.prompt);
    }
  });

  test('Kindersprache: keine „Betreuungsperson“, kein „Antarktika“', () {
    for (final question in all) {
      final text = '${question.prompt} ${question.choices.join(' ')} '
          '${question.explanation}';
      expect(text.contains('Betreuungsperson'), isFalse, reason: text);
      expect(text.contains('Antarktika'), isFalse, reason: text);
    }
  });

  test('Klasse 2: jede Einheit hat mindestens 12 eigene Fragen (S-M15)', () {
    final own = <String, int>{};
    for (final question in banks[2]!.where((q) => q.grade == 2)) {
      own[question.unit] = (own[question.unit] ?? 0) + 1;
    }
    expect(own.keys.toSet(), <String>{
      'Zeit und Kalender',
      'Verkehr',
      'Berufe',
      'Körper',
      'Familie und Gemeinschaft',
      'Wetter',
      'Pflanzen',
      'Tiere',
      'Jahreszeiten',
    });
    own.forEach((unit, count) {
      expect(count, greaterThanOrEqualTo(12), reason: unit);
    });
    // Eine Klasse-2-Einheit wird nicht mehr mit Klasse-1-Fragen aufgefüllt.
    for (final unit in own.keys) {
      final factory = ExerciseFactory(seed: 5);
      for (var i = 0; i < 60; i++) {
        final task =
            factory.next(grade: 2, subject: 'Sachunterricht', unit: unit);
        expect(task.difficulty, 2, reason: '$unit: ${task.prompt}');
      }
    }
  });

  test('Notrufnummern: Feuerwehr 122, Polizei 133, Rettung 144', () {
    String answerTo(String part) =>
        all.firstWhere((question) => question.prompt.contains(part)).answer;
    expect(answerTo('Nummer hat die Feuerwehr'), '122');
    expect(answerTo('die Polizei brauchst'), '133');
    expect(answerTo('die Rettung braucht'), '144');
  });

  test('Diagramme lesen: das Diagramm steht in der Aufgabe (S-M14)', () {
    final factory = ExerciseFactory(seed: 14);
    final drawn = <String>{};
    for (var i = 0; i < 400; i++) {
      final task = factory.next(
          grade: 4, subject: 'Sachunterricht', unit: 'Diagramme lesen');
      if (task.unit != 'Diagramme lesen') continue;
      expect(task.prompt, isNot(contains('Ein Diagramm zeigt 8')));
      if (task.prompt.startsWith('Lies das Diagramm.')) {
        // Mindestens zwei Reihen aus Kästchen, die Werte selbst stehen
        // nicht als Zahl im Text.
        final rows = task.prompt
            .split('\n')
            .where((line) => line.contains(': 🟦'))
            .toList();
        expect(rows.length, greaterThanOrEqualTo(2), reason: task.prompt);
        for (final row in rows) {
          expect(row, isNot(matches(RegExp(r'\d+$'))), reason: row);
        }
        drawn.add(task.prompt);
      }
    }
    expect(drawn.length, greaterThanOrEqualTo(4));
  });
}
