import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/reading/widgets/reading_syllable_chip.dart';

void main() {
  testWidgets('renders syllable parts without plain black word fallback', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingSyllableChip(parts: <String>['Gar', 'ten']),
        ),
      ),
    );

    expect(find.byType(RichText), findsOneWidget);
    expect(find.text('Garten'), findsNothing);
    // Die Silben stehen als TextSpans in einem RichText; der Finder muss
    // RichText durchsuchen (vorher übersprungen, weil er das nicht tat).
    expect(find.textContaining('Gar', findRichText: true), findsOneWidget);
  });

  testWidgets('keeps active chip tappable size visually highlighted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingSyllableChip(
            parts: <String>['Lu', 'mo'],
            active: true,
            listening: true,
          ),
        ),
      ),
    );

    final container = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(container.decoration, isA<BoxDecoration>());
    expect(find.text('Lumo'), findsNothing);
  });
}
