import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/tutoring/arithmetic_task_aid.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';

TaskInstance task(String op, int a, int b, int answer) => TaskInstance(
      taskInstanceId: '$op-$a-$b',
      templateId: 'arithmetic-test',
      childId: 'test',
      seedHash: 'test',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('test'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {},
      prompt: '$a $op $b',
      options: const [],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: VisualType.dots, data: {
        'operation': op,
        'left': a,
        'right': b,
      }),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime.utc(2026, 11, 22),
    );

void main() {
  Future<void> show(WidgetTester tester, TaskInstance instance) =>
      tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: ArithmeticTaskAid(task: instance, reduceMotion: true))));
  testWidgets('Originalaufgabe behält Faktoren, Reihen und offene Lösung',
      (tester) async {
    await show(tester, task('multiplication', 6, 7, 42));
    expect(find.byType(LumoQuantityArt), findsNWidgets(42));
    expect(find.text('6 Reihen mit je 7 Äpfeln'), findsOneWidget);
    expect(find.textContaining('42'), findsNothing);
    await tester.tap(find.text('Feld drehen'));
    await tester.pump();
    expect(find.text('7 Reihen mit je 6 Äpfeln'), findsOneWidget);
    await show(tester, task('multiplication', 4, 3, 12));
    expect(find.text('4 Reihen mit je 3 Äpfeln'), findsOneWidget);
    expect(find.byType(LumoQuantityArt), findsNWidgets(12));
    await show(tester, task('multiplication', 4, 3, 7));
    expect(find.byType(LumoQuantityArt), findsNothing);
  });
  for (final example in [
    ('addition', 8, 5, 13, 10),
    ('subtraction', 14, 8, 6, 10),
    ('addition', 3, 4, 7, 5)
  ]) {
    testWidgets(
        'Zwei selbst ausgeführte Sprünge ${example.$1} ${example.$2} und ${example.$3}',
        (tester) async {
      await show(tester, task(example.$1, example.$2, example.$3, example.$4));
      final target = example.$4;
      final start = example.$2;
      final anchor = example.$5;
      await tester.tap(find.text('$start prüfen'));
      await tester.pump();
      expect(find.text('Suche zuerst die $anchor.'), findsOneWidget);
      final direction =
          start < target ? 'Einen Schritt vor' : 'Einen Schritt zurück';
      for (final steps in [(anchor - start).abs(), (target - anchor).abs()]) {
        for (var i = 0; i < steps; i++) {
          await tester.tap(find.byTooltip(direction));
          await tester.pump();
        }
        await tester.tap(find.textContaining(' prüfen'));
        await tester.pump();
      }
      expect(find.textContaining('Probe: $target '), findsOneWidget);
    });
  }
}
