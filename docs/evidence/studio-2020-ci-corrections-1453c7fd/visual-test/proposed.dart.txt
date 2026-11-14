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

bool _columnsReady(WidgetTester tester) {
  if (find.byKey(const ValueKey('lumo-pause-panel')).evaluate().isNotEmpty) {
    return false;
  }
  for (var column = 0; column < 7; column++) {
    final control = find.byKey(ValueKey('connect-column-$column'));
    if (control.evaluate().length != 1 ||
        tester.widget<IconButton>(control).onPressed == null) {
      return false;
    }
  }
  return true;
}

int _placedPieces() => find
    .byWidgetPredicate((widget) =>
        widget is Semantics &&
        (widget.properties.label?.startsWith('Reihe ') ?? false) &&
        ((widget.properties.label?.endsWith(': child') ?? false) ||
            (widget.properties.label?.endsWith(': lumo') ?? false)))
    .evaluate()
    .length;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() ready, {
  required String reason,
}) async {
  // Drain the real async fallback/save and animation work, with a hard bound.
  // A mounted but paused or disabled control is not a ready game.
  for (var frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (ready()) return;
  }
  expect(ready(), isTrue, reason: reason);
}

Future<void> _showColumn(WidgetTester tester, int column) async {
  final finder = find.byKey(ValueKey('connect-column-$column'));
  await tester.ensureVisible(finder);
  await tester.pump();
  expect(finder.hitTestable(), findsOneWidget,
      reason: 'Column ${column + 1} must be reachable by a real tap.');
  expect(tester.widget<IconButton>(finder).onPressed, isNotNull);
  final control = tester.getRect(finder);
  final cell =
      tester.getRect(find.byKey(ValueKey('connect-cell-5-$column')));
  expect(control.width, greaterThanOrEqualTo(48));
  expect(control.height, greaterThanOrEqualTo(48));
  expect(control.center.dx, closeTo(cell.center.dx, 1),
      reason: 'Each drop button must align with its board column.');
}

void main() {
  const nativeChannel = MethodChannel('lumo_lernen/connect_four');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, (_) async {
      throw MissingPluginException('Flutter fallback fixture');
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(nativeChannel, null);
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
      await app.hydrateFromWallet();
      LumoVoice.instance.isEnabled = false;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
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
      await _pumpUntil(tester, () => _columnsReady(tester),
          reason: 'The unavailable native session must finish and resume '
              'the Flutter board before any game input.');
      expect(_placedPieces(), 0);
      // Capture actual gameplay, not an empty concept board.
      final twoPlayers = find.byKey(const ValueKey('connect-mode-true'));
      await tester.ensureVisible(twoPlayers);
      await tester.pump();
      expect(twoPlayers.hitTestable(), findsOneWidget);
      expect(tester.widget<FilledButton>(twoPlayers).onPressed, isNotNull);
      await tester.tap(twoPlayers);
      await _pumpUntil(
        tester,
        () =>
            find.byKey(const ValueKey('connect-level-mittel')).evaluate().isEmpty &&
            _columnsReady(tester),
        reason: 'The actual two-player selection must finish saving.',
      );
      const moves = [
        (column: 3, row: 5, player: 'child'),
        (column: 2, row: 5, player: 'lumo'),
        (column: 3, row: 4, player: 'child'),
        (column: 2, row: 4, player: 'lumo'),
        (column: 4, row: 5, player: 'child'),
        (column: 5, row: 5, player: 'lumo'),
      ];
      for (var index = 0; index < moves.length; index++) {
        final move = moves[index];
        await _showColumn(tester, move.column);
        await tester.tap(find.byKey(ValueKey('connect-column-${move.column}')));
        await _pumpUntil(
          tester,
          () => _placedPieces() == index + 1 && _columnsReady(tester),
          reason: 'Move ${index + 1} must persist and finish its drop animation.',
        );
        final cell = tester.widget<Semantics>(
          find.byKey(ValueKey('connect-cell-${move.row}-${move.column}')),
        );
        expect(cell.properties.label, endsWith(': ${move.player}'));
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
      for (var column = 0; column < 7; column++) {
        await _showColumn(tester, column);
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
