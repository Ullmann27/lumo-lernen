import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/schoolbook/widgets/schoolbook_task_widgets.dart';

const _sentence = 'Die Katze schläft.';
const _choices = <String>[
  _sentence,
  'schläft die Katze',
  'Katze die schläft',
];

TaskInstance _task({String expected = _sentence}) => TaskInstance(
      taskInstanceId: 'sentence-privacy',
      templateId: 'existing-sentence',
      childId: 'local-fixture',
      seedHash: 'sentence-fixture',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('deutsch.satz_bauen'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {'unit': 'Satz bauen', 'visual': 'auto'},
      prompt: 'Welcher Satz ist richtig?',
      options: _choices
          .map((choice) =>
              AnswerOption(id: choice, label: choice, payload: choice))
          .toList(growable: false),
      correctAnswer: expected,
      visualPayload: const VisualPayload(type: VisualType.none),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime.utc(2026, 11, 15),
    );

Future<void> _render(
  WidgetTester tester,
  TaskInstance task, {
  bool allowRetry = true,
  ValueChanged<AdaptiveTaskAnswer>? onAnswered,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(
        size: Size(820, 950),
        disableAnimations: true,
      ),
      child: Scaffold(
        body: SingleChildScrollView(
          child: AdaptiveTaskRenderer(
            key: ValueKey(task.correctAnswer),
            task: task,
            allowRetry: allowRetry,
            onAnswered: onAnswered,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
}

List<String> _visibleWordCues(WidgetTester tester) => tester
    .widgetList<WordCardRow>(find.byType(WordCardRow))
    .expand((row) => row.words)
    .toList(growable: false);

void main() {
  for (final allowRetry in [true, false]) {
    testWidgets(
        'sentence ${allowRetry ? "practice" : "test"} does not preview the solution',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(820, 950));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final task = _task();
      final answers = <AdaptiveTaskAnswer>[];
      await _render(tester, task,
          allowRetry: allowRetry, onAnswered: answers.add);

      // The correct sentence is a legitimate answer option. It must not also
      // be assembled as an always-visible model before the child chooses.
      expect(_visibleWordCues(tester).join(' '),
          isNot(contains('Die Katze schläft')));
      expect(find.text('So sieht der richtige Satz aus. Nun finde ihn unten.'),
          findsNothing);
      expect(answers, isEmpty);

      final answer = find.text(_sentence);
      await tester.ensureVisible(answer);
      await tester.tap(answer);
      await tester.pump();
      expect(answers, hasLength(1));
      expect(answers.single.task.taskInstanceId, task.taskInstanceId);
      expect(answers.single.answer, _sentence);
      expect(answers.single.correct, isTrue);
      expect(answers.single.hintUsed, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('unanswered word cues are independent of the hidden answer key',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(820, 950));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _render(tester, _task());
    final initial = _visibleWordCues(tester);
    // This deliberate answer-key perturbation checks presentation privacy,
    // not the grammar of a generated exercise. Prompt and choices stay equal.
    await _render(tester, _task(expected: _choices[1]));
    expect(_visibleWordCues(tester), initial,
        reason: 'A hidden answer key cannot alter the unassisted model.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
