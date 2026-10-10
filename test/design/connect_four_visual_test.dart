import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  for (final size in const [
    Size(360, 800),
    Size(640, 360),
    Size(1280, 720),
    Size(740, 840),
  ]) {
    testWidgets('Connect Four layout ${size.width}x${size.height}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      await app.hydrateFromWallet();
      const key = ValueKey('connect-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: key,
          child: LumoConnectFourScreen(appState: app, seed: 1),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(LumoConnectFourScreen));
        for (final asset in [
          'assets/lumo_design/bg/bg_glass_islands.png',
          'assets/lumo_design/fox/fox_thumb_wink.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pump();
      // Capture actual gameplay, not an empty concept board.
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await tester.pump();
      for (final column in [3, 2, 3, 2, 4, 5]) {
        await tester.tap(find.byKey(ValueKey('connect-column-$column')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
      }
      final folder = Platform.environment['LUMO_CONNECT_CAPTURES'];
      if (folder != null) {
        final boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('$folder/${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
