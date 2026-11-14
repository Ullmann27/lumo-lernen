import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

LumoAppState _state({
  int grade = 1,
  required String subject,
  required String unit,
  LumoSessionKind kind = LumoSessionKind.quickPractice,
}) {
  final state = LumoAppState(walletRepository: RewardWalletRepository());
  state.update(state.state.copyWith(
    childName: 'Mira',
    grade: grade,
    subject: subject,
    unit: unit,
    sessionKind: kind,
    testLevel: 0,
    settings: const AppSettings(aiProxyEnabled: false, voiceEnabled: false),
  ));
  return state;
}

Widget _lesson(LumoAppState state) =>
    MaterialApp(home: Scaffold(body: LearningContent(appState: state)));

Future<void> _open(WidgetTester tester, LumoAppState state) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(state.dispose);
  await tester.pumpWidget(_lesson(state));
  await tester.pump();
}

AdaptiveTaskRenderer _renderer(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));

Future<void> _close(WidgetTester tester, LumoAppState state) async {
  await state.flushRewards();
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  expect(LumoCompanionRequests.instance.taskContext.value, isNull);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.taskContext.value = null;
  });
  tearDown(() => LumoVoice.instance.isEnabled = true);

  test('exact adventure generation preserves the child name and selection', () {
    var personalized = 0;
    for (var seed = 0; seed < 40; seed++) {
      final task = ExerciseFactory(seed: seed).nextExact(
        grade: 2,
        subject: 'Mathematik',
        unit: 'Rechengeschichten',
        childName: 'Mira',
        weakSkills: const {'Rechengeschichten': 5},
      );
      expect(task.grade, 2);
      expect(task.subject, 'Mathematik');
      expect(task.unit, 'Rechengeschichten');
      expect(task.choices, contains(task.answer));
      if (task.prompt.contains('Mira')) personalized++;
    }
    expect(personalized, greaterThan(0),
        reason: 'The exact path must forward personalization to real stories');
  });

  for (final label in ['Woerter lesen', 'Wörter lesen']) {
    testWidgets('$label stays a reading lesson after the finite bank repeats',
        (tester) async {
      final state = _state(subject: 'Lesen', unit: label);
      await _open(tester, state);
      // Grade one has five word cards. Eight displayed questions necessarily
      // reach the repeat fallback, where the old code switched to German.
      for (var question = 0; question < 8; question++) {
        final renderer = _renderer(tester);
        expect(renderer.task.templateId, 'legacy.Lesen.Woerter lesen');
        expect(renderer.task.parameters['unit'], 'Woerter lesen');
        expect(renderer.task.difficulty, 1);
        expect(renderer.task.prompt, startsWith('Lies: '));
        expect(renderer.task.prompt, endsWith('Welches Wort passt?'));
        expect(
            LumoCompanionRequests.instance.taskContext.value?.subject, 'Lesen');
        expect(LumoCompanionRequests.instance.taskContext.value?.unit,
            'Woerter lesen');
        if (question < 7) {
          renderer.onAnswered!(AdaptiveTaskAnswer(
            task: renderer.task,
            answer: renderer.task.correctAnswer,
            correct: true,
          ));
          await tester.pump(const Duration(seconds: 7));
          await tester.pump(const Duration(milliseconds: 400));
        }
      }
      await _close(tester, state);
    });
  }

  testWidgets('canonical Zahlenstrahl is not replaced by the old alias',
      (tester) async {
    final state = _state(subject: 'Mathematik', unit: 'Zahlenstrahl');
    await _open(tester, state);
    final task = _renderer(tester).task;
    expect(task.templateId, 'legacy.Mathematik.Zahlenstrahl');
    expect(task.parameters['unit'], 'Zahlenstrahl');
    expect(
        LumoCompanionRequests.instance.taskContext.value?.unit, 'Zahlenstrahl');
    await _close(tester, state);
  });

  testWidgets('test difficulty changes replace the task and companion context',
      (tester) async {
    final state = _state(
      grade: 2,
      subject: 'Lesen',
      unit: 'Sätze lesen',
      kind: LumoSessionKind.test,
    );
    await _open(tester, state);
    final before = _renderer(tester).task;
    expect(before.difficulty, 2);

    state.update(state.state.copyWith(testLevel: 1));
    await tester.pumpWidget(_lesson(state));
    await tester.pump(const Duration(milliseconds: 400));
    final after = _renderer(tester).task;
    expect(after.difficulty, 3);
    expect(after.templateId, 'legacy.Lesen.Sätze lesen');
    expect(after.taskInstanceId, isNot(before.taskInstanceId));
    expect(
        LumoCompanionRequests.instance.taskContext.value?.prompt, after.prompt);
    expect(LumoCompanionRequests.instance.taskContext.value?.isExam, isTrue);
    expect(state.state.stars, 0);
    expect(state.state.xp, 0);
    await _close(tester, state);
  });

  for (final subject in ['Alle', 'Mathematik']) {
    testWidgets('$subject keeps its deliberate mixed-topic round',
        (tester) async {
      final state = _state(subject: subject, unit: 'Alle');
      await _open(tester, state);
      final task = _renderer(tester).task;
      final current = LumoCompanionRequests.instance.taskContext.value!;
      expect(task.prompt, isNotEmpty);
      expect(Curriculum.exerciseSubjectsForGrade(1), contains(current.subject));
      expect(
          Curriculum.unitsForGrade(current.subject, 1), contains(current.unit));
      expect(current.unit, isNot('Alle'));
      if (subject != 'Alle') expect(current.subject, subject);
      expect(state.state.stars, 0);
      expect(state.state.xp, 0);
      await _close(tester, state);
    });
  }
}
