import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_voice_bubble.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('LumoVoiceBubble', () {
    testWidgets('renders message, status and transcript', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LumoVoiceBubble(
            message: 'Frag Lumo mit deiner Stimme.',
            statusLabel: 'Bereit',
            transcript: 'Ich glaube drei',
            onMicPressed: null,
          ),
        ),
      );

      expect(find.text('Bereit'), findsOneWidget);
      expect(find.text('Frag Lumo mit deiner Stimme.'), findsOneWidget);
      expect(find.text('Ich glaube drei'), findsOneWidget);
      expect(find.text('🦊'), findsOneWidget);
    });

    testWidgets('shows listening state and fires mic callback', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        wrap(
          LumoVoiceBubble(
            message: 'Ich höre dir zu.',
            isListening: true,
            onMicPressed: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Ich höre zu ...'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.graphic_eq_rounded));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows thinking state', (tester) async {
      await tester.pumpWidget(
        wrap(
          const LumoVoiceBubble(
            message: 'Einen Moment.',
            isThinking: true,
            onMicPressed: null,
          ),
        ),
      );

      expect(find.text('Lumo denkt nach ...'), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });
  });
}
