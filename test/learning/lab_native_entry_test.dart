import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/progress_repository.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../learning_lab_runtime_test.dart' show frames, mountLab, tap;
import 'module_coach_confirmation_test.dart' show pause, resume;

class _NativeRound {
  final result = Completer<Map<String, Object?>>();
  Map<dynamic, dynamic>? payload;

  void install(WidgetTester tester) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('lumo_lernen/bridge');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch3D') {
        expect((call.arguments as Map)['scene'], 'learning');
        payload = (call.arguments as Map)['learning'] as Map;
        return result.future;
      }
      return <String, Object?>{'destination': 'learn'};
    });
    addTearDown(() async {
      if (!result.isCompleted) result.complete({'destination': 'learn'});
      resume(tester);
      await frames(tester);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}

void main() {
  final bus = LumoCompanionRequests.instance;
  setUp(bus.clearLearningScope);
  tearDown(bus.clearLearningScope);

  for (final mode in LabMode.values) {
    testWidgets('${mode.name}: visible native entry preserves the exact task',
        (tester) async {
      final native = _NativeRound()..install(tester);
      final topicIndex = LabCatalog.topics.indexWhere((t) => t.mode == mode);
      final topic = LabCatalog.topics[topicIndex];
      final app =
          await mountLab(tester, grade: topic.minimumGrade, topic: topicIndex);
      final before = bus.taskContext.value!;
      final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
      final oldNext = tester
          .widget<FilledButton>(find.byKey(const ValueKey('lab-next')))
          .onPressed!;
      final entry = find.byKey(const ValueKey('lab-open-3d'));
      await tester.ensureVisible(entry);
      await tester.pump();
      expect(tester.getSize(entry).height, greaterThanOrEqualTo(48));
      expect(tester.getSize(entry).width, greaterThanOrEqualTo(48));
      await tap(tester, 'lab-open-3d');
      expect(native.payload, isNotNull);
      expect(native.payload!['kind'], 'task_card');
      expect(native.payload!['sourceTaskId'], before.taskId);
      expect(native.payload!['prompt'], before.prompt);
      expect(native.payload!['answerChoices'], before.answerChoices);
      expect(native.payload!['scope'], bus.learningIdentity.value!.toJson());
      expect(
          (native.payload!['objectIds'] as List)
              .every(bus.taskContext.value!.objectIds.contains),
          isTrue);
      expect(native.payload!.containsKey('correctAnswer'), isFalse);
      expect(native.payload!.containsKey('reward'), isFalse);
      expect(bus.taskContext.value!.helpLevel, greaterThanOrEqualTo(1));
      oldNext();
      await frames(tester);
      expect(find.byKey(const ValueKey('lab-phase-example')), findsOneWidget,
          reason:
              'A hidden Flutter callback must not advance the native step.');
      expect(bus.taskContext.value!.taskId, before.taskId);
      native.result.complete({'destination': 'learn'});
      await frames(tester);
      expect(bus.taskContext.value!.taskId, before.taskId);
      expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('native return before resume keeps an ungraded recall candidate',
      (tester) async {
    final native = _NativeRound()..install(tester);
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    await tap(tester, 'quantity-add');
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    final taskId = bus.taskContext.value!.taskId;
    final oldConfirm = tester
        .widget<FilledButton>(find.byKey(const ValueKey('lab-check-answer')))
        .onPressed!;
    await tap(tester, 'lab-open-3d');
    expect(native.payload, isNotNull);
    expect(bus.taskContext.value!.helpLevel, 1);
    final launched = bus.learningIdentity.value!;
    pause(tester);
    await frames(tester);
    expect(bus.learningIdentity.value, launched);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: launched, candidate: '16'),
        isTrue);
    await frames(tester);
    final proposed = bus.learningIdentity.value!;
    expect(proposed.stepId, launched.stepId);
    expect(
        bus.taskContext.value!.attempts, 1); // The earlier model observation.
    expect(app.learningDailyDone(), 0);
    oldConfirm();
    native.result.complete({'destination': 'learn'});
    await frames(tester);
    expect(bus.learningIdentity.value, proposed);
    expect(app.learningDailyDone(), 0);
    resume(tester);
    await frames(tester);
    await tester.binding.setSurfaceSize(const Size(840, 900));
    await frames(tester);
    expect(bus.taskContext.value!.taskId, taskId);
    expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('lab-answer')))
            .controller!
            .text,
        '16');
    oldConfirm();
    await frames(tester);
    expect(app.learningDailyDone(), 0);
    await tap(tester, 'lab-check-answer');
    expect(app.learningDailyDone(), 1);
    await tester.runAsync(() async {
      final record = (await app.captureLearningProfile())
          .profile
          .journey
          .records[SkillRecord.makeId('Mathematik', 'Plus bis 20')]!;
      expect(record.independentCorrect, 0);
      expect(record.assistedCorrect, 2);
    });
    // Help belongs to the viewed problem, not to the following transfer task.
    await tap(tester, 'lab-next');
    await tester.enterText(find.byKey(const ValueKey('lab-answer')), '11');
    await tap(tester, 'lab-check-answer');
    await tester.runAsync(() async {
      final record = (await app.captureLearningProfile())
          .profile
          .journey
          .records[SkillRecord.makeId('Mathematik', 'Plus bis 20')]!;
      expect(record.independentCorrect, 1);
      expect(record.assistedCorrect, 2);
    });
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'native pattern proposal cannot move the hidden step or survive Stop',
      (tester) async {
    final native = _NativeRound()..install(tester);
    final index =
        LabCatalog.topics.indexWhere((t) => t.mode == LabMode.pattern);
    final topic = LabCatalog.topics[index];
    final app = await mountLab(tester, topic: index, grade: topic.minimumGrade);
    await tap(tester, 'lab-next');
    await tap(tester,
        'pattern-option-${topic.problems.first.tokens.indexOf(topic.problems.first.expected)}');
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    final answer = topic.problems[2].expected;
    await tap(tester, 'lab-open-3d');
    expect(native.payload, isNotNull);
    final initial = bus.learningIdentity.value!;
    pause(tester);
    await frames(tester);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: answer),
        isTrue);
    await frames(tester);
    tester
        .widget<PatternBuildBoard>(find.byType(PatternBuildBoard))
        .onChanged(0);
    await frames(tester);
    expect(bus.learningIdentity.value!.stepId, initial.stepId);
    expect(
        tester
            .widget<PatternBuildBoard>(find.byType(PatternBuildBoard))
            .selected,
        isNull);
    expect(app.learningDailyDone(), 0);
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: bus.learningIdentity.value!),
        isTrue);
    await frames(tester);
    native.result.complete({'destination': 'learn'});
    await frames(tester);
    resume(tester);
    await frames(tester);
    expect(
        tester
            .widget<PatternBuildBoard>(find.byType(PatternBuildBoard))
            .selected,
        isNull);
    await tap(tester, 'lab-check-answer');
    expect(app.learningDailyDone(), 0);
    expect(find.text('Wähle zuerst eine Form.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
