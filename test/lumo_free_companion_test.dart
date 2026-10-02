import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/fox/lumo_free_companion.dart';

void main() {
  Future<void> mount(WidgetTester tester,
      {bool reduced = true,
      double width = 360,
      LumoCompanionScene scene = const LumoCompanionScene(),
      ValueChanged<LumoCompanionAction>? onAction}) async {
    await tester.binding.setSurfaceSize(Size(width, 640));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      const Expanded(child: Center(child: Text('Meine Lernaufgabe'))),
      RepaintBoundary(
          key: const ValueKey('capture'),
          child: LumoFreeCompanion(
              scene: scene,
              onAction: onAction ?? (_) {},
              reducedMotion: reduced,
              proactive: false)),
    ]))));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
  }

  testWidgets('fox explains app on request and suggestions require acceptance',
      (tester) async {
    final actions = <LumoCompanionAction>[];
    await mount(tester, onAction: actions.add);
    await tester.tap(find.text('Idee'));
    await tester.pumpAndSettle();
    expect(actions, isEmpty);
    await tester.tap(find.text('Übung starten'));
    await tester.pumpAndSettle();
    expect(actions, [LumoCompanionAction.suggestTask]);
    await tester.tap(find.byKey(const ValueKey('lumo-fox-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Die ganze App erklären'));
    await tester.pumpAndSettle();
    expect(find.text(LumoCompanionScene.appExplanation), findsOneWidget);
    expect(find.text('Vorlesen'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('task help stays in place; exams do not dispatch learning help',
      (tester) async {
    final actions = <LumoCompanionAction>[];
    await mount(tester,
        scene: const LumoCompanionScene(hasTask: true), onAction: actions.add);
    await tester.tap(find.text('Erklären'));
    await tester.pumpAndSettle();
    expect(actions, [LumoCompanionAction.explainTask]);
    await mount(tester,
        scene: const LumoCompanionScene(hasTask: true, schoolwork: true),
        onAction: actions.add);
    await tester.tap(find.text('Fragen'));
    await tester.pumpAndSettle();
    expect(actions, [LumoCompanionAction.explainTask]);
    expect(find.text('Dein eigener Lernschritt'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('motion and fold resize keep complete fox within reserved floor',
      (tester) async {
    await mount(tester, reduced: false);
    final first = tester.getRect(find.byKey(const ValueKey('lumo-fox-button')));
    await mount(tester,
        reduced: false, scene: const LumoCompanionScene(section: 'reading'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 450));
    final during =
        tester.getRect(find.byKey(const ValueKey('lumo-fox-button')));
    expect(during.left, lessThan(first.left));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')));
    if (Platform.environment['LUMO_CAPTURE_FOX'] == '1') {
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/lumo-fox-motion.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await mount(tester,
        reduced: false,
        width: 280,
        scene: const LumoCompanionScene(section: 'reading'));
    await tester.pump(const Duration(seconds: 3));
    final beforeTap =
        tester.getRect(find.byKey(const ValueKey('lumo-fox-button')));
    final walkingFloor =
        tester.getRect(find.byKey(const ValueKey('lumo-walking-floor')));
    await tester.tapAt(walkingFloor.topRight + const Offset(-5, 1));
    await tester.pump(const Duration(milliseconds: 100));
    // A turn settles first, so the fox is never instantly mirrored mid-stride.
    expect(tester.getRect(find.byKey(const ValueKey('lumo-fox-button'))).left,
        beforeTap.left);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getRect(find.byKey(const ValueKey('lumo-fox-button'))).left,
        greaterThan(beforeTap.left));
    expect(find.text('Was möchtest du machen?'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    final fox = tester.getRect(find.byKey(const ValueKey('lumo-fox-button')));
    final floor =
        tester.getRect(find.byKey(const ValueKey('lumo-companion-floor')));
    expect(floor.contains(fox.topLeft), isTrue);
    expect(floor.contains(fox.bottomRight - const Offset(.1, .1)), isTrue);
    expect(tester.takeException(), isNull);
    if (Platform.environment['LUMO_CAPTURE_FOX'] == '1') {
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('capture')));
        final image = await boundary.toImage(pixelRatio: 3);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/lumo-fox-idle.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
  });
}
