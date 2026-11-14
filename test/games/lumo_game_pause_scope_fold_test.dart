import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/shared/lumo_game_pause_scope.dart';

void main() {
  testWidgets(
      'short Fold landscape with large text keeps Spieleauswahl directly tappable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(926, 362));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var left = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(926, 362),
            textScaler: TextScaler.linear(1.6),
          ),
          child: LumoPausePanel(
            onResume: () {},
            onRestart: () {},
            onLeave: () => left = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Spiel pausiert'), findsOneWidget);
    expect(find.text('Fortsetzen').hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('pause-leave-games')).hitTestable(),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pause-leave-games')));
    expect(left, isTrue);
  });

  for (final scale in <double>[1.0, 1.6]) {
    testWidgets('short Fold pause controls keep 48 dp edge taps at scale $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(926, 362));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final callbacks = <String, int>{
        'Fortsetzen': 0,
        'Zur Spieleauswahl': 0,
        'Neu starten': 0,
      };
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(926, 362),
              textScaler: TextScaler.linear(scale),
            ),
            child: LumoPausePanel(
              onResume: () => callbacks['Fortsetzen'] =
                  callbacks['Fortsetzen']! + 1,
              onRestart: () => callbacks['Neu starten'] =
                  callbacks['Neu starten']! + 1,
              onLeave: () => callbacks['Zur Spieleauswahl'] =
                  callbacks['Zur Spieleauswahl']! + 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final controls = <String, Finder>{
        'Fortsetzen': find.ancestor(
          of: find.text('Fortsetzen'),
          matching: find.byType(InkWell),
        ),
        'Zur Spieleauswahl': find.byKey(const ValueKey('pause-leave-games')),
        'Neu starten': find.ancestor(
          of: find.text('Neu starten'),
          matching: find.byType(InkWell),
        ),
      };
      final expectedCallbacks = Map<String, int>.of(callbacks);
      for (final entry in controls.entries) {
        expect(entry.value, findsOneWidget);
        expect(entry.value.hitTestable(), findsOneWidget);
        final bounds = tester.getRect(entry.value);
        expect(bounds.width, greaterThanOrEqualTo(48), reason: entry.key);
        expect(bounds.height, greaterThanOrEqualTo(48), reason: entry.key);
        for (final verticalOffset in <double>[-23.5, 23.5]) {
          await tester.tapAt(bounds.center + Offset(0, verticalOffset));
          await tester.pumpAndSettle();
          expectedCallbacks[entry.key] = expectedCallbacks[entry.key]! + 1;
          expect(callbacks, expectedCallbacks,
              reason: '${entry.key} must own its full 48 dp target');
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
