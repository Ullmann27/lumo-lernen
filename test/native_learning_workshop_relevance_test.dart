import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';

TaskInstance clockTask({
  int hour = 3,
  int minute = 30,
  Object answer = '3:30 Uhr',
  List<AnswerOption> options = const [
    AnswerOption(id: 'a', label: '3:00 Uhr'),
    AnswerOption(id: 'b', label: '3:30 Uhr'),
    AnswerOption(id: 'c', label: '4:00 Uhr'),
    AnswerOption(id: 'd', label: '4:30 Uhr'),
  ],
}) =>
    TaskInstance(
      taskInstanceId: 'uhr-aufgabe',
      templateId: 'clock',
      childId: 'local-test-child',
      seedHash: 'verified-test-seed',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('math-clock'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const <String, Object?>{},
      prompt: 'Wie spät ist es auf der gezeigten Uhr?',
      options: options,
      correctAnswer: answer,
      visualPayload: VisualPayload(
        type: VisualType.clock,
        data: <String, Object?>{'hour': hour, 'minute': minute},
      ),
      helpPayload: const HelpPayload(
          shortHint: 'Langer Zeiger: Minuten. Kurzer Zeiger: Stunden.'),
      generatedAt: DateTime(2026, 11, 16),
    );

void main() {
  test('Clock always sends the actual dial and choice labels', () {
    final activity = NativeLearningActivity.fromTask(clockTask());
    expect(activity?.kind, 'clock');
    final launch = activity!.toLaunchOptions();
    expect(launch['hour'], 3);
    expect(launch['minute'], 30);
    expect(launch['answerChoices'], [
      '3:00 Uhr',
      '3:30 Uhr',
      '4:00 Uhr',
      '4:30 Uhr',
    ]);
    expect(launch['prompt'], 'Wie spät ist es auf der gezeigten Uhr?');
    expect(launch.containsKey('correctAnswer'), isFalse);
    expect(launch.containsKey('childId'), isFalse);
  });

  test('Wrong clock coordinates cannot be smuggled into native 3D', () {
    expect(NativeLearningActivity.fromTask(clockTask(hour: 0)), isNull);
    expect(NativeLearningActivity.fromTask(clockTask(minute: 60)), isNull);
    expect(
        NativeLearningActivity.fromTask(clockTask(
            hour: 4, minute: 30, answer: '3:30 Uhr')),
        isNull);
  });

  test('No answers, duplicate choices and wrong answers stay in Flutter', () {
    expect(NativeLearningActivity.fromTask(clockTask(options: [])), isNull);
    expect(
        NativeLearningActivity.fromTask(clockTask(options: const [
          AnswerOption(id: 'a', label: '3:30 Uhr'),
          AnswerOption(id: 'b', label: '3:30 Uhr'),
        ])),
        isNull);
    expect(NativeLearningActivity.fromTask(clockTask(answer: '7:15 Uhr')),
        isNull);
  });

  test('Other visual tasks must not open an unhelpful universal 3D card', () {
    final unsupported = TaskInstance(
      taskInstanceId: 'language-task',
      templateId: 'parts-of-speech',
      childId: 'local-test-child',
      seedHash: 'test',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('language'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const <String, Object?>{},
      prompt: 'Welches Wort ist ein Tunwort?',
      options: const [
        AnswerOption(id: 'a', label: 'laufen'),
        AnswerOption(id: 'b', label: 'Haus'),
      ],
      correctAnswer: 'laufen',
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: const HelpPayload(shortHint: 'Was kann man tun?'),
      generatedAt: DateTime(2026, 11, 16),
    );
    expect(NativeLearningActivity.forTask(unsupported), isNull);
    expect(NativeLearningActivity.fromTask(unsupported), isNull);
  });
}
