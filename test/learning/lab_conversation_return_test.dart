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

Future<int> pumpRequestedFrames(WidgetTester tester,
    {Future<void> Function()? afterFrame}) async {
  var count = 0;
  await tester.idle();
  while (tester.binding.hasScheduledFrame) {
    expect(count++, lessThan(60),
        reason: 'The calm Lab must stop requesting frames after route return.');
    await tester.pump(const Duration(milliseconds: 25));
    await tester.idle();
    await afterFrame?.call();
  }
  return count;
}

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
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester
          .binding.platformDispatcher.clearAccessibilityFeaturesTestValue);
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
      await tap(tester, 'lab-ask-lumo');
      expect(find.byType(LumoAgentContent), findsOneWidget);
      final conversation = find.byType(LumoAgentContent);
      final input =
          find.descendant(of: conversation, matching: find.byType(TextField));
      await tester.ensureVisible(input);
      await tester.pump();
      await tester.enterText(input, 'Warum zuerst zwei?');
      tester.testTextInput.hide();
      await frames(tester);
      final send = find.descendant(
          of: conversation,
          matching: find.widgetWithText(FilledButton, 'Senden'));
      await tester.ensureVisible(send);
      await tester.pump();
      await tester.tap(send);
      await frames(tester);
      expect(
          find.descendant(
              of: conversation,
              matching: find.textContaining(
                  'Bis zur Zehn fehlen 2, denn 10 minus 8 ist 2')),
          findsOneWidget);
      final stop = find.descendant(
          of: conversation,
          matching: find.widgetWithText(OutlinedButton, 'Stopp'));
      await tester.ensureVisible(stop);
      await tester.pump();
      await tester.tap(stop);
      await frames(tester);
      final checkpointBefore =
          await tester.runAsync<LearningLabCheckpoint?>(() async {
        final lease = await app.captureLearningProfile();
        return LearningLabResumeRepository(
            studentId: lease.studentId,
            mayWrite: () => false).load(LabCatalog.topics.first, 0);
      });
      expect(checkpointBefore, isNotNull);
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

      // A device produces only requested frames. An unconditional pump after
      // route.completed would hide a queued post-frame callback that never
      // requested the frame it needs to rebind this page.
      await tester.tap(find.byTooltip('Zurück zur Aufgabe'));
      var stoneTaps = 0;
      final returnFrames =
          await pumpRequestedFrames(tester, afterFrame: () async {
        final board = tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard));
        if (board.enabled) {
          expect(bus.learningIdentity.value, isNotNull,
              reason: 'An enabled model must own a usable task identity in '
                  'every return frame, before a child can tap its stone.');
          expect(bus.taskContext.value!.taskId, task.taskId);
          expect(
              bus.taskContext.value!.profileGeneration, task.profileGeneration);
          if (stoneTaps == 0) {
            expect(find.byType(LumoAgentContent), findsNothing);
            expect(bus.taskContext.value!.stepId, task.stepId);
            expect(bus.isCurrentLearningIdentity(oldIdentity), isFalse);
            oldModelChange(2);
            expect(
                tester
                    .widget<QuantityBridgeBoard>(
                        find.byType(QuantityBridgeBoard))
                    .moved,
                0);
            final bank = find.byKey(const ValueKey('quantity-bank-0'));
            expect(bank.hitTestable(), findsOneWidget);
            expect(
                tester
                    .widget<FilledButton>(
                        find.byKey(const ValueKey('lab-next')))
                    .onPressed,
                isNotNull);
            // Exactly the first usable frame receives the only stone tap.
            // No ensureVisible, forced extra pump, delay or second tap.
            await tester.tap(bank);
            stoneTaps++;
          }
        }
      });
      expect(find.byType(LumoAgentContent), findsNothing);
      expect(bus.taskContext.value, isNotNull,
          reason: 'Route disposed after $returnFrames requested frames, but '
              'the Lab must not wait for a child touch to publish its task.');
      expect(bus.taskContext.value!.taskId, task.taskId);
      expect(bus.taskContext.value!.prompt, task.prompt);
      expect(bus.isCurrentLearningIdentity(oldIdentity), isFalse);
      expect(stoneTaps, 1);

      oldModelChange(2);
      expect(
          tester
              .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
              .moved,
          1,
          reason: 'An old callback must not regain ownership.');
      expect(
          bus.requestLearningAction(LumoLearningAction.hint,
              identity: oldIdentity),
          isFalse);

      final board =
          tester.widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard));
      expect(board.enabled, isTrue);
      expect(
          tester
              .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
              .moved,
          1,
          reason: 'The first offered stone tap must move exactly one stone.');
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
