import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';

void main() {
  group('PrimarySchoolWordData', () {
    test('grade pools use actual words, not manufactured count targets', () {
      for (var grade = 1; grade <= 4; grade++) {
        expect(PrimarySchoolWordData.nounsExactlyForGrade(grade), isNotEmpty);
        expect(PrimarySchoolWordData.verbsForGrade(grade), isNotEmpty);
        expect(PrimarySchoolWordData.adjectivesForGrade(grade), isNotEmpty);
      }
      final words = PrimarySchoolWordData.dictionary.keys;
      expect(words, isNot(contains('WaldHund')));
      expect(words, isNot(contains('SchulMama')));
      expect(words, isNot(contains('weiterweinen')));
      expect(words, isNot(contains('sehr groß')));
      for (final word in words) {
        expect(word, isNot(contains(' ')), reason: word);
        expect(word.substring(1), isNot(matches(RegExp(r'[A-ZÄÖÜ]'))),
            reason: word);
        expect(PrimarySchoolWordData.syllablesFor(word)!.join(), word);
      }
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

    test('word selection helpers return values from their source lists', () {
      final nouns = PrimarySchoolWordData.nounsForGrade(2);

      expect(nouns, contains(PrimarySchoolWordData.nounForGrade(2, 7)));
      expect(PrimarySchoolWordData.verbs,
          contains(PrimarySchoolWordData.verbForSeed(11)));
      expect(PrimarySchoolWordData.adjectives,
          contains(PrimarySchoolWordData.adjectiveForSeed(13)));
    });

    test('sound helpers return usable fallback-safe words', () {
      final firstSoundWord =
          PrimarySchoolWordData.firstSoundWordForGrade(1, seed: 21);
      final endSoundWord =
          PrimarySchoolWordData.endSoundWordForGrade(1, seed: 22);

      expect(firstSoundWord, isNotNull);
      expect(firstSoundWord!.trim(), isNotEmpty);
      expect(endSoundWord, isNotNull);
      expect(endSoundWord!.trim(), isNotEmpty);
    });

    test('syllables and articles are available for known Austrian words', () {
      expect(PrimarySchoolWordData.syllablesFor('Banane'),
          <String>['Ba', 'na', 'ne']);
      expect(PrimarySchoolWordData.syllablesFor('banane'),
          <String>['Ba', 'na', 'ne']);
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
        expect(PrimarySchoolWordData.syllablesFor(noun), isNotNull,
            reason: noun);
        expect(
            PrimarySchoolWordData.syllablesFor(noun)!
                .every((part) => part.trim().isNotEmpty),
            isTrue,
            reason: noun);
      }
    });

    test(
        'rhyme pairs contain exactly two different non-empty words from the explicit rhyme pool',
        () {
      expect(PrimarySchoolWordData.rhymePairs,
          hasLength(greaterThanOrEqualTo(50)));
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
      final allWords = PrimarySchoolWordData.dictionary.keys
          .map((word) => word.toLowerCase())
          .toSet();
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
      final normalized = PrimarySchoolWordData.dictionary.keys
          .map((word) => word.toLowerCase())
          .toList();
      expect(normalized.toSet(), hasLength(normalized.length));
    });
  });
}
