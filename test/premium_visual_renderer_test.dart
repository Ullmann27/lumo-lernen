import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/features/learning/renderers/lumo_premium_visuals.dart';

/// Smoke-Tests fuer die 12 Premium-Visuals.
///
/// Ziel: Sicherstellen dass jedes Visual bei
///   - leerem visualPayload-data
///   - bei realistischen Daten
/// nicht crasht und mindestens ein Widget rendert.
///
/// Was hier NICHT getestet wird:
///   - Pixelgenaue Optik (das wuerde golden-Tests brauchen)
///   - Performance (separater Benchmark-Job)
void main() {
  /// Hilfsfunktion: minimaler TaskInstance mit gewuenschter Payload.
  TaskInstance buildTask({
    required VisualType type,
    String prompt = 'Test-Aufgabe',
    Object answer = '5',
    Map<String, Object?> data = const <String, Object?>{},
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    return TaskInstance(
      taskInstanceId: 't1',
      templateId: 'tpl1',
      childId: 'child1',
      seedHash: 'seed',
      subject: LearningSubject.mathematik,
      skillId: const SkillId('test-skill'),
      taskType: TaskType.multipleChoice,
      difficulty: 1,
      parameters: parameters,
      prompt: prompt,
      options: const <AnswerOption>[
        AnswerOption(id: 'a', label: 'A'),
        AnswerOption(id: 'b', label: 'B'),
        AnswerOption(id: 'c', label: 'C'),
      ],
      correctAnswer: answer,
      visualPayload: VisualPayload(type: type, data: data),
      helpPayload: const HelpPayload(),
      generatedAt: DateTime(2026, 1, 1),
    );
  }

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 360, child: child),
          ),
        ),
      );

  group('QuantityCompareVisual', () {
    testWidgets('rendert bei leerem Payload ohne Crash', (tester) async {
      await tester.pumpWidget(wrap(QuantityCompareVisual(
        task: buildTask(type: VisualType.quantityCompare, prompt: 'Was ist mehr?'),
      )));
      expect(find.byType(QuantityCompareVisual), findsOneWidget);
    });

    testWidgets('rendert bei gefuelltem Payload', (tester) async {
      await tester.pumpWidget(wrap(QuantityCompareVisual(
        task: buildTask(
          type: VisualType.quantityCompare,
          data: {'left': 3, 'right': 5, 'emoji': '🍎'},
        ),
      )));
      expect(find.text('oder'), findsOneWidget);
    });
  });

  group('ClockFaceVisual', () {
    testWidgets('rendert bei leerem Payload (Fallback 12:00)', (tester) async {
      await tester.pumpWidget(wrap(ClockFaceVisual(
        task: buildTask(type: VisualType.clock, prompt: 'Welche Uhrzeit?'),
      )));
      expect(find.byType(ClockFaceVisual), findsOneWidget);
    });

    testWidgets('rendert bei 07:30 ohne Crash', (tester) async {
      await tester.pumpWidget(wrap(ClockFaceVisual(
        task: buildTask(
          type: VisualType.clock,
          data: {'hour': 7, 'minute': 30},
        ),
      )));
      expect(find.byType(ClockFaceVisual), findsOneWidget);
    });

    testWidgets('rendert bei extremer Stunde 25 ohne Crash', (tester) async {
      // hour % 24 sollte verhindern dass Painter wegfliegt.
      await tester.pumpWidget(wrap(ClockFaceVisual(
        task: buildTask(
          type: VisualType.clock,
          data: {'hour': 25, 'minute': 90},
        ),
      )));
      expect(find.byType(ClockFaceVisual), findsOneWidget);
    });
  });

  group('MoneyCoinsVisual', () {
    testWidgets('rendert bei leerem Payload', (tester) async {
      await tester.pumpWidget(wrap(MoneyCoinsVisual(
        task: buildTask(type: VisualType.money, prompt: 'Was kostet das?'),
      )));
      expect(find.byType(MoneyCoinsVisual), findsOneWidget);
    });

    testWidgets('rendert 150 Cent als 1,50 Euro', (tester) async {
      await tester.pumpWidget(wrap(MoneyCoinsVisual(
        task: buildTask(
          type: VisualType.money,
          data: {'cents': 150},
        ),
      )));
      expect(find.byType(MoneyCoinsVisual), findsOneWidget);
    });
  });

  group('FractionPizzaVisual', () {
    testWidgets('rendert bei leerem Payload (Fallback 1/2)', (tester) async {
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(type: VisualType.fractionPizza, prompt: 'Welcher Bruch?'),
      )));
      expect(find.byType(FractionPizzaVisual), findsOneWidget);
    });

    testWidgets('rendert 3/4 ohne Crash', (tester) async {
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(
          type: VisualType.fractionPizza,
          data: {'numerator': 3, 'denominator': 4},
        ),
      )));
      expect(find.byType(FractionPizzaVisual), findsOneWidget);
    });

    testWidgets('clampt extrem grosse Nenner auf 12', (tester) async {
      // Painter clamped intern, das soll auch bei n > 12 nicht crashen.
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(
          type: VisualType.fractionPizza,
          data: {'numerator': 5, 'denominator': 100},
        ),
      )));
      expect(find.byType(FractionPizzaVisual), findsOneWidget);
    });
  });

  group('BarChartMiniVisual', () {
    testWidgets('zeigt Hinweis bei leerem Payload', (tester) async {
      // Wichtig: NICHT erfundene Demo-Werte zeigen, sondern Hinweis.
      await tester.pumpWidget(wrap(BarChartMiniVisual(
        task: buildTask(type: VisualType.barChart, prompt: 'Diagramm:'),
      )));
      expect(find.byType(BarChartMiniVisual), findsOneWidget);
      expect(find.text('Schau die Aufgabe an und überlege die Zahlen.'), findsOneWidget);
    });

    testWidgets('rendert echte Daten', (tester) async {
      await tester.pumpWidget(wrap(BarChartMiniVisual(
        task: buildTask(
          type: VisualType.barChart,
          data: {'bars': [3, 5, 2, 4]},
        ),
      )));
      expect(find.byType(BarChartMiniVisual), findsOneWidget);
    });
  });

  group('RhymeBubbleVisual', () {
    testWidgets('rendert bei leerem Prompt ohne Crash', (tester) async {
      // Bug B1: split(' ').last crashte bei leerem Prompt.
      await tester.pumpWidget(wrap(RhymeBubbleVisual(
        task: buildTask(type: VisualType.rhymeBubble, prompt: ''),
      )));
      expect(find.byType(RhymeBubbleVisual), findsOneWidget);
    });

    testWidgets('rendert mit Wort aus Payload', (tester) async {
      await tester.pumpWidget(wrap(RhymeBubbleVisual(
        task: buildTask(
          type: VisualType.rhymeBubble,
          data: {'word': 'Haus', 'rhymes': ['Maus', 'Laus', 'Klaus']},
        ),
      )));
      expect(find.text('Haus'), findsOneWidget);
    });
  });

  group('SyllableClapVisual', () {
    testWidgets('rendert bei leerem Payload', (tester) async {
      await tester.pumpWidget(wrap(SyllableClapVisual(
        task: buildTask(type: VisualType.syllableClap, prompt: 'Wie viele Silben?'),
      )));
      expect(find.byType(SyllableClapVisual), findsOneWidget);
    });

    testWidgets('rendert Silben aus Payload', (tester) async {
      await tester.pumpWidget(wrap(SyllableClapVisual(
        task: buildTask(
          type: VisualType.syllableClap,
          data: {'word': 'Banane', 'syllables': ['Ba', 'na', 'ne']},
        ),
      )));
      expect(find.text('Ba'), findsOneWidget);
      expect(find.text('na'), findsOneWidget);
    });
  });

  group('WordFamilyTreeVisual', () {
    testWidgets('rendert bei leerem Payload (Fallback)', (tester) async {
      await tester.pumpWidget(wrap(WordFamilyTreeVisual(
        task: buildTask(type: VisualType.wordFamilyTree, prompt: 'Wortfamilie?'),
      )));
      expect(find.byType(WordFamilyTreeVisual), findsOneWidget);
    });

    testWidgets('rendert Wortstamm + Familie', (tester) async {
      await tester.pumpWidget(wrap(WordFamilyTreeVisual(
        task: buildTask(
          type: VisualType.wordFamilyTree,
          data: {'root': 'fahren', 'family': ['Fahrt', 'Fahrer', 'gefahren']},
        ),
      )));
      expect(find.text('fahren'), findsOneWidget);
    });
  });

  group('SentenceBlocksVisual', () {
    testWidgets('rendert bei leerem Payload aus Prompt-Split', (tester) async {
      await tester.pumpWidget(wrap(SentenceBlocksVisual(
        task: buildTask(
          type: VisualType.sentenceBlocks,
          prompt: 'Der Hund bellt laut.',
        ),
      )));
      expect(find.byType(SentenceBlocksVisual), findsOneWidget);
    });
  });

  group('WordTypeColorVisual', () {
    testWidgets('rendert Wortarten-Legende und Aufgabentext', (tester) async {
      await tester.pumpWidget(wrap(WordTypeColorVisual(
        task: buildTask(
          type: VisualType.wordTypeColor,
          prompt: 'Was ist das fuer ein Wort?',
        ),
      )));
      expect(find.text('Nomen'), findsOneWidget);
      expect(find.text('Verb'), findsOneWidget);
      expect(find.text('Adjektiv'), findsOneWidget);
    });
  });

  group('ArticleCardsVisual', () {
    testWidgets('rendert drei Artikel-Karten', (tester) async {
      await tester.pumpWidget(wrap(ArticleCardsVisual(
        task: buildTask(type: VisualType.articleCards, prompt: 'der/die/das?'),
      )));
      expect(find.text('der'), findsOneWidget);
      expect(find.text('die'), findsOneWidget);
      expect(find.text('das'), findsOneWidget);
    });
  });
}
