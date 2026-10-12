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
}
