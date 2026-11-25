import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_tutor_contracts.dart';
import 'package:lumo_lernen/core/lumo_tutor_engine.dart';

LumoTutorRequest languageRequest({
  required String unit,
  required String prompt,
  required String answer,
  LumoTutorSubject subject = LumoTutorSubject.deutsch,
  LumoTutorHelpLevel level = LumoTutorHelpLevel.hintOnly,
  LumoTutorMode mode = LumoTutorMode.miniLesson,
}) =>
    LumoTutorRequest(
      mode: mode,
      subject: subject,
      grade: 1,
      unit: unit,
      currentPrompt: prompt,
      correctAnswer: answer,
      helpLevel: level,
    );

void main() {
  const engine = LumoTutorEngine();

  test('sound help uses sounds, not the unrelated word-type instruction', () {
    final response = engine.buildLocalFallback(languageRequest(
      unit: 'Anfangslaute',
      prompt: 'Mit welchem Laut beginnt Maus?',
      answer: 'M',
    ));
    expect(response.speech, contains('ersten Laut'));
    expect(response.shortHint, isNot(contains('Wortart')));
  });

  test('syllable help changes with the requested support level', () {
    final speeches = <String>{};
    for (final level in [
      LumoTutorHelpLevel.hintOnly,
      LumoTutorHelpLevel.guidedStep,
      LumoTutorHelpLevel.visualExplanation,
    ]) {
      final response = engine.buildLocalFallback(languageRequest(
        unit: 'Silben',
        prompt: 'Wie viele Silben hat Banane?',
        answer: '3',
        level: level,
      ));
      speeches.add(response.speech);
      expect(response.speech.toLowerCase(), contains('silben'));
      expect(response.speech, isNot(contains('3')));
      if (level == LumoTutorHelpLevel.hintOnly) {
        expect(response.visualPlan.type, LumoTutorVisualType.none);
      } else {
        expect(response.visualPlan.parts, ['Ba', 'na', 'ne']);
      }
    }
    expect(speeches, hasLength(3));
  });

  test('unknown syllable splitting is not rendered as an empty word lesson', () {
    final response = engine.buildLocalFallback(languageRequest(
      unit: 'Silben',
      prompt: 'Wie viele Silben hat Mondsonde?',
      answer: '3',
      level: LumoTutorHelpLevel.visualExplanation,
    ));
    expect(response.visualPlan.type, LumoTutorVisualType.none);
    expect(response.speech.toLowerCase(), contains('silben'));
  });

  test('picture reading keeps three methods tied to the picture, without answer',
      () {
    final speeches = <String>{};
    for (final level in [
      LumoTutorHelpLevel.hintOnly,
      LumoTutorHelpLevel.guidedStep,
      LumoTutorHelpLevel.visualExplanation,
    ]) {
      final response = engine.buildLocalFallback(languageRequest(
        subject: LumoTutorSubject.lesen,
        unit: 'Bild und Wort',
        prompt: 'Schau genau: 🐸\nWelches Wort passt zu diesem Bild?',
        answer: 'Frosch',
        level: level,
      ));
      speeches.add(response.speech);
      expect(response.speech, contains('Bild'));
      expect(response.speech, isNot(contains('Frosch')));
      expect(response.speech, isNot(contains('Textstelle')));
    }
    expect(speeches, hasLength(3));
  });

  test('word reading compares meaning and spelling instead of inventing a text',
      () {
    final response = engine.buildLocalFallback(languageRequest(
      subject: LumoTutorSubject.lesen,
      unit: 'Woerter lesen',
      prompt: 'Lies: Dieses Tier bellt.\nWelches Wort passt?',
      answer: 'Hund',
      level: LumoTutorHelpLevel.visualExplanation,
    ));
    expect(response.speech, contains('Buchstabe für Buchstabe'));
    expect(response.speech, contains('Beschreibung'));
    expect(response.speech, isNot(contains('Hund')));
  });

  test('passage comprehension uses the existing evidence-seeking help', () {
    final response = engine.buildLocalFallback(languageRequest(
      subject: LumoTutorSubject.lesen,
      unit: 'Lesesinn',
      prompt: 'Lena nimmt ihren roten Ball mit. Was nimmt Lena mit?',
      answer: 'ihren roten Ball',
      level: LumoTutorHelpLevel.visualExplanation,
    ));
    expect(response.speech, contains('im Text eine Stelle'));
    expect(response.speech, isNot(contains('roten Ball')));
  });

  test('test mode suppresses the new language assistance', () {
    final response = engine.buildLocalFallback(languageRequest(
      subject: LumoTutorSubject.lesen,
      unit: 'Bild und Wort',
      prompt: 'Welches Wort passt?',
      answer: 'Hund',
      mode: LumoTutorMode.testReview,
      level: LumoTutorHelpLevel.visualExplanation,
    ));
    expect(response.shortHint, 'Auswertung nach dem Test');
    expect(response.visualPlan.type, LumoTutorVisualType.none);
  });

  test('a matching wrong operation receives the existing task-bound explanation',
      () {
    final response = engine.buildLocalFallback(const LumoTutorRequest(
      mode: LumoTutorMode.mistakeExplanation,
      subject: LumoTutorSubject.mathematik,
      grade: 1,
      unit: 'Plus bis 10',
      helpLevel: LumoTutorHelpLevel.guidedStep,
      currentPrompt: '7 + 2 = ?',
      correctAnswer: '9',
      childAnswer: '5',
      attemptCount: 2,
    ));
    expect(response.speech, contains('Plus und Minus'));
    expect(response.speech, isNot(contains('9')));
  });

  test('an unrelated wrong answer does not get a claimed cause', () {
    final response = engine.buildLocalFallback(const LumoTutorRequest(
      mode: LumoTutorMode.mistakeExplanation,
      subject: LumoTutorSubject.mathematik,
      grade: 1,
      unit: 'Plus bis 10',
      helpLevel: LumoTutorHelpLevel.guidedStep,
      currentPrompt: '7 + 2 = ?',
      correctAnswer: '9',
      childAnswer: '80',
      attemptCount: 2,
    ));
    expect(response.speech, contains('Starte bei 7'));
    expect(response.speech, isNot(contains('verwechselt')));
  });
}
