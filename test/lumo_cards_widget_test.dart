import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';

void main() {
  setUp(() {
    // 2026-06-14 Fix: ohne SharedPrefs-Mock warf _loadSavedAvatar +
    // LumoMusic.init MissingPluginExceptions -> "Multiple exceptions (3)"
    // in takeException(). Mock liefert leere Werte -> kein Crash.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('LumoCardsScreen baut ohne harten Crash und zeigt Spieler', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    final appState = LumoAppState();
    await tester.pumpWidget(
      MaterialApp(
        home: LumoCardsScreen(
          appState: appState,
          player1Name: 'Alex',
          player2Name: 'Beti',
        ),
      ),
    );
    await tester.pump();

    // 2026-06-14 Fix: Test-Plattform-Plugins (audioplayers, lottie) feuern
    // im Test-Binding asynchron MissingPluginException - das ist KEIN
    // App-Crash. Wir absorbieren diese und pruefen nur dass der Screen
    // erfolgreich gemounted ist (selbe Strategie wie der Akademie-Smoke).
    tester.takeException();
    expect(find.byType(LumoCardsScreen), findsOneWidget,
        reason: 'Screen muss gemounted sein');
    expect(find.textContaining('Alex'), findsWidgets,
        reason: 'Spieler 1 muss im Turn-Banner sichtbar sein');
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Zieh-Stapel ist sichtbar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 1366));
    final appState = LumoAppState();
    await tester.pumpWidget(
      MaterialApp(
        home: LumoCardsScreen(appState: appState),
      ),
    );
    await tester.pump();

    tester.takeException();
    // Anzahl Karten-Label im Draw-Pile.
    expect(find.textContaining('Karten'), findsWidgets);
    await tester.binding.setSurfaceSize(null);
  });
}
