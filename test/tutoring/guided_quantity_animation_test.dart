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
              : lesson.concept == GuidedMathConcept.bridgeTen
                  ? step.a + step.b
                  : step.a * step.b;
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          await tester.pump(const Duration(milliseconds: 700));
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          await tester.pump(const Duration(milliseconds: 1600));
          expect(find.byType(LumoQuantityArt), findsNWidgets(count));
          expect(tester.takeException(), isNull);
          if (lesson.concept == GuidedMathConcept.bridgeTen && step.b > 0) {
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
}
