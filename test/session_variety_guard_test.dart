import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/session_variety_guard.dart';

void main() {
  LumoTask task({
    String prompt = 'Mit welchem Laut beginnt Sonne?',
    String answer = 'S',
    List<String> choices = const <String>['S', 'M', 'F'],
    String unit = 'Anfangslaute',
  }) {
    return LumoTask(
      id: 'test-id',
      grade: 1,
      subject: 'Deutsch',
      unit: unit,
      prompt: prompt,
      choices: choices,
      answer: answer,
      explanation: 'Test',
    );
  }

  group('SessionVarietyGuard', () {
    test('allows a new task and blocks the same task after remembering it', () {
      final guard = SessionVarietyGuard();
      final first = task();

      expect(guard.allows(first), isTrue);
      guard.remember(first);
      expect(guard.allows(first), isFalse);
    });

    test('blocks repeated answers during strict checks', () {
      final guard = SessionVarietyGuard();
      guard.remember(task(answer: 'S'));

      final repeatedAnswer = task(
        prompt: 'Mit welchem Laut beginnt Salat?',
        answer: 'S',
        choices: const <String>['S', 'A', 'M'],
      );

      expect(guard.allows(repeatedAnswer), isFalse);
      expect(guard.allows(repeatedAnswer, relaxed: true), isTrue);
    });

    test('blocks repeated significant words from prompts', () {
      final guard = SessionVarietyGuard();
      guard.remember(task(prompt: 'Wie viele Silben hat Banane?', answer: '3'));

      final repeatedWord = task(
        prompt: 'Schreibe das Wort Banane.',
        answer: 'Fertig',
        choices: const <String>['Fertig'],
        unit: 'Wort schreiben',
      );

      expect(guard.allows(repeatedWord), isFalse);
    });

    test('normalizes prompt patterns by replacing numbers and long words', () {
      final guard = SessionVarietyGuard();

      expect(
        guard.promptPattern('Lumo hat 12 Sterne und bekommt 3 dazu.'),
        guard.promptPattern('Lumo hat 7 Blumen und bekommt 2 dazu.'),
      );
    });

    test('reset clears remembered session state', () {
      final guard = SessionVarietyGuard();
      final first = task();

      guard.remember(first);
      expect(guard.allows(first), isFalse);

      guard.reset();
      expect(guard.allows(first), isTrue);
    });
  });
}
