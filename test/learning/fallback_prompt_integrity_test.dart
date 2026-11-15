import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/schoolbook/widgets/schoolbook_task_widgets.dart';

TaskInstance _task({
  required String prompt,
  required Object answer,
  LearningSubject subject = LearningSubject.mathematik,
  VisualType visual = VisualType.none,
  Map<String, Object?> data = const {},
  Map<String, Object?> parameters = const {},
}) =>
    TaskInstance(
      taskInstanceId: 'fallback-prompt-integrity',
      templateId: 'fallback-prompt-integrity',
      childId: 'local-fixture',
      seedHash: 'fixed-fixture',
      subject: subject,
      skillId: const SkillId('fallback-integrity'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: parameters,
      prompt: prompt,
      options: [AnswerOption(id: 'answer', label: '$answer', payload: answer)],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: visual, data: data),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime.utc(2026, 11, 15),
    );

Future<void> _render(WidgetTester tester, TaskInstance task) async {
  await tester.binding.setSurfaceSize(const Size(420, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(
        body: SingleChildScrollView(
          child: AdaptiveTaskRenderer(
              task: task, allowRetry: false, reduceMotion: true),
        ),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('two given numbers do not imply an arithmetic instruction',
      (tester) async {
    await _render(
        tester, _task(prompt: 'Welche Zahl steht links: 3 oder 0?', answer: 3));
    expect(find.text('Mengenbild'), findsNothing);
    expect(find.text('Wegnehmen-Bild'), findsNothing);
  });

  testWidgets('subtraction model does not print the result before an answer',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: '12 − 5 = ?',
            answer: 7,
            visual: VisualType.dots,
            data: const {'operation': 'subtraction', 'left': 12, 'right': 5}));
    expect(find.text('Wegnehmen-Bild'), findsOneWidget);
    expect(find.textContaining('Ergebnis:'), findsNothing);
  });

  testWidgets(
      'a wrong integer answer key does not render a contradictory model',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: '8 + 5 = ?',
            answer: 15,
            visual: VisualType.dots,
            data: const {'operation': 'addition', 'left': 8, 'right': 5}));
    expect(find.text('Mengenbild'), findsNothing);
    expect(find.byType(QuantityDotsVisual), findsNothing);
  });

  testWidgets('decimal answer four never becomes a whole-number quantity guess',
      (tester) async {
    await _render(tester,
        _task(prompt: '1,5 + 2,5 = ?', answer: 4, visual: VisualType.dots));
    expect(find.text('Mengenbild'), findsNothing);
    expect(find.byType(QuantityDotsVisual), findsNothing);
  });

  testWidgets('writing fallback does not use hidden target as a word model',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: 'Welches Wort ist richtig geschrieben?',
            answer: 'Blume',
            subject: LearningSubject.deutsch,
            parameters: const {'visual': 'writing_line'},
            data: const {'word': 'Blume', 'target': 'Blume'}));
    expect(find.byType(WritingLineBox), findsNothing);
    expect(find.byType(WordCardRow), findsNothing);
    expect(find.text('Blume'), findsOneWidget,
        reason: 'The solution remains a legitimate answer option only.');
  });

  testWidgets('writing fallback retains a word that is actually given',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: 'Aus 1 mach 2: Auto -> ?',
            answer: 'Autos',
            subject: LearningSubject.deutsch,
            parameters: const {'visual': 'writing_line'},
            data: const {'word': 'Auto', 'target': 'Autos'}));
    expect(
        tester.widget<WordCardRow>(find.byType(WordCardRow)).words, ['Auto']);
    expect(find.text('Autos'), findsOneWidget);
  });

  testWidgets('sound fallback requires a given word and never invents one',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: 'Welchen Laut hörst du?',
            answer: 'M',
            subject: LearningSubject.deutsch,
            parameters: const {'unit': 'Anfangslaute'}));
    expect(find.byType(SoundHighlightWord), findsNothing);
    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('ten full tens are retained instead of silently clamped to nine',
      (tester) async {
    await _render(
        tester,
        _task(
            prompt: 'Wie viele Zehner hat 100?',
            answer: 10,
            visual: VisualType.tenOnes,
            data: const {'tens': 10, 'ones': 0}));
    final card =
        tester.widget<SchoolbookTaskCard>(find.byType(SchoolbookTaskCard));
    expect(card.ribbonLabel, '100');
    expect(find.text('90'), findsNothing);
    final rods = find.byWidgetPredicate(
        (widget) => widget is Container && widget.constraints?.minHeight == 72);
    expect(rods, findsNWidgets(10));
  });
}
