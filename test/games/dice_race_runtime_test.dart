import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/features/games/dice_race/lumo_dice_race_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

const boundary = ValueKey('dice-capture');

Future<void> capture(WidgetTester tester, String name) async {
  final folder = Platform.environment['LUMO_DICE_CAPTURES'];
  if (folder == null) return;
  await tester.runAsync(() async {
    await Future.wait(tester.widgetList<Image>(find.byType(Image)).map(
        (image) =>
            precacheImage(image.image, tester.element(find.byWidget(image)))));
  });
  await tester.pump();
  await tester.runAsync(() async {
    final render =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundary));
    final image = await render.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$folder/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final size in const [
    Size(360, 640),
    Size(392, 850),
    Size(967, 805),
    Size(926, 362),
    Size(640, 360),
    Size(568, 320),
    Size(1280, 800)
  ]) {
    testWidgets('Actual dice game fits $size with enlarged text',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      app.updateSettings(const AppSettings(
          voiceEnabled: false,
          soundEnabled: false,
          autoReadEnabled: false,
          reduceAnimations: true));
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  size: size, textScaler: TextScaler.linear(1.6)),
              child: RepaintBoundary(
                  key: boundary,
                  child: LumoDiceRaceScreen(appState: app, seed: 17)))));
      await tester.pump(const Duration(milliseconds: 100));
      await capture(
          tester, 'dice-${size.width.toInt()}x${size.height.toInt()}');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('dice-roll')).hitTestable(),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dice-roll')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      expect(find.textContaining('gehst'), findsOneWidget);
      await capture(tester,
          'dice-after-move-${size.width.toInt()}x${size.height.toInt()}');
      expect(find.textContaining(' / 30'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Pausieren / Zurück'));
      await tester.pump();
      expect(find.text('Fortsetzen'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
