import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/tutoring/native_learning_activity.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

Future<LumoAppState> _mount(WidgetTester tester,
    {LumoSessionKind kind = LumoSessionKind.quickPractice,
    String unit = 'Plus bis 10',
    int grade = 1}) async {
  SharedPreferences.setMockInitialValues({});
  LumoVoice.instance.isEnabled = false;
  final bus = LumoCompanionRequests.instance;
  bus.clearLearningScope();
  await tester.binding.setSurfaceSize(const Size(840, 1200));
  final app = LumoAppState();
  await app.school.setActiveStudent('commands-child');
  await app.loadLearningProfile();
  app.updateSettings(const AppSettings(
      voiceEnabled: false, autoReadEnabled: false, reduceAnimations: true));
  app.update(app.state.copyWith(
      subject: 'Mathematik', unit: unit, grade: grade, sessionKind: kind));
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
        body: AnimatedBuilder(
      animation: app,
      builder: (_, __) => LearningContent(appState: app),
    )),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  addTearDown(() async {
    if (tester.binding.lifecycleState == AppLifecycleState.paused) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
    bus.clearLearningScope();
    await tester.binding.setSurfaceSize(null);
  });
  return app;
}

void main() {
  testWidgets('spoken proposal is editable and never grades itself',
      (tester) async {
    final app = await _mount(tester);
    final bus = LumoCompanionRequests.instance;
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    final correct = renderer.task.options.firstWhere((option) =>
        '${option.payload ?? option.label}' ==
        '${renderer.task.correctAnswer}');
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: 'verhört'),
        isTrue);
    await tester.pump();
    expect(bus.taskContext.value!.attempts, 0);
    expect(app.learningProfile.dailyDone(), 0);
    final field = find.byKey(const ValueKey('learning-answer-candidate'));
    expect(field, findsOneWidget);
    await tester.enterText(field, correct.label);
    final confirm = find.byKey(const ValueKey('learning-confirm-candidate'));
    await tester.ensureVisible(confirm);
    await tester.pump();
    await tester.tap(confirm);
    await tester.pump();
    expect(bus.taskContext.value!.attempts, 1);
    expect(bus.taskContext.value!.lastCorrect, isTrue);
    expect(
        find.byKey(const ValueKey('learning-answer-candidate')), findsNothing);
  });

  testWidgets('stop discards proposal and rejects its captured identity',
      (tester) async {
    final app = await _mount(tester);
    final bus = LumoCompanionRequests.instance;
    final old = bus.learningIdentity.value!;
    bus.requestLearningAction(LumoLearningAction.proposeAnswer,
        identity: old, candidate: '13');
    await tester.pump();
    bus.cancelLearningInteraction();
    await tester.pump();
    expect(
        find.byKey(const ValueKey('learning-answer-candidate')), findsNothing);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: old, candidate: '7'),
        isFalse);
    expect(app.learningProfile.dailyDone(), 0);
    expect(bus.taskContext.value!.attempts, 0);
  });

  testWidgets('task switch retires an old proposal without a learning error',
      (tester) async {
    final app = await _mount(tester);
    final bus = LumoCompanionRequests.instance;
    final old = bus.learningIdentity.value!;
    bus.requestLearningAction(LumoLearningAction.proposeAnswer,
        identity: old, candidate: '4');
    await tester.pump();
    final oldConfirm = tester
        .widget<FilledButton>(
            find.byKey(const ValueKey('learning-confirm-candidate')))
        .onPressed!;
    app.update(app.state.copyWith(unit: 'Minus bis 10'));
    await tester.pump();
    await tester.pump();
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: old, candidate: '4'),
        isFalse);
    expect(bus.taskContext.value!.unit, 'Minus bis 10');
    expect(bus.taskContext.value!.attempts, 0);
    bus.requestLearningAction(LumoLearningAction.proposeAnswer,
        identity: bus.learningIdentity.value!,
        candidate: bus.taskContext.value!.answerChoices.first);
    await tester.pump();
    oldConfirm();
    await tester.pump();
    expect(bus.taskContext.value!.attempts, 0,
        reason:
            'A button retained from the old task cannot confirm a new proposal.');
    expect(find.byKey(const ValueKey('learning-answer-candidate')),
        findsOneWidget);
  });

  testWidgets('trying alone after a hint retains assisted evidence',
      (tester) async {
    final app = await _mount(tester);
    final bus = LumoCompanionRequests.instance;
    bus.requestLearningAction(LumoLearningAction.hint,
        identity: bus.learningIdentity.value!);
    await tester.pump();
    final self = find.byKey(const ValueKey('learning-self-try'));
    await tester.ensureVisible(self);
    await tester.pump();
    await tester.tap(self);
    await tester.pump();
    final renderer =
        tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
    renderer.onAnswered!(AdaptiveTaskAnswer(
        task: renderer.task,
        answer: renderer.task.correctAnswer,
        correct: true));
    await tester.pump();
    await tester.runAsync(app.flushTutorEvidence);
    expect(app.learningJourney().values.single.assistedCorrect, 1);
    expect(app.learningJourney().values.single.independentCorrect, 0);
  });

  testWidgets('assessment mode keeps its no-help boundary', (tester) async {
    await _mount(tester, kind: LumoSessionKind.test);
    final bus = LumoCompanionRequests.instance;
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        isFalse);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: '12'),
        isFalse);
    expect(find.byKey(const ValueKey('learning-self-try')), findsNothing);
    for (final action in [
      LumoLearningAction.repeat,
      LumoLearningAction.slower
    ]) {
      expect(
          bus.requestLearningAction(action,
              identity: bus.learningIdentity.value!),
          isTrue);
      await tester.pump();
      expect(bus.taskContext.value!.helpLevel, 0);
      expect(bus.taskContext.value!.attempts, 0);
    }
    expect(find.byKey(const ValueKey('adaptive-open-3d')), findsNothing);
  });

  testWidgets('non-specialised adaptive family exposes the canonical 3D card',
      (tester) async {
    await _mount(tester, grade: 2, unit: 'Plus bis 100');
    final task = tester
        .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
        .task;
    expect(NativeLearningActivity.fromTask(task), isNull);
    expect(NativeLearningActivity.forTask(task).kind, 'task_card');
    final action = find.byKey(const ValueKey('adaptive-open-3d'));
    expect(action, findsOneWidget);
    await tester.ensureVisible(action);
    await tester.pump();
    expect(action.hitTestable(), findsOneWidget);
    expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'adaptive pause and route overlay retire proposals and keep the task',
      (tester) async {
    final app = await _mount(tester);
    final bus = LumoCompanionRequests.instance;
    final captured = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: captured, candidate: '13'),
        isTrue);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(bus.taskContext.value, isNull);
    if (tester.binding.lifecycleState == AppLifecycleState.paused) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    }
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(bus.taskContext.value!.taskId, captured.taskId);
    expect(
        find.byKey(const ValueKey('learning-answer-candidate')), findsNothing);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: captured, candidate: '13'),
        isFalse);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Andere Seite'))));
    await tester.pumpAndSettle();
    expect(bus.taskContext.value, isNull);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(bus.taskContext.value!.taskId, captured.taskId);
    expect(app.learningDailyDone(), 0);
    expect(tester.takeException(), isNull);
  });
}
