import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_assets.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_discard_pile.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_color_picker.dart';

void main() {
  test('Visible color names do not rename persisted domain identifiers', () {
    expect(LumoCardColor.values.map((c) => c.name),
        ['orange', 'purple', 'blue', 'green']);
    expect(LumoCardColor.values.map((c) => c.displayName),
        ['Rot', 'Gelb', 'Blau', 'Grün']);
  });
  for (final entry in [
    (LumoCardColor.orange, 'Rot', 'red'),
    (LumoCardColor.purple, 'Gelb', 'yellow'),
    (LumoCardColor.blue, 'Blau', 'blue'),
    (LumoCardColor.green, 'Grün', 'green'),
  ]) {
    testWidgets('Discard, picker and real PNG agree for ${entry.$1.name}',
        (tester) async {
      final card = LumoCard(
          id: 'palette', color: entry.$1, type: LumoCardType.number, number: 7);
      expect(LumoCardsAssets.assetFor(card), contains('/${entry.$3}/'));
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: LumoDiscardPile(
                  topCard: card, selectedColor: entry.$1))));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(entry.$2), findsOneWidget);
      expect(find.text('Lila'), findsNothing);
      expect(find.text('Orange'), findsNothing);
      LumoCardColor? picked;
      await tester.pumpWidget(MaterialApp(
          home: Stack(children: [LumoColorPicker(onPick: (c) => picked = c)])));
      await tester.tap(find.text(entry.$2));
      expect(picked, entry.$1, reason: 'Historical domain keys remain unchanged');
      expect(tester.takeException(), isNull);
    });
  }
}
