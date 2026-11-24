import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_place_value_workshop.dart';

void main() {
  Future<void> tap(WidgetTester tester, String key) async {
    final finder = find.byKey(ValueKey(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  for (final size in [
    const Size(280, 740),
    const Size(360, 820),
    const Size(880, 1000)
  ]) {
    testWidgets('new construction plus comprehension, actual inputs at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final results = <LumoPlaceValueTransfer>[];
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(2),
                  disableAnimations: true),
              child: Scaffold(
                  body: SingleChildScrollView(
                      child: LumoPlaceValueWorkshop(
                          number: 84,
                          reduceMotion: true,
                          onTransferChecked: results.add))))));
      for (var i = 0; i < 8; i++) {
        await tap(tester, 'lumo-tens-block-$i');
      }
      expect(results, isEmpty);
      await tap(tester, 'lumo-place-value-build-next');
      expect(find.textContaining('57'), findsWidgets);
      for (var i = 0; i < 5; i++) {
        await tap(tester, 'lumo-build-add-ten');
      }
      for (var i = 0; i < 7; i++) {
        await tap(tester, 'lumo-build-add-one');
      }
      expect(results, isEmpty);
      await tap(tester, 'lumo-build-check');
      expect(results, isEmpty);
      await tap(tester, 'lumo-comprehension-7');
      expect(results.single.number, 57);
      expect(results.single.independent, isTrue);
      expect(results.single.correct, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('ten selected loose cubes conserve 84 when bundled',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child:
                    LumoPlaceValueWorkshop(number: 84, reduceMotion: true)))));
    await tap(tester, 'lumo-place-value-bundle-mode');
    for (var i = 0; i < 10; i++) {
      await tap(tester, 'lumo-loose-cube-$i');
    }
    final bundle = find.byKey(const ValueKey('lumo-bundle-ten'));
    expect(tester.getSize(bundle).height, greaterThanOrEqualTo(48));
    await tap(tester, 'lumo-bundle-ten');
    expect(find.textContaining('8 Zehner und 4 Einer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('corrected construction is practice, never independent transfer',
      (tester) async {
    final results = <LumoPlaceValueTransfer>[];
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: LumoPlaceValueWorkshop(
                    number: 84,
                    reduceMotion: true,
                    onTransferChecked: results.add)))));
    for (var i = 0; i < 8; i++) {
      await tap(tester, 'lumo-tens-block-$i');
    }
    await tap(tester, 'lumo-place-value-build-next');
    await tap(tester, 'lumo-build-check');
    for (var i = 0; i < 5; i++) {
      await tap(tester, 'lumo-build-add-ten');
    }
    for (var i = 0; i < 7; i++) {
      await tap(tester, 'lumo-build-add-one');
    }
    await tap(tester, 'lumo-build-check');
    await tap(tester, 'lumo-comprehension-7');
    expect(results.single.independent, isFalse);
  });
}
