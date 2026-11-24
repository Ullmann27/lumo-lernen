import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/tutoring/guided_product_array.dart';
import 'package:lumo_lernen/widgets/design/lumo_quantity_art.dart';

void main() {
  const lesson = GuidedLessonCatalog.equalGroups;
  for (final reduced in [true, false]) {
    testWidgets(
        'Drehen hält alle Äpfel und die Fünferreihe zusammen, reduzierte Bewegung $reduced',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: GuidedProductArray(
        rows: 3,
        columns: 2,
        example: true,
        reduceMotion: reduced,
      ))));
      expect(find.text('3 Reihen mit je 2 Äpfeln'), findsOneWidget);
      await tester.tap(find.text('Feld drehen'));
      await tester.pumpAndSettle();
      expect(find.text('2 Reihen mit je 3 Äpfeln'), findsOneWidget);
      expect(find.byType(LumoQuantityArt), findsNWidgets(6));
      await tester.tap(find.text('6 × 7 mit der Fünferreihe'));
      await tester.pumpAndSettle();
      expect(find.text('6 Reihen mit je 7 Äpfeln'), findsOneWidget);
      expect(find.byType(LumoQuantityArt), findsNWidgets(42));
      final apple = find.byKey(const ValueKey('guided-group-apple-5-6'));
      final old = tester.getCenter(apple);
      await tester.drag(apple, const Offset(-70, 0));
      await tester.pumpAndSettle();
      expect(find.text('7 Reihen mit je 6 Äpfeln'), findsOneWidget);
      expect(tester.getCenter(apple).dx, lessThan(old.dx));
      expect(find.byType(LumoQuantityArt), findsNWidgets(42));
    });
  }
  test('Fehler erkennen bei Plus statt Mal und beim ersten Zehnerschritt', () {
    expect(lesson.steps[3].arithmeticRetry('5'), contains('addiert'));
    expect(GuidedLessonCatalog.subtractTen.steps[5].arithmeticRetry('10'),
        contains('zurückgegangen'));
  });
}
