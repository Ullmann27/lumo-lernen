import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../learning_lab_runtime_test.dart' show frames, tap;

Future<LumoAppState> mountGuidedCoach(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  final bus = LumoCompanionRequests.instance;
  bus.clearLearningScope();
  await tester.binding.setSurfaceSize(const Size(420, 1000));
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState();
    await app.school.setActiveStudent('guided-coach-test');
    await app.hydrateFromWallet();
    await app.loadLearningProfile();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  });
  final steps = GuidedLessonCatalog.bridgeTen.steps
      .where((step) => step.type == TutoringStepType.independentTask)
      .toList();
  final lesson = GuidedLesson(
      id: 'guided-confirmation-test',
      title: 'Über den Zehner',
      description: 'Geprüfte Aufgaben aus dem vorhandenen Katalog',
      grade: 1,
      schoolUnit: 'Plus bis 20',
      concept: GuidedLessonConcept.bridgeTen,
      steps: steps);
  await tester.pumpWidget(MaterialApp(
      home:
          GuidedLessonScreen(appState: app, lesson: lesson, discovery: false)));
  await frames(tester);
  addTearDown(() async {
    if (tester.binding.lifecycleState == AppLifecycleState.paused) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
  testWidgets('guided speech is editable and only confirmation grades',
      (tester) async {
    final app = await mountGuidedCoach(tester);
    final bus = LumoCompanionRequests.instance;
    expect(propose('dreizehn'), isTrue);
    await frames(tester);
    expect(bus.taskContext.value!.attempts, 0);
    expect(app.learningDailyDone(), 0);
    expect(find.byKey(const ValueKey('guided-candidate')), findsOneWidget);
    await tester.enterText(
        find.byKey(const ValueKey('guided-candidate-edit')), '14');
    await tap(tester, 'guided-confirm-candidate');
    expect(bus.taskContext.value!.lastCorrect, isTrue);
    expect(bus.taskContext.value!.attempts, 1);
    expect(app.learningDailyDone(), 1);
    expect(find.byKey(const ValueKey('guided-candidate')), findsNothing);
  });

  testWidgets(
      'guided hints stay staged; stop and next task reject old candidates',
      (tester) async {
    final app = await mountGuidedCoach(tester);
    final bus = LumoCompanionRequests.instance;
    for (final action in [
      LumoLearningAction.hint,
      LumoLearningAction.repeat,
      LumoLearningAction.slower,
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
    final captured = bus.learningIdentity.value!;
    expect(propose('14'), isTrue);
    await frames(tester);
    final oldConfirm = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('guided-confirm-candidate')))
        .onPressed!;
    bus.cancelLearningInteraction();
    await frames(tester);
    expect(find.byKey(const ValueKey('guided-candidate')), findsNothing);
    oldConfirm();
    await frames(tester);
    expect(bus.taskContext.value!.attempts, 0);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: captured, candidate: '14'),
        isFalse);
    expect(bus.taskContext.value!.helpLevel, 2);
    expect(propose('14'), isTrue);
    await frames(tester);
    await tap(tester, 'guided-confirm-candidate');
    expect(bus.taskContext.value!.lastCorrect, isTrue);
    expect(app.learningJourney().values.single.assistedCorrect, 1);
    expect(app.learningJourney().values.single.independentCorrect, 0);
    await tap(tester, 'guided-continue');
    oldConfirm();
    await frames(tester);
    expect(bus.taskContext.value!.attempts, 0);
    expect(bus.taskContext.value!.taskId, isNot(captured.taskId));
  });

  testWidgets(
      'guided pause, overlay and resize preserve task but retire proposals',
      (tester) async {
    await mountGuidedCoach(tester);
    final bus = LumoCompanionRequests.instance;
    bus.requestLearningAction(LumoLearningAction.hint,
        identity: bus.learningIdentity.value!);
    await frames(tester);
    final captured = bus.learningIdentity.value!;
    expect(propose('14'), isTrue);
    await frames(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(tester);
    expect(bus.taskContext.value, isNull);
    if (tester.binding.lifecycleState == AppLifecycleState.paused) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester);
    expect(bus.taskContext.value!.taskId, captured.taskId);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(find.byKey(const ValueKey('guided-candidate')), findsNothing);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: captured, candidate: '14'),
        isFalse);
    await tester.binding.setSurfaceSize(const Size(840, 900));
    await frames(tester);
    expect(bus.taskContext.value!.taskId, captured.taskId);
    expect(bus.taskContext.value!.helpLevel, 1);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final route = MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Andere Seite')));
    navigator.push(route);
    await frames(tester);
    expect(bus.taskContext.value, isNull);
    navigator.pop();
    await frames(tester);
    expect(bus.taskContext.value!.taskId, captured.taskId);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'native guided pause retains owner and returns an ungraded proposal',
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
    final app = await mountGuidedCoach(tester);
    final bus = LumoCompanionRequests.instance;
    await tap(tester, 'guided-open-3d');
    expect(payload, isNotNull);
    final identity = bus.learningIdentity.value!;
    expect(payload!['scope'], identity.toJson());
    expect(bus.taskContext.value!.helpLevel, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(tester);
    expect(bus.learningIdentity.value, identity);
    expect(propose('14'), isTrue);
    await frames(tester);
    expect(bus.taskContext.value!.attempts, 0);
    expect(app.learningDailyDone(), 0);
    nativeReturn.complete({'destination': 'learn'});
    await frames(tester);
    expect(bus.learningIdentity.value, identity);
    if (tester.binding.lifecycleState == AppLifecycleState.paused) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester);
    expect(bus.taskContext.value!.taskId, identity.taskId);
    expect(find.byKey(const ValueKey('guided-candidate')), findsOneWidget);
    await tap(tester, 'guided-confirm-candidate');
    expect(bus.taskContext.value!.lastCorrect, isTrue);
    expect(app.learningJourney().values.single.assistedCorrect, 1);
    expect(app.learningJourney().values.single.independentCorrect, 0);
    debugDefaultTargetPlatformOverride = null;
  });
}
