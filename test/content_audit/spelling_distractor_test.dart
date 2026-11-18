// Fachprüfung 2026-11 (D-S3): Im Wortdetektiv stand "Beet" als falsche
// Schreibung von "Bett". Die Frage nennt das gesuchte Wort nicht, also waren
// zwei Antworten richtig geschrieben. Als falsche Schreibung dürfen nur echte
// Falschschreibungen stehen.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/adventure/adventure_word_data.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/spelling_context_data.dart';

/// Prüfliste: echte deutsche Wörter (auch Namen), die einer Falschschreibung
/// zum Verwechseln ähnlich sehen. Wird bei neuen Wortlisten ergänzt.
const realLookalikes = <String>{
  'Beet', 'Bett', 'Lid', 'Lied', 'Baal', 'Ball', 'Sohne', 'Söhne', 'Becker',
  'Ur', 'Uhr', 'Ofen', 'offen', 'Mine', 'Miene', 'Wal', 'Wahl', 'Mal', 'Mahl',
  'war', 'wahr', 'Meer', 'mehr', 'Seite', 'Saite', 'Leib', 'Laib', 'Lerche',
  'Lärche', 'Stil', 'Stiel', 'wieder', 'wider', 'Boot', 'bot', 'Rad', 'Rat',
  'bald', 'Feld', 'fällt', 'Held', 'hält', 'Stadt', 'statt', 'seit', 'seid',
  'Bund', 'bunt', 'Hüte', 'Hütte', 'Miete', 'Mitte', 'Rate', 'Ratte', 'Riese',
  'Risse', 'Schal', 'Schall', 'fühlen', 'füllen', 'Höhle', 'Hölle', 'Kahn',
  'kann', 'Wahn', 'wann', 'Bahn', 'Bann', 'den', 'denn', 'wen', 'wenn', 'in',
  'ihn', 'im', 'ihm', 'Mann', 'man', 'das', 'dass', 'ist', 'isst', 'fast',
  'fasst', 'Rose', 'Rosse', 'Wiese', 'Hase', 'hasse', 'Nase', 'nasse', 'lasen',
  'lassen', 'Ruhm', 'Rum', 'Lehre', 'leere', 'Leere', 'Moor', 'Mohr', 'Ware',
  'wahre', 'Wagen', 'Waagen', 'Waage', 'Wange', 'Wanne', 'Tor', 'Tür', 'Tier',
  'Tee', 'See', 'Fee', 'Reh', 'Zeh', 'Schnee', 'Kamm', 'kam', 'Lamm', 'lahm',
  'Schiff', 'schief', 'still', 'Stiehl', 'Polen', 'Pollen', 'Ton', 'Tonne',
  'Sonne', 'Sohn', 'Hof', 'hoffe', 'Rasen', 'Rassen', 'Masse', 'Maße', 'Muse',
  'Muße', 'Buße', 'Busse', 'Fuß', 'Fluss', 'Floß', 'reisen', 'reißen',
  'weise', 'weiße', 'Weise', 'Waise', 'heiser', 'heißer', 'Biss', 'bis',
};

