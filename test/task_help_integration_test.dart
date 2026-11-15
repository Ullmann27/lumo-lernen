import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.taskContext.value = null;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  for (final kind in [
    LumoSessionKind.quickPractice,
    LumoSessionKind.test,
    LumoSessionKind.schoolwork
  ]) {
    testWidgets('fox help respects $kind and stays on the current task',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final state = LumoAppState(walletRepository: RewardWalletRepository());
      state.update(state.state.copyWith(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        sessionKind: kind,
        settings: const AppSettings(aiProxyEnabled: false, voiceEnabled: false),
      ));
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
        body: LearningContent(appState: state),
      )));
      await tester.pump();
      final before = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      final requests = LumoCompanionRequests.instance;
      expect(requests.taskContext.value?.prompt, before.prompt);
      final isExam = kind != LumoSessionKind.quickPractice;
      expect(requests.taskContext.value?.isExam, isExam);
      final helpButton = find.widgetWithText(OutlinedButton, 'Hilf mir');
      requests.requestTaskHelp();
      await tester.pump();
      if (isExam) {
        expect(find.text('Lumo erklärt'), findsNothing);
        expect(helpButton, findsNothing);
      } else {
        expect(find.text('Lumo erklärt'), findsOneWidget);
        expect(find.textContaining('Beginne mit der ersten Menge'),
            findsOneWidget);
        expect(helpButton, findsOneWidget);
        expect(tester.widget<OutlinedButton>(helpButton).onPressed, isNotNull);
        final helpSize = tester.getSize(helpButton);
        expect(helpSize.width, greaterThanOrEqualTo(48));
        expect(helpSize.height, greaterThanOrEqualTo(48));
        // The visible canonical control must advance the same staged help
        // as a companion request, without submitting or replacing the task.
        await tester.ensureVisible(helpButton);
        await tester.tap(helpButton);
        await tester.pump();
        expect(find.textContaining('Starte bei'), findsOneWidget);
        expect(
            find.textContaining('Beginne mit der ersten Menge'), findsNothing);
        requests.requestTaskHelp();
        await tester.pump();
        expect(find.textContaining('Teile'), findsOneWidget);
        expect(find.textContaining('Prüfe durch Zurückzählen'), findsOneWidget);
      }
      final after = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
          .task;
      expect(after.taskInstanceId, before.taskInstanceId);
      expect(state.state.stars, 0);
      expect(state.state.xp, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(requests.taskContext.value, isNull);
      state.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('disposing helped lesson preserves the next screen task owner',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState(walletRepository: RewardWalletRepository());
    addTearDown(state.dispose);
    state.update(state.state.copyWith(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      sessionKind: LumoSessionKind.quickPractice,
      settings: const AppSettings(aiProxyEnabled: false, voiceEnabled: false),
    ));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: LearningContent(appState: state)),
    ));
    await tester.pump();
    final requests = LumoCompanionRequests.instance;
    for (var level = 0; level < 3; level++) {
      requests.requestTaskHelp();
      await tester.pump();
    }
    final formerOwner = requests.taskContext.value;
    expect(formerOwner, isNotNull);
    final successor = LumoCompanionTaskContext(
      subject: 'Deutsch',
      unit: 'Silben',
      prompt: 'Wie viele Silben hat Banane?',
      taskId: 'successor-screen-task',
      profileGeneration: state.profileGeneration,
    );
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        // The new page schedules its publication while replacing the old
        // page. It publishes before the old page's post-frame owner cleanup.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          requests.publishTask(successor);
        });
        return const SizedBox.shrink();
      }),
    ));
    await tester.pump();
    expect(requests.taskContext.value, same(successor));
    expect(requests.taskContext.value, isNot(same(formerOwner)));
    expect(tester.takeException(), isNull);
    requests.clearTask(successor);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'changing the selected activity replaces the active task and help',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState(walletRepository: RewardWalletRepository());
    state.update(state.state.copyWith(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        settings: const AppSettings(voiceEnabled: false)));
    Widget lesson() =>
        MaterialApp(home: Scaffold(body: LearningContent(appState: state)));
    await tester.pumpWidget(lesson());
    await tester.pump();
    LumoCompanionRequests.instance.requestTaskHelp();
    await tester.pump();
    expect(find.text('Lumo erklärt'), findsOneWidget);
    state.update(state.state.copyWith(unit: 'Minus bis 10'));
    await tester.pumpWidget(lesson());
    await tester.pump(const Duration(milliseconds: 400));
    final task = tester
        .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer))
        .task;
    expect(task.parameters['unit'], 'Minus bis 10');
    expect(find.text('Lumo erklärt'), findsNothing);
    expect(
        LumoCompanionRequests.instance.taskContext.value?.unit, 'Minus bis 10');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a ten-task practice session ends instead of silently looping',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = LumoAppState(walletRepository: RewardWalletRepository());
    state.update(state.state.copyWith(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        settings: const AppSettings(voiceEnabled: false)));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: LearningContent(appState: state))));
    await tester.pump();
    for (var step = 0; step < 10; step++) {
      final renderer = tester
          .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
      renderer.onAnswered!(AdaptiveTaskAnswer(
        task: renderer.task,
        answer: renderer.task.correctAnswer,
        correct: true,
      ));
      await tester.pump(const Duration(seconds: 7));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.text('Einheit beendet'), findsOneWidget);
    expect(find.byType(AdaptiveTaskRenderer), findsNothing);
    expect(
        LumoCompanionRequests.instance.taskContext.value?.answering, isFalse);
    await state.flushRewards();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    state.dispose();
    expect(tester.takeException(), isNull);
  });
}
