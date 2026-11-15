import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/journal/lumo_journal_screen.dart';
import 'package:lumo_lernen/features/learning/curriculum_activities_screen.dart';
import 'package:lumo_lernen/features/learning/cross_grade_practice_screen.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_progress.dart';
import 'package:lumo_lernen/widgets/design/lumo_learning_module_frame.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 40));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _show(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _frames(tester);
  expect(target.hitTestable(), findsOneWidget,
      reason: 'The control must actually be reachable by touch.');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoCompanionRequests.instance.clearLearningScope();
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  testWidgets('method help records assistance through the real module scope',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    final progress = LearningModuleProgress(
        appState: app, subject: 'Mathematik', unit: 'Minus bis 10');
    await tester.pumpWidget(MaterialApp(
        home: LearningModuleProgressScope(
      progress: progress,
      child: LumoLearningModuleFrame(
          appState: app,
          title: 'Mathe-Abenteuer',
          moduleTitle: 'Minus bis 10',
          icon: Icons.calculate,
          taskIndex: 0,
          totalTasks: 2,
          correctAnswers: 0,
          canLeave: () => !progress.hasPending,
          child: FilledButton(
              key: const ValueKey('test-module-submit'),
              onPressed: () =>
                  progress.saveAnswer(correct: true, prompt: '8 - 3 = ?'),
              child: const Text('Antwort prüfen'))),
    )));
    await _frames(tester);
    final tools = find.byKey(const ValueKey('learning-module-tools'));
    await tester.ensureVisible(tools);
    expect(tester.getSize(tools).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(tools).height, greaterThanOrEqualTo(48));
    await tester.tap(tools);
    await _frames(tester);
    await tester.tap(find.byKey(const ValueKey('learning-module-help')));
    await _frames(tester);
    expect(find.byKey(const ValueKey('learning-module-method-hint')),
        findsOneWidget);
    final alternative =
        find.byKey(const ValueKey('learning-module-alternative-help'));
    await _show(tester, alternative);
    await tester.tap(alternative);
    await _frames(tester);
    expect(find.text('LUMO · Schritt 2 von 3'), findsOneWidget);
    final selfTry = find.byKey(const ValueKey('learning-module-self-try'));
    await _show(tester, selfTry);
    await tester.tap(selfTry);
    await _frames(tester);
    final submit = find.byKey(const ValueKey('test-module-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await _frames(tester);
    final skill = app.learningSkills().values.single;
    expect(skill.correct, 1);
    expect(skill.hintCount, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    progress.dispose();
    app.dispose();
  }, timeout: const Timeout(Duration(seconds: 45)));

  testWidgets(
      'practical cards open existing exact practice and protected journal',
      (tester) async {
    final app = LumoAppState(walletRepository: RewardWalletRepository());
    await tester.pumpWidget(MaterialApp(
        home: CurriculumActivitiesScreen(
            grade: 1, subject: 'Kunst und Gestaltung', appState: app)));
    await _frames(tester);
    final digital =
        find.byKey(const ValueKey('activity-g1_art_notice-practice'));
    await tester.scrollUntilVisible(digital, 200,
        scrollable: find.byType(Scrollable).first);
    await _show(tester, digital);
    await tester.tap(digital);
    await _frames(tester);
    expect(find.byType(CrossGradePracticeScreen), findsOneWidget);
    expect(
        tester
            .widget<CrossGradePracticeScreen>(
                find.byType(CrossGradePracticeScreen))
            .unit,
        'Geometrie Formen');
    Navigator.of(tester.element(find.byType(CrossGradePracticeScreen))).pop();
    await _frames(tester);
    final journal =
        find.byKey(const ValueKey('activity-g1_art_notice-journal'));
    await _show(tester, journal);
    await tester.tap(journal);
    await _frames(tester);
    expect(find.byType(LumoJournalScreen), findsOneWidget);
    expect(app.learningSkills(), isEmpty,
        reason: 'Opening a practical activity is not an assessed answer.');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
  }, timeout: const Timeout(Duration(seconds: 45)));
}
