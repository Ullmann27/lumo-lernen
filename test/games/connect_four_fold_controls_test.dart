import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/games/connect_four/lumo_connect_four_game.dart';

void main() {
  testWidgets(
      'Fold outer-screen at 320dp: all seven real 44dp column buttons remain reachable',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    await tester.binding.setSurfaceSize(const Size(320, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    await app.hydrateFromWallet();
    await tester.pumpWidget(MaterialApp(
      home: LumoConnectFourScreen(appState: app, seed: 1978),
    ));
    await tester.pump();

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
    final lastColumn = find.byKey(const ValueKey('connect-column-6'));
    await tester.ensureVisible(lastColumn);
    await tester.pump();
    await tester.tap(lastColumn);
    await tester.pump(const Duration(milliseconds: 450));
    final actualCell = tester.widget<Semantics>(
      find.byKey(const ValueKey('connect-cell-5-6')),
    );
    expect(actualCell.properties.label, endsWith(': child'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
