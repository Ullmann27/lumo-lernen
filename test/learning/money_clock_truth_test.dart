import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/lumo_premium_visuals.dart';

TaskInstance _task(VisualType type, String prompt,
        {Map<String, Object?> data = const {}}) =>
    TaskInstance(
      taskInstanceId: 'visual-truth',
      templateId: 'visual-truth',
      childId: 'synthetic',
      seedHash: 'fixed',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('money-time'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: const {},
      prompt: prompt,
      options: const [AnswerOption(id: 'a', label: '1')],
      correctAnswer: 1,
      visualPayload: VisualPayload(type: type, data: data),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 11, 15),
    );

Widget _screen(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    );

// Read the actual values printed on the pieces. A total caption is not proof
// that the child can see that amount. Explicit multiples represent bundles.
int _visibleCents(WidgetTester tester) {
  final piece = RegExp(r'^(?:(\d+) × )?(\d+)(€|c)$');
  return tester.widgetList<Text>(find.byType(Text)).fold(0, (sum, text) {
    final match = piece.firstMatch(text.data ?? '');
    if (match == null) return sum;
    final count = int.parse(match.group(1) ?? '1');
    return sum + count * int.parse(match.group(2)!) *
        (match.group(3) == '€' ? 100 : 1);
  });
}

void main() {
  for (final cents in [0, 1, 150, 2375, 5000, 125789, 10000000]) {
    testWidgets('every visible piece sums to $cents cents', (tester) async {
      await tester.pumpWidget(_screen(MoneyCoinsVisual(
        task: _task(VisualType.money, 'Welchen Betrag siehst du?',
            data: {'cents': cents}),
      )));
      expect(_visibleCents(tester), cents,
          reason: 'No truncated coins or decorative extra countable money');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('one decimal digit means tenths of a euro', (tester) async {
    await tester.pumpWidget(_screen(MoneyCoinsVisual(
      task: _task(VisualType.money, 'Ein Heft kostet 1,5 €. Was bedeutet das?'),
    )));
    expect(_visibleCents(tester), 150);
  });

  testWidgets('missing money data never invents one euro', (tester) async {
    await tester.pumpWidget(_screen(MoneyCoinsVisual(
      task: _task(VisualType.money, 'Welches Zahlungsmittel kennst du?'),
    )));
    expect(_visibleCents(tester), 0);
    expect(find.text('1 €'), findsNothing);
  });

  testWidgets('missing time data never invents clock hands', (tester) async {
    await tester.pumpWidget(_screen(ClockFaceVisual(
      task: _task(VisualType.clock, 'Wie viele Stunden hat ein Tag?'),
    )));
    final paintedClock = find.byWidgetPredicate((widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_ClockPainter');
    expect(paintedClock, findsNothing);
  });

  testWidgets('invalid clock payload is not silently wrapped', (tester) async {
    await tester.pumpWidget(_screen(ClockFaceVisual(
      task: _task(VisualType.clock, 'Lies die Uhr.',
          data: {'hour': 25, 'minute': 90}),
    )));
    expect(find.byKey(const ValueKey('learning-clock-known')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valid task time is accessible and preserved', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(_screen(ClockFaceVisual(
        task: _task(VisualType.clock, 'Lies die Uhr.',
            data: {'hour': 7, 'minute': 30}),
      )));
      expect(find.bySemanticsLabel('Uhr: Stunde 7, Minute 30'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });
}
