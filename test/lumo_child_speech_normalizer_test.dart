import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_child_speech_normalizer.dart';

void main() {
  const normalizer = LumoChildSpeechNormalizer();

  group('LumoChildSpeechNormalizer', () {
    test('normalizes umlauts and number words', () {
      expect(normalizer.normalizeText('Ich glaube fünf.'), 'ich glaube 5');
      expect(normalizer.normalizeText('ZWÖLF Sterne'), '12 sterne');
    });

    test('matches exact spoken choice', () {
      final match = normalizer.normalizeAnswer(
        spokenText: 'drei',
        choices: <String>['2', '3', '4'],
      );

      expect(match.matchedChoice, '3');
      expect(match.needsConfirmation, isFalse);
    });

    test('matches answer embedded in child sentence', () {
      final match = normalizer.normalizeAnswer(
        spokenText: 'Ich glaube es ist drei',
        choices: <String>['2', '3', '4'],
      );

      expect(match.matchedChoice, '3');
      expect(match.confidence, greaterThan(.8));
    });

    test('asks for confirmation for loose word matches', () {
      final match = normalizer.normalizeAnswer(
        spokenText: 'bana',
        choices: <String>['Banane', 'Rose', 'Maus'],
      );

      expect(match.matchedChoice, 'Banane');
      expect(match.needsConfirmation, isTrue);
    });

    test('asks for confirmation when no choice is understood', () {
      final match = normalizer.normalizeAnswer(
        spokenText: 'weiss ich nicht',
        choices: <String>['Hund', 'Katze'],
      );

      expect(match.hasMatch, isFalse);
      expect(match.needsConfirmation, isTrue);
    });
  });
}
