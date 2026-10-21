import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_motion.dart';
import 'package:lumo_lernen/widgets/design/lumo_scene_atmosphere.dart';

void main() {
  setUp(() => LumoMotion.appReduced = false);
  tearDown(() => LumoMotion.appReduced = false);

  test('HIGH requires measured headroom; repeated slow frames stop effects',
      () {
    final budget = LumoEffectBudget();
    expect(budget.profile, LumoEffectProfile.medium);
    for (var i = 0; i < 60; i++) {
      budget.record(
          const Duration(milliseconds: 5), const Duration(milliseconds: 7));
    }
    expect(budget.profile, LumoEffectProfile.medium);
    for (var i = 0; i < 60; i++) {
      budget.record(
          const Duration(milliseconds: 5), const Duration(milliseconds: 7));
    }
    expect(budget.profile, LumoEffectProfile.high);
    for (var i = 0; i < 60; i++) {
      budget.record(
          const Duration(milliseconds: 24), const Duration(milliseconds: 4));
    }
    expect(budget.profile, LumoEffectProfile.low);
    for (var i = 0; i < 120; i++) {
      budget.record(
          const Duration(milliseconds: 2), const Duration(milliseconds: 2));
    }
    expect(budget.profile, LumoEffectProfile.low,
        reason:
            'A static fallback does not oscillate back to expensive effects');
  });

  test('one isolated expensive frame does not downgrade a smooth window', () {
    final budget = LumoEffectBudget();
    budget.record(
        const Duration(milliseconds: 70), const Duration(milliseconds: 70));
    for (var i = 0; i < 59; i++) {
      budget.record(
          const Duration(milliseconds: 6), const Duration(milliseconds: 6));
    }
    expect(budget.profile, LumoEffectProfile.medium);
  });

  testWidgets('reduced motion and hidden routes stop the scene clock',
      (tester) async {
    Widget scene({required bool quiet, bool enabled = true}) => MaterialApp(
          home: TickerMode(
            enabled: enabled,
            child: LumoSceneAtmosphere(
              reduceMotion: quiet,
              child: const SizedBox(width: 300, height: 200),
            ),
          ),
        );
    await tester.pumpWidget(scene(quiet: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(scene(quiet: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(scene(quiet: false, enabled: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('scene pauses when scrolled out and resumes when visible',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        controller: scroll,
        child: const Column(
          children: [
            LumoSceneAtmosphere(child: SizedBox(height: 200, width: 400)),
            SizedBox(height: 1600),
          ],
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    scroll.jumpTo(700);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    scroll.jumpTo(0);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
