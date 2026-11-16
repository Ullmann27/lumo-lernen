import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';

NativeLearningActivity? pattern({
  Object? sequence = const ['Kreis', 'Dreieck', 'Kreis', 'Dreieck'],
  Object? choices = const ['Kreis', 'Dreieck', 'Quadrat'],
  Object? period = 2,
  Object? expected = 'Kreis',
}) =>
    NativeLearningActivity.fromPattern(
      sequence: sequence,
      choices: choices,
      period: period,
      expected: expected,
    );

void main() {
  test('current domain choices and minimal group reach native pattern scene',
      () {
    final task = TaskInstance(
      taskInstanceId: 'existing-pattern-task',
      templateId: 'existing-pattern-template',
      childId: 'synthetic-child',
      seedHash: 'pattern-seed',
      subject: LearningSubject.logik,
      skillId: const SkillId('pattern'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {},
      prompt: 'Welche Form folgt?',
      options: const [
        AnswerOption(id: 'a', label: 'Kreis', payload: 'Kreis'),
        AnswerOption(id: 'b', label: 'Dreieck', payload: 'Dreieck'),
        AnswerOption(id: 'c', label: 'Quadrat', payload: 'Quadrat'),
      ],
      correctAnswer: 'Kreis',
      visualPayload: const VisualPayload(type: VisualType.sequence, data: {
        'sequence': ['Kreis', 'Dreieck', 'Kreis', 'Dreieck'],
        'period': 2,
      }),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 11, 15),
    );
    final native = NativeLearningActivity.fromTask(task);
    expect(native, isNotNull);
    expect(native!.kind, 'pattern');
    expect(jsonDecode(jsonEncode(native.toLaunchOptions())), {
      'kind': 'pattern',
      'sequence': ['Kreis', 'Dreieck', 'Kreis', 'Dreieck'],
      'choices': ['Kreis', 'Dreieck', 'Quadrat'],
      'period': 2,
    });
    expect(task.taskInstanceId, 'existing-pattern-task');
    expect(task.correctAnswer, 'Kreis');
    expect(native.toLaunchOptions().containsKey('correctAnswer'), isFalse);
    expect(native.toLaunchOptions().containsKey('childId'), isFalse);
  });

  test('incomplete last group uses actual sequence length', () {
    final native = pattern(
      sequence: ['Kreis', 'Dreieck', 'Kreis', 'Dreieck', 'Kreis'],
      expected: 'Dreieck',
    );
    expect(native, isNotNull);
    expect(native!.toLaunchOptions()['sequence'], hasLength(5));
  });

  test('mismatched domain answer and absent correct option are rejected', () {
    expect(pattern(expected: 'Dreieck'), isNull);
    expect(pattern(choices: ['Dreieck', 'Quadrat']), isNull);
  });

  test('at least two repetitions and the smallest period are required', () {
    expect(pattern(sequence: ['Kreis', 'Dreieck', 'Quadrat', 'Kreis']), isNull);
    expect(pattern(sequence: ['Kreis', 'Dreieck', 'Kreis']), isNull);
    expect(
      pattern(
        sequence: [
          'Kreis',
          'Dreieck',
          'Kreis',
          'Dreieck',
          'Kreis',
          'Dreieck',
          'Kreis',
          'Dreieck'
        ],
        period: 4,
      ),
      isNull,
    );
    expect(pattern(sequence: List.filled(4, 'Kreis'), period: 1), isNotNull);
  });

  test('native payload has explicit type and bounded finite choices', () {
    for (final invalid in [null, true, '2', 2.0, -1, 0, 5]) {
      expect(pattern(period: invalid), isNull, reason: '$invalid');
    }
    expect(pattern(choices: ['Kreis', 'Kreis']), isNull);
    expect(pattern(choices: ['Kreis']), isNull);
    expect(pattern(choices: ['Kreis', 'Dreieck', 3]), isNull);
    expect(pattern(sequence: List.filled(14, 'Kreis'), period: 1), isNull);
  });

  test('labels cannot contain hidden control characters or be silently trimmed',
      () {
    for (final label in [
      ' Kreis',
      'Kreis ',
      'Kreis\n',
      'Kreis\u007f',
      'Kreis\u0085',
      '',
      'x' * 25
    ]) {
      expect(pattern(choices: ['Kreis', label]), isNull, reason: label);
    }
  });

  test('caller mutations cannot rewrite a prepared illustration', () {
    final sequence = ['Kreis', 'Dreieck', 'Kreis', 'Dreieck'];
    final choices = ['Kreis', 'Dreieck', 'Quadrat'];
    final native = pattern(sequence: sequence, choices: choices)!;
    sequence[0] = 'Quadrat';
    choices.clear();
    expect((native.toLaunchOptions()['sequence'] as List).first, 'Kreis');
    expect(native.toLaunchOptions()['choices'], hasLength(3));
    expect(() => (native.toLaunchOptions()['sequence'] as List).clear(),
        throwsUnsupportedError);
  });
}
