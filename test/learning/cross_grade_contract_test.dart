import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning/widgets/interactive_task_workspace.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _open(WidgetTester tester, LumoAppState app,
    {String unit = 'Plus bis 10'}) async {
  await tester.pumpWidget(MaterialApp(
    home: CrossGradePracticeScreen(
        profileName: 'ContractProbe',
        enrolledGrade: 2,
        lessonGrade: 1,
        subject: 'Mathematik',
        unit: unit,
        appState: app),
  ));
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bus.clearLearningScope();
  });

  testWidgets('voice proposals require child confirmation and preserve grades',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    app.update(app.state.copyWith(grade: 2));
    await _open(tester, app);
    final context = bus.taskContext.value!;
    expect(context.objectIds, contains('task-workspace'));
    expect(context.answering, isTrue);
    expect(context.answerChoices.length, greaterThan(1));
    final prompt = tester
        .widget<Text>(find.byKey(const ValueKey('cross-grade-question')))
        .data!;
    final values = RegExp(r'(\d+)\s*\+\s*(\d+)').firstMatch(prompt)!;
    final answer =
        '${int.parse(values.group(1)!) + int.parse(values.group(2)!)}';
    final prefs = await SharedPreferences.getInstance();
    const key =
        'cross_grade_practice_v1:contractprobe:1:Mathematik:Plus bis 10:answered';

    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!,
            candidate: 'unsicher erkannt'),
        isTrue);
    await _frames(tester);
    expect(prefs.getInt(key), isNull);
    expect(bus.taskContext.value!.attempts, 0);
    expect(bus.taskContext.value!.errorType, isNull);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('cross-grade-proposal-confirm')))
            .onPressed,
        isNull);

    final input = find.byKey(const ValueKey('cross-grade-answer-proposal'));
    await tester.ensureVisible(input);
    await tester.enterText(input, answer);
    await _frames(tester);
    expect(prefs.getInt(key), isNull);
    final confirm = find.byKey(const ValueKey('cross-grade-proposal-confirm'));
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _frames(tester);
    expect(prefs.getInt(key), 1);
    expect(bus.taskContext.value!.lastCorrect, isTrue);
    expect(app.state.grade, 2);
    expect(app.state.stars, 0);
    expect(app.state.xp, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  });

  testWidgets('help repeat slower stop use current object and task scopes',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await _open(tester, app);
    final firstIdentity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.point,
            identity: firstIdentity, objectId: 'an-object-from-another-task'),
        isFalse);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: firstIdentity),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.helpLevel, 1);
    expect(
        bus.requestLearningAction(LumoLearningAction.repeat,
            identity: firstIdentity),
        isFalse);
    final beforeRepeat = bus.taskContext.value!.taskId;
    expect(
        bus.requestLearningAction(LumoLearningAction.repeat,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.taskId, beforeRepeat);
    expect(bus.taskContext.value!.helpLevel, 1,
        reason: 'Repeating the same problem cannot erase observed help.');
    expect(
        bus.requestLearningAction(LumoLearningAction.slower,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
    expect(
        tester
            .widget<InteractiveTaskWorkspace>(
                find.byType(InteractiveTaskWorkspace))
            .slow,
        isTrue);

    final beforeStop = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: beforeStop),
        isTrue);
    await _frames(tester);
    expect(bus.taskContext.value!.isExplanation, isFalse);
    expect(bus.learningPresentation.value, isNull);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: beforeStop, candidate: '13'),
        isFalse);

    final previous = bus.learningIdentity.value!;
    await _open(tester, app, unit: 'Minus bis 10');
    expect(bus.taskContext.value!.unit, 'Minus bis 10');
    expect(bus.taskContext.value!.helpLevel, 0);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: previous),
        isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((key) => key.endsWith(':answered')), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  });

  testWidgets('workspace survives scroll to answers and back', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await _open(tester, app);
    final workspace = find.byType(InteractiveTaskWorkspace);
    final originalState = tester.state(workspace);
    await tester
        .ensureVisible(find.byKey(const ValueKey('cross-grade-choice-3')));
    await _frames(tester);
    await tester.ensureVisible(workspace);
    await _frames(tester);
    expect(identical(tester.state(workspace), originalState), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  });
}
