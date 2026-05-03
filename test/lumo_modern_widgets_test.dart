import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_modern_card.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_primary_cta.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_stat_pill.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('modern Lumo base widgets', () {
    testWidgets('LumoModernCard renders its child', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LumoModernCard(
            child: Text('Karte'),
          ),
        ),
      );

      expect(find.text('Karte'), findsOneWidget);
    });

    testWidgets('LumoPrimaryCta renders label and handles tap', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          LumoPrimaryCta(
            label: 'Aufgabe starten',
            icon: Icons.rocket_launch_rounded,
            onPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Aufgabe starten'), findsOneWidget);
      await tester.tap(find.text('Aufgabe starten'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('LumoStatPill renders value and label', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LumoStatPill(
            value: '24',
            label: 'Sterne',
            iconEmoji: '⭐',
          ),
        ),
      );

      expect(find.text('24'), findsOneWidget);
      expect(find.text('Sterne'), findsOneWidget);
      expect(find.text('⭐'), findsOneWidget);
    });
  });
}
