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

Future<void> _ready(WidgetTester tester) async {
  for (var frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    final buttons = [
      for (var c = 0; c < 7; c++) find.byKey(ValueKey('connect-column-$c')),
    ];
    if (find.text('Spiel pausiert').evaluate().isEmpty &&
        buttons.every((finder) =>
            finder.evaluate().length == 1 &&
            tester.widget<IconButton>(finder).onPressed != null)) {
      return;
    }
  }
  fail('The actual Flutter round did not become ready within 2 seconds.');
}

void _alignedTouchTargets(WidgetTester tester) {
  for (var column = 0; column < 7; column++) {
    final control =
        tester.getRect(find.byKey(ValueKey('connect-column-$column')));
    final cell = tester.getRect(find.byKey(ValueKey('connect-cell-5-$column')));
    expect(control.width, greaterThanOrEqualTo(48));
    expect(control.height, greaterThanOrEqualTo(48));
    expect(control.center.dx, closeTo(cell.center.dx, .1),
        reason: 'Column $column must remain under its own board cells.');
  }
}

void _expectPieces(WidgetTester tester,
    {required int child, required int lumo}) {
  var actualChild = 0;
  var actualLumo = 0;
  for (var row = 0; row < 6; row++) {
    for (var column = 0; column < 7; column++) {
      final label = tester
          .widget<Semantics>(find.byKey(ValueKey('connect-cell-$row-$column')))
          .properties
          .label!;
      if (label.endsWith(': child')) actualChild++;
      if (label.endsWith(': lumo')) actualLumo++;
    }
  }
  expect(actualChild, child);
  expect(actualLumo, lumo);
}

Future<void> _swipe(
    WidgetTester tester, Finder viewport, Offset distance) async {
  final rect = tester.getRect(viewport);
  await tester.dragFrom(Offset(rect.center.dx, rect.bottom - 24), distance);
  final scrollable =
      find.descendant(of: viewport, matching: find.byType(Scrollable)).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  for (var frame = 0; frame < 75; frame++) {
    await tester.pump(const Duration(milliseconds: 20));
    if (!position.isScrollingNotifier.value) {
      await tester.pumpAndSettle(const Duration(milliseconds: 20),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
      return;
    }
  }
  fail('The actual finger swipe did not settle within 1.5 seconds.');
}

void _fullyVisible(
    WidgetTester tester, Finder control, Finder viewport, Size screenSize) {
  final rect = tester.getRect(control);
  final visibleViewport =
      tester.getRect(viewport).intersect(Offset.zero & screenSize);
  final exposed = rect.intersect(visibleViewport);
  expect(exposed.width, greaterThanOrEqualTo(48 - .001),
      reason: 'The whole 48dp-wide touch target must be exposed.');
  expect(exposed.height, greaterThanOrEqualTo(48 - .001),
      reason: 'The whole 48dp-high touch target must be exposed.');
  expect(control.hitTestable(), findsOneWidget);
}

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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lumo_lernen/connect_four'),
            (_) async =>
                throw MissingPluginException('Flutter fallback fixture'));
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lumo_lernen/connect_four'), null);
  });

  for (final scenario in const [
    (size: Size(320, 740), textScale: 1.0),
    (size: Size(360, 800), textScale: 1.0),
    (size: Size(640, 360), textScale: 1.0),
    (size: Size(320, 480), textScale: 2.0),
  ]) {
    testWidgets(
        'C4 shared board swipe and real 48dp drops '
        '${scenario.size.width}x${scenario.size.height} '
        'text ${scenario.textScale}', (tester) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      LumoVoice.instance.isEnabled = false;
      const capture = ValueKey('connect-fold-capture');
      try {
        await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scenario.textScale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: capture,
            child: LumoConnectFourScreen(appState: app, seed: 1978),
          ),
        ));
        await _ready(tester);
        await tester.runAsync(() async {
          final context = tester.element(find.byType(LumoConnectFourScreen));
          for (final asset in [
            'assets/lumo_design/bg/bg_glass_islands.png',
            'assets/lumo_design/fox/fox_thumb_wink.png',
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
        });
        final mode = find.byKey(const ValueKey('connect-mode-true'));
        await tester.ensureVisible(mode);
        await tester.pump();
        expect(mode.hitTestable(), findsOneWidget);
        await tester.tap(mode);
        await _ready(tester);
        expect(find.byKey(const ValueKey('connect-level-mittel')), findsNothing,
            reason:
                'The real two-player mode must have replaced the bot controls.');
        _expectPieces(tester, child: 0, lumo: 0);

        final viewport = find.byKey(const ValueKey('connect-column-scroll'));
        expect(viewport, findsOneWidget);
        await tester.ensureVisible(viewport);
        await tester.pump();
        _alignedTouchTargets(tester);
        final scrollable = find
            .descendant(of: viewport, matching: find.byType(Scrollable))
            .first;
        final position = tester.state<ScrollableState>(scrollable).position;
        expect(position.maxScrollExtent, greaterThan(0));
        final before = position.pixels;

        // Move the real viewport with pointer events, not jumpTo/ensureVisible.
        await _swipe(tester, viewport, const Offset(-220, 0));
        expect(position.pixels, greaterThan(before));
        _alignedTouchTargets(tester);
        final lastColumn = find.byKey(const ValueKey('connect-column-6'));
        _fullyVisible(tester, lastColumn, viewport, scenario.size);
        await tester.tap(lastColumn);
        await _ready(tester);
        expect(
            tester
                .widget<Semantics>(
                    find.byKey(const ValueKey('connect-cell-5-6')))
                .properties
                .label,
            endsWith(': child'));
        _expectPieces(tester, child: 1, lumo: 0);

        // A reverse finger swipe must keep the first column equally precise.
        await _swipe(tester, viewport, const Offset(220, 0));
        _alignedTouchTargets(tester);
        final firstColumn = find.byKey(const ValueKey('connect-column-0'));
        _fullyVisible(tester, firstColumn, viewport, scenario.size);
        await tester.tap(firstColumn);
        await _ready(tester);
        expect(
            tester
                .widget<Semantics>(
                    find.byKey(const ValueKey('connect-cell-5-0')))
                .properties
                .label,
            endsWith(': lumo'));
        _expectPieces(tester, child: 1, lumo: 1);
        expect(tester.takeException(), isNull);

        final folder = Platform.environment['LUMO_CONNECT_CAPTURES'];
        if (folder != null) {
          final boundary =
              tester.renderObject<RenderRepaintBoundary>(find.byKey(capture));
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            try {
              final data =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File('$folder/fold-'
                  '${scenario.size.width.toInt()}x${scenario.size.height.toInt()}-'
                  'text${scenario.textScale}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(data!.buffer.asUint8List());
            } finally {
              image.dispose();
            }
          });
        }
      } finally {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      }
    });
  }
}
