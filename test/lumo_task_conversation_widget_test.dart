import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_task_dialogue.dart';
import 'package:lumo_lernen/core/lumo_task_dialogue_adapter.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/school_exercise_generator.dart';
import 'package:lumo_lernen/core/settings_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/domain/tutoring/tutoring_session_planner.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import 'helpers/native_storage_fixture.dart';

/// The widget, dialogue engine, context and task adapters are real. Recognition
/// is an injected boundary fake and voice output is disabled. These tests are
/// neither microphone recordings nor audible Android playback evidence.
class _SpeechBoundary extends LumoSpeechListener {
  _SpeechBoundary({this.ready = true}) : super(isAndroid: false);
  final bool ready;
  bool _running = false;
  int initializes = 0, starts = 0, cancellations = 0;
  Future<void>? cancelBarrier;
  ValueChanged<String>? partial;
  ValueChanged<String>? finalResult;
  VoidCallback? noMatch;
  LumoSpeechRecognition? recognition;

  @override
  bool get listening => _running;
  @override
  bool get awaitingFinalResult => false;
  @override
  String? get error =>
      ready ? null : 'Die Mikrofonfreigabe wurde abgelehnt. Du kannst tippen.';
  @override
  LumoSpeechRecognition? get lastRecognition => recognition;

  @override
  Future<bool> initialize() async {
    initializes++;
    return ready;
  }

  @override
  Future<void> startListening({
    ValueChanged<String>? onResult,
    ValueChanged<String>? onFinalResult,
    VoidCallback? onNoMatch,
  }) async {
    partial = onResult;
    finalResult = onFinalResult;
    noMatch = onNoMatch;
    starts++;
    _running = true;
    notifyListeners();
  }

  void finish(String text, {double confidence = .95}) {
    recognition = LumoSpeechRecognition(
        captureId: starts, text: text, isFinal: true, confidence: confidence);
    partial?.call(text);
    _running = false;
    finalResult?.call(text);
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    cancellations++;
    _running = false;
    partial = null;
    finalResult = null;
    noMatch = null;
    notifyListeners();
    final barrier = cancelBarrier;
    if (barrier != null) await barrier;
  }
}

Future<void> _frames(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void _publish(LumoAppState app,
    {bool answerTask = false, String id = 'task-a', int revision = 1}) {
  final snapshot = answerTask
      ? LumoTaskDialogueAdapter.fromSchoolExercise(
          task: const LumoTask(
              id: 'eight-plus-five',
              grade: 1,
              subject: 'Mathematik',
              unit: 'Plus bis 20',
              prompt: '8 + 5 = ?',
              choices: ['12', '13', '14'],
              answer: '13',
              explanation: '8 + 2 = 10; 10 + 3 = 13.'),
          sessionId: '${app.profileGeneration}/learn/session-1',
          taskId: id,
          stepId: 'answer',
          revision: revision)
      : LumoTaskDialogueAdapter.fromGuidedLesson(
          lesson: GuidedLessonCatalog.bridgeTen,
          step: GuidedLessonCatalog.bridgeTen.steps
              .firstWhere((step) => step.type == TutoringStepType.showExample),
          sessionId: '${app.profileGeneration}/learn/session-1',
          taskId: id,
          stepId: 'demonstration',
          revision: revision,
          acceptingAnswer: false);
  LumoCompanionRequests.instance.publishTask(LumoCompanionTaskContext(
    subject: 'Mathematik',
    unit: 'Plus bis 20',
    prompt: snapshot.prompt,
    taskId: id,
    activity: 'guided_lesson',
    ownerSection: 'learn',
    profileGeneration: app.profileGeneration,
    answering: answerTask,
    dialogue: snapshot,
  ));
}

Future<LumoAppState> _mount(
  WidgetTester tester,
  _SpeechBoundary speech, {
  bool microphoneEnabled = false,
  bool answerTask = false,
  LumoConfirmedTaskAnswer? onConfirmed,
  ValueChanged<LumoTaskDialogueReply>? onReviewedHelp,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1100));
  final app = await nativeStorageFixture(
      tester, () => LumoAppState(walletRepository: RewardWalletRepository()));
  await tester.runAsync(() async {
    await SettingsRepository.save(AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: microphoneEnabled,
        reduceAnimations: true));
    await app.ensureSettingsLoaded();
  });
  app.setSection(LumoSection.learn);
  _publish(app, answerTask: answerTask);
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
    body: SingleChildScrollView(
        child: LumoAgentContent(
      key: const ValueKey('tested-inline-conversation'),
      appState: app,
      onSection: (_) {},
      compact: true,
      onConfirmedAnswer: onConfirmed,
      onReviewedHelp: onReviewedHelp,
      speechForTesting: speech,
    )),
  )));
  await _frames(tester);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    app.dispose();
    LumoCompanionRequests.instance.clearLearningScope();
    await tester.binding.setSurfaceSize(null);
  });
  return app;
}

