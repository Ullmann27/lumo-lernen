import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/shape_trace_task_renderer.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_shape_trace_canvas.dart';

void main() {
  for (final allowRetry in [true, false]) {
    testWidgets(
      'shape tracing honours allowRetry=$allowRetry after a mistake',
      (tester) async {
        final events = <ShapeTraceTaskResult>[];
        final task = TaskInstance(
          taskInstanceId: 'shape',
          templateId: 'square',
          childId: 'child',
          seedHash: '1',
          subject: LearningSubject.mathematik,
          skillId: const SkillId('shape'),
          taskType: TaskType.shapeTrace,
          difficulty: 1,
          parameters: const {'shape': 'square'},
          prompt: 'Zeichne ein Quadrat nach',
          options: const [],
          correctAnswer: 'Quadrat',
          visualPayload: const VisualPayload(type: VisualType.none),
          helpPayload: const HelpPayload(),
          generatedAt: DateTime(2026),
        );
        await tester.binding.setSurfaceSize(const Size(900, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AdaptiveTaskRenderer(
                task: task,
                allowRetry: allowRetry,
                onShapeTraced: events.add,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Jetzt ich!'));
        await tester.pump();
        final drawArea = find
            .descendant(
              of: find.byType(LumoShapeTraceCanvas),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Listener &&
                    widget.onPointerDown != null &&
                    widget.onPointerMove != null,
              ),
            )
            .last;
        final origin = tester.getTopLeft(drawArea) + const Offset(40, 40);
        final gesture = await tester.startGesture(origin);
        await gesture.moveTo(origin + const Offset(15, 15));
        await gesture.up();
        await tester.pump();
        await tester.tap(find.text('Fertig'));
        await tester.pump();
        expect(events, hasLength(1));
        expect(events.single.correct, isFalse);

        final clearButton = tester.widget<GestureDetector>(
          find
              .ancestor(
                of: find.text('Neu'),
                matching: find.byType(GestureDetector),
              )
              .first,
        );
        expect(clearButton.onTap != null, allowRetry);

        if (allowRetry) {
          await tester.tap(find.text('Neu'));
          await tester.pump();
          // A complete square is now accepted, and a solved task locks again.
          final square = await tester.startGesture(origin);
          var previous = Offset.zero;
          for (final point in const [
            Offset(120, 0),
            Offset(120, 120),
            Offset(0, 120),
            Offset(0, 0),
          ]) {
            // Six samples per side match the canvas' corner detector.
            for (var step = 1; step <= 6; step++) {
              await square.moveTo(
                origin + Offset.lerp(previous, point, step / 6)!,
              );
            }
            previous = point;
          }
          await square.up();
          await tester.pump();
          await tester.tap(find.text('Fertig'));
          await tester.pump();
          expect(events, hasLength(2));
          expect(events.last.correct, isTrue);
        }
        await tester.tap(find.text('Fertig'));
        await tester.pump();
        expect(events, hasLength(allowRetry ? 2 : 1));
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
