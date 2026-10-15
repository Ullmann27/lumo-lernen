import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';
import '../games/dice_race_runtime_test.dart' show boundary, capture;

void main() {
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf')))
        .load();
  });
  for (final size in const [Size(360, 640), Size(568, 320), Size(967, 805)]) {
    testWidgets('Original Lumo Cards intro fits $size and skips once',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var starts = 0;
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: boundary,
              child: Stack(
                  children: [LumoIntroSplash(onComplete: () => starts++)]))));
      await tester.pump(const Duration(milliseconds: 900));
      await capture(
          tester, 'cards-intro-${size.width.toInt()}x${size.height.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(starts, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