void main() {
  final realWords = <String>{
    ...realLookalikes,
    ...PrimarySchoolWordData.dictionary.keys,
    for (final item in adventureSpellings) item.correct,
  };

  void expectOnlyMisspellings(
      String correct, Iterable<String> wrong, String source) {
    for (final option in wrong) {
      expect(option, isNot(correct), reason: source);
      expect(realWords.contains(option), isFalse,
          reason: '$source: „$option“ ist ein richtig geschriebenes Wort und '
              'darf nicht als falsche Schreibung von „$correct“ stehen.');
    }
    expect(wrong.toSet().length, wrong.length, reason: source);
  }

  test('Wortdetektiv bietet als falsche Schreibung keine echten Wörter an', () {
    expect(adventureSpellings, isNotEmpty);
    for (final item in adventureSpellings) {
      expectOnlyMisspellings(item.correct, item.wrong, 'Wortdetektiv');
    }
    final bett =
        adventureSpellings.firstWhere((item) => item.correct == 'Bett');
    expect(bett.wrong, isNot(contains('Beet')));
  });

  test('„ie oder i“ bietet keine echten Wörter als falsche Schreibung an', () {
    final template = GermanTaskTemplates.templates
        .firstWhere((template) => template.id == 'g3_ie_or_i');
    final seen = <String>{};
    for (var seed = 0; seed < 400; seed++) {
      final task = template.concretize(seed);
      seen.add(task.answer);
      expectOnlyMisspellings(
          task.answer,
          task.choices.where((choice) => choice != task.answer),
          'ie oder i');
    }
    expect(seen.length, greaterThanOrEqualTo(20));
  });

  test('Rechtschreibfragen ohne Satz bieten nur echte Falschschreibungen an',
      () {
    var checked = 0;
    for (var grade = 1; grade <= 4; grade++) {
      for (final unit in <String>['Haeufige Woerter', 'Dehnungen']) {
        final factory = ExerciseFactory(seed: 100 + grade);
        for (var i = 0; i < 400; i++) {
          final task = factory.next(
              grade: grade, subject: 'Rechtschreibung', unit: unit);
          if (task.prompt != 'Welche Schreibweise ist richtig?') continue;
          checked++;
          expectOnlyMisspellings(
              task.answer,
              task.choices.where((choice) => choice != task.answer),
              '$unit Klasse $grade');
        }
      }
    }
    expect(checked, greaterThan(100));
  });

  test('Kontextsätze: falsche Schreibungen sind keine echten Wörter', () {
    for (final context in spellingContexts) {
      if (context.unit == 'Satzzeichen') continue;
      expect(context.sentence, contains('___'), reason: context.sentence);
      expectOnlyMisspellings(
          context.answer, context.wrong, 'Satz „${context.sentence}“');
    }
  });

  test('Häufige Wörter: jede Klasse übt eigene Wörter (D-M9)', () {
    for (var grade = 2; grade <= 4; grade++) {
      final own = spellingContexts
          .where((context) =>
              context.unit == 'Haeufige Woerter' && context.grade == grade)
          .map((context) => context.answer)
          .toSet();
      expect(own.length, greaterThanOrEqualTo(12), reason: 'Klasse $grade');
      final earlier = spellingContexts
          .where((context) =>
              context.unit == 'Haeufige Woerter' && context.grade < grade)
          .map((context) => context.answer)
          .toSet();
      final factory = ExerciseFactory(seed: 300 + grade);
      for (var i = 0; i < 300; i++) {
        final task = factory.next(
            grade: grade, subject: 'Rechtschreibung', unit: 'Haeufige Woerter');
        if (!task.prompt.contains('___')) continue;
        expect(earlier, isNot(contains(task.answer)),
            reason: 'Klasse $grade bekommt das Wort einer früheren Klasse: '
                '${task.answer}');
        expect(own, contains(task.answer));
      }
    }
  });

  test('Häufige Wörter Klasse 4: echte Klasse-4-Wörter, auch ohne Satz', () {
    final own = spellingContexts
        .where((context) =>
            context.unit == 'Haeufige Woerter' && context.grade == 4)
        .map((context) => context.answer)
        .toSet();
    expect(own.length, greaterThanOrEqualTo(24));
    final lowerGrades = spellingContexts
        .where((context) =>
            context.unit == 'Haeufige Woerter' && context.grade <= 2)
        .map((context) => context.answer)
        .toSet()
      ..addAll(<String>['Fahrrad', 'Haus', 'Ball', 'Sonne', 'Katze']);
    final factory = ExerciseFactory(seed: 404);
    final answers = <String>{};
    for (var i = 0; i < 600; i++) {
      final task = factory.next(
          grade: 4, subject: 'Rechtschreibung', unit: 'Haeufige Woerter');
      answers.add(task.answer);
      expect(lowerGrades, isNot(contains(task.answer)), reason: task.prompt);
    }
    expect(answers.length, greaterThanOrEqualTo(26));
  });

  test('Doppelmitlaut und Dehnungen: Klasse 3 und 4 üben eigene Wörter (D-M9)',
      () {
    for (final unit in <String>['Doppelmitlaut', 'Dehnungen']) {
      for (var grade = 3; grade <= 4; grade++) {
        final own = spellingContexts
            .where((c) => c.unit == unit && c.grade == grade)
            .map((c) => c.answer)
            .toSet();
        expect(own.length, greaterThanOrEqualTo(12), reason: '$unit $grade');
        final factory = ExerciseFactory(seed: 500 + grade);
        for (var i = 0; i < 200; i++) {
          final task = factory.next(
              grade: grade, subject: 'Rechtschreibung', unit: unit);
          // Kontextsätze stammen aus der eigenen Klasse; die feste Wortliste
          // (ein Viertel der Aufgaben) bleibt Wiederholung.
          if (!task.prompt.endsWith('Welche Schreibweise passt in die Lücke?')) {
            continue;
          }
          expect(own, contains(task.answer), reason: '$unit $grade');
        }
      }
    }
  });

  test('Wortende: der Verwechslungspartner steht immer zur Wahl (D-M8)', () {
    const partners = <String, String>{
      'd': 't', 't': 'd', 'g': 'k', 'k': 'g', 'b': 'p', 'p': 'b',
    };
    final factory = ExerciseFactory(seed: 77);
    final answers = <String>{};
    for (var i = 0; i < 400; i++) {
      final task =
          factory.next(grade: 2, subject: 'Rechtschreibung', unit: 'Wortende');
      answers.add(task.answer);
      expect(task.choices, contains(partners[task.answer]),
          reason: '${task.prompt} ${task.choices}');
      expect(task.choices, hasLength(4));
      expect(task.prompt.contains('Stad_'), isFalse);
    }
    expect(answers, containsAll(<String>['d', 't', 'g', 'k', 'b']));
  });

  test('St oder Sp: das Wort steht nicht mehr in der Frage (D-M11)', () {
    final factory = ExerciseFactory(seed: 78);
    final answers = <String>{};
    for (var i = 0; i < 300; i++) {
      final task = factory.next(
          grade: 2, subject: 'Rechtschreibung', unit: 'St oder Sp');
      if (!task.prompt.contains('Wortanfang')) continue;
      answers.add(task.answer);
      final rest = RegExp(r'__(\S+)$').firstMatch(task.prompt)!.group(1)!;
      final word = '${task.answer}$rest';
      expect(task.prompt.contains(word), isFalse, reason: task.prompt);
      expect(task.explanation, contains(word));
      expect(task.choices.toSet(), <String>{'St', 'Sp', 'Sch'});
    }
    expect(answers, <String>{'St', 'Sp', 'Sch'});
  });
}
