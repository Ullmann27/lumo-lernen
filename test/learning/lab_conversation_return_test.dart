import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/features/learning/nextgen/learning_lab_resume.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../learning_lab_runtime_test.dart' show frames, mountLab, tap;

void main() {
  final bus = LumoCompanionRequests.instance;
  setUp(bus.clearLearningScope);
  tearDown(bus.clearLearningScope);

  testWidgets('visible lab resume rebinds without a resize', (tester) async {
    final app = await mountLab(tester, size: const Size(900, 2400));
    final task = bus.taskContext.value!;
    final oldIdentity = bus.learningIdentity.value!;
    final oldModelChange = tester
        .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
        .onChanged;
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(bus.taskContext.value, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(bus.taskContext.value!.taskId, task.taskId);
    expect(bus.taskContext.value!.stepId, task.stepId);
    expect(bus.isCurrentLearningIdentity(oldIdentity), isFalse);
    oldModelChange(2);
    final board =
        tester.widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard));
    expect(board.moved, 0);
    expect(board.enabled, isTrue);
    final bank = find.byKey(const ValueKey('quantity-bank-0'));
    expect(bank.hitTestable(), findsOneWidget);
    await tester.tap(bank);
    await tester.pump();
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    final saved = await tester.runAsync(() async {
      final lease = await app.captureLearningProfile();
      return LearningLabResumeRepository(
          studentId: lease.studentId,
          mayWrite: () => false).load(LabCatalog.topics.first, 0);
    });
    expect(saved!.moved, 1);
    expect(saved.problemId, task.taskId);
    expect(saved.phase, 'example');
    expect(saved.done, isFalse);
    expect(saved.attempt, 0);
    expect(tester.takeException(), isNull);
  });

  for (final permissionInterruption in [false, true]) {
    testWidgets(
        'own conversation return rebinds visible model '
        '(permission interruption: $permissionInterruption)', (tester) async {
      final app = await mountLab(tester, size: const Size(900, 2400));
      app.setSection(LumoSection.learn);
      await frames(tester);
      await tap(tester, 'lab-help');
      await tap(tester, 'lab-stop');
      final task = bus.taskContext.value!;
      final oldIdentity = bus.learningIdentity.value!;
      final oldModelChange = tester
          .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
          .onChanged;
      final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
      final checkpointBefore = await tester.runAsync(() async {
        final lease = await app.captureLearningProfile();
        return LearningLabResumeRepository(
            studentId: lease.studentId,
            mayWrite: () => false).load(LabCatalog.topics.first, 0);
      });
      expect(checkpointBefore, isNotNull);

      await tap(tester, 'lab-ask-lumo');
      expect(find.byType(LumoAgentContent), findsOneWidget);
      if (permissionInterruption) {
        addTearDown(() => tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        await tester.pump();
        expect(bus.taskContext.value, isNull);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        expect(bus.taskContext.value!.taskId, task.taskId);
      }

      // Close the real animated modal. Explicit frames expose the interval
      // between didComplete(null), route disposal and the caller's finally.
      // No resize, app-settings write or pumpAndSettle may repair the page.
      await tester.tap(find.byTooltip('Zurück zur Aufgabe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump();
      expect(find.byType(LumoAgentContent), findsNothing);
      expect(bus.taskContext.value!.taskId, task.taskId);
      expect(bus.taskContext.value!.prompt, task.prompt);
      expect(bus.taskContext.value!.stepId, task.stepId);
      expect(bus.isCurrentLearningIdentity(oldIdentity), isFalse);

      oldModelChange(2);
      expect(
          tester
              .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
              .moved,
          0,
          reason: 'An old callback must not regain ownership.');
      expect(
          bus.requestLearningAction(LumoLearningAction.hint,
              identity: oldIdentity),
          isFalse);

      final board =
          tester.widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard));
      expect(board.enabled, isTrue);
      final bank = find.byKey(const ValueKey('quantity-bank-0'));
      expect(bank.hitTestable(), findsOneWidget);
      final nextEnabled = tester
              .widget<FilledButton>(find.byKey(const ValueKey('lab-next')))
              .onPressed !=
          null;
      await tester.tap(bank);
      await tester.pump();
      expect(
          tester
              .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
              .moved,
          1,
          reason: 'The visible stone must move after return. '
              'The same frame had lab-next enabled=$nextEnabled.');
      expect(nextEnabled, isTrue);
      expect(
          tester
              .widget<OutlinedButton>(find.byKey(const ValueKey('lab-help')))
              .onPressed,
          isNotNull);
      final checkpointAfter = await tester.runAsync(() async {
        final lease = await app.captureLearningProfile();
        return LearningLabResumeRepository(
            studentId: lease.studentId,
            mayWrite: () => false).load(LabCatalog.topics.first, 0);
      });
      expect(checkpointAfter!.moved, 1);
      expect(checkpointAfter.problemId, task.taskId);
      expect(checkpointAfter.phase, 'example');
      expect(checkpointAfter.sessionId, checkpointBefore!.sessionId);
      expect(checkpointAfter.hint, checkpointBefore.hint);
      expect(checkpointAfter.support, checkpointBefore.support);
      expect(checkpointAfter.attempt, checkpointBefore.attempt);
      expect(checkpointAfter.done, isFalse);
      expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
      expect(tester.takeException(), isNull);
    });
  }
}
