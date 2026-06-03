import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';

void main() {
  testWidgets('LumoCardsScreen baut ohne Crash und zeigt Spieler', (tester) async {
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

    // Bug-Fix 2026-06-03: Vorher suchte 'Lumo Cards' im Header. Der
    // Titel-Text existiert aber seit dem Score-Header-Refactor nicht
    // mehr direkt im Screen (nur noch in der Tile der Spiele-Uebersicht).
    // Robusterer Check: kein Crash + Spieler-Name im DOM.
    expect(tester.takeException(), isNull,
        reason: 'Screen darf nicht crashen');
    expect(find.textContaining('Alex'), findsWidgets,
        reason: 'Spieler 1 muss im Turn-Banner sichtbar sein');
  });

  testWidgets('Zieh-Stapel ist sichtbar', (tester) async {
    final appState = LumoAppState();
    await tester.pumpWidget(
      MaterialApp(
        home: LumoCardsScreen(appState: appState),
      ),
    );
    await tester.pump();

    // Anzahl Karten-Label im Draw-Pile.
    expect(find.textContaining('Karten'), findsWidgets);
  });
}
