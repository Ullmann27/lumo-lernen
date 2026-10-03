import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/widgets/fox/lumo_animated_fox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> mount(WidgetTester tester,
      {bool moving = false,
      bool reduced = false,
      bool active = true,
      bool voice = false,
      LumoFoxExpression expression = LumoFoxExpression.idle}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(
            key: const ValueKey('motion-capture'),
            child: LumoAnimatedFox(
              moving: moving,
              facingRight: false,
              size: 220,
              active: active,
              reducedMotion: reduced,
              voiceEnabled: voice,
              expression: expression,
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 350)));
    await tester.pump();
  }

  LumoFoxPainter painter(WidgetTester tester) => tester
      .widget<CustomPaint>(
          find.byKey(const ValueKey('lumo-animated-fox-paint')))
      .painter! as LumoFoxPainter;

  Future<void> capture(WidgetTester tester, String label) async {
    if (Platform.environment['LUMO_CAPTURE_EXPRESSIONS'] != '1') return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('motion-capture')));
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/lumo-expression-$label.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  tearDown(() {
    LumoVoice.instance.status.value = VoiceStatus.idle;
    LumoVoice.instance.isEnabled = true;
  });

  testWidgets('complete sprite modes blend and settle instead of snapping',
      (tester) async {
    await mount(tester);
    final before = painter(tester);
    expect(before.sample.moving, isFalse);
    await capture(tester, 'idle');
    await mount(tester, moving: true);
    expect(painter(tester).blend, 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(painter(tester).blend, greaterThan(0));
    expect(painter(tester).blend, lessThan(1));
    await tester.pump(const Duration(milliseconds: 110));
    expect(painter(tester).blend, 1);
    await capture(tester, 'walk');
    await mount(tester, expression: LumoFoxExpression.celebrate);
    await tester.pump(const Duration(milliseconds: 300));
    expect(painter(tester).sample.celebrating, isTrue);
    await capture(tester, 'celebrate');
    await tester.pump(const Duration(milliseconds: 1500));
    expect(painter(tester).sample.celebrating, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion freezes every decorative part and mouth',
      (tester) async {
    await mount(tester,
        reduced: true, voice: true, expression: LumoFoxExpression.greet);
    LumoVoice.instance.status.value = VoiceStatus.speaking;
    LumoVoice.instance.spokenWordRevision.value++;
    await tester.pump(const Duration(milliseconds: 500));
    final still = painter(tester).sample;
    expect(still.elapsed, 0);
    expect(still.breath, 1);
    expect(still.headAngle, 0);
    expect(still.pawAngle, 0);
    expect(still.tailAngle, 0);
    expect(still.mouth, 0);
    await tester.pump(const Duration(seconds: 3));
    expect(painter(tester).sample.elapsed, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('TTS word events animate mouth only during enabled speech',
      (tester) async {
    await mount(tester, voice: true, expression: LumoFoxExpression.explain);
    expect(painter(tester).sample.mouth, 0);
    LumoVoice.instance.status.value = VoiceStatus.speaking;
    LumoVoice.instance.spokenWordRevision.value++;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).sample.mouth, greaterThan(.5));
    await capture(tester, 'explain');
    LumoVoice.instance.status.value = VoiceStatus.idle;
    await tester.pump();
    expect(painter(tester).sample.mouth, 0);
    LumoVoice.instance.status.value = VoiceStatus.speaking;
    await tester.pump();
    LumoVoice.instance.isEnabled = false;
    await tester.pump();
    expect(painter(tester).sample.mouth, 0);
    await mount(tester, voice: false);
    LumoVoice.instance.status.value = VoiceStatus.speaking;
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).sample.mouth, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('background and inactive routes freeze and safely resume motion',
      (tester) async {
    await mount(tester, expression: LumoFoxExpression.think);
    await tester.pump(const Duration(milliseconds: 300));
    await capture(tester, 'think');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    final paused = painter(tester).sample.elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(painter(tester).sample.elapsed, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter(tester).sample.elapsed, greaterThan(paused));
    await mount(tester, active: false);
    final hidden = painter(tester).sample.elapsed;
    await tester.pump(const Duration(seconds: 3));
    expect(painter(tester).sample.elapsed, hidden);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
