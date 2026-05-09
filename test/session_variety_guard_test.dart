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

    test('builds separator-safe persistent markers for exact and family repeats', () {
      final guard = SessionVarietyGuard();
      final first = task(
        prompt: 'Lumo hat 12 Sterne und bekommt 3 dazu.',
        answer: '15',
        choices: const <String>['15', '14', '16'],
        unit: 'Plus bis 20',
      );
      final nearRepeat = task(
        prompt: 'Lumo hat 7 Blumen und bekommt 2 dazu.',
        answer: '15',
        choices: const <String>['16', '15', '14'],
        unit: 'Plus bis 20',
      );

      final firstKeys = guard.taskMemoryKeys(first);
      final repeatKeys = guard.taskMemoryKeys(nearRepeat);

      expect(firstKeys, hasLength(2));
      expect(firstKeys.every((key) => !key.contains('|')), isTrue);
      expect(firstKeys.first, startsWith('task-'));
      expect(firstKeys.last, startsWith('family-'));
      expect(firstKeys.first, isNot(repeatKeys.first));
      expect(firstKeys.last, repeatKeys.last);
    });

    test('task key includes mission tag and writing target', () {
      final guard = SessionVarietyGuard();
      final normal = task(
        prompt: 'Schreibe: Mama',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
      );
      final handwriting = LumoTask(
        id: 'write-id',
        grade: 1,
        subject: 'Schreiben',
        unit: 'Wort schreiben',
        prompt: 'Schreibe: Mama',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Test',
        handwriting: true,
        missionTag: 'writing-a',
      );
      final otherTarget = LumoTask(
        id: 'write-id',
        grade: 1,
        subject: 'Schreiben',
        unit: 'Wort schreiben',
        prompt: 'Schreibe: Papa',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Test',
        handwriting: true,
        missionTag: 'writing-a',
      );
      final otherMission = LumoTask(
        id: 'write-id',
        grade: 1,
        subject: 'Schreiben',
        unit: 'Wort schreiben',
        prompt: 'Schreibe: Mama',
        choices: const <String>['Fertig'],
        answer: 'Fertig',
        explanation: 'Test',
        handwriting: true,
        missionTag: 'writing-b',
      );

      expect(guard.taskKey(normal), isNot(guard.taskKey(handwriting)));
      expect(guard.taskKey(handwriting), isNot(guard.taskKey(otherTarget)));
      expect(guard.taskKey(handwriting), isNot(guard.taskKey(otherMission)));
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
