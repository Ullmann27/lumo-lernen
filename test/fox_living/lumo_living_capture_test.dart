import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/fox/living/lumo_living_character.dart';

/// Real Flutter renders of the living Lumo for visual review.
/// Run with LUMO_LIVING_CAPTURES=<dir> to write PNG frames.
final _dir = Platform.environment['LUMO_LIVING_CAPTURES'];
const _boundary = ValueKey('living-capture');

Future<void> _save(WidgetTester tester, String name) async {
  if (_dir == null) return;
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$_dir/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

Future<void> _loadImages(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump();
  }
}

void main() {
  testWidgets('every living state renders from the original poses',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = LumoLivingController(state: LumoLivingState.greet);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0B2347),
        body: Center(
          child: RepaintBoundary(
            key: _boundary,
            child: Container(
              color: const Color(0xFF0B2347),
              padding: const EdgeInsets.all(10),
              child: LumoLivingCharacter(controller: controller, size: 300),
            ),
          ),
        ),
      ),
    ));
    await _loadImages(tester);
    for (final state in LumoLivingState.values) {
      controller.perform(state);
      // Let the pose fade in and the motion settle, then sample two moments.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(find.bySemanticsLabel(state.semanticLabel), findsOneWidget);
      await _save(tester, 'state-${state.name}-a');
      for (var i = 0; i < 25; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _save(tester, 'state-${state.name}-b');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a blink closes both eyes with the original lids',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = LumoLivingController(state: LumoLivingState.explain);
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0B2347),
        body: Center(
          child: RepaintBoundary(
            key: _boundary,
            child: Container(
              color: const Color(0xFF0B2347),
              padding: const EdgeInsets.all(10),
              child: LumoLivingCharacter(controller: controller, size: 300),
            ),
          ),
        ),
      ),
    ));
    await _loadImages(tester);
    // The first scheduled blink starts at 1.2 s of character time.
    var t = 0;
    while (t < 1150) {
      await tester.pump(const Duration(milliseconds: 10));
      t += 10;
    }
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await _save(tester, 'blink-${i.toString().padLeft(2, '0')}');
    }
    expect(tester.takeException(), isNull);
  });
}
