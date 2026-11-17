// Fachprüfung 2026-11 (D-S3): Im Wortdetektiv stand "Beet" als falsche
// Schreibung von "Bett". Die Frage nennt das gesuchte Wort nicht, also waren
// zwei Antworten richtig geschrieben. Als falsche Schreibung dürfen nur echte
// Falschschreibungen stehen.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/adventure/adventure_word_data.dart';
import 'package:lumo_lernen/core/german_task_templates.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';

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
}
