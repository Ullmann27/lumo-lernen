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
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  const bridge = MethodChannel('lumo_lernen/connect_four');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            bridge,
            (_) async =>
                throw MissingPluginException('Flutter fallback fixture'));
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, null);
  });
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
    Size(1200, 896),
  ]) {
    testWidgets('Connect Four layout ${size.width}x${size.height}',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      LumoVoice.instance.isEnabled = false;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
      await app.hydrateFromWallet();
      const key = ValueKey('connect-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: key,
          child: LumoConnectFourScreen(appState: app, seed: 1),
        ),
      ));
      await _waitForPlayableBoard(tester);
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
      expect(find.byKey(const ValueKey('connect-mode-true')).hitTestable(),
          findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await _waitForPlayableBoard(tester);
      expect(find.byKey(const ValueKey('connect-level-mittel')), findsNothing);
      for (final column in [3, 2, 3, 2, 4, 5]) {
        final control = find.byKey(ValueKey('connect-column-$column'));
        await tester.ensureVisible(control);
        await tester.pump();
        expect(control.hitTestable(), findsOneWidget);
        await tester.tap(control);
        await _waitForPlayableBoard(tester);
      }
      var occupiedCells = 0;
      for (var row = 0; row < 6; row++) {
        for (var column = 0; column < 7; column++) {
          final cell = tester.widget<Semantics>(
              find.byKey(ValueKey('connect-cell-$row-$column')));
          if (!cell.properties.label!.endsWith(': empty')) occupiedCells++;
        }
      }
      expect(occupiedCells, 6,
          reason: 'The capture must show all six real moves.');
      if (size.width > size.height) {
        final fox =
            tester.getRect(find.byKey(const ValueKey('connect-companion-fox')));
        final controls =
            tester.getRect(find.byKey(const ValueKey('connect-column-3')));
        expect(fox.top, greaterThanOrEqualTo(0));
        expect(fox.bottom, lessThanOrEqualTo(controls.top),
            reason: 'The complete mascot must fit above the game controls.');
      }
      for (var column = 0; column < 7; column++) {
        final cell =
            tester.getRect(find.byKey(ValueKey('connect-cell-5-$column')));
        final controlFinder = find.byKey(ValueKey('connect-column-$column'));
        final control = tester.getRect(controlFinder);
        final controlSize = tester.getSize(controlFinder);
        expect(control.center.dx, closeTo(cell.center.dx, 1),
            reason: 'Each drop button must align with its board column.');
        expect(controlSize.width, greaterThanOrEqualTo(48));
        expect(controlSize.height, greaterThanOrEqualTo(48));
        // Rect dimensions subtract global coordinates. Allow only arithmetic
        // roundoff, while requiring the untransformed target to remain 48dp.
        expect(control.width, closeTo(controlSize.width, 1e-9));
        expect(control.height, closeTo(controlSize.height, 1e-9));
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
    });
  }
}

Future<void> _waitForPlayableBoard(WidgetTester tester) async {
  final column = find.byKey(const ValueKey('connect-column-0'));
  for (var frame = 0; frame < 50; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (column.evaluate().isNotEmpty &&
        tester.widget<IconButton>(column).onPressed != null &&
        find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isEmpty) {
      return;
    }
  }
  fail('The real Flutter board did not become playable within five seconds.');
}
