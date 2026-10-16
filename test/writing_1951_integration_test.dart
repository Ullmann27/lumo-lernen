import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/writing_target_parser.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/writing/expanded_writing_template_repository.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_writing_canvas.dart';

TaskInstance writingTask(String target) => TaskInstance(
      taskInstanceId: '1951-$target',
      templateId: 'writing-1951',
      childId: 'child-local',
      seedHash: '1951',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('de.letter_writing'),
      taskType: TaskType.writingCanvas,
      difficulty: 1,
      parameters: <String, Object?>{'symbol': target},
      prompt: 'Schreibe: $target',
      correctAnswer: target,
      options: const [],
      visualPayload: VisualPayload(
          type: VisualType.writingPath,
          data: <String, Object?>{'symbol': target}),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 10, 16),
    );

void main() {
  test('every mixed writing swing exercise uses a real traceable letter', () {
    const repository = ExpandedWritingTemplateRepository();
    for (var grade = 1; grade <= 4; grade++) {
      for (var seed = 0; seed < 30; seed++) {
        final task = ExerciseFactory(seed: seed).next(
          grade: grade,
          subject: 'Schreiben',
          unit: 'Schwunguebung',
        );
        final target = WritingTargetParser.parse(task.prompt);
        expect(target, isIn(<String>['S', 'C', 'O', 'U']));
        expect(task.prompt, isNot(contains('∿')));
        expect(repository.findOrFallback(target).strokes, isNotEmpty);
      }
    }
  });

  testWidgets('the actual letter canvas is square and accepts stylus ink',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    WritingTaskResult? submitted;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: WritingTaskRenderer(
          task: writingTask('S'),
          onSubmitted: (value) => submitted = value,
        ),
      ),
    )));
    await tester.ensureVisible(find.text('Hier tippen zum Schreiben'));
    await tester.tap(find.text('Hier tippen zum Schreiben'));
    await tester.pumpAndSettle();
    final paintArea = find.byKey(const ValueKey('lumo-learning-ink-surface'));
    expect(paintArea, findsOneWidget);
    final size = tester.getSize(paintArea);
    expect(size.width, closeTo(size.height, 1.5));
    final rect = tester.getRect(paintArea);
    await tester.dragFrom(
        rect.center + const Offset(-45, -35), const Offset(80, 75));
    await tester.pump();
    final finish = tester.widget<TextButton>(
        find.byKey(const ValueKey('writing-modal-finish')));
    expect(finish.onPressed, isNotNull);
    await tester.tap(find.byKey(const ValueKey('writing-modal-finish')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spurübereinstimmung'),
        findsOneWidget);
    await tester.tap(find.text('Fertig'));
    expect(submitted?.strokes, isNotEmpty);
    expect(submitted?.typedAnswer, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard mode can submit a real written word', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 930));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    WritingTaskResult? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: SingleChildScrollView(
        child: WritingTaskRenderer(
          task: writingTask('Mama'),
          onSubmitted: (value) => result = value,
        ),
      ),
    )));
    final input = find.byKey(const ValueKey('writing-keyboard-answer'));
    expect(input, findsOneWidget);
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Mama');
    await tester.pump();
    await tester.ensureVisible(find.text('Fertig'));
    await tester.tap(find.text('Fertig'));
    expect(result?.typedAnswer, 'Mama');
    expect(result?.graded, isTrue);
    expect(result?.strokes, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
