import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_mission_card.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_subject_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('LumoMissionCard', () {
    testWidgets('renders title, description and progress label', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LumoMissionCard(
            title: 'Tägliche Mission',
            description: 'Löse 3 Deutsch-Aufgaben',
            progress: .66,
            progressLabel: '2 / 3',
            iconEmoji: '🎯',
            rewardValue: '+10',
            rewardLabel: 'Sterne',
          ),
        ),
      );

      expect(find.text('Tägliche Mission'), findsOneWidget);
      expect(find.text('Löse 3 Deutsch-Aufgaben'), findsOneWidget);
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.text('+10'), findsOneWidget);
      expect(find.text('Sterne'), findsOneWidget);
      expect(find.text('🎯'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          LumoMissionCard(
            title: 'Tägliche Mission',
            description: 'Löse 3 Mathe-Aufgaben',
            progress: .33,
            progressLabel: '1 / 3',
            icon: Icons.flag_rounded,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Tägliche Mission'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('LumoSubjectCard', () {
    testWidgets('renders title, description and progress label', (tester) async {
      await tester.pumpWidget(
        wrap(
          LumoSubjectCard(
            title: 'Wörter lesen',
            description: 'Lies die Wörter und sammle Sterne!',
            progress: .60,
            progressLabel: '12 / 20',
            accentColor: Colors.blue,
            emojiAsset: '📖',
            onTap: () {},
          ),
        ),
      );

      expect(find.text('Wörter lesen'), findsOneWidget);
      expect(find.text('Lies die Wörter und sammle Sterne!'), findsOneWidget);
      expect(find.text('12 / 20'), findsOneWidget);
      expect(find.text('📖'), findsOneWidget);
    });

    testWidgets('fires onTap callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          LumoSubjectCard(
            title: 'Buchstaben finden',
            description: 'Finde die richtigen Buchstaben!',
            progress: .40,
            progressLabel: '8 / 20',
            accentColor: Colors.green,
            iconAsset: Icons.search_rounded,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Buchstaben finden'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
