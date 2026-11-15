import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_screen.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../learning_lab_runtime_test.dart' show frames, mountLab, tap;

void main() {
  final bus = LumoCompanionRequests.instance;
  setUp(bus.clearLearningScope);
  tearDown(bus.clearLearningScope);

  testWidgets('lab retires hidden bindings and restores the same model',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    final before = bus.taskContext.value!;
    final identity = bus.learningIdentity.value!;
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());

    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(tester);
    expect(bus.taskContext.value, isNull,
        reason: 'A paused lab must release its command receiver.');
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(bus.taskContext.value!.prompt, before.prompt);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);
    await tester.binding.setSurfaceSize(const Size(344, 882));
    await frames(tester);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final visibleIdentity = bus.learningIdentity.value!;
    navigator.push<void>(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Anderer Bereich'))));
    await frames(tester);
    expect(bus.taskContext.value, isNull,
        reason: 'A covered lab must not consume the visible route’s requests.');
    navigator.pop();
    await frames(tester);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: visibleIdentity),
        isFalse);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lab proposal needs confirmation and stop discards its candidate',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    await tap(tester, 'quantity-add');
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    final identity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: '16'),
        isTrue);
    await frames(tester);
    final field = find.byKey(const ValueKey('lab-answer'));
    expect(tester.widget<TextField>(field).controller!.text, '16');
    expect(app.learningDailyDone(), 0);

    final proposedIdentity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: proposedIdentity),
        isTrue);
    await frames(tester);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: proposedIdentity, candidate: '16'),
        isFalse);
    expect(app.learningDailyDone(), 0);

    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: '16'),
        isTrue);
    await frames(tester);
    expect(app.learningDailyDone(), 0);
    await tap(tester, 'lab-check-answer');
    expect(app.learningDailyDone(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the lab restores its saved model without new rewards',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        isTrue);
    await frames(tester);
    final before = bus.taskContext.value!;
    final identity = bus.learningIdentity.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
    await tester.pumpWidget(MaterialApp(
        home: LearningLabScreen(
            appState: app, topic: LabCatalog.topics.first, seed: 0)));
    await frames(tester);
    expect(find.byKey(const ValueKey('lab-phase-build')), findsOneWidget);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(bus.taskContext.value!.helpLevel, before.helpLevel);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });
}