Future<void> _ask(WidgetTester tester, String question) async {
  final input = find.byKey(const ValueKey('lumo-agent-question-field'));
  await tester.ensureVisible(input);
  await tester.enterText(input, question);
  final send = find.byKey(const ValueKey('lumo-agent-send'));
  await tester.ensureVisible(send);
  await tester.tap(send);
  await _frames(tester);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _frames(tester);
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    await LumoVoice.instance.stop();
    LumoVoice.instance.lastError.value = null;
    LumoCompanionRequests.instance.clearLearningScope();
    LumoCompanionRequests.instance.tutor.activateProfile(0);
  });

  testWidgets('inline why-two uses the current guided example without scoring',
      (tester) async {
    final speech = _SpeechBoundary();
    final app = await _mount(tester, speech);
    final stars = app.state.stars, xp = app.state.xp;
    await _ask(tester, 'Warum zuerst zwei?');
    expect(_text(tester, 'lumo-conversation-subtitle'), contains('2 Plätze'));
    expect(_text(tester, 'lumo-dialogue-object-focus'),
        contains('Platz 9 im Zehnerfeld'));
    expect(_text(tester, 'lumo-dialogue-object-focus'),
        contains('Platz 10 im Zehnerfeld'));
    expect(app.state.stars, stars);
    expect(app.state.xp, xp);
    expect(app.state.solved, isEmpty);
    expect(speech.initializes, 0);
    for (final key in ['lumo-conversation-start', 'lumo-conversation-stop']) {
      expect(tester.getSize(find.byKey(ValueKey(key))).height,
          greaterThanOrEqualTo(48));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'correction replaces a draft; a double confirmation dispatches once',
      (tester) async {
    final speech = _SpeechBoundary();
    final submitted = <String>[];
    final accepted = Completer<bool>();
    final cancelling = Completer<void>();
    addTearDown(() {
      if (!cancelling.isCompleted) cancelling.complete();
      if (!accepted.isCompleted) accepted.complete(false);
    });
    final app =
        await _mount(tester, speech, answerTask: true, onConfirmed: (reply) {
      submitted.add(reply.draftAnswer!);
      return accepted.future;
    });
    await _ask(tester, 'zwölf');
    expect(_text(tester, 'lumo-answer-draft'), contains('12'));
    expect(submitted, isEmpty);
    await _ask(tester, 'Nein, ich meinte dreizehn');
    expect(_text(tester, 'lumo-answer-draft'), contains('13'));
    expect(submitted, isEmpty);
    expect(app.state.solved, isEmpty);
    speech.cancelBarrier = cancelling.future;
    // Two events can reach the same enabled widget before the next frame.
    final confirm = tester
        .widget<OutlinedButton>(
            find.byKey(const ValueKey('lumo-answer-confirm')))
        .onPressed!;
    confirm();
    confirm();
    await tester.pump();
    expect(submitted, isEmpty);
    speech.cancelBarrier = null;
    cancelling.complete();
    await _frames(tester);
    expect(submitted, ['13']);
    accepted.complete(true);
    await _frames(tester);
    expect(find.byKey(const ValueKey('lumo-answer-draft')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'disabled microphone retains typed help and cannot initialize capture',
      (tester) async {
    final speech = _SpeechBoundary();
    await _mount(tester, speech);
    final start = tester.widget<OutlinedButton>(
        find.byKey(const ValueKey('lumo-conversation-start')));
    expect(start.onPressed, isNull);
    await _tap(tester, 'lumo-conversation-interrupt');
    expect(speech.initializes, 0);
    expect(speech.starts, 0);
    expect(find.textContaining('Elternbereich ausgeschaltet'), findsOneWidget);
    await _ask(tester, 'Warum zuerst zwei?');
    expect(_text(tester, 'lumo-conversation-subtitle'), contains('2 Plätze'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'one start permits several real dialogue turns through a fake recognition boundary',
      (tester) async {
    final speech = _SpeechBoundary();
    await _mount(tester, speech, microphoneEnabled: true);
    await _tap(tester, 'lumo-conversation-start');
    expect(speech.starts, 1);
    expect(_text(tester, 'lumo-conversation-state'), contains('Mikrofon an'));
    speech.finish('Warum zuerst zwei?');
    await _frames(tester);
    expect(_text(tester, 'lumo-conversation-subtitle'), contains('2 Plätze'));
    expect(speech.starts, 2);
    speech.finish('Den zweiten Schritt verstehe ich nicht');
    await _frames(tester);
    expect(_text(tester, 'lumo-conversation-subtitle'),
        contains('bleiben 3 daneben'));
    expect(speech.starts, 3);
    await _tap(tester, 'lumo-conversation-stop');
    expect(speech.listening, isFalse);
    expect(_text(tester, 'lumo-conversation-state'), contains('Mikrofon aus'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an old capture cannot answer or reopen after task change',
      (tester) async {
    final speech = _SpeechBoundary();
    final app = await _mount(tester, speech, microphoneEnabled: true);
    await _tap(tester, 'lumo-conversation-start');
    final oldFinal = speech.finalResult!;
    _publish(app, id: 'task-b', revision: 2);
    await _frames(tester);
    oldFinal('Warum zuerst zwei?');
    await _frames(tester);
    expect(_text(tester, 'lumo-conversation-subtitle'),
        isNot(contains('2 Plätze')));
    expect(speech.starts, 1);
    expect(speech.listening, isFalse);
    expect(app.state.solved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile switch discards the previous child draft and history',
      (tester) async {
    final speech = _SpeechBoundary();
    var confirmed = 0;
    final app =
        await _mount(tester, speech, answerTask: true, onConfirmed: (_) async {
      confirmed++;
      return true;
    });
    await _ask(tester, 'dreizehn');
    expect(find.byKey(const ValueKey('lumo-answer-draft')), findsOneWidget);
    final oldGeneration = app.profileGeneration;
    await tester.runAsync(() async {
      await app.school.setActiveStudent('dialogue-other-child');
      await app.loadLearningProfile();
    });
    await _frames(tester);
    expect(app.profileGeneration, greaterThan(oldGeneration));
    expect(find.byKey(const ValueKey('lumo-answer-draft')), findsNothing);
    expect(confirmed, 0);
    expect(app.state.solved, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'resize preserves an ungraded draft and lifecycle resume keeps microphone off',
      (tester) async {
    final speech = _SpeechBoundary();
    var confirmed = 0;
    final app = await _mount(tester, speech,
        microphoneEnabled: true, answerTask: true, onConfirmed: (_) async {
      confirmed++;
      return true;
    });
    await _ask(tester, 'dreizehn');
    await tester.binding.setSurfaceSize(const Size(760, 1000));
    await _frames(tester);
    expect(_text(tester, 'lumo-answer-draft'), contains('13'));
    expect(confirmed, 0);
    await _tap(tester, 'lumo-conversation-start');
    expect(speech.starts, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await _frames(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(speech.starts, 1);
    expect(speech.listening, isFalse);
    expect(confirmed, 0);
    expect(app.state.solved, isEmpty);
    expect(find.textContaining('Gespräch ist pausiert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('denied recognition remains understandable and typed input works',
      (tester) async {
    final speech = _SpeechBoundary(ready: false);
    await _mount(tester, speech, microphoneEnabled: true);
    await _tap(tester, 'lumo-conversation-start');
    expect(speech.initializes, 1);
    expect(speech.starts, 0);
    expect(find.textContaining('Mikrofonfreigabe wurde abgelehnt'),
        findsOneWidget);
    await _ask(tester, 'Warum zuerst zwei?');
    expect(_text(tester, 'lumo-conversation-subtitle'), contains('2 Plätze'));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'interrupt awaiting native cancellation cannot open the next task microphone',
      (tester) async {
    final speech = _SpeechBoundary();
    final app = await _mount(tester, speech, microphoneEnabled: true);
    final cancelling = Completer<void>();
    addTearDown(() {
      if (!cancelling.isCompleted) cancelling.complete();
    });
    speech.cancelBarrier = cancelling.future;
    final interrupt = tester
        .widget<OutlinedButton>(
            find.byKey(const ValueKey('lumo-conversation-interrupt')))
        .onPressed!;
    interrupt();
    await tester.pump();
    _publish(app, id: 'next-task', revision: 2);
    speech.cancelBarrier = null;
    cancelling.complete();
    await _frames(tester);
    expect(speech.starts, 0);
    expect(speech.listening, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stop wins over a final transcript awaiting native cancellation',
      (tester) async {
    final speech = _SpeechBoundary();
    await _mount(tester, speech, microphoneEnabled: true);
    await _tap(tester, 'lumo-conversation-start');
    final cancelling = Completer<void>();
    addTearDown(() {
      if (!cancelling.isCompleted) cancelling.complete();
    });
    speech.cancelBarrier = cancelling.future;
    speech.finish('Warum zuerst zwei?');
    await tester.pump();
    final stop = tester
        .widget<OutlinedButton>(
            find.byKey(const ValueKey('lumo-conversation-stop')))
        .onPressed!;
    stop();
    speech.cancelBarrier = null;
    cancelling.complete();
    await _frames(tester);
    expect(_text(tester, 'lumo-conversation-subtitle'),
        isNot(contains('2 Plätze')));
    expect(speech.starts, 1);
    expect(speech.listening, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a failing task callback releases confirmation for a fresh attempt',
      (tester) async {
    final speech = _SpeechBoundary();
    var submissions = 0;
    await _mount(tester, speech, answerTask: true, onConfirmed: (_) async {
      submissions++;
      if (submissions == 1) throw StateError('controlled storage failure');
      return true;
    });
    await _ask(tester, 'dreizehn');
    await _tap(tester, 'lumo-answer-confirm');
    expect(tester.takeException(), isNull);
    await _ask(tester, 'dreizehn');
    await _tap(tester, 'lumo-answer-confirm');
    expect(submissions, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'task changed by the lesson help callback cannot receive the old subtitle',
      (tester) async {
    final speech = _SpeechBoundary();
    late LumoAppState app;
    app = await _mount(tester, speech, onReviewedHelp: (_) {
      _publish(app, id: 'task-opened-by-lesson', revision: 2);
    });
    await _ask(tester, 'Warum zuerst zwei?');
    expect(_text(tester, 'lumo-conversation-subtitle'),
        isNot(contains('2 Plätze')));
    expect(
        find.byKey(const ValueKey('lumo-dialogue-object-focus')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
