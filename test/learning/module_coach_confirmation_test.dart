import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning_lab_runtime_test.dart' show frames, tap;

void pause(WidgetTester tester) {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
}

void resume(WidgetTester tester) {
  if (tester.binding.lifecycleState == AppLifecycleState.paused) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  }
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
}

Future<LumoAppState> mountModule(WidgetTester tester, String id) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  final bus = LumoCompanionRequests.instance;
  bus.clearLearningScope();
  await tester.binding.setSurfaceSize(const Size(420, 1000));
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState();
    await app.school.setActiveStudent('module-confirmation-$id');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.update(app.state.copyWith(grade: 2, section: LumoSection.learn));
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        reduceAnimations: true,
        calmMode: true));
  });
  await tester.pumpWidget(
      MaterialApp(home: LearningModuleRegistry.builderFor(id, app)!));
  await frames(tester);
  addTearDown(() async {
    resume(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
    app.dispose();
    bus.clearLearningScope();
    await tester.binding.setSurfaceSize(null);
  });
  return app;
}

bool propose(String value) {
  final bus = LumoCompanionRequests.instance;
  return bus.requestLearningAction(LumoLearningAction.proposeAnswer,
      identity: bus.learningIdentity.value!, candidate: value);
}

void main() {
  for (final entry in const [
    ('d2_artikel', 'module'),
    ('m1_plus10', 'plus10')
  ]) {
    testWidgets(
        '${entry.$1}: pause, resize and overlay retain task and reject old confirmation',
        (tester) async {
      final app = await mountModule(tester, entry.$1);
      final bus = LumoCompanionRequests.instance;
      for (final action in [
        LumoLearningAction.hint,
        LumoLearningAction.repeat,
        LumoLearningAction.slower
      ]) {
        expect(
            bus.requestLearningAction(action,
                identity: bus.learningIdentity.value!),
            isTrue);
        await frames(tester);
        expect(bus.taskContext.value!.helpLevel, 1);
      }
      expect(
          bus.requestLearningAction(LumoLearningAction.hint,
              identity: bus.learningIdentity.value!),
          isTrue);
      await frames(tester);
      expect(bus.taskContext.value!.helpLevel, 2);
      final initial = bus.learningIdentity.value!;
      expect(propose(bus.taskContext.value!.answerChoices.first), isTrue);
      await frames(tester);
      final oldConfirm = tester
          .widget<FilledButton>(
              find.byKey(ValueKey('${entry.$2}-confirm-candidate')))
          .onPressed!;
      pause(tester);
      await frames(tester);
      expect(bus.taskContext.value, isNull);
      resume(tester);
      await frames(tester);
      expect(bus.taskContext.value!.taskId, initial.taskId);
      expect(bus.taskContext.value!.helpLevel, 2);
      expect(
          find.byKey(ValueKey('${entry.$2}-answer-candidate')), findsNothing);
      expect(
          bus.requestLearningAction(LumoLearningAction.proposeAnswer,
              identity: initial, candidate: '4'),
          isFalse);
      expect(propose(bus.taskContext.value!.answerChoices.first), isTrue);
      await frames(tester);
      oldConfirm();
      await frames(tester);
      expect(bus.taskContext.value!.attempts, 0);
      bus.cancelLearningInteraction();
      await frames(tester);
      await tester.binding.setSurfaceSize(const Size(840, 900));
      await frames(tester);
      expect(bus.taskContext.value!.taskId, initial.taskId);
      expect(bus.taskContext.value!.helpLevel, 2);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Andere Seite'))));
      await frames(tester);
      expect(bus.taskContext.value, isNull);
      navigator.pop();
      await frames(tester);
      expect(bus.taskContext.value!.taskId, initial.taskId);
      expect(bus.taskContext.value!.helpLevel, 2);
      expect(app.learningDailyDone(), 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '${entry.$1}: native return before resume keeps an ungraded candidate',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const bridge = MethodChannel('lumo_lernen/bridge');
      final nativeReturn = Completer<Map<String, Object?>>();
      Map<dynamic, dynamic>? payload;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, (call) async {
        if (call.method == 'launch3D') {
          payload = (call.arguments as Map)['learning'] as Map;
          return nativeReturn.future;
        }
        return <String, Object?>{'destination': 'learn'};
      });
      addTearDown(() {
        if (!nativeReturn.isCompleted) {
          nativeReturn.complete({'destination': 'learn'});
        }
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(bridge, null);
        debugDefaultTargetPlatformOverride = null;
      });
      final app = await mountModule(tester, entry.$1);
      final bus = LumoCompanionRequests.instance;
      final taskId = bus.taskContext.value!.taskId;
      await tap(tester, '${entry.$2}-open-3d');
      expect(payload, isNotNull);
      final identity = bus.learningIdentity.value!;
      expect(payload!['kind'], 'task_card');
      expect(payload!['sourceTaskId'], taskId);
      expect(payload!['scope'], identity.toJson());
      expect(payload!.containsKey('correctAnswer'), isFalse);
      expect(payload!['allowedActions'], contains('proposeAnswer'));
      expect(bus.taskContext.value!.helpLevel, 1);
      pause(tester);
      await frames(tester);
      expect(bus.learningIdentity.value, identity);
      final answer = bus.taskContext.value!.answerChoices.first;
      expect(propose(answer), isTrue);
      await frames(tester);
      expect(bus.taskContext.value!.attempts, 0);
      expect(app.learningDailyDone(), 0);
      nativeReturn.complete({'destination': 'learn'});
      await frames(tester);
      expect(bus.learningIdentity.value, identity);
      resume(tester);
      await frames(tester);
      expect(bus.taskContext.value!.taskId, taskId);
      expect(
          find.byKey(ValueKey('${entry.$2}-answer-candidate')), findsOneWidget);
      await tap(tester, '${entry.$2}-confirm-candidate');
      expect(bus.taskContext.value!.attempts, 1);
      expect(bus.taskContext.value!.lastAnswer, answer);
      expect(bus.taskContext.value!.lastCorrect, isNotNull);
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
