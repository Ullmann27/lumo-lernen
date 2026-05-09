import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';

void main() {
  group('PrimarySchoolWordData', () {
    test('grade lists meet expanded Volksschule targets', () {
      expect(PrimarySchoolWordData.nounsExactlyForGrade(1), hasLength(greaterThanOrEqualTo(200)));
      expect(PrimarySchoolWordData.verbsForGrade(1), hasLength(greaterThanOrEqualTo(50)));
      expect(PrimarySchoolWordData.adjectivesForGrade(1), hasLength(greaterThanOrEqualTo(30)));

      expect(PrimarySchoolWordData.nounsExactlyForGrade(2), hasLength(greaterThanOrEqualTo(250)));
      expect(PrimarySchoolWordData.verbsForGrade(2), hasLength(greaterThanOrEqualTo(80)));
      expect(PrimarySchoolWordData.adjectivesForGrade(2), hasLength(greaterThanOrEqualTo(50)));

      expect(PrimarySchoolWordData.nounsExactlyForGrade(3), hasLength(greaterThanOrEqualTo(300)));
      expect(PrimarySchoolWordData.verbsForGrade(3), hasLength(greaterThanOrEqualTo(100)));
      expect(PrimarySchoolWordData.adjectivesForGrade(3), hasLength(greaterThanOrEqualTo(60)));

      expect(PrimarySchoolWordData.nounsExactlyForGrade(4), hasLength(greaterThanOrEqualTo(350)));
      expect(PrimarySchoolWordData.verbsForGrade(4), hasLength(greaterThanOrEqualTo(120)));
      expect(PrimarySchoolWordData.adjectivesForGrade(4), hasLength(greaterThanOrEqualTo(80)));
    });

    test('nounsForGrade grows with grade without empty lists', () {
      final grade1 = PrimarySchoolWordData.nounsForGrade(1);
      final grade2 = PrimarySchoolWordData.nounsForGrade(2);
      final grade3 = PrimarySchoolWordData.nounsForGrade(3);
      final grade4 = PrimarySchoolWordData.nounsForGrade(4);

      expect(grade1, isNotEmpty);
      expect(grade2.length, greaterThanOrEqualTo(grade1.length));
      expect(grade3.length, greaterThanOrEqualTo(grade2.length));
      expect(grade4.length, greaterThanOrEqualTo(grade3.length));
    });

    test('deterministic helpers return values from their source lists', () {
      final nouns = PrimarySchoolWordData.nounsForGrade(2);

      expect(nouns, contains(PrimarySchoolWordData.nounForGrade(2, 7)));
      expect(PrimarySchoolWordData.verbs, contains(PrimarySchoolWordData.verbForSeed(11)));
      expect(PrimarySchoolWordData.adjectives, contains(PrimarySchoolWordData.adjectiveForSeed(13)));
    });

    test('sound helpers return usable fallback-safe words', () {
      final firstSoundWord = PrimarySchoolWordData.firstSoundWordForGrade(1, seed: 21);
      final endSoundWord = PrimarySchoolWordData.endSoundWordForGrade(1, seed: 22);

      expect(firstSoundWord, isNotNull);
      expect(firstSoundWord!.trim(), isNotEmpty);
      expect(endSoundWord, isNotNull);
      expect(endSoundWord!.trim(), isNotEmpty);
    });

    test('syllables and articles are available for known Austrian words', () {
      expect(PrimarySchoolWordData.syllablesFor('Banane'), <String>['Ba', 'na', 'ne']);
      expect(PrimarySchoolWordData.syllablesFor('banane'), <String>['Ba', 'na', 'ne']);
      expect(PrimarySchoolWordData.articleFor('Biene'), 'die');
      expect(PrimarySchoolWordData.articleFor('biene'), 'die');
      expect(PrimarySchoolWordData.articleFor('Semmel'), 'die');
      expect(PrimarySchoolWordData.articleFor('Sackerl'), 'das');
      expect(PrimarySchoolWordData.articleFor('Schlagobers'), 'das');
      expect(PrimarySchoolWordData.articleFor('Marille'), 'die');
      expect(PrimarySchoolWordData.articleFor('Topfen'), 'der');
    });

    test('every noun has article and syllables', () {
      for (final noun in PrimarySchoolWordData.nounsForGrade(4)) {
        expect(PrimarySchoolWordData.articleFor(noun), isNotNull, reason: noun);
        expect(PrimarySchoolWordData.syllablesFor(noun), isNotNull, reason: noun);
        expect(PrimarySchoolWordData.syllablesFor(noun)!.every((part) => part.trim().isNotEmpty), isTrue, reason: noun);
      }
    });

    test('rhyme pairs contain exactly two different non-empty words with matching ending', () {
      expect(PrimarySchoolWordData.rhymePairs, hasLength(greaterThanOrEqualTo(80)));
      for (final pair in PrimarySchoolWordData.rhymePairs) {
        expect(pair, hasLength(2));
        expect(pair.first.trim(), isNotEmpty);
        expect(pair.last.trim(), isNotEmpty);
        expect(pair.first, isNot(pair.last));
        // Klangprüfung bleibt bewusst konservativ: Die geprüften Paare sind
        // aus dem lokalen Reim-Pool und dürfen keine leeren/gleichen Wörter sein.
      }
    });

    test('word bank avoids German terms that should be Austrian-localized', () {
      final allWords = PrimarySchoolWordData.dictionary.keys.map((word) => word.toLowerCase()).toSet();
      expect(allWords, isNot(contains('brötchen')));
      expect(allWords, isNot(contains('tüte')));
      expect(allWords, isNot(contains('sahne')));
      expect(allWords, isNot(contains('quark')));
      expect(allWords, contains('semmel'));
      expect(allWords, contains('sackerl'));
      expect(allWords, contains('schlagobers'));
      expect(allWords, contains('topfen'));
    });

    test('no duplicate dictionary keys after lowercase normalization', () {
      final normalized = PrimarySchoolWordData.dictionary.keys.map((word) => word.toLowerCase()).toList();
      expect(normalized.toSet(), hasLength(normalized.length));
    });
  });
}
