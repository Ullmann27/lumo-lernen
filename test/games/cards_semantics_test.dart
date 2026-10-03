import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_playing_card.dart';

void main() {
  testWidgets('Visible card labels reflect rendered colours and special types',
      (tester) async {
    final semantics = tester.ensureSemantics();
    for (final color in LumoCardColor.values) {
      final expectedColor = ['Rot', 'Gelb', 'Blau', 'Grün'][color.index];
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: LumoPlayingCard(
                  card: LumoCard(
                      id: 'visible',
                      color: color,
                      type: LumoCardType.number,
                      number: 7),
                  playable: true))));
      expect(
          find.bySemanticsLabel('Lumo Karte, $expectedColor, Zahl 7, spielbar'),
          findsOneWidget);
    }
    for (final type
        in LumoCardType.values.where((t) => t != LumoCardType.number)) {
      final card = LumoPlayingCard(
          card:
              LumoCard(id: 'special', color: LumoCardColor.green, type: type));
      await tester.pumpWidget(MaterialApp(home: Center(child: card)));
      expect(find.bySemanticsLabel(card.semanticLabel), findsOneWidget);
      expect(card.semanticLabel,
          contains(card.card.isWild ? 'Vier Farben' : 'Grün'));
      expect(tester.takeException(), isNull);
    }
    semantics.dispose();
  });

  testWidgets('Covered bot card reveals neither colour, value nor special type',
      (tester) async {
    final semantics = tester.ensureSemantics();
    for (final type in LumoCardType.values) {
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: LumoPlayingCard(
                  card: LumoCard(
                      id: 'private-card-id',
                      color: LumoCardColor.blue,
                      type: type,
                      number: 9),
                  faceDown: true))));
      expect(find.bySemanticsLabel('Verdeckt'), findsOneWidget);
      expect(
          find.bySemanticsLabel(
              RegExp('Lumo Karte|Blau|Zahl 9|private-card-id')),
          findsNothing);
    }
    semantics.dispose();
  });
}
