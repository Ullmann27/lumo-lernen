import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/tutoring/guided_place_value_arithmetic.dart';

void main() {
  Future<void> show(WidgetTester tester, int a, int b, bool subtract) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: GuidedPlaceValueArithmetic(left: a, right: b, subtract: subtract),
      ))));

  for (final example in [(37, 25, false, 57, 60, 62), (52, 27, true, 32, 30, 25)]) {
    testWidgets('guided steps keep the final answer open: $example',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await show(tester, example.$1, example.$2, example.$3);
      final answerKey = ValueKey('place-value-choice-${example.$6}');
      expect(find.byKey(answerKey), findsNothing);
      for (final checkpoint in [example.$4, example.$5]) {
        final button = find.byKey(ValueKey('place-value-choice-$checkpoint'));
        expect(button, findsOneWidget);
        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        await tester.tap(button);
        await tester.pump();
        expect(find.byKey(answerKey), findsNothing);
      }
      expect(find.textContaining('Den letzten Schritt rechnest du selbst'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Noch einmal erklären'));
      await tester.pump();
      expect(find.byKey(ValueKey('place-value-choice-${example.$4}')), findsOneWidget);
    });
  }

  testWidgets('wrong step does not advance; new task resets', (tester) async {
    await show(tester, 37, 25, false);
    await tester.tap(find.byKey(const ValueKey('place-value-choice-47')));
    await tester.pump();
    expect(find.text('37 + 20 = ?'), findsOneWidget);
    expect(find.textContaining('noch einmal getrennt'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('place-value-choice-57')));
    await tester.pump();
    expect(find.text('57 + 3 = ?'), findsOneWidget);
    await show(tester, 52, 27, true);
    expect(find.text('52 − 20 = ?'), findsOneWidget);
    expect(find.textContaining('noch einmal getrennt'), findsNothing);
  });
}
