import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';
import 'package:lumo_lernen/core/lumo_context_engine.dart';
import 'package:lumo_lernen/core/lumo_conversation_controller.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class ControlledProxy extends LumoAiProxyClient {
  final entered = Completer<void>();
  final reply = Completer<LumoAiProxyResponse>();
  LumoSpeechCancellation? request;
  Map<String, Object?>? extras;
  @override
  Future<LumoAiProxyResponse> ask({
    required AppSettings settings,
    required LumoSessionState state,
    required String message,
    List<LumoAiChatTurn> history = const [],
    LumoAiContext context = LumoAiContext.companion,
    Map<String, Object?>? extras,
    LumoSpeechCancellation? cancellation,
  }) async {
    request = cancellation;
    this.extras = extras;
    entered.complete();
    return reply.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LumoAppState app;
  late LumoContextEngine context;
  late LumoConversationController conversation;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    LumoCompanionRequests.instance.taskContext.value = null;
    app = LumoAppState();
    app.update(app.state.copyWith(
        section: LumoSection.exercises,
        subject: 'Mathematik',
        unit: 'Plus bis 10'));
    context = LumoContextEngine(app);
    conversation = LumoConversationController(context);
  });
  tearDown(() {
    conversation.dispose();
    context.dispose();
    app.dispose();
    LumoCompanionRequests.instance.taskContext.value = null;
  });

  void task({int attempts = 1, bool? correct = false, bool exam = false}) {
    LumoCompanionRequests.instance.taskContext.value = LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Plus bis 10',
      prompt: 'Rechne 4 + 3.',
      taskId: 'local-task-only',
      attempts: attempts,
      helpLevel: 1,
      lastAnswer: '6',
      lastCorrect: correct,
      isExam: exam,
      previousHelp: 'Schau auf die beiden Mengen.',
      localHelp: attempts >= 2
          ? 'Zähle von vier aus drei Schritte weiter.'
          : 'Lege vier Punkte und dann drei Punkte dazu.',
    );
  }

  test('local question uses the real task and never mutates progress',
      () async {
    task();
    final stars = app.state.stars, xp = app.state.xp;
    final reply = await conversation.ask('Warum ist das falsch?');
    expect(reply.reply, contains('vier Punkte'));
    expect(reply.reply, isNot(contains('4 + 3 = 7')));
    expect(app.state.stars, stars);
    expect(app.state.xp, xp);
    expect(app.state.solved, isEmpty);
    task(attempts: 3);
    final retry = await conversation.ask('Kannst du es noch einmal erklären?');
    expect(retry.reply, contains('drei Schritte'));
    expect(retry.reply, isNot(reply.reply));
  });

  test('parent chat-only consent never releases task details or answers', () {
    task();
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.chatOnly));
    expect(context.remoteContext, {'section': 'exercises'});
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.learningHelp));
    final remote = context.remoteContext;
    expect(remote['taskPrompt'], 'Rechne 4 + 3.');
    expect(remote['lastAnswer'], '6');
    expect(remote['lastCorrect'], false);
    expect(remote.keys, isNot(contains('taskId')));
    expect(remote.keys, isNot(contains('correctAnswer')));
    expect(remote.keys, isNot(contains('childName')));
    expect(remote.keys, isNot(contains('touchCoordinates')));
  });

  test('assessment forbids cloud help even through a direct controller call',
      () async {
    task(exam: true);
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.fullCoach));
    final proxy = ControlledProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final response = await conversation.ask('Was muss ich machen?');
    expect(response.reply, contains('Im Test'));
    expect(proxy.entered.isCompleted, false);
  });

  test('task opening cancels an in-flight general chat and its memory',
      () async {
    // Active tasks never go to a general model. The asynchronous stale
    // response case therefore starts before an active lesson is published.
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.learningHelp));
    final proxy = ControlledProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final pending = conversation.ask('Lumo, was ist eine Biene?');
    await proxy.entered.future;
    expect(proxy.extras?['taskPrompt'], isNull);
    task(attempts: 2);
    expect(proxy.request?.cancelled, true);
    proxy.reply.complete(const LumoAiProxyResponse(
        reply: 'Eine verspätete Antwort.',
        blocked: false,
        source: 'openai_proxy'));
    expect((await pending).source, 'cancelled');
    expect(conversation.history, isEmpty);
  });

  test('pause cancels a pending answer; resume never activates microphone',
      () async {
    app.updateSettings(const AppSettings(aiProxyEnabled: true));
    final proxy = ControlledProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final pending = conversation.ask('Was ist eine Biene?');
    await proxy.entered.future;
    conversation.pause();
    expect(proxy.request?.cancelled, true);
    proxy.reply.complete(const LumoAiProxyResponse(
        reply: 'Eine Biene.', blocked: false, source: 'openai_proxy'));
    expect((await pending).source, 'cancelled');
    conversation.resume();
    expect(conversation.phase, LumoConversationPhase.idle);
    expect(app.state.settings.microphoneEnabled, false);
  });

  test('memory is at most four exchanges and clears on real navigation',
      () async {
    for (var i = 0; i < 6; i++) {
      await conversation.ask('Was ist eine Biene?');
    }
    expect(conversation.history.length, 8);
    app.update(app.state.copyWith(section: LumoSection.games));
    expect(conversation.history, isEmpty);
    expect(context.task, isNull);
  });

  test('private or oversized questions never enter conversation memory',
      () async {
    final private =
        await conversation.ask('Meine Telefonnummer ist 0664 1234567');
    expect(private.blocked, true);
    expect(conversation.history, isEmpty);
    final large = await conversation.ask('A' * 1201);
    expect(large.source, 'local_input_too_long');
    expect(conversation.history, isEmpty);
  });
  test('Chat4 ties 8+5 to visible ten frame without scoring', () async {
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
      prompt: 'Rechne 8 + 5.',
      taskId: 'ten-frame-8-plus-5',
      localHelp: 'Das Zehnerfeld zeigt acht besetzte Plätze.',
      helpLevel: 1,
    );
    final beforeStars = app.state.stars;
    final beforeXp = app.state.xp;
    final response = await conversation.ask('Warum zuerst zwei?');
    expect(response.source, 'local_task_dialogue');
    expect(response.reply, contains('zwei Plätze frei'));
    expect(response.reply, isNot(contains('dreizehn')));
    expect(conversation.lastTaskAction, isNotNull);
    expect(app.state.stars, beforeStars);
    expect(app.state.xp, beforeXp);
    expect(app.state.solved, isEmpty);
  });

  test('Chat4 ASR correction is not a scored error', () async {
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
      prompt: 'Rechne 8 + 5.',
      taskId: 'asr-correction-fixture',
      attempts: 0,
      helpLevel: 1,
    );
    final response = await conversation.ask('Nein, ich meinte dreizehn');
    expect(response.source, 'local_task_dialogue');
    expect(response.reply, contains('dreizehn'));
    expect(app.state.solved, isEmpty);
    expect(app.state.practiceErrors, 0);
  });

  test('Chat4 explicit stop cancels and stale task cue clears', () async {
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
      prompt: 'Rechne 8 + 5.',
      taskId: 'stop-fixture',
      localHelp: 'Schau auf die freien Felder.',
      helpLevel: 1,
    );
    final first = await conversation.ask('Warum zuerst zwei?');
    expect(first.source, 'local_task_dialogue');
    final interrupted = await conversation.ask('Stopp');
    expect(interrupted.source, 'cancelled');
    expect(conversation.phase, LumoConversationPhase.interrupted);
    expect(conversation.activeCue.value, isNull);
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Deutsch',
      unit: 'Silben',
      prompt: 'Wie viele Silben hat Banane?',
      taskId: 'other-task',
    );
    expect(conversation.history, isEmpty);
    expect(conversation.activeCue.value, isNull);
  });

  test('Chat4 unverified proxy cannot override an active task', () async {
    LumoCompanionRequests.instance.taskContext.value =
        const LumoCompanionTaskContext(
      subject: 'Mathematik',
      unit: 'Zehnerübergang',
      prompt: 'Rechne 8 + 5.',
      taskId: 'no-cloud-answer',
      localHelp: 'Lege acht Punkte.',
    );
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.learningHelp));
    final proxy = ControlledProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final answer = await conversation.ask('Sag mir die Lösung');
    expect(answer.isCloudAnswer, isFalse);
    expect(proxy.entered.isCompleted, false);
  });

}
