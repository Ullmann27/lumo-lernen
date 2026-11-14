import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_shape_trace_canvas.dart';

Finder get _drawingArea => find
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

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<GestureDetector>(find
            .ancestor(
                of: find.text(label), matching: find.byType(GestureDetector))
            .first)
        .onTap !=
    null;

Future<void> _openCanvas(
  WidgetTester tester, {
  ScrollController? scroll,
}) async {
  await tester.binding.setSurfaceSize(const Size(480, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SizedBox(
        height: 620,
        child: SingleChildScrollView(
          controller: scroll,
          child: const Column(children: [
            SizedBox(height: 70),
            RepaintBoundary(
              key: ValueKey('shape-canvas-image'),
              child: LumoShapeTraceCanvas(shape: 'square', height: 300),
            ),
            SizedBox(height: 900),
          ]),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Jetzt ich!'));
  await tester.pumpAndSettle();
}

Future<Uint8List> _raster(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('shape-canvas-image')));
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      return Uint8List.fromList(data!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  }))!;
}

void main() {
  testWidgets('shape strokes keep the lesson stationary in every direction',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await _openCanvas(tester, scroll: scroll);
    final area = tester.getRect(_drawingArea);
    for (final delta in const [
      Offset(0, -90),
      Offset(0, 90),
      Offset(-90, 0),
      Offset(90, 0),
    ]) {
      await tester.dragFrom(area.center, delta);
      await tester.pump();
      expect(scroll.offset, 0,
          reason: 'A shape stroke beginning inside the canvas owns its drag');
      expect(tester.getRect(_drawingArea), area);
    }
    expect(_enabled(tester, 'Fertig'), isTrue);

    await tester.dragFrom(const Offset(240, 580), const Offset(0, -90));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0),
        reason: 'The surrounding lesson remains scrollable');
  });

  testWidgets('lifting a second finger cannot finish the active shape stroke',
      (tester) async {
    await _openCanvas(tester);
    final center = tester.getCenter(_drawingArea);
    final first = await tester.startGesture(center, pointer: 1);
    await first.moveBy(const Offset(0, 40));
    final second =
        await tester.startGesture(center + const Offset(80, 0), pointer: 2);
    await second.moveBy(const Offset(50, 30));
    await second.up();
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isFalse,
        reason: 'Only the original pointer can complete its own stroke');

    await first.moveBy(const Offset(40, 0));
    await first.up();
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isTrue);
    await tester.tap(find.text('Zurück'));
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isFalse,
        reason: 'Two fingers must have produced exactly one completed stroke');
  });

  testWidgets('cancelled shape strokes are discarded and the next stroke works',
      (tester) async {
    await _openCanvas(tester);
    final center = tester.getCenter(_drawingArea);
    final interrupted = await tester.startGesture(center);
    await interrupted.moveBy(const Offset(50, 30));
    await interrupted.cancel();
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isFalse,
        reason: 'Android cancellation must not submit an unfinished stroke');

    await tester.dragFrom(center, const Offset(40, 30));
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isTrue);
    await tester.tap(find.text('Zurück'));
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isFalse);
  });

  testWidgets('cancelling a later stroke preserves earlier completed work',
      (tester) async {
    await _openCanvas(tester);
    final center = tester.getCenter(_drawingArea);
    await tester.dragFrom(center, const Offset(40, 30));
    final interrupted = await tester.startGesture(center);
    await interrupted.moveBy(const Offset(-40, -30));
    await interrupted.cancel();
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isTrue);
    await tester.tap(find.text('Zurück'));
    await tester.pump();
    expect(_enabled(tester, 'Fertig'), isFalse,
        reason: 'Undo removes the one completed stroke, never a cancelled one');
  });

  testWidgets('undo and clear actually erase the painted stroke pixels',
      (tester) async {
    await _openCanvas(tester);
    final empty = await _raster(tester);
    final center = tester.getCenter(_drawingArea);
    await tester.dragFrom(center, const Offset(90, 40));
    await tester.pump();
    final firstStroke = await _raster(tester);
    expect(listEquals(firstStroke, empty), isFalse,
        reason: 'The real canvas must first contain visible ink');
    await tester.dragFrom(center, const Offset(-90, -40));
    await tester.pump();
    expect(listEquals(await _raster(tester), firstStroke), isFalse);

    await tester.tap(find.text('Zurück'));
    await tester.pump();
    expect(listEquals(await _raster(tester), firstStroke), isTrue,
        reason: 'Undo erases the second stroke while keeping the first visible');
    await tester.tap(find.text('Neu'));
    await tester.pump();
    expect(listEquals(await _raster(tester), empty), isTrue,
        reason: 'Clear must erase the visible ink as well as its data');
  });
}
