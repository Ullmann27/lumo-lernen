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

  test('task change cancels a pending answer and discards its memory',
      () async {
    task();
    app.updateSettings(const AppSettings(
        aiProxyEnabled: true, aiLearningMode: AiLearningMode.learningHelp));
    final proxy = ControlledProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final pending = conversation.ask('Lumo, was muss ich hier machen?');
    await proxy.entered.future;
    expect(proxy.extras?['taskPrompt'], 'Rechne 4 + 3.');
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
}
