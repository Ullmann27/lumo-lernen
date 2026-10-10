import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

int pieces(WidgetTester tester, String player) => find
    .byWidgetPredicate((widget) =>
        widget is Semantics &&
        (widget.properties.label?.startsWith('Reihe ') ?? false) &&
        (widget.properties.label?.endsWith(': $player') ?? false))
    .evaluate()
    .length;

Future<LumoAppState> setupGame(WidgetTester tester,
    {bool reduced = false}) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = LumoAppState();
  await app.hydrateFromWallet();
  await tester.pumpWidget(MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
      child: child!,
    ),
    home: LumoConnectFourScreen(appState: app, seed: 1),
  ));
  await tester.pump();
  return app;
}

void main() {
  testWidgets('double taps are locked and paused bot never advances',
      (tester) async {
    final app = await setupGame(tester);
    await tester.tap(find.byKey(const ValueKey('connect-column-0')));
    await tester.tap(find.byKey(const ValueKey('connect-column-1')));
    await tester.pump();
    expect(pieces(tester, 'child'), 1);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('Pausieren / Zurück'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(pieces(tester, 'lumo'), 0);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    await tester.tap(find.text('Fortsetzen'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));
    expect(pieces(tester, 'lumo'), 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('local two-player win rewards once and replay preserves wallet',
      (tester) async {
    final app = await setupGame(tester, reduced: true);
    await tester.tap(find.byKey(const ValueKey('connect-mode-true')));
    await tester.pump();
    for (final c in [0, 6, 1, 6, 2, 5, 3]) {
      await tester.tap(find.byKey(ValueKey('connect-column-$c')));
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
    }
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(app.state.stars, 5);
    await tester.tap(find.text('Nochmal!'));
    await tester.pump();
    expect(pieces(tester, 'child'), 0);
    expect(pieces(tester, 'lumo'), 0);
    expect(app.state.stars, 5);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });

  testWidgets('restart mid-fall invalidates old animation and bot callbacks',
      (tester) async {
    final app = await setupGame(tester);
    await tester.tap(find.byKey(const ValueKey('connect-column-0')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Neu starten'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(pieces(tester, 'child'), 0);
    expect(pieces(tester, 'lumo'), 0);
    expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('connect-column-0')))
            .onPressed,
        isNotNull);
    expect(app.state.stars, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
