import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/theme/lumo_visual_tokens.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  testWidgets('Next Gen tile remains accessible and opens its real action',
      (tester) async {
    var launches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 220,
              child: LumoColorTile(
                icon: Icons.menu_book_rounded,
                title: 'Lernen',
                subtitle: 'Mathe, Deutsch und mehr',
                color: LumoVisualTokens.learning,
                onTap: () => launches++,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Lernen'), findsOneWidget);
    expect(find.text('Mathe, Deutsch und mehr'), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
    await tester.tap(find.text('Lernen'));
    await tester.pump();
    expect(launches, 1);
  });

  testWidgets('Next Gen card stays usable at compact phone width',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 148,
            height: 160,
            child: LumoColorTile(
              icon: Icons.sports_esports_rounded,
              title: 'Spielen',
              subtitle: 'Lumo Kart und Memory',
              color: LumoVisualTokens.games,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Spielen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
