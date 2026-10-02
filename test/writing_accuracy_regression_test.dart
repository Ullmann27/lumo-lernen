import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/writing_target_parser.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/writing/expanded_writing_template_repository.dart';
import 'package:lumo_lernen/domain/writing/writing_domain.dart';
import 'package:lumo_lernen/domain/writing/writing_path_geometry.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_writing_canvas.dart';

const repository = ExpandedWritingTemplateRepository();

Stroke stroke(String id, List<math.Point<double>> points) =>
    Stroke(id: id, points: [
      for (var i = 0; i < points.length; i++)
        StrokePoint(x: points[i].x, y: points[i].y, timestampMs: i * 20),
    ]);

WritingEvaluation evaluate(String symbol, List<Stroke> strokes) =>
    const WritingEvaluator().evaluate(
      template: repository.findOrFallback(symbol),
      attempt: WritingAttempt(
          taskInstanceId: 'test',
          childId: 'test',
          targetSymbol: symbol,
          mode: WritingMode.trace,
          strokes: strokes,
          startedAt: DateTime(2026),
          finishedAt: DateTime(2026, 1, 1, 0, 0, 3)),
    );

List<Stroke> trace(String symbol, {bool reverse = false}) => [
      for (final model in repository.findOrFallback(symbol).strokes)
        stroke(
            '${model.order}',
            reverse
                ? WritingPathGeometry.sample(model.pathData).reversed.toList()
                : WritingPathGeometry.sample(model.pathData)),
    ];

TaskInstance task(String symbol) => TaskInstance(
      taskInstanceId: 'writing_$symbol',
      templateId: 'writing',
      childId: 'local',
      seedHash: '1',
      subject: LearningSubject.deutsch,
      skillId: const SkillId('de.letter_writing'),
      taskType: TaskType.writingCanvas,
      difficulty: 1,
      parameters: {'symbol': symbol},
      prompt: 'Schreibe: $symbol',
      correctAnswer: symbol,
  options: const [],
      visualPayload:
          VisualPayload(type: VisualType.writingPath, data: {'symbol': symbol}),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026),
    );

void main() {
  test('B has its own two bowls and never reuses the A triangle', () {
    final a = repository.findOrFallback('A');
    final b = repository.findOrFallback('B');
    expect(b.strokes.first.startX, b.strokes.first.endX);
    expect(b.strokes.where((s) => s.pathData.contains('C')).length, 2);
    expect(b.strokes.map((s) => s.pathData),
        isNot(a.strokes.map((s) => s.pathData)));
    final wrong = evaluate('B', trace('A'));
    expect(wrong.overallScore, lessThan(.70));
    expect(wrong.incomplete, isTrue);
  });

  test('All supported paths are bounded and accept a matching trace', () {
    for (final symbol in [
      ...ExpandedWritingTemplateRepository.uppercaseLetters,
      ...ExpandedWritingTemplateRepository.numberSymbols,
      '∿'
    ]) {
      final model = repository.findOrFallback(symbol, grade: 4);
      expect(model.symbol, symbol);
      expect(model.grade, 4);
      expect(model.strokes, isNotEmpty, reason: symbol);
      for (final line in model.strokes) {
        final points = WritingPathGeometry.sample(line.pathData);
        expect(points, isNotEmpty, reason: symbol);
        for (final point in points) {
          expect(point.x, inInclusiveRange(0, 100), reason: symbol);
          expect(point.y, inInclusiveRange(0, 100), reason: symbol);
        }
        expect(points.first.x, closeTo(line.startX, .001));
        expect(points.last.y, closeTo(line.endY, .001));
      }
      final result = evaluate(symbol, trace(symbol));
      expect(result.overallScore, greaterThan(.95), reason: symbol);
      expect(result.incomplete, isFalse, reason: symbol);
    }
  });

  test('Two-digit paths really place digits side by side with sequential order',
      () {
    final model = repository.findOrFallback('10');
    final left = WritingPathGeometry.sample(model.strokes.first.pathData);
    final right = WritingPathGeometry.sample(model.strokes.last.pathData);
    expect(left.every((p) => p.x < 50), isTrue);
    expect(right.every((p) => p.x > 50), isTrue);
    expect(model.strokes.map((s) => s.order).toList(), [1, 2]);
  });

  test('Unknown and lowercase targets stay ungraded rather than turning into A',
      () {
    for (final target in ['100', 'a', 'ä', '?', 'Mama', '']) {
      final model = repository.findOrFallback(target);
      expect(model.symbol, target);
      expect(model.strokes, isEmpty);
      expect(evaluate(target, trace('A')).overallScore, 0);
    }
    expect(WritingTargetParser.parse('Schreibe: Lumo liest.'), 'Lumo liest.');
    expect(WritingTargetParser.parse('Schreibe: ∿'), '∿');
    expect(WritingTargetParser.parse('Spure den Buchstaben B nach.'), 'B');
    expect(WritingTargetParser.parse('Heute machen wir eine Übung.'), '');
  });

  test('Small tracing deviations pass; same endpoints with scribbles fail', () {
    final slightlyUneven = [
      for (final model in repository.findOrFallback('A').strokes)
        stroke(
            '${model.order}',
            WritingPathGeometry.sample(model.pathData)
                .map((p) => math.Point(p.x + 2, p.y - 1.5))
                .toList()),
    ];
    final good = evaluate('A', slightlyUneven);
    expect(good.overallScore, greaterThanOrEqualTo(.70));
    expect(good.incomplete, isFalse);
    final scribble = [
      for (final model in repository.findOrFallback('A').strokes)
        stroke('${model.order}', [
          math.Point(model.startX, model.startY),
          const math.Point(95, 5),
          const math.Point(5, 5),
          const math.Point(95, 95),
          const math.Point(5, 95),
          math.Point(model.endX, model.endY)
        ]),
    ];
    final wrong = evaluate('A', scribble);
    expect(wrong.overallScore, lessThan(.70));
    expect(wrong.incomplete, isTrue);
  });

  test('Closed-curve direction and missing strokes cannot claim completion',
      () {
    expect(evaluate('O', trace('O')).incomplete, isFalse);
    expect(evaluate('O', trace('O', reverse: true)).incomplete, isTrue);
    final missing = evaluate('A', trace('A').take(2).toList());
    expect(missing.incomplete, isTrue);
    expect(missing.overallScore, lessThan(.70));
  });

  testWidgets(
      'Free writing submits as ungraded and a new task clears the old attempt',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(850, 1150));
    WritingTaskResult? submitted;
    Widget screen(String symbol) => MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
          child: WritingTaskRenderer(
              task: task(symbol), onSubmitted: (result) => submitted = result),
        )));
    await tester.pumpWidget(screen('Mama'));
    await tester.tap(find.text('Hier tippen zum Schreiben'));
    await tester.pumpAndSettle();
    final canvas = find.byType(LumoWritingCanvas);
    expect(tester.widget<LumoWritingCanvas>(canvas).template.strokes, isEmpty);
    final paint =
        find.descendant(of: canvas, matching: find.byType(CustomPaint)).first;
    final area = tester.getRect(paint);
    await tester.dragFrom(
        area.topLeft + const Offset(30, 60), const Offset(200, 100));
    await tester.pump();
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    expect(find.textContaining('keine Note oder Richtig-Bewertung'),
        findsOneWidget);
    await tester.tap(find.text('Fertig'));
    await tester.pump();
    expect(submitted?.graded, isFalse);
    expect(submitted?.evaluation.overallScore, 0);
    submitted = null;
    await tester.pumpWidget(screen('B'));
    await tester.tap(find.text('Fertig'));
    expect(submitted, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}
