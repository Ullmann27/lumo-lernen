import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/tutoring/guided_math_illustration.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
  });
  for (final lesson in GuidedLessonCatalog.all) {
    for (final step in lesson.steps.where((step) => step.a > 0)) {
      for (final width in [260.0, 360.0, 720.0]) {
        testWidgets(
            '${lesson.id}/${step.title}: exact quantity at width $width',
            (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: GuidedMathIllustration(
                  lesson: lesson, step: step, reduceMotion: false),
            ),
          ));
          final count = step.b == 0
              ? step.a
              : switch (lesson.concept) {
                  GuidedLessonConcept.bridgeTen => step.a + step.b,
                  GuidedLessonConcept.equalGroups => step.a * step.b,
                  GuidedLessonConcept.subtractTen => step.a,
                  _ => throw StateError('Non-mathematical quantity fixture'),
                };
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          await tester.pump(const Duration(milliseconds: 1600));
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          expect(tester.takeException(), isNull);
          if (lesson.concept == GuidedLessonConcept.bridgeTen && step.b > 0) {
            final moved = step.type == TutoringStepType.showExample ||
                step.answerKind == GuidedAnswerKind.remainder;
            var insideTen = 0;
            for (var i = 0; i < count; i++) {
              final apple = tester.widget<Positioned>(
                  find.byKey(ValueKey('guided-bridge-apple-$i')));
              final cell = apple.width! + 3;
              if (apple.left! < cell * 5) insideTen++;
              final rect = tester
                  .getRect(find.byKey(ValueKey('guided-bridge-apple-$i')));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
            }
            expect(insideTen, moved ? 10 : step.a,
                reason: 'The explanation and remainder show a real full ten');
          }
          if (lesson.concept == GuidedLessonConcept.subtractTen && step.b > 0) {
            var kept = 0;
            for (var i = 0; i < count; i++) {
              final key = ValueKey('guided-subtract-apple-$i');
              final apple = tester.widget<Positioned>(find.byKey(key));
              if (apple.left! < (apple.width! + 3) * 5) kept++;
              final rect = tester.getRect(find.byKey(key));
              expect(rect.left, greaterThanOrEqualTo(0));
              expect(rect.right, lessThanOrEqualTo(width));
            }
            expect(
                kept,
                step.type == TutoringStepType.showExample
                    ? step.a - step.b
                    : step.answerKind == GuidedAnswerKind.subtractRemainder
                        ? 10
                        : step.a,
                reason: 'Only an explanation removes the final quantity; '
                    'independent questions keep their starting amount');
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }
  testWidgets('reduced motion shows the same final ten and remaining apples',
      (tester) async {
    const lesson = GuidedLessonCatalog.bridgeTen;
    final step = lesson.steps[2];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GuidedMathIllustration(
            lesson: lesson, step: step, reduceMotion: true),
      ),
    ));
    await tester.pump();
    expect(find.byType(LumoQuantityArt), findsNWidgets(12));
    final moved = tester.widget<Positioned>(
        find.byKey(const ValueKey('guided-bridge-apple-7')));
    expect(moved.left, (moved.width! + 3) * 2);
    expect(moved.top, moved.width! + 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('subtraction first reaches ten, then removes the rest',
      (tester) async {
    const lesson = GuidedLessonCatalog.subtractTen;
    Future<void> show(bool reduced) => tester.pumpWidget(MaterialApp(
        key: ValueKey(reduced),
        home: Scaffold(
            body: GuidedMathIllustration(
                lesson: lesson,
                step: lesson.steps[2],
                reduceMotion: reduced))));
    int kept() => [
          for (var i = 0; i < 12; i++)
            tester.widget<Positioned>(
                find.byKey(ValueKey('guided-subtract-apple-$i')))
        ].where((apple) => apple.left! < (apple.width! + 3) * 5).length;
    await show(false);
    expect(kept(), 12);
    await tester.pump(const Duration(milliseconds: 800));
    expect(kept(), 10);
    expect(find.byType(LumoQuantityArt), findsNWidgets(12));
    await tester.pump(const Duration(milliseconds: 800));
    expect(kept(), 7);
    await show(true);
    await tester.pump();
    expect(kept(), 7);
    expect(find.byType(LumoQuantityArt), findsNWidgets(12));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
