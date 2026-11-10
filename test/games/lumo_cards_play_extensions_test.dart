import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_jump_celebration.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_result_dialog.dart';

void main() {
  testWidgets('Lumo-Sprung celebration shows the hop title', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(child: LumoJumpCelebration()),
      ),
    ));
    await tester.pump();
    expect(find.text('Lumo-Sprung!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('round summary lists stars without changing the reward text',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            LumoResultDialog(
              winnerName: 'Du',
              kindWon: true,
              reward: 4,
              streak: 1,
              onRestart: () {},
              onExit: () {},
            ),
          ],
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('cards-round-summary')), findsOneWidget);
    expect(find.text('Rundenzusammenfassung'), findsOneWidget);
    expect(find.text('Du bekommst 4 Sterne!'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
