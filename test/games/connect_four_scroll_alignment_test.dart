import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('lumo_lernen/connect_four'),
            (_) async =>
                throw MissingPluginException('Flutter fallback fixture'));
  });

  for (final size in const [
    Size(320, 740),
    Size(360, 800),
    Size(640, 360),
  ]) {
    testWidgets(
        '48dp columns stay aligned and playable while scrolling at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      LumoVoice.instance.isEnabled = false;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });
      await tester.pumpWidget(MaterialApp(
        home: LumoConnectFourScreen(appState: app, seed: 1978),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
      await tester.pumpAndSettle();

      final scroll = find.byKey(const ValueKey('connect-column-scroll'));
      for (final column in [0, 1, 2, 3, 4, 5, 6, 0]) {
        final control = find.byKey(ValueKey('connect-column-$column'));
        await tester.ensureVisible(control);
        await tester.pump();
        final viewport = tester.getRect(scroll);
        final target = tester.getRect(control);
        expect(control.hitTestable(), findsOneWidget);
        final targetSize = tester.getSize(control);
        expect(targetSize.width, greaterThanOrEqualTo(48));
        expect(targetSize.height, greaterThanOrEqualTo(48));
        // Global-coordinate subtraction permits only arithmetic roundoff;
        // the actual RenderBox must still provide a full 48dp touch target.
        expect(target.width, closeTo(targetSize.width, 1e-9));
        expect(target.height, closeTo(targetSize.height, 1e-9));
        expect(target.left, greaterThanOrEqualTo(viewport.left - .01));
        expect(target.right, lessThanOrEqualTo(viewport.right + .01));
        Rect? previous;
        for (var c = 0; c < 7; c++) {
          final button =
              tester.getRect(find.byKey(ValueKey('connect-column-$c')));
          final cell =
              tester.getRect(find.byKey(ValueKey('connect-cell-5-$c')));
          expect(button.center.dx, closeTo(cell.center.dx, 1),
              reason:
                  'Scrolling must keep every button below its actual column.');
          if (previous != null) {
            expect(previous.right, lessThanOrEqualTo(button.left + .01),
                reason: 'Adjacent touch targets must never overlap.');
          }
          previous = button;
        }
        await tester.tap(control);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump();
      }
      for (var c = 0; c < 7; c++) {
        final cell =
            tester.widget<Semantics>(find.byKey(ValueKey('connect-cell-5-$c')));
        expect(cell.properties.label,
            endsWith(': ${c.isEven ? 'child' : 'lumo'}'));
      }
      expect(
          tester
              .widget<Semantics>(find.byKey(const ValueKey('connect-cell-4-0')))
              .properties
              .label,
          endsWith(': lumo'),
          reason:
              'Returning from the last column must keep the first playable.');
      expect(tester.takeException(), isNull);
    });
  }
}
