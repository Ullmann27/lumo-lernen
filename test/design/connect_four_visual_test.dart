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
  const channel = MethodChannel('lumo_lernen/connect_four');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel,
            (_) async => throw MissingPluginException('Flutter fallback fixture'));
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
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
      final app = LumoAppState();
      await app.hydrateFromWallet();
      LumoVoice.instance.isEnabled = false;
      const key = ValueKey('connect-capture');
      await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: key,
          child: LumoConnectFourScreen(appState: app, seed: 1),
        ),
      ));
      await tester.pumpAndSettle();
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
      // The compact landscape companion panel and narrow column strip are
      // intentionally scrollable. Reach the real controls before touching them.
      final twoPlayers = find.byKey(const ValueKey('connect-mode-true'));
      await tester.ensureVisible(twoPlayers);
      await tester.pump();
      expect(twoPlayers.hitTestable(), findsOneWidget);
      await tester.tap(twoPlayers);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('connect-level-mittel')), findsNothing);

      // Exercise every actual column once. The alternating bottom row cannot
      // finish the game, and proves that each visible target maps to its column.
      for (var column = 0; column < 7; column++) {
        final control = find.byKey(ValueKey('connect-column-$column'));
        final targetSize = tester.getSize(control);
        expect(targetSize.width, greaterThanOrEqualTo(48));
        expect(targetSize.height, greaterThanOrEqualTo(48));
        await tester.ensureVisible(control);
        await tester.pump();
        expect(control.hitTestable(), findsOneWidget);
        expect(tester.widget<IconButton>(control).onPressed, isNotNull);
        await tester.tap(control);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        final cell =
            tester.widget<Semantics>(find.byKey(ValueKey('connect-cell-5-$column')));
        expect(cell.properties.label,
            endsWith(column.isEven ? ': child' : ': lumo'));
      }
      if (size.width > size.height) {
        final fox =
            tester.getRect(find.byKey(const ValueKey('connect-companion-fox')));
        final controls =
            tester.getRect(find.byKey(const ValueKey('connect-column-3')));
        expect(fox.top, greaterThanOrEqualTo(0));
        expect(fox.bottom, lessThanOrEqualTo(controls.top),
            reason: 'The complete mascot must fit above the game controls.');
      }
      final columnViewport =
          find.byKey(const ValueKey('connect-column-scroll'));
      final scrollState = tester.state<ScrollableState>(find.descendant(
          of: columnViewport, matching: find.byType(Scrollable)));
      if (scrollState.position.maxScrollExtent <= 0) {
        for (var column = 0; column < 7; column++) {
          final cell =
              tester.getRect(find.byKey(ValueKey('connect-cell-5-$column')));
          final control =
              tester.getRect(find.byKey(ValueKey('connect-column-$column')));
          expect(control.center.dx, closeTo(cell.center.dx, 1),
              reason: 'When all 48dp targets fit, each must align with its column.');
        }
      } else {
        expect(tester.getSize(columnViewport).width, lessThan(7 * 48 + 24),
            reason: 'Scrolling is only needed when seven full touch targets do not fit.');
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
