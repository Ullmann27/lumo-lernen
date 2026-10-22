import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/quiz/quiz_show_content.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _capture(WidgetTester tester, String name,
    Size viewport, double textScale, String phase) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('quiz-visual-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Quiz screenshot has no PNG bytes');
      final directory = Directory('.ci-results/quiz-premium-stage');
      await directory.create(recursive: true);
      final output = File('${directory.path}/$name.png');
      await output.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      final source = File('.ci-results/source-sha.txt');
      await File('${directory.path}/$name.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'source_commit': await source.exists()
              ? (await source.readAsString()).trim()
              : 'not-recorded-local-run',
          'capture_kind': 'actual Flutter widget-test rendering',
          'android_or_physical_device_capture': false,
          'reference_match_approved': false,
          'viewport_width': viewport.width,
          'viewport_height': viewport.height,
          'text_scale': textScale,
          'phase': phase,
          'png_width': image.width,
          'png_height': image.height,
          'png_bytes': await output.length(),
        }),
        flush: true,
      );
    } finally {
      image.dispose();
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    final voiceEnabled = LumoVoice.instance.isEnabled;
    LumoVoice.instance.isEnabled = false;
    addTearDown(() => LumoVoice.instance.isEnabled = voiceEnabled);
  });

  for (final width in <double>[320, 420, 1024]) {
    for (final textScale in <double>[1, 1.5]) {
      testWidgets('Premium quiz capture $width px at text scale $textScale',
          (tester) async {
        final viewport = Size(width, 1200);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        addTearDown(app.dispose);
        await tester.runAsync(() async {
          await app.ensureSettingsLoaded();
          app.updateSettings(const AppSettings(
            voiceEnabled: false,
            soundEnabled: false,
            autoReadEnabled: false,
            microphoneEnabled: false,
            aiProxyEnabled: false,
            reduceAnimations: true,
            calmMode: true,
          ));
        });
        await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('quiz-visual-capture'),
            // Same actual question and answer placement in every viewport.
            child: QuizShowContent(
              appState: app,
              previewQuestionSeed: 20261015,
            ),
          ),
        ));
        await _frames(tester);
        final captureContext = tester.element(
            find.byKey(const ValueKey('quiz-visual-capture')));
        for (final image in tester.widgetList<Image>(find.byType(Image))) {
          await tester.runAsync(() => precacheImage(image.image, captureContext));
        }
        await _frames(tester);
        expect(find.byKey(const ValueKey('lumo-meister-stage')), findsOneWidget);
        expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
        expect(find.text('50:50'), findsOneWidget);
        expect(find.text('Publikum'), findsOneWidget);
        expect(find.text('Lumo-Tipp'), findsOneWidget);
        expect(tester.takeException(), isNull);
        final prefix = '${width.toInt()}px-scale-${textScale.toStringAsFixed(1)}';
        await _capture(tester, '$prefix-initial', viewport, textScale, 'initial');

        final answer = find.byKey(const ValueKey('lumo-meister-answer-0'));
        expect(answer, findsOneWidget);
        await tester.ensureVisible(answer);
        await tester.pump();
        await tester.tap(answer);
        await _frames(tester);
        final reveal = find.text('Antwort einloggen');
        expect(reveal, findsOneWidget);
        await tester.ensureVisible(reveal);
        await tester.pump();
        await tester.tap(reveal);
        await tester.pump(const Duration(milliseconds: 220));
        expect(find.text('Lumo prüft deine Antwort …'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$prefix-locking', viewport, textScale, 'locking');

        // Reduced-motion accessibility uses the real 750ms delay.
        // Do not label a screenshot "revealed" while the quiz is still
        // displaying the suspense bar instead of its actual answer.
        await tester.pump(const Duration(milliseconds: 650));
        await _frames(tester);
        expect(find.text('Lumo prüft deine Antwort …'), findsNothing);
        expect(find.byKey(const ValueKey('lumo-meister-fox')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _capture(tester, '$prefix-revealed', viewport, textScale, 'revealed');
        await tester.pumpWidget(const SizedBox.shrink());
        await _frames(tester);
      }, timeout: const Timeout(Duration(seconds: 45)));
    }
  }
}
