import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/schoolbook/widgets/schoolbook_task_widgets.dart';

/// Befund S4 der Fachprüfung Mathematik: Im Schularbeits- und Testmodus
/// stand unter dem Zahlenstrahl das Ergebnis der Minusaufgabe („9 - 4 = 5“),
/// bei Zahlen über 20 eine falsche Gleichung („62 - 24 = 20“).
void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(width: 360, child: child),
          ),
        ),
      );

  List<String> texts(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data ?? '')
      .toList();

  testWidgets('Zahlenstrahl bis 10 nennt das Ergebnis nicht', (tester) async {
    await tester.pumpWidget(
        wrap(const NumberLineJumpVisual(start: 9, takeAway: 4)));
    expect(find.text('9 − 4 = ?'), findsOneWidget);
    expect(texts(tester).any((text) => text.contains('= 5')), isFalse);
    expect(find.byKey(const ValueKey('number-line-jump')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zehnerübergang zeigt die Zerlegung, aber nicht das Ergebnis',
      (tester) async {
    await tester.pumpWidget(
        wrap(const NumberLineJumpVisual(start: 15, takeAway: 8)));
    expect(find.text('15 − 5 − 3 = ?'), findsOneWidget);
    expect(texts(tester).any((text) => text.contains('= 7')), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ohne Zehnerübergang gibt es nur einen Sprung', (tester) async {
    // Früher wurde 15 − 3 als Sprung „−5“ beschriftet.
    await tester.pumpWidget(
        wrap(const NumberLineJumpVisual(start: 15, takeAway: 3)));
    expect(find.text('15 − 3 = ?'), findsOneWidget);
    expect(texts(tester).any((text) => text.contains('= 12')), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('über 20: keine falsche Gleichung, kein Zahlenstrahl 0–20',
      (tester) async {
    for (final pair in const [(62, 24), (978, 263), (4075, 1091)]) {
      await tester.pumpWidget(
          wrap(NumberLineJumpVisual(start: pair.$1, takeAway: pair.$2)));
      expect(find.text('${pair.$1} − ${pair.$2} = ?'), findsOneWidget);
      expect(texts(tester).any((text) => text.contains('= 20')), isFalse);
      expect(texts(tester), hasLength(1));
      expect(find.byKey(const ValueKey('number-line-jump')), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  test('beschriftet sind nur Fünferzahlen und die Startzahl', () {
    for (var start = 1; start <= 20; start++) {
      for (var takeAway = 1; takeAway <= start; takeAway++) {
        final result = start - takeAway;
        final labelled = NumberLineJumpVisual.labelledTicks(start);
        expect(labelled, <int>{0, 5, 10, 15, 20, start});
        if (result % 5 != 0) {
          expect(labelled, isNot(contains(result)),
              reason: '$start − $takeAway');
        }
      }
    }
  });

  testWidgets('Zwanzigerfeld: Rechnung endet mit „= ?“', (tester) async {
    await tester.pumpWidget(
        wrap(const TwentyFrameVisual(start: 15, takeAway: 8)));
    expect(find.text('15 − 8 = ?'), findsOneWidget);
    expect(find.text('15 − 5 − 3 = ?'), findsOneWidget);
    expect(texts(tester).any((text) => text.contains('= 7')), isFalse);
    expect(tester.takeException(), isNull);
  });
}
