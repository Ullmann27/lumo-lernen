import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_shape_trace_canvas.dart';

Finder _drawArea() => find
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

bool _canSubmit(WidgetTester tester) =>
    tester
        .widget<GestureDetector>(
          find
              .ancestor(
                of: find.text('Fertig'),
                matching: find.byType(GestureDetector),
              )
              .first,
        )
        .onTap !=
    null;

Future<ScrollController> _showTracingLesson(WidgetTester tester) async {
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 480,
          height: 480,
          child: SingleChildScrollView(
            controller: scroll,
            child: const Column(
              children: [
                SizedBox(height: 24),
                LumoShapeTraceCanvas(shape: 'square', height: 240),
                ColoredBox(
                  key: ValueKey('outside-drawing-area'),
                  color: Colors.white,
                  child: SizedBox(height: 700, width: double.infinity),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Jetzt ich!'));
  await tester.pump();
  return scroll;
}

void main() {
  testWidgets('vertical shape strokes keep the lesson stationary',
      (tester) async {
    final scroll = await _showTracingLesson(tester);
    final origin = tester.getCenter(_drawArea());

    await tester.dragFrom(origin, const Offset(0, -90));
    await tester.pump();

    expect(scroll.offset, 0,
        reason: 'A shape stroke must never drag the surrounding lesson.');
    expect(_canSubmit(tester), isTrue);

    // Only gestures beginning outside the canvas may move the lesson.
    final outside = tester.getTopLeft(
      find.byKey(const ValueKey('outside-drawing-area')),
    );
    await tester.dragFrom(outside + const Offset(80, 60), const Offset(0, -70));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a second finger cannot replace or finish the active shape stroke',
      (tester) async {
    await _showTracingLesson(tester);
    final origin = tester.getTopLeft(_drawArea()) + const Offset(40, 40);
    final first = await tester.startGesture(origin, pointer: 1);
    final second = await tester.startGesture(
      origin + const Offset(160, 60),
      pointer: 2,
    );
    await first.moveBy(const Offset(80, 0));
    await second.moveBy(const Offset(40, 0));
    await second.up();
    await tester.pump();

    expect(_canSubmit(tester), isFalse,
        reason: 'The original drawing pointer is still down.');

    await first.moveBy(const Offset(0, 80));
    await first.up();
    await tester.pump();
    expect(_canSubmit(tester), isTrue,
        reason: 'The original stroke must survive the second finger.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelling a pointer discards its unfinished shape stroke',
      (tester) async {
    await _showTracingLesson(tester);
    final origin = tester.getTopLeft(_drawArea()) + const Offset(40, 40);
    final interrupted = await tester.startGesture(origin);
    await interrupted.moveBy(const Offset(80, 0));
    await interrupted.cancel();
    await tester.pump();
    expect(_canSubmit(tester), isFalse,
        reason: 'Interrupted strokes are not completed answers.');

    final retry = await tester.startGesture(origin);
    await retry.moveBy(const Offset(80, 0));
    await retry.up();
    await tester.pump();
    expect(_canSubmit(tester), isTrue);
    expect(tester.takeException(), isNull);
  });
}
