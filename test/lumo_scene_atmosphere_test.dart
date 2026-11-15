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

  testWidgets('landscape moves while text and tap targets remain fixed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 320,
          height: 240,
          child: LumoSceneAtmosphere(
            scenery: const ColoredBox(color: Colors.blue),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                key: const ValueKey('stationary-action'),
                onPressed: () => taps++,
                child: const Text('Loslernen'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    final action = find.byKey(const ValueKey('stationary-action'));
    final position = tester.getTopLeft(action);
    final targetSize = tester.getSize(action);
    final scenery = find.byKey(const ValueKey('lumo-scenery-drift'));
    final before = tester.widget<Transform>(scenery).transform.clone();
    await tester.pump(const Duration(seconds: 3));
    final after = tester.widget<Transform>(scenery).transform;
    expect(after.storage, isNot(orderedEquals(before.storage)));
    expect(tester.getTopLeft(action), position);
    expect(tester.getSize(action), targetSize);
    await tester.tap(action);
    expect(taps, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('quiet scenery preserves functional child ticker mode',
      (tester) async {
    bool? childTicking;
    await tester.pumpWidget(MaterialApp(
      home: LumoSceneAtmosphere(
        reduceMotion: true,
        scenery: const ColoredBox(color: Colors.blue),
        child: Builder(builder: (context) {
          childTicking = TickerMode.of(context);
          return const SizedBox(height: 200);
        }),
      ),
    ));
    await tester.pump(const Duration(seconds: 1));
    expect(childTicking, isTrue,
        reason: 'A decorative budget must not freeze functional content');
    expect(tester.binding.transientCallbackCount, 0);
    final transform = tester
        .widget<Transform>(find.byKey(const ValueKey('lumo-scenery-drift')))
        .transform;
    expect(transform.getTranslation().x, 0);
    expect(transform.getTranslation().y, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('background and resume stop and restart decorative frames',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: LumoSceneAtmosphere(child: SizedBox(height: 200)),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.transientCallbackCount, greaterThan(0));
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

  testWidgets('layout changes refresh visibility at an unchanged scroll offset',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    late StateSetter relayout;
    var leadingSpace = 700.0;
    bool? childTicking;
    const contentKey = ValueKey('relayout-scene-content');
    // Keep this exact widget instance: moving an existing const/cached child
    // does not call its didUpdateWidget or change its own layout constraints.
    final scene = LumoSceneAtmosphere(
      child: Builder(builder: (context) {
        childTicking = TickerMode.of(context);
        return const SizedBox(key: contentKey, height: 180, width: 300);
      }),
    );
    await tester.pumpWidget(MaterialApp(
      home: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          height: 400,
          child: StatefulBuilder(builder: (context, setState) {
            relayout = setState;
            return SingleChildScrollView(
              controller: scroll,
              child: Column(children: [
                SizedBox(height: leadingSpace),
                scene,
                const SizedBox(height: 900),
              ]),
            );
          }),
        ),
      ),
    ));
    await tester.pump();
    expect(scroll.offset, 0);
    expect(childTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);

    relayout(() => leadingSpace = 80);
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, 0);
    expect(tester.getTopLeft(find.byKey(contentKey)).dy, 80);
    expect(childTicking, isTrue,
        reason: 'Visible functional content must resume after a pure relayout');
    expect(tester.binding.transientCallbackCount, greaterThan(0));

    relayout(() => leadingSpace = 700);
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, 0);
    expect(childTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse,
        reason: 'An invisible scene must not drive frames to watch visibility');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewport relayout respects background state without idle frames',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    late StateSetter resize;
    var viewportHeight = 200.0;
    bool? childTicking;
    final scene = LumoSceneAtmosphere(
      child: Builder(builder: (context) {
        childTicking = TickerMode.of(context);
        return const SizedBox(height: 100, width: 300);
      }),
    );
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        resize = setState;
        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: viewportHeight,
            child: SingleChildScrollView(
              controller: scroll,
              child: Column(children: [
                const SizedBox(height: 260),
                scene,
                const SizedBox(height: 900),
              ]),
            ),
          ),
        );
      }),
    ));
    await tester.pump();
    expect(childTicking, isFalse);
    resize(() => viewportHeight = 400);
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, 0);
    expect(childTicking, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    resize(() => viewportHeight = 200);
    await tester.pump();
    await tester.pump();
    expect(childTicking, isFalse);
    expect(tester.binding.transientCallbackCount, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(childTicking, isFalse,
        reason: 'Resuming the app must not animate a still hidden scene');
    expect(tester.binding.hasScheduledFrame, isFalse);

    resize(() => viewportHeight = 400);
    await tester.pump();
    await tester.pump();
    expect(scroll.offset, 0);
    expect(childTicking, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reparenting a scene releases its old scroll visibility source',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final sceneKey = GlobalKey();
    late StateSetter reparent;
    var insideScroll = true;
    bool? childTicking;
    final scene = LumoSceneAtmosphere(
      key: sceneKey,
      child: Builder(builder: (context) {
        childTicking = TickerMode.of(context);
        return const SizedBox(height: 180, width: 300);
      }),
    );
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(builder: (context, setState) {
        reparent = setState;
        return insideScroll
            ? SingleChildScrollView(
                controller: scroll,
                child: Column(children: [
                  const SizedBox(height: 900),
                  scene,
                  const SizedBox(height: 900),
                ]),
              )
            : Center(child: SizedBox(height: 180, child: scene));
      }),
    ));
    await tester.pump();
    final originalState = sceneKey.currentState;
    expect(childTicking, isFalse);
    reparent(() => insideScroll = false);
    await tester.pump();
    await tester.pump();
    expect(sceneKey.currentState, same(originalState));
    expect(scroll.hasClients, isFalse);
    expect(childTicking, isTrue);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);
  });
}
