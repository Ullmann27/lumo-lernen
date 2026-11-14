import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  for (final size in const [Size(320, 740), Size(640, 360)]) {
    testWidgets(
        'Connect Four pushes, leaves and restores its real route at $size',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final previousHitTestPolicy =
          WidgetController.hitTestWarningShouldBeFatal;
      WidgetController.hitTestWarningShouldBeFatal = true;
      addTearDown(() {
        WidgetController.hitTestWarningShouldBeFatal = previousHitTestPolicy;
      });
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      const table = MethodChannel('lumo_lernen/connect_four');
      var nativeAttempts = 0;
      messenger.setMockMethodCallHandler(table, (call) async {
        if (call.method == 'open') nativeAttempts++;
        throw MissingPluginException('Flutter fallback fixture');
      });
      addTearDown(() => messenger.setMockMethodCallHandler(table, null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      LumoVoice.instance.isEnabled = false;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        app.dispose();
      });

      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          return Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        LumoConnectFourScreen(appState: app, seed: 1978),
                  ),
                ),
                child: const Text('Spielauswahl'),
              ),
            ),
          );
        }),
      ));

      Future<void> settle() => tester.pumpAndSettle(
            const Duration(milliseconds: 100),
            EnginePhase.sendSemanticsUpdate,
            const Duration(seconds: 5),
          );
      Future<void> tapVisible(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pump();
        expect(finder.hitTestable(), findsOneWidget);
        await tester.tap(finder);
      }

      await tester.tap(find.text('Spielauswahl'));
      await settle();
      expect(nativeAttempts, 1);
      expect(find.text('Spiel pausiert'), findsNothing);
      expect(find.byType(LumoConnectFourScreen), findsOneWidget);
      await tapVisible(find.byKey(const ValueKey('connect-mode-true')));
      await settle();
      final lastColumn = find.byKey(const ValueKey('connect-column-6'));
      await tapVisible(lastColumn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(tester.getSize(lastColumn).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(lastColumn).height, greaterThanOrEqualTo(48));
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('connect-cell-5-6')))
            .properties
            .label,
        endsWith(': child'),
      );

      await tester.tap(find.byTooltip('Pausieren / Zurück'));
      await tester.pump();
      expect(find.text('Spiel pausiert'), findsOneWidget);
      final leave = find.byKey(const ValueKey('pause-leave-games'));
      await tapVisible(leave);
      await settle();
      expect(find.byType(LumoConnectFourScreen), findsNothing);
      expect(find.text('Spielauswahl'), findsOneWidget);
      expect(Navigator.of(tester.element(find.text('Spielauswahl'))).canPop(),
          isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(app.state.stars, 0);

      await tester.tap(find.text('Spielauswahl'));
      await settle();
      expect(nativeAttempts, 2);
      expect(find.text('Spiel pausiert'), findsNothing);
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('connect-cell-5-6')))
            .properties
            .label,
        endsWith(': child'),
        reason: 'Leaving and reopening must preserve the same saved board.',
      );
      await tapVisible(find.byKey(const ValueKey('connect-column-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      expect(
        tester
            .widget<Semantics>(find.byKey(const ValueKey('connect-cell-5-0')))
            .properties
            .label,
        endsWith(': lumo'),
        reason:
            'The restored two-player round must keep Gold as the next turn.',
      );
      expect(tester.takeException(), isNull);
    });
  }
}
