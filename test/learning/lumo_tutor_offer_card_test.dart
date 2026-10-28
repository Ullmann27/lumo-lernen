import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning/widgets/lumo_tutor_offer_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in [280.0, 360.0, 880.0]) {
    testWidgets('proactive invitation works at ${width.toInt()}dp',
        (tester) async {
      var accepted = 0;
      var declined = 0;
      await tester.binding.setSurfaceSize(Size(width, 750));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: LumoTutorOfferCard(
              reduceMotion: true,
              onAccept: () => accepted++,
              onDecline: () => declined++,
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Soll ich dir das auf eine andere Art zeigen?'),
          findsOneWidget);
      final accept = find.byKey(const ValueKey('lumo-tutor-offer-accept'));
      final decline = find.byKey(const ValueKey('lumo-tutor-offer-decline'));
      expect(tester.getSize(accept).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(decline).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.tap(accept);
      await tester.pump();
      await tester.tap(decline);
      await tester.pump();
      expect(accepted, 1);
      expect(declined, 1);
    });
  }

  testWidgets('large text remains accessible and never auto-activates a choice',
      (tester) async {
    var calls = 0;
    await tester.binding.setSurfaceSize(const Size(320, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: LumoTutorOfferCard(
              reduceMotion: true,
              onAccept: () => calls++,
              onDecline: () => calls++,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(calls, 0);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('lumo-tutor-offer-fox')), findsOneWidget);
  });
}
