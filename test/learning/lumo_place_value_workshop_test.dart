import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requires clear two-digit place-value question, not ordinary sums', () {
    expect(LumoPlaceValueWorkshop.numberForPrompt(
        'Wie viele Zehner stecken in 84?'), 84);
    expect(LumoPlaceValueWorkshop.numberForPrompt(
        'Wie viele Einer sind in 70?'), 70);
    expect(LumoPlaceValueWorkshop.numberForPrompt('84 + 2 = ?'), isNull);
    expect(LumoPlaceValueWorkshop.numberForPrompt(
        'Zehner von 184'), isNull);
    expect(LumoPlaceValueWorkshop.numberForPrompt(
        'Zehner 24 oder 45?'), isNull);
  });

  testWidgets('child physically counts eight rods before answer appears',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: LumoPlaceValueWorkshop(
            number: 84,
            reduceMotion: true,
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const ValueKey('lumo-place-value-workshop')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-one-block-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-one-block-4')), findsNothing);
    expect(find.textContaining('Geschafft!'), findsNothing);
    for (var i = 0; i < 8; i++) {
      final key = find.byKey(ValueKey('lumo-tens-block-$i'));
      await tester.ensureVisible(key);
      await tester.tap(key);
      await tester.pump();
    }
    expect(find.textContaining('8 volle Zehner und 4 Einer'), findsOneWidget);
    final reset = find.byKey(const ValueKey('lumo-place-value-reset'));
    await tester.ensureVisible(reset);
    expect(tester.getSize(reset).height, greaterThanOrEqualTo(48));
    await tester.tap(reset);
    await tester.pump();
    expect(find.textContaining('Geschafft!'), findsNothing);
    expect(find.textContaining('0 volle Zehner gezählt'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero ones and small Fold cover layout remain legible',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: LumoPlaceValueWorkshop(
              number: 70,
              reduceMotion: true,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Keine einzelnen Würfel übrig'), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-tens-block-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('lumo-one-block-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
