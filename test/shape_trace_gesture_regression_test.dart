import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_shape_trace_canvas.dart';

// Independent behavior probes. These use the production canvas and real
// pointer sequences; they never call the private start/move/end methods.
Future<Finder> mountShape(
  WidgetTester tester, {
  required List<ShapeTraceResult> results,
  ScrollController? scroll,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 850));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    scroll?.dispose();
    await tester.binding.setSurfaceSize(null);
  });
  final shape = LumoShapeTraceCanvas(
    shape: 'square',
    height: 260,
    onSubmitted: results.add,
  );
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: scroll == null
          ? Align(alignment: Alignment.topCenter, child: shape)
          : SizedBox(
              height: 560,
              child: SingleChildScrollView(
                controller: scroll,
                child: Column(children: [
                  const SizedBox(height: 64),
                  shape,
                  const ColoredBox(
                    color: Colors.white,
                    child: SizedBox(height: 700, width: double.infinity),
                  ),
                ]),
              ),
            ),
    ),
  ));
  await tester.tap(find.text('Jetzt ich!'));
  await tester.pumpAndSettle();
  return find.descendant(
    of: find.byType(LumoShapeTraceCanvas),
    matching: find.byWidgetPredicate((widget) =>
        widget is Listener &&
        widget.onPointerDown != null &&
        widget.onPointerMove != null),
  ).last;
}

Future<void> drawSquare(
  WidgetTester tester,
  TestGesture gesture,
  Offset origin, {
  Future<void> Function()? afterFirstSide,
}) async {
  var previous = Offset.zero;
  var side = 0;
  for (final end in const [
    Offset(120, 0),
    Offset(120, 120),
    Offset(0, 120),
    Offset.zero,
  ]) {
    for (var step = 1; step <= 6; step++) {
      await gesture.moveTo(origin + Offset.lerp(previous, end, step / 6)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    if (side == 0 && afterFirstSide != null) await afterFirstSide();
    previous = end;
    side++;
  }
}

void main() {
  testWidgets('shape vertical ink keeps its scrollable learning page stationary',
      (tester) async {
    final scroll = ScrollController();
    final area = await mountShape(tester, results: [], scroll: scroll);
    scroll.jumpTo(20);
    await tester.pump();
    final before = tester.getRect(area);
    final beforeOffset = scroll.offset;
    final observedOffsets = <double>[];
    final observedOrigins = <Offset>[];
    final gesture = await tester.startGesture(
      before.center + const Offset(0, 50),
      pointer: 71,
    );
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(0, -12));
      await tester.pump(const Duration(milliseconds: 16));
      observedOffsets.add(scroll.offset);
      observedOrigins.add(tester.getTopLeft(area));
    }
    await gesture.up();
    await tester.pump();
    // Retain exact behavioral observations even on an expected red run.
    debugPrint('[ShapeGesture] beforeOffset=$beforeOffset '
        'during=$observedOffsets beforeOrigin=${before.topLeft} '
        'duringOrigins=$observedOrigins');
    expect(observedOffsets, everyElement(closeTo(beforeOffset, 0.001)),
        reason: 'A vertical drawing stroke must never scroll the lesson.');
    for (final origin in observedOrigins) {
      expect((origin - before.topLeft).distance, lessThan(0.001),
          reason: 'The actual drawing surface must remain stationary.');
    }
  });

  testWidgets('a second shape pointer cannot replace the first complete drawing',
      (tester) async {
    final results = <ShapeTraceResult>[];
    final area = await mountShape(tester, results: results);
    final origin = tester.getTopLeft(area) + const Offset(40, 40);
    final first = await tester.startGesture(origin, pointer: 81);
    await drawSquare(tester, first, origin, afterFirstSide: () async {
      final second = await tester.startGesture(
        origin + const Offset(175, 70),
        pointer: 82,
      );
      await second.moveBy(const Offset(12, 18));
      await second.up();
      await tester.pump();
    });
    await first.up();
    await tester.pump();
    await tester.tap(find.text('Fertig'));
    await tester.pump();
    debugPrint('[ShapeGesture] secondPointer results='
        '${results.map((value) => '${value.correct}:${value.feedback}').join('|')}');
    expect(results, hasLength(1));
    expect(results.single.correct, isTrue,
        reason: 'An unrelated second touch cannot corrupt the first square.');
  });

  testWidgets('a cancelled shape pointer is not committed or evaluated',
      (tester) async {
    final results = <ShapeTraceResult>[];
    final area = await mountShape(tester, results: results);
    final origin = tester.getTopLeft(area) + const Offset(40, 40);
    final gesture = await tester.startGesture(origin, pointer: 91);
    await drawSquare(tester, gesture, origin);
    await gesture.cancel();
    await tester.pump();
    await tester.tap(find.text('Fertig'), warnIfMissed: false);
    await tester.pump();
    debugPrint('[ShapeGesture] cancel results='
        '${results.map((value) => '${value.correct}:${value.feedback}').join('|')}');
    expect(results, isEmpty,
        reason: 'Cancellation must discard this incomplete pointer transaction.');
  });
}
