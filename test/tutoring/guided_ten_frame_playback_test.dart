import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/tutoring/guided_ten_frame_animation.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader(
      'Nunito',
    )..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  Future<void> show(
    WidgetTester tester, {
    bool reduced = false,
    double width = 360,
    Future<void> Function(String)? narrate,
    VoidCallback? stopNarration,
    bool autoNarrate = false,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF07172E),
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: const ValueKey('ten-frame-capture'),
              child: GuidedTenFrameAnimation(
                left: 8,
                right: 5,
                reduceMotion: reduced,
                onNarratePhase: narrate,
                onStopNarration: stopNarration,
                autoNarrate: autoNarrate,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Positioned apple(WidgetTester tester, int index) => tester.widget<Positioned>(
        find.byKey(ValueKey('guided-bridge-apple-$index')),
      );
  int inside(WidgetTester tester) => List.generate(
        13,
        (i) => apple(tester, i),
      ).where((a) => a.left! < (a.width! + 3) * 5).length;
  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(LumoQuantityArt), findsNWidgets(13));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets(
      'speech holds the matching phase; pause and seeks cancel stale completions',
      (tester) async {
    final spoken = <String>[];
    final finished = <Completer<void>>[];
    var stops = 0;
    await show(tester,
        autoNarrate: true,
        stopNarration: () => stops++,
        narrate: (text) {
          spoken.add(text);
          final completion = Completer<void>();
          finished.add(completion);
          return completion.future;
        });
    expect(spoken.single, '8 Äpfel sind im Zehnerfeld. 5 kommen dazu.');
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    final beforePause = stops;
    await tap(tester, 'ten-frame-play');
    expect(stops, greaterThan(beforePause));
    finished[0].complete();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    expect(spoken, hasLength(1));
    await tap(tester, 'ten-frame-play');
    expect(spoken, hasLength(2));
    finished[1].complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Schritt 2 von 6'), findsOneWidget);
    expect(spoken.last, 'Im Zehnerfeld sind noch 2 Plätze frei.');
    await tap(tester, 'ten-frame-next');
    expect(spoken.last, 'Schiebe 2 von den 5 Äpfeln in die freien Plätze.');
    final count = spoken.length;
    finished[2].complete();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 3 von 6'), findsOneWidget);
    expect(spoken.length, count);
    await tap(tester, 'ten-frame-back');
    expect(spoken.last, 'Im Zehnerfeld sind noch 2 Plätze frei.');
    await tap(tester, 'ten-frame-replay');
    expect(spoken.last, spoken.first);
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    await tap(tester, 'ten-frame-read');
    expect(find.text('Stimme stoppen'), findsNothing);
    await close(tester);
    for (final completion in finished) {
      if (!completion.isCompleted) completion.complete();
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'manual speech respects automatic-reading preference and reduced motion',
      (tester) async {
    final spoken = <String>[];
    final finished = <Completer<void>>[];
    await show(tester, reduced: true, narrate: (text) {
      spoken.add(text);
      final completion = Completer<void>();
      finished.add(completion);
      return completion.future;
    });
    expect(spoken, isEmpty);
    await tap(tester, 'ten-frame-replay');
    await tap(tester, 'ten-frame-next');
    expect(spoken, isEmpty);
    await tap(tester, 'ten-frame-read');
    expect(spoken.single, 'Im Zehnerfeld sind noch 2 Plätze frei.');
    finished.single.complete();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 2 von 6'), findsOneWidget);
    expect(find.byKey(const ValueKey('ten-frame-play')), findsNothing);
    await close(tester);
  });

  testWidgets(
      'speed, mute and background cannot leave old speech driving animation',
      (tester) async {
    final spoken = <String>[];
    final finished = <Completer<void>>[];
    var stops = 0;
    Future<void> narrate(String text) {
      spoken.add(text);
      final completion = Completer<void>();
      finished.add(completion);
      return completion.future;
    }

    await show(tester,
        autoNarrate: true, narrate: narrate, stopNarration: () => stops++);
    await tap(tester, 'ten-frame-speed');
    expect(spoken, hasLength(2));
    expect(spoken.last, spoken.first);
    finished.first.complete();
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    final beforeBackground = stops;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(stops, greaterThan(beforeBackground));
    finished.last.complete();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    await tap(tester, 'ten-frame-play');
    expect(spoken, hasLength(3));
      final beforeMute = stops;
    await show(tester);
      expect(stops, greaterThan(beforeMute));
    expect(find.byKey(const ValueKey('ten-frame-read')), findsNothing);
    finished.last.complete();
    await tester.pump(const Duration(seconds: 20));
    expect(spoken, hasLength(3));
    expect(find.text('Schritt 6 von 6'), findsOneWidget);
    await close(tester);
  });

  testWidgets('child can run and inspect each explanation step',
      (tester) async {
    await show(tester);
    await tap(tester, 'ten-frame-replay');
    for (var step = 0; step < 6; step++) {
      if (step > 0) await tap(tester, 'ten-frame-next');
      await tester.pump(const Duration(milliseconds: 250));
      expect(inside(tester), step < 3 ? 8 : 10);
      expect(find.text('Schritt ${step + 1} von 6'), findsOneWidget);
      final capture = Platform.environment['LUMO_TEN_FRAME_CAPTURES'];
      if (capture != null) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('ten-frame-capture')))
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(capture).create(recursive: true);
          await File('$capture/ten-frame-step-${step + 1}.png')
              .writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await close(tester);
  });

  testWidgets('pause, slow, back, replay and manual steps preserve 8+5', (
    tester,
  ) async {
    await show(tester);
    expect(inside(tester), 8);
    expect(find.textContaining('8 + 2 + 3 = 13'), findsNothing);
    await tap(tester, 'ten-frame-play');
    await tester.pump(const Duration(seconds: 12));
    expect(inside(tester), 8);
    await tap(tester, 'ten-frame-speed');
    expect(find.text('Tempo: langsam'), findsOneWidget);
    await tap(tester, 'ten-frame-play');
    await tester.pump(const Duration(seconds: 4));
    expect(inside(tester), 8, reason: 'Slow playback is still before movement');
    await tap(tester, 'ten-frame-play');
    await tap(tester, 'ten-frame-next');
    expect(inside(tester), 8);
    await tap(tester, 'ten-frame-next');
    expect(inside(tester), 10);
    await tap(tester, 'ten-frame-next');
    expect(find.textContaining('Daneben bleiben 3'), findsOneWidget);
    await tap(tester, 'ten-frame-next');
    expect(find.textContaining('8 + 2 + 3 = 13'), findsOneWidget);
    await tap(tester, 'ten-frame-back');
    expect(find.textContaining('8 + 2 + 3 = 13'), findsNothing);
    await tap(tester, 'ten-frame-replay');
    expect(inside(tester), 8);
    await tester.pump(const Duration(seconds: 20));
    expect(inside(tester), 8, reason: 'Replay resets but waits for the child');
    await close(tester);
  });

  testWidgets('backgrounding pauses exactly and does not autoplay on return', (
    tester,
  ) async {
    await show(tester);
    await tester.pump(const Duration(seconds: 4));
    final before = apple(tester, 8).left;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 12));
    expect(apple(tester, 8).left, before);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 12));
    expect(apple(tester, 8).left, before);
    expect(find.text('Abspielen'), findsOneWidget);
    await close(tester);
  });

  for (final width in [260.0, 360.0, 720.0]) {
    testWidgets('exact ten plus three and 48dp controls at $width', (
      tester,
    ) async {
      await show(tester, reduced: true, width: width);
      expect(inside(tester), 10);
      expect(find.byType(LumoQuantityArt), findsNWidgets(13));
      expect(find.byKey(const ValueKey('ten-frame-play')), findsNothing);
      for (final key in [
        'ten-frame-back',
        'ten-frame-next',
        'ten-frame-replay',
      ]) {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(target).width, greaterThanOrEqualTo(48));
        final rect = tester.getRect(target);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
      }
      final capture = Platform.environment['LUMO_TEN_FRAME_CAPTURES'];
      if (capture != null) {
        await tester.runAsync(() async {
          final image = await tester
              .renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('ten-frame-capture')),
              )
              .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(capture).create(recursive: true);
          await File(
            '$capture/ten-frame-${width.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tap(tester, 'ten-frame-replay');
      expect(inside(tester), 8);
      await tap(tester, 'ten-frame-next');
      await tester.pump(const Duration(seconds: 8));
      expect(inside(tester), 8, reason: 'Reduced motion never starts a ticker');
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }
}
