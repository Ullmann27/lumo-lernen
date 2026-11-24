import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_holo_effects.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';

Widget _host(Widget child, {bool disableAnimations = false}) => MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: child),
      ),
    );

void main() {
  tearDown(() => LumoMotion.appReduced = false);

  testWidgets('Schimmer läuft in zufälligen Abständen und endet wieder',
      (tester) async {
    await tester.pumpWidget(_host(LumoHoloShimmer(
      random: math.Random(1),
      minInterval: const Duration(seconds: 2),
      maxInterval: const Duration(seconds: 2),
      child: const SizedBox(width: 120, height: 60),
    )));
    final state =
        tester.state<LumoHoloShimmerState>(find.byType(LumoHoloShimmer));
    expect(state.isActive, isTrue, reason: 'nächster Durchlauf ist geplant');
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'zwischen den Durchläufen wird nichts neu gezeichnet');

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isTrue,
        reason: 'der Lichtstreifen läuft gerade');

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'nach dem Durchlauf wieder Ruhe');
    expect(state.isActive, isTrue, reason: 'der nächste Durchlauf ist geplant');
  });

  testWidgets('reduzierte Bewegung (System) plant keinen Schimmer',
      (tester) async {
    await tester.pumpWidget(_host(
      const LumoHoloShimmer(child: SizedBox(width: 120, height: 60)),
      disableAnimations: true,
    ));
    final state =
        tester.state<LumoHoloShimmerState>(find.byType(LumoHoloShimmer));
    expect(state.isActive, isFalse);
    await tester.pump(const Duration(seconds: 30));
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(state.isActive, isFalse);
  });

  testWidgets('App-Ruhemodus stoppt Schimmer und Lichtfeld', (tester) async {
    LumoMotion.appReduced = true;
    await tester.pumpWidget(_host(const SizedBox(
      width: 300,
      height: 300,
      child: Stack(children: [
        Positioned.fill(child: LumoHoloField()),
        LumoHoloShimmer(child: SizedBox(width: 120, height: 60)),
      ]),
    )));
    expect(
        tester
            .state<LumoHoloShimmerState>(find.byType(LumoHoloShimmer))
            .isActive,
        isFalse);
    expect(
        tester.state<LumoHoloFieldState>(find.byType(LumoHoloField)).isActive,
        isFalse);
    await tester.pump(const Duration(seconds: 40));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Schimmer fängt keine Taps ab und hält 48 dp ein',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: LumoPressable(
            child: SizedBox(
              width: 48,
              height: 48,
              child: InkWell(
                onTap: () => taps++,
                child: const Center(child: Text('Los')),
              ),
            ),
          ),
        ),
      ),
    ));
    final size = tester.getSize(find.byType(LumoPressable));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    final layer = find.byKey(const ValueKey('lumo-holo-shimmer-layer'));
    expect(layer, findsOneWidget);
    expect(tester.getSize(layer), size,
        reason: 'der Schimmer deckt genau die Fläche ab');

    await tester.tap(find.text('Los'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('Druck kippt die Fläche leicht und federt zurück',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: Center(
        child: LumoPressable(
          shimmer: false,
          child: SizedBox(
            width: 160,
            height: 80,
            child: GestureDetector(onTap: () {}),
          ),
        ),
      )),
    ));
    Matrix4 matrix() => tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(LumoPressable),
                matching: find.byType(Transform))
            .first)
        .transform;
    expect(matrix().isIdentity(), isTrue);

    final gesture = await tester.startGesture(
        tester.getTopLeft(find.byType(LumoPressable)) + const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(matrix().isIdentity(), isFalse);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(matrix().isIdentity(), isTrue);
  });

  testWidgets('Kein Kippen bei reduzierter Bewegung', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: MaterialApp(
        home: Center(
          child: LumoPressable(
            child: SizedBox(
                width: 160, height: 80, child: GestureDetector(onTap: () {})),
          ),
        ),
      ),
    ));
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(LumoPressable)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final transform = tester
        .widget<Transform>(find
            .descendant(
                of: find.byType(LumoPressable),
                matching: find.byType(Transform))
            .first)
        .transform;
    expect(transform.isIdentity(), isTrue);
    await gesture.up();
    await tester.pump();
  });
}
