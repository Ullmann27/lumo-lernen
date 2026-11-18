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

    // Fachprüfung Mathematik S6: „Erweitere den Bruch 3/6 mit 2.“ zeigte
    // eine Pizza mit 1 von 6 Stücken, weil keine Bilddaten ankamen und der
    // Zähler dann auf 1 gesetzt wurde.
    testWidgets('Erweitern zeigt den Bruch der Aufgabe, nicht 1/n',
        (tester) async {
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(
          type: VisualType.fractionPizza,
          prompt: 'Erweitere den Bruch 3/6 mit 2. Wie heißt der neue Bruch?',
          answer: '6/12',
        ),
      )));
      expect(find.byKey(const ValueKey('fraction-pizza-3-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('fraction-pizza-1-6')), findsNothing);
      // Die feiner geteilte Pizza ist noch ungefärbt: Der neue Zähler ist
      // die Lösung und wird nicht gezeigt.
      expect(find.byKey(const ValueKey('fraction-pizza-0-12')), findsOneWidget);
      expect(find.byKey(const ValueKey('fraction-pizza-6-12')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Erweitern mit Bilddaten: 5/6 mit 3', (tester) async {
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(
          type: VisualType.fractionPizza,
          prompt: 'Erweitere den Bruch 5/6 mit 3. Wie heißt der neue Bruch?',
          answer: '15/18',
          data: {'numerator': 5, 'denominator': 6, 'factor': 3},
        ),
      )));
      expect(find.byKey(const ValueKey('fraction-pizza-5-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('fraction-pizza-0-18')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ein einzelner Bruch im Text bestimmt Zähler und Nenner',
        (tester) async {
      await tester.pumpWidget(wrap(FractionPizzaVisual(
        task: buildTask(
          type: VisualType.fractionPizza,
          prompt: 'Welcher Teil der Pizza ist 3/4?',
        ),
      )));
      expect(find.byKey(const ValueKey('fraction-pizza-3-4')), findsOneWidget);
      expect(tester.takeException(), isNull);
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

  // Fachprüfung Mathematik S3: Die Bilder zu kg/g, l/ml und m/cm nannten
  // die umgerechnete Zahl („6 kg = 6000 g“, „0 cm … 700 cm“) und damit die
  // Lösung. Sie zeigen jetzt nur das Gegebene und die Grundbeziehung.
  group('Umrechnungsbilder nennen die Lösung nicht', () {
    List<String> shownTexts(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data ?? '')
        .toList();

    testWidgets('Masse: 6 kg zeigt „1 kg = 1000 g“, aber nicht 6000',
        (tester) async {
      await tester.pumpWidget(wrap(ScaleMeasureVisual(
        task: buildTask(
            type: VisualType.scaleMeasure,
            prompt: 'Wie viele Gramm sind 6 kg?',
            answer: 6000),
      )));
      expect(find.text('1 kg = 1000 g'), findsOneWidget);
      expect(find.byKey(const ValueKey('scale-unknown')), findsOneWidget);
      expect(find.text('?'), findsOneWidget);
      expect(shownTexts(tester).any((text) => text.contains('6000')), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Masse mit Rest: 8 kg und 100 g zeigt beide Angaben',
        (tester) async {
      await tester.pumpWidget(wrap(ScaleMeasureVisual(
        task: buildTask(
            type: VisualType.scaleMeasure,
            prompt: 'Wie viele Gramm sind 8 kg und 100 g?',
            answer: 8100),
      )));
      expect(find.text('8'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      final texts = shownTexts(tester);
      expect(texts.any((text) => text.contains('8000')), isFalse);
      expect(texts.any((text) => text.contains('8100')), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Hohlmaß: 8 Liter zeigt „1 Liter = 1000 ml“, aber nicht 8000',
        (tester) async {
      await tester.pumpWidget(wrap(ScaleMeasureVisual(
        task: buildTask(
            type: VisualType.scaleMeasure,
            prompt: 'Wie viele Milliliter sind 8 Liter und 100 Milliliter?',
            answer: 8100),
      )));
      expect(find.text('1 Liter = 1000 ml'), findsOneWidget);
      final texts = shownTexts(tester);
      expect(texts.any((text) => text.contains('8000')), isFalse);
      expect(texts.any((text) => text.contains('8100')), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Länge: 7 Meter zeigt „1 m = 100 cm“, aber nicht 700',
        (tester) async {
      await tester.pumpWidget(wrap(RulerCompareVisual(
        task: buildTask(
            type: VisualType.rulerCompare,
            prompt: 'Wie viele Zentimeter sind 7 Meter?',
            answer: 700),
      )));
      expect(find.text('1 m = 100 cm'), findsOneWidget);
      expect(find.text('7 m'), findsOneWidget);
      expect(shownTexts(tester).any((text) => text.contains('700')), isFalse);
      expect(tester.takeException(), isNull);
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

  // Fachprüfung Mathematik S12: Beim Mittelwert aus drei Kindern zeigte das
  // Diagramm nur zwei Balken „Mo“ und „Di“, der dritte Wert fehlte.
  group('SimpleBarChartVisual', () {
    testWidgets('zeigt alle drei Werte mit den Beschriftungen der Bilddaten',
        (tester) async {
      await tester.pumpWidget(wrap(SimpleBarChartVisual(
        task: buildTask(
          type: VisualType.simpleBarChart,
          prompt: 'Drei Kinder sammeln Sterne: 42, 49 und 53.',
          answer: 48,
          data: {
            'bars': [42, 49, 53],
            'labels': ['Kind 1', 'Kind 2', 'Kind 3'],
          },
        ),
      )));
      for (final value in ['42', '49', '53']) {
        expect(find.text(value), findsOneWidget);
      }
      for (final label in ['Kind 1', 'Kind 2', 'Kind 3']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Mo'), findsNothing);
      expect(find.text('Di'), findsNothing);
      // Der Mittelwert selbst steht nicht im Bild.
      expect(find.text('48'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ohne Bilddaten: alle Zahlen der Aufgabe, keine erfundenen Tage',
        (tester) async {
      await tester.pumpWidget(wrap(SimpleBarChartVisual(
        task: buildTask(
          type: VisualType.simpleBarChart,
          prompt: 'Drei Kinder sammeln Sterne: 12, 18 und 21.',
        ),
      )));
      for (var index = 0; index < 3; index++) {
        expect(find.byKey(ValueKey('chart-bar-$index')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('chart-bar-3')), findsNothing);
      expect(find.text('Mo'), findsNothing);
      expect(tester.takeException(), isNull);
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
