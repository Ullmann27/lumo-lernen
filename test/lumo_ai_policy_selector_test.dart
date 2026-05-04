import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_ai_learning_access.dart';
import 'package:lumo_lernen/features/parents/widgets/lumo_ai_policy_selector.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('LumoAiPolicySelector', () {
    testWidgets('renders headers and all policy options', (tester) async {
      await tester.pumpWidget(
        wrap(
          LumoAiPolicySelector(
            currentMode: LumoAiLearningMode.chatOnly,
            onModeChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Lumo KI-Assistent'), findsOneWidget);
      expect(find.text('Wähle, wie Lumo dein Kind beim Lernen unterstützen darf.'), findsOneWidget);

      expect(find.text('Nur KI-Chat'), findsOneWidget);
      expect(find.text('Aufgabenhilfe'), findsOneWidget);
      expect(find.text('Lesehilfe'), findsOneWidget);
      expect(find.text('Voller Lumo-Coach'), findsOneWidget);

      expect(find.text('💬'), findsOneWidget);
      expect(find.text('💡'), findsOneWidget);
      expect(find.text('📖'), findsOneWidget);
      expect(find.text('🚀'), findsOneWidget);
    });

    testWidgets('fires onModeChanged callback with correct mode when tapped', (tester) async {
      LumoAiLearningMode? selectedMode;

      await tester.pumpWidget(
        wrap(
          LumoAiPolicySelector(
            currentMode: LumoAiLearningMode.off,
            onModeChanged: (mode) => selectedMode = mode,
          ),
        ),
      );

      await tester.tap(find.text('Voller Lumo-Coach'));
      await tester.pumpAndSettle();

      expect(selectedMode, equals(LumoAiLearningMode.fullCoach));
    });
  });
}
