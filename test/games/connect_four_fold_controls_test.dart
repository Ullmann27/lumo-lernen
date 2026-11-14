import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lumo_lernen/connect_four'),
            (_) async =>
                throw MissingPluginException('Flutter fallback fixture'));
  });
  testWidgets(
      'Fold outer-screen at 320dp: all seven real 48dp column buttons remain reachable',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
    await app.hydrateFromWallet();
    LumoVoice.instance.isEnabled = false;
    await tester.pumpWidget(MaterialApp(
      home: LumoConnectFourScreen(appState: app, seed: 1978),
    ));
    await tester.pumpAndSettle();

    // Use the actual local two-player game, not a mocked board.
    await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
    await tester.pump();
    final scroll = find.byKey(const ValueKey('connect-column-scroll'));
    expect(scroll, findsOneWidget);
    for (var i = 0; i < 7; i++) {
      expect(find.byKey(ValueKey('connect-column-$i')), findsOneWidget);
    }

    // Last physical column must remain accessible even when all seven
    // non-shrunk touch targets exceed the device's outer-screen width.
    for (var i = 0; i < 7; i++) {
      final size = tester.getSize(find.byKey(ValueKey('connect-column-$i')));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      final button = tester.getRect(find.byKey(ValueKey('connect-column-$i')));
      final cell = tester.getRect(find.byKey(ValueKey('connect-cell-5-$i')));
      expect(button.center.dx, closeTo(cell.center.dx, 1),
          reason: 'Scrolling controls and board must share one column pitch.');
    }
    final lastColumn = find.byKey(const ValueKey('connect-column-6'));
    await tester.ensureVisible(lastColumn);
    await tester.pump();
    final viewport = tester.getRect(scroll);
    final lastTarget = tester.getRect(lastColumn);
    expect(lastTarget.left, greaterThanOrEqualTo(viewport.left));
    expect(lastTarget.right, lessThanOrEqualTo(viewport.right));
    expect(lastTarget.top, greaterThanOrEqualTo(viewport.top));
    expect(lastTarget.bottom, lessThanOrEqualTo(viewport.bottom));
    for (var i = 0; i < 7; i++) {
      final button = tester.getRect(find.byKey(ValueKey('connect-column-$i')));
      final cell = tester.getRect(find.byKey(ValueKey('connect-cell-5-$i')));
      expect(button.center.dx, closeTo(cell.center.dx, 1),
          reason: 'Board cells must follow the same horizontal scroll offset.');
    }
    expect(lastColumn.hitTestable(), findsOneWidget);
    final gesture = await tester.startGesture(lastTarget.center);
    try {
      await tester.pump(const Duration(milliseconds: 150));
      final pressedTarget = tester.getRect(lastColumn);
      final pressedSize = tester.getSize(lastColumn);
      expect(pressedSize.width, greaterThanOrEqualTo(48));
      expect(pressedSize.height, greaterThanOrEqualTo(48));
      // Global-coordinate subtraction can round 48dp to 47.99999999999997.
      // This tolerance cannot hide a pressed transform shrinking the target.
      expect(pressedTarget.width, closeTo(pressedSize.width, 1e-9));
      expect(pressedTarget.height, closeTo(pressedSize.height, 1e-9));
    } finally {
      await gesture.up();
    }
    await tester.pump(const Duration(milliseconds: 450));
    final actualCell = tester.widget<Semantics>(
      find.byKey(const ValueKey('connect-cell-5-6')),
    );
    expect(actualCell.properties.label, endsWith(': child'));
    expect(tester.takeException(), isNull);
  });
}
