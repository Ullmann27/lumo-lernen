import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';

/// Die Antwortkarten sind für den Vorleser Schaltflächen mit „Antwort N“.
/// Die Android-Lernreise (lumo_learning_journey_probe.py) tippt genau diese
/// Beschriftung an; sie muss eindeutig sein und die Antwort auslösen.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('Antwortkarten sind Schaltflächen mit eindeutiger Beschriftung',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(480, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.pumpWidget(MaterialApp(home: PlusBis10Screen(appState: app)));
    await tester.pump(const Duration(milliseconds: 600));

    final prompt = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .singleWhere((text) => RegExp(r'^\d+ \+ \d+ = \?$').hasMatch(text));
    final values = RegExp(r'\d+').allMatches(prompt).map((m) => int.parse(m[0]!));
    final correct = values.reduce((a, b) => a + b);
    final cards = tester
        .widgetList<Text>(find.descendant(
            of: find.byType(GridView), matching: find.byType(Text)))
        .map((text) => int.parse(text.data!))
        .toList();
    expect(cards, contains(correct));
    for (final value in cards) {
      final label = find.bySemanticsLabel('Antwort $value');
      expect(label, findsOneWidget, reason: 'Antwort $value');
      expect(
        tester.getSemantics(label),
        matchesSemantics(
            label: 'Antwort $value', isButton: true, hasTapAction: true,
            hasEnabledState: true, isEnabled: true),
      );
    }

    await tester.tap(find.bySemanticsLabel('Antwort $correct'));
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 17));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    expect(find.text('Aufgabe 2 / 30'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    app.dispose();
    semantics.dispose();
  });
}
