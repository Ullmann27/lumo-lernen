import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/error_breakdown_repository.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/learning/error_detective.dart';
import 'package:lumo_lernen/domain/learning/lumo_learning_domain.dart';
import 'package:lumo_lernen/domain/writing/writing_domain.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/learning/renderers/adaptive_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/shape_trace_task_renderer.dart';
import 'package:lumo_lernen/features/learning/renderers/writing_task_renderer.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class _DelayedIdentityState extends LumoAppState {
  bool holdNextIdentity = false;
  final releaseIdentity = Completer<void>();
  LearningProfileLease? heldIdentity;

  @override
  Future<LearningProfileLease> captureLearningProfile() {
    // Capture the real selected child immediately, then delay only delivery.
    // No scoring, profile, answer or persistence behavior is substituted.
    final captured = super.captureLearningProfile();
    if (!holdNextIdentity) return captured;
    holdNextIdentity = false;
    return captured.then((owner) async {
      heldIdentity = owner;
      await releaseIdentity.future;
      return owner;
    });
  }
}

class _DelayedHelp extends LumoAiProxyClient {
  final entered = Completer<void>();
  final reply = Completer<LumoAiProxyResponse>();

  @override
  Future<LumoAiProxyResponse> ask({
    required AppSettings settings,
    required LumoSessionState state,
    required String message,
    List<LumoAiChatTurn> history = const [],
    LumoAiContext context = LumoAiContext.companion,
    Map<String, Object?>? extras,
    LumoSpeechCancellation? cancellation,
  }) {
    if (!entered.isCompleted) entered.complete();
    return reply.future;
  }
}

Future<void> _frames(WidgetTester tester, [int count = 20]) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

Future<void> _flush(WidgetTester tester, LumoAppState app) async {
  var saved = false;
  app.flushLearningProgress().then((_) => saved = true);
  for (var frame = 0; frame < 100 && !saved; frame++) {
    await _frames(tester, 1);
  }
  expect(saved, isTrue, reason: 'Actual tapped attempts finish storage.');
}

TaskInstance _task(WidgetTester tester) =>
    tester.widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer)).task;

