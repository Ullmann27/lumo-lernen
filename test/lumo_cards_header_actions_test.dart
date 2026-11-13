import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_cards_score_header.dart';

void main() {
  for (final width in [320.0, 344.0, 412.0, 840.0]) {
    for (final textScale in [1.0, 1.4]) {
      testWidgets('3D entry preserves explicit pause at $width / $textScale',
          (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var paused = 0;
        var opened = 0;
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: Scaffold(
            body: LumoCardsScoreHeader(
              round: 2,
              totalRounds: 3,
              targetPoints: 123,
              onClose: () {},
              onEmoji: () {},
              onAudioSettings: () {},
              onOpponentSettings: () {},
              onSettings: () => paused++,
              onNativeTable: () => opened++,
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        final pause = find.byTooltip('Pause und Neustart');
        final table = find.byKey(const ValueKey('cards-native-table'));
        for (final button in [pause, table]) {
          final bounds = tester.getRect(button);
          expect(bounds.width, greaterThanOrEqualTo(48));
          expect(bounds.height, greaterThanOrEqualTo(48));
          expect(bounds.left, greaterThanOrEqualTo(0));
          expect(bounds.right, lessThanOrEqualTo(width));
        }
        await tester.tap(pause);
        expect(paused, 1);
        expect(opened, 0);
        await tester.tap(table);
        expect(opened, 1);
        expect(paused, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
