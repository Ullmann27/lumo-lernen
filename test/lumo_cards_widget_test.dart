import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';

void main() {
  testWidgets('LumoCardsScreen baut ohne Crash und zeigt Titel', (tester) async {
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

    // Top-Bar zeigt 'Lumo Cards'.
    expect(find.text('Lumo Cards'), findsOneWidget);
    // Spieler-Namen erscheinen im Turn-Banner.
    expect(find.textContaining('Alex'), findsWidgets);
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
