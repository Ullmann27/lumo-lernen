import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/cognitive_profile_generator.dart';
import 'package:lumo_lernen/domain/cognitive/cognitive_profile.dart';
import 'package:lumo_lernen/features/tests/cognitive_profile_visual_prompt.dart';
import 'package:lumo_lernen/features/tests/iq/iq_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (var grade = 1; grade <= 4; grade++) {
    testWidgets('Real Denkprofil grade $grade pattern and rotation show visual clues',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final questions = CognitiveProfileGenerator.forGrade(grade);
      expect(questions, hasLength(50));
      final numeric = questions.firstWhere((q) =>
          q.domain == CognitiveDomain.patternReasoning &&
          q.prompt.startsWith('Welche Zahl folgt?'));
      final shapes = questions.firstWhere((q) =>
          q.domain == CognitiveDomain.patternReasoning &&
          q.prompt.startsWith('Setze das Muster fort:'));
      final spatial = questions.firstWhere((q) =>
          q.domain == CognitiveDomain.spatialReasoning);

      Future<void> show(CognitiveQuestion question) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(body: CognitiveProfileVisualPrompt(question: question)),
        ));
        await tester.pump();
        expect(find.byType(IqTile), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await show(numeric);
      expect(find.byKey(const ValueKey('cognitive-visual-pattern')),
          findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      await show(shapes);
      expect(find.byKey(const ValueKey('cognitive-visual-pattern')),
          findsOneWidget);
      expect(find.text('?'), findsOneWidget);

      await show(spatial);
      expect(find.byIcon(Icons.rotate_right_rounded), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
    });
  }
}
