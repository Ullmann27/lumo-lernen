import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/tutoring/guided_advanced_math_illustration.dart';
import 'package:lumo_lernen/features/tutoring/guided_math_illustration.dart';

void main() {
  for (final width in [260.0, 360.0, 720.0]) {
    testWidgets(
        'hundred regrouping preserves 310 cells throughout animation at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const lesson = GuidedLessonCatalog.bridgeHundred;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GuidedMathIllustration(
                  lesson: lesson,
                  step: lesson.steps[2],
                  reduceMotion: false))));
      for (final phase in [
        (Duration.zero, 240, 70),
        (const Duration(milliseconds: 1200), 300, 10),
        (const Duration(milliseconds: 2200), 310, 0)
      ]) {
        await tester.pump(phase.$1);
        final first = find.byKey(const ValueKey('hundred-first-quantity'));
        final second = find.byKey(const ValueKey('hundred-second-quantity'));
        expect(tester.widget<BaseTenBlocks>(first).value, phase.$2);
        expect(tester.widget<BaseTenBlocks>(second).value, phase.$3);
        for (final pair in [(first, phase.$2), (second, phase.$3)]) {
          final tiles = find.descendant(
              of: pair.$1,
              matching: find.byWidgetPredicate(
                  (w) => w.key?.toString().contains('hundred-tile-') ?? false));
          final rods = find.descendant(
              of: pair.$1,
              matching: find.byWidgetPredicate(
                  (w) => w.key?.toString().contains('ten-rod-') ?? false));
          expect(tiles, findsNWidgets(pair.$2 ~/ 100));
          expect(rods, findsNWidgets(pair.$2 % 100 ~/ 10));
          for (final node in [...tiles.evaluate(), ...rods.evaluate()]) {
            final rect = tester.getRect(find.byWidget(node.widget));
            expect(rect.left, greaterThanOrEqualTo(0));
            expect(rect.right, lessThanOrEqualTo(width));
          }
        }
        expect(tester.takeException(), isNull);
      }
    });
    testWidgets(
        'advanced independent task retains inputs and hides completed result at $width',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const lesson = GuidedLessonCatalog.bridgeHundred;
      final step = lesson.steps.firstWhere((s) => s.isIndependent);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GuidedMathIllustration(
                  lesson: lesson, step: step, reduceMotion: false))));
      await tester.pump(const Duration(seconds: 5));
      expect(
          tester
              .widgetList<BaseTenBlocks>(find.byType(BaseTenBlocks))
              .map((w) => w.value)
              .toList(),
          [360, 80]);
      expect(find.textContaining(step.expected), findsNothing);
      expect(tester.takeException(), isNull);
    });
    for (final step
        in GuidedLessonCatalog.fractionParts.steps.where((s) => s.b > 0)) {
      testWidgets(
          '${step.title}: equal fraction areas at $width, solution only in example',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: GuidedMathIllustration(
                    lesson: GuidedLessonCatalog.fractionParts,
                    step: step,
                    reduceMotion: true))));
        await tester.pump();
        final whole =
            tester.getRect(find.byKey(const ValueKey('guided-fraction-whole')));
        for (var i = 0; i < step.b; i++) {
          final rect = tester.getRect(find.byKey(ValueKey('fraction-part-$i')));
          expect(rect.width, closeTo(whole.width / step.b, .001));
          expect(rect.height, whole.height);
          expect(
              rect.left, closeTo(whole.left + i * whole.width / step.b, .001));
        }
        if (step.isQuestion) {
          expect(find.textContaining(step.expected), findsNothing);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
