import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/primary_school_word_data.dart';

void main() {
  group('PrimarySchoolWordData', () {
    test('nounsForGrade grows with grade without empty lists', () {
      final grade1 = PrimarySchoolWordData.nounsForGrade(1);
      final grade2 = PrimarySchoolWordData.nounsForGrade(2);
      final grade3 = PrimarySchoolWordData.nounsForGrade(3);

      expect(grade1, isNotEmpty);
      expect(grade2.length, greaterThanOrEqualTo(grade1.length));
      expect(grade3.length, greaterThanOrEqualTo(grade2.length));
    });

    test('deterministic helpers return values from their source lists', () {
      final nouns = PrimarySchoolWordData.nounsForGrade(2);

      expect(nouns, contains(PrimarySchoolWordData.nounForGrade(2, 7)));
      expect(PrimarySchoolWordData.verbs, contains(PrimarySchoolWordData.verbForSeed(11)));
      expect(
        PrimarySchoolWordData.adjectives,
        contains(PrimarySchoolWordData.adjectiveForSeed(13)),
      );
    });

    test('sound helpers return usable fallback-safe words', () {
      final firstSoundWord = PrimarySchoolWordData.firstSoundWordForGrade(1, seed: 21);
      final endSoundWord = PrimarySchoolWordData.endSoundWordForGrade(1, seed: 22);

      expect(firstSoundWord, isNotNull);
      expect(firstSoundWord!.trim(), isNotEmpty);
      expect(endSoundWord, isNotNull);
      expect(endSoundWord!.trim(), isNotEmpty);
    });

    test('syllables and articles are available for known words', () {
      expect(PrimarySchoolWordData.syllablesFor('Banane'), <String>['Ba', 'na', 'ne']);
      expect(PrimarySchoolWordData.syllablesFor('banane'), <String>['Ba', 'na', 'ne']);
      expect(PrimarySchoolWordData.articleFor('Biene'), 'die');
      expect(PrimarySchoolWordData.articleFor('biene'), 'die');
    });

    test('rhyme pairs always contain exactly two non-empty words', () {
      final pair = PrimarySchoolWordData.rhymePairForSeed(42);

      expect(pair, hasLength(2));
      expect(pair.first.trim(), isNotEmpty);
      expect(pair.last.trim(), isNotEmpty);
      expect(pair.first, isNot(pair.last));
    });
  });
}