Future<void> _tapWrong(WidgetTester tester, TaskInstance task) async {
  final wrong = task.options.firstWhere((option) {
    final answer = '${option.payload ?? option.label}';
    return answer != '${task.correctAnswer}' &&
        const ErrorDetective()
                .analyze(
                    subject: 'Mathematik',
                    prompt: task.prompt,
                    correctAnswer: '${task.correctAnswer}',
                    givenAnswer: answer)
                .confidence >=
            0.65;
  });
  final action = find
      .descendant(
          of: find.byType(AdaptiveTaskRenderer),
          matching: find.text(wrong.label))
      .last;
  await tester.ensureVisible(action);
  await tester.tap(action);
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.taskContext.value = null;
  });

  testWidgets(
      'same-name classmates keep error owners and reject a late previous-child help reply',
      (tester) async {
    _DelayedIdentityState? app;
    final proxy = _DelayedHelp();
    const errors = ErrorBreakdownRepository();
    const firstId = 'learning-profile-first';
    const secondId = 'learning-profile-second';
    const legacy = '{"unassigned historical observation":7}';
    const lateReply = 'Diese alte Hilfe gehört ausschließlich zum ersten Kind.';
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1000));
      await tester.runAsync(() async {
        app = _DelayedIdentityState();
        app!.update(app!.state.copyWith(
            childName: 'Gleiches Testkind',
            grade: 1,
            subject: 'Mathematik',
            unit: 'Plus bis 10',
            section: LumoSection.learn,
            sessionKind: LumoSessionKind.quickPractice));
        await app!.school.setActiveStudent(firstId);
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            soundEnabled: false,
            reduceAnimations: true,
            aiProxyEnabled: true,
            aiProxyUrl: '',
            aiLearningMode: AiLearningMode.learningHelp));
      });
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: AnimatedBuilder(
                  animation: app!,
                  builder: (_, __) =>
                      LearningContent(appState: app!, aiProxy: proxy)))));
      await _frames(tester, 40);
      final firstTask = _task(tester);
      final oldGeneration = app!.profileGeneration;
      final legacyKey = 'lumo.error_breakdown.${firstTask.childId}';
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(legacyKey, legacy);
      });

      // The real wrong-answer tap initiates the delayed diagnostic lease.
      app!.holdNextIdentity = true;
      await _tapWrong(tester, firstTask);
      expect(app!.heldIdentity, isNotNull);
      expect(app!.heldIdentity!.studentId, firstId);
      expect(app!.state.practiceErrors, 1);
      expect(app!.state.weakSkills['Plus bis 10'], 1);
      final help = find.byKey(const ValueKey('lumo-help-hologlass-button'));
      await tester.ensureVisible(help);
      await tester.tap(help);
      await _frames(tester);
      expect(proxy.entered.isCompleted, isTrue);
      expect(LumoCompanionRequests.instance.taskContext.value!.helpLevel, 1);
      expect(LumoCompanionRequests.instance.taskContext.value!.attempts, 1);

      // Return the old network answer after the identity changed but before
      // the widget can rebuild and replace its still-identical old task ID.
      await tester.runAsync(() async {
        await app!.school.setActiveStudent(secondId);
        expect(app!.profileGeneration, greaterThan(oldGeneration));
        proxy.reply.complete(const LumoAiProxyResponse(
            reply: lateReply, blocked: false, source: 'openai_proxy'));
        await Future<void>.delayed(Duration.zero);
        await app!.loadLearningProfile();
      });
      await _frames(tester, 40);
      final secondTask = _task(tester);
      expect(secondTask.childId, firstTask.childId,
          reason: 'Display name and grade deliberately remain identical.');
      expect(secondTask.taskInstanceId, isNot(firstTask.taskInstanceId));
      expect(find.text(lateReply), findsNothing);
      expect(app!.state.practiceErrors, 0);
      expect(app!.state.weakSkills, isEmpty);
      final fresh = LumoCompanionRequests.instance.taskContext.value!;
      expect(fresh.profileGeneration, app!.profileGeneration);
      expect(fresh.attempts, 0);
      expect(fresh.helpLevel, 0);
      expect(fresh.previousHelp, isNull);
      await tester.runAsync(() async {
        expect(await errors.loadForProfile(secondId), isEmpty);
      });

      await _tapWrong(tester, secondTask);
      expect(app!.state.practiceErrors, 1);
      expect(app!.state.weakSkills['Plus bis 10'], 1);
      app!.releaseIdentity.complete();
      await _flush(tester, app!);
      await tester.runAsync(() async {
        final first = await errors.loadForProfile(firstId);
        final second = await errors.loadForProfile(secondId);
        expect(first.values.fold<int>(0, (sum, value) => sum + value), 1);
        expect(second.values.fold<int>(0, (sum, value) => sum + value), 1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(legacyKey), legacy,
            reason: 'No inferred ownership or migration of old bytes.');
        final storedKeys = prefs
            .getKeys()
            .where((key) => key.startsWith('lumo.error_breakdown.profile_v1_'))
            .toSet();
        expect(storedKeys, {
          'lumo.error_breakdown.profile_v1_${sha256.convert(utf8.encode(firstId))}',
          'lumo.error_breakdown.profile_v1_${sha256.convert(utf8.encode(secondId))}',
        });
        for (final id in [firstId, secondId]) {
          final attempts = await app!.attemptLog.load(studentId: id);
          expect(attempts, hasLength(1));
          expect(attempts.single.correct, isFalse);
          expect(attempts.single.hintUsed, isFalse);
        }
      });
      expect(find.text(lateReply), findsNothing);
      expect(tester.takeException(), isNull);

      // A real parent profile reset clears only the selected child's new
      // diagnostic namespace, after draining and invalidating prior leases.
      var reset = false;
      app!.resetLearningProfile().then((_) => reset = true);
      for (var frame = 0; frame < 100 && !reset; frame++) {
        await _frames(tester, 1);
      }
      expect(reset, isTrue);
      await _frames(tester);
      await tester.runAsync(() async {
        expect(await errors.loadForProfile(secondId), isEmpty);
        final first = await errors.loadForProfile(firstId);
        expect(first.values.fold<int>(0, (sum, value) => sum + value), 1);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(legacyKey), legacy);
      });
      await _tapWrong(tester, _task(tester));
      await _flush(tester, app!);
      await tester.runAsync(() async {
        final second = await errors.loadForProfile(secondId);
        expect(second.values.fold<int>(0, (sum, value) => sum + value), 1,
            reason: 'Reset diagnostics never resurrect previous counts.');
      });
    } finally {
      if (app != null && !app!.releaseIdentity.isCompleted) {
        app!.releaseIdentity.complete();
      }
      if (!proxy.reply.isCompleted) {
        proxy.reply.complete(const LumoAiProxyResponse(
            reply: '', blocked: false, source: 'cancelled'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester, 5);
      app?.dispose();
      LumoCompanionRequests.instance.taskContext.value = null;
      await tester.binding.setSurfaceSize(null);
    }
  });

  test('unknown diagnostic fields retain their exact bytes', () async {
    const errors = ErrorBreakdownRepository();
    const id = 'future-schema-profile';
    final key =
        'lumo.error_breakdown.profile_v1_${sha256.convert(utf8.encode(id))}';
    const raw = '{"known":7,"future":{"n":3}}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, raw);
    await expectLater(
        errors.incrementForProfile(id, 'new', mayWrite: () => true),
        throwsFormatException);
    expect(prefs.getString(key), raw);
  });

  testWidgets(
      'revoking parent AI permission rejects an already requested reply',
      (tester) async {
    LumoAppState? app;
    final proxy = _DelayedHelp();
    const reply =
        'Die Eltern haben diese Online-Hilfe inzwischen ausgeschaltet.';
    try {
      await tester.binding.setSurfaceSize(const Size(690, 1000));
      await tester.runAsync(() async {
        app = LumoAppState();
        app!.update(app!.state.copyWith(
            grade: 1,
            subject: 'Mathematik',
            unit: 'Plus bis 10',
            sessionKind: LumoSessionKind.quickPractice));
        await app!.school.setActiveStudent('consent-profile');
        await app!.loadLearningProfile();
        app!.updateSettings(const AppSettings(
            voiceEnabled: false,
            autoReadEnabled: false,
            soundEnabled: false,
            reduceAnimations: true,
            aiProxyEnabled: true,
            aiProxyUrl: '',
            aiLearningMode: AiLearningMode.learningHelp));
      });
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: AnimatedBuilder(
                  animation: app!,
                  builder: (_, __) =>
                      LearningContent(appState: app!, aiProxy: proxy)))));
      await _frames(tester, 40);
      final originalTask = _task(tester);
      final originalGeneration = app!.profileGeneration;
      final help = find.byKey(const ValueKey('lumo-help-hologlass-button'));
      await tester.ensureVisible(help);
      await tester.tap(help);
      await _frames(tester);
      expect(proxy.entered.isCompleted, isTrue);
      final localHelp =
          LumoCompanionRequests.instance.taskContext.value!.previousHelp;
      expect(localHelp, isNotNull);
      app!.updateSettings(app!.state.settings.copyWith(aiProxyEnabled: false));
      proxy.reply.complete(const LumoAiProxyResponse(
          reply: reply, blocked: false, source: 'openai_proxy'));
      await _frames(tester);
      expect(app!.profileGeneration, originalGeneration);
      expect(_task(tester).taskInstanceId, originalTask.taskInstanceId);
      expect(find.text(reply), findsNothing);
      expect(LumoCompanionRequests.instance.taskContext.value!.previousHelp,
          localHelp,
          reason: 'The actual local hint remains available.');
      expect(app!.state.practiceErrors, 0);
      expect(tester.takeException(), isNull);
    } finally {
      if (!proxy.reply.isCompleted) {
        proxy.reply.complete(const LumoAiProxyResponse(
            reply: '', blocked: false, source: 'cancelled'));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await _frames(tester, 5);
      app?.dispose();
      await tester.binding.setSurfaceSize(null);
    }
  });

  for (final kind in ['typed', 'skipped', 'practice', 'shape']) {
    testWidgets('late $kind callbacks never act on the next child',
        (tester) async {
      LumoAppState? app;
      try {
        await tester.binding.setSurfaceSize(const Size(690, 1000));
        await tester.runAsync(() async {
          app = LumoAppState();
          app!.update(app!.state.copyWith(
              childName: 'Gleiches Testkind',
              grade: 1,
              subject: kind == 'shape' ? 'Mathematik' : 'Schreiben',
              unit: kind == 'shape' ? 'Formen Nachzeichnen' : 'Wort schreiben',
              sessionKind: LumoSessionKind.quickPractice));
          await app!.school.setActiveStudent('callback-first');
          await app!.loadLearningProfile();
          app!.updateSettings(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              soundEnabled: false,
              reduceAnimations: true));
        });
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: AnimatedBuilder(
                    animation: app!,
                    builder: (_, __) => LearningContent(appState: app!)))));
        await _frames(tester, 40);
        final renderer = tester
            .widget<AdaptiveTaskRenderer>(find.byType(AdaptiveTaskRenderer));
        expect(renderer.task.taskType,
            kind == 'shape' ? TaskType.shapeTrace : TaskType.writingCanvas);
        void deliverOldCallback() {
          if (kind == 'shape') {
            renderer.onShapeTraced!(ShapeTraceTaskResult(
                task: renderer.task,
                correct: false,
                shape: 'Quadrat',
                feedback: 'Nochmal probieren.'));
          } else {
            renderer.onWritingSubmitted!(WritingTaskResult(
                task: renderer.task,
                evaluation: const WritingEvaluation(
                    overallScore: 0,
                    startPointScore: 0,
                    directionScore: 0,
                    coverageScore: 0,
                    pathDistanceScore: 0,
                    strokeOrderScore: 0,
                    mirrored: false,
                    incomplete: false,
                    hints: []),
                strokes: const [],
                skipped: kind == 'skipped',
                typedAnswer: kind == 'typed' ? 'falsches Wort' : null));
          }
        }

        // A modal completion can race the first frame of the selected child.
        await tester.runAsync(() async {
          await app!.school.setActiveStudent('callback-second');
          deliverOldCallback();
          expect(app!.state.practiceErrors, 0);
          expect(app!.state.weakSkills, isEmpty);
          expect(LumoCompanionRequests.instance.taskContext.value, isNull);
          await app!.loadLearningProfile();
        });
        await _frames(tester, 40);
        final freshTask = _task(tester);
        expect(freshTask.taskInstanceId, isNot(renderer.task.taskInstanceId));
        // It also remains stale after the replacement task is already visible.
        deliverOldCallback();
        await _frames(tester);
        expect(_task(tester).taskInstanceId, freshTask.taskInstanceId);
        expect(LumoCompanionRequests.instance.taskContext.value!.attempts, 0);
        expect(app!.state.practiceErrors, 0);
        expect(app!.state.weakSkills, isEmpty);
        await _flush(tester, app!);
        await tester.runAsync(() async {
          expect(await app!.attemptLog.load(), isEmpty);
        });
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await _frames(tester, 5);
        app?.dispose();
        await tester.binding.setSurfaceSize(null);
      }
    });
  }
}
