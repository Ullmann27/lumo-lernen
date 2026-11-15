import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';
import 'package:lumo_lernen/core/lumo_context_engine.dart';
import 'package:lumo_lernen/core/lumo_conversation_controller.dart';
import 'package:lumo_lernen/core/lumo_learning_dialogue_intent.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class DeferredLessonProxy extends LumoAiProxyClient {
  final replies = <Completer<LumoAiProxyResponse>>[];
  final requests = <LumoSpeechCancellation?>[];
  @override
  void warmup(AppSettings settings) {}
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
    final result = Completer<LumoAiProxyResponse>();
    replies.add(result);
    requests.add(cancellation);
    return result.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  late LumoAppState app;
  late LumoContextEngine context;
  late LumoConversationController conversation;

  LumoCompanionTaskContext task({
    String id = 'eight-plus-five',
    String step = 'bridge',
    int attempts = 0,
    bool? correct,
    bool explaining = false,
    bool exam = false,
    String prompt = '8 + 5',
    String explanation = '8 + 5: Acht liegen im Zehnerfeld. Zwei ergänzen '
        'zur Zehn, drei bleiben daneben.',
    List<String> objects = const [
      'ten_frame',
      'addend',
      'bridge_two',
      'remainder_three'
    ],
    List<String> choices = const ['12', '13', '14'],
    Set<LumoLearningAction> actions = const {
      ...lumoDefaultLearningActions,
      LumoLearningAction.proposeAnswer,
      LumoLearningAction.look,
      LumoLearningAction.point,
      LumoLearningAction.highlight,
    },
  }) =>
      LumoCompanionTaskContext(
          taskId: id,
          subject: 'Mathematik',
          unit: 'Plus bis 20',
          prompt: prompt,
          stepId: step,
          explanation: explanation,
          objectIds: objects,
          answerChoices: choices,
          allowedActions: actions,
          profileGeneration: app.profileGeneration,
          attempts: attempts,
          lastCorrect: correct,
          localHelp: 'Ergänze zuerst zur Zehn.',
          isExplanation: explaining,
          answering: !explaining,
          isExam: exam);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoVoice.instance.isEnabled = false;
    bus.clearLearningScope();
    app = LumoAppState();
    app.update(app.state.copyWith(
        section: LumoSection.exercises,
        subject: 'Mathematik',
        unit: 'Plus bis 20'));
    app.updateSettings(const AppSettings(voiceEnabled: false));
    bus.tutor.activateProfile(app.profileGeneration);
    context = LumoContextEngine(app);
    conversation = LumoConversationController(context);
  });
  tearDown(() async {
    conversation.dispose();
    context.dispose();
    app.dispose();
    bus.clearLearningScope();
    await LumoVoice.instance.stop();
  });

  test('why two explains the active example instead of calling it completed',
      () async {
    bus.publishTask(task(explaining: true));
    final reply = await conversation.ask('Warum zuerst zwei?');
    expect(reply.reply, contains('10 minus 8 ist 2'));
    expect(reply.reply, contains('3 übrig'));
    expect(reply.reply, isNot(contains('abgeschlossen')));
    expect(bus.learningPresentation.value?.pointObjectId, 'bridge_two');
    expect(app.state.solved, isEmpty);
    expect(app.state.stars, 0);
  });

  test('wrong answer, misrecognition and correction only propose editable text',
      () async {
    bus.publishTask(task(attempts: 1, correct: false));
    final actions = <LumoLearningActionRequest>[];
    void received() {
      final request = bus.learningAction.value;
      if (request?.action == LumoLearningAction.proposeAnswer)
        actions.add(request!);
    }

    bus.learningAction.addListener(received);
    addTearDown(() => bus.learningAction.removeListener(received));
    final first = await conversation.ask('vierzehn');
    expect(first.source, 'local_answer_proposal');
    expect(actions.last.candidate, '14');
    final corrected =
        await conversation.ask('Nein, nicht vierzehn, sondern dreizehn.');
    expect(corrected.reply, contains('bestätigst'));
    expect(actions.last.candidate, '13');
    expect(bus.taskContext.value?.lastCorrect, false);
    expect(bus.taskContext.value?.attempts, 1);
    expect(bus.tutor.mistakes, 0);
    expect(app.state.solved, isEmpty);
    expect(app.state.stars, 0);
    expect(app.state.xp, 0);
  });

  test(
      'same task retains conversation while changed snapshot invalidates old lease',
      () async {
    bus.publishTask(task());
    await conversation.ask('Warum zuerst zwei?');
    final prior = conversation.history;
    final lease = bus.learningIdentity.value!;
    final revision = context.revision;
    bus.publishTask(task());
    expect(context.revision, revision);
    expect(bus.isCurrentLearningIdentity(lease), true);
    bus.publishTask(task(step: 'remainder', attempts: 1, correct: false));
    expect(context.revision, greaterThan(revision));
    expect(bus.isCurrentLearningIdentity(lease), false);
    expect(conversation.history, prior);
    bus.publishTask(task(id: 'different-task'));
    expect(conversation.history, isEmpty);
  });

  test(
      'stop cancels pending inference and its figure lease; late reply stays silent',
      () async {
    bus.publishTask(task());
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.learningHelp));
    final proxy = DeferredLessonProxy();
    conversation.dispose();
    var recognizerStops = 0;
    conversation = LumoConversationController(context,
        proxy: proxy, onInterrupt: () => recognizerStops++);
    final pending = conversation.ask('Was ist eine Biene?');
    await waitForRequests(proxy, 1);
    final lease = bus.learningIdentity.value!;
    bus.publishLearningPresentation(LumoLearningPresentation(
        identity: lease,
        gazeObjectId: 'ten_frame',
        pointObjectId: 'bridge_two',
        animationState: 'explaining'));
    final stopsBefore = recognizerStops;
    final stopped = await conversation.ask('Lumo, bitte Stopp!');
    expect(stopped.source, 'local_stopped');
    expect(proxy.requests.single?.cancelled, true);
    expect(recognizerStops, greaterThan(stopsBefore));
    expect(bus.isCurrentLearningIdentity(lease), false);
    expect(bus.learningPresentation.value, isNull);
    expect(bus.learningAudio.value, isNull);
    expect(conversation.responseMaySpeak, false);
    proxy.replies.single.complete(const LumoAiProxyResponse(
        reply: 'Zu spät.', blocked: false, source: 'openai_proxy'));
    expect((await pending).source, 'cancelled');
    expect(conversation.history, isEmpty);
    expect(LumoVoice.instance.clipMouth.value, isNull);
  });

  test('new question replaces thinking; old reply cannot win the race',
      () async {
    bus.publishTask(task());
    app.updateSettings(const AppSettings(
        voiceEnabled: false,
        aiProxyEnabled: true,
        aiLearningMode: AiLearningMode.learningHelp));
    final proxy = DeferredLessonProxy();
    conversation.dispose();
    conversation = LumoConversationController(context, proxy: proxy);
    final old = conversation.ask('Was ist eine Biene?');
    await waitForRequests(proxy, 1);
    final replacement = conversation.ask('Was ist ein Baum?');
    await waitForRequests(proxy, 2);
    expect(proxy.requests.first?.cancelled, true);
    proxy.replies[1].complete(const LumoAiProxyResponse(
        reply: 'Der Baum hat Wurzeln.',
        blocked: false,
        source: 'openai_proxy'));
    expect((await replacement).reply, 'Der Baum hat Wurzeln.');
    proxy.replies[0].complete(const LumoAiProxyResponse(
        reply: 'Alte Biene.', blocked: false, source: 'openai_proxy'));
    expect((await old).source, 'cancelled');
    expect(conversation.history.map((turn) => turn.content),
        ['Was ist ein Baum?', 'Der Baum hat Wurzeln.']);
  });

  test(
      'owned help can publish its checked next step without losing the local reply',
      () async {
    bus.publishTask(task(explaining: true));
    void advance() {
      if (bus.learningAction.value?.action == LumoLearningAction.explain) {
        bus.publishTask(task(explaining: true, step: 'bridge_two'));
      }
    }

    bus.learningAction.addListener(advance);
    addTearDown(() => bus.learningAction.removeListener(advance));
    final reply = await conversation.ask('Warum zuerst zwei?');
    expect(reply.source, 'local_lesson_explain');
    expect(reply.reply, contains('10 minus 8 ist 2'));
    expect(conversation.responseIdentity?.stepId, 'bridge_two');
    expect(conversation.history.length, 2);
  });

  test('Banane repeat and slower preserve the checked syllables', () async {
    bus.publishTask(task(
        id: 'banana',
        explaining: true,
        prompt: 'Sprich Banane in Silben.',
        explanation: 'Ba – na – ne. Banane hat drei Silben.',
        objects: const ['syllable_0', 'syllable_1', 'syllable_2']));
    final repeated = await conversation.ask('Bitte wiederholen.');
    final slower = await conversation.ask('Bitte langsamer.');
    expect(repeated.reply, contains('Ba – na – ne'));
    expect(slower.reply, repeated.reply);
    expect(bus.learningPresentation.value?.gazeObjectId, 'syllable_0');
    expect(app.state.solved, isEmpty);
  });

  test('pattern hint points to its group and does not submit an answer',
      () async {
    bus.publishTask(task(
        id: 'pattern',
        prompt: 'Rot blau rot blau: Was kommt?',
        explanation:
            'Schau auf die Gruppe rot, blau. Diese Gruppe wiederholt sich.',
        objects: const ['pattern_group', 'pattern_next'],
        choices: const ['rot', 'blau', 'gelb']));
    final reply = await conversation.ask('Gib mir einen Hinweis.');
    expect(reply.reply, contains('Gruppe rot, blau'));
    expect(bus.learningPresentation.value?.pointObjectId, 'pattern_group');
    expect(bus.learningAction.value?.action, LumoLearningAction.hint);
    expect(app.state.solved, isEmpty);
  });

  test('stale, foreign and disallowed commands cannot enter the active scene',
      () {
    bus.publishTask(task(actions: const {LumoLearningAction.look}));
    final lease = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: lease, candidate: '13'),
        false);
    expect(
        bus.requestLearningAction(LumoLearningAction.look,
            identity: lease, objectId: 'foreign-object'),
        false);
    expect(
        bus.requestLearningAction(LumoLearningAction.look,
            identity: lease, objectId: 'ten_frame'),
        true);
    bus.cancelLearningInteraction();
    expect(
        bus.requestLearningAction(LumoLearningAction.look,
            identity: lease, objectId: 'ten_frame'),
        false);
    expect(
        bus.publishLearningPresentation(LumoLearningPresentation(
            identity: lease, pointObjectId: 'ten_frame')),
        false);
    bus.publishTask(task(exam: true));
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        false);
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: bus.learningIdentity.value!),
        true);
  });

  test('pause and resume do not resurrect an utterance or enable microphone',
      () async {
    bus.publishTask(task(explaining: true));
    await conversation.ask('Warum zuerst zwei?');
    final lease = conversation.responseIdentity!;
    conversation.pause();
    expect(conversation.phase, LumoConversationPhase.paused);
    expect(bus.isCurrentLearningIdentity(lease), false);
    expect(conversation.responseMaySpeak, false);
    conversation.resume();
    expect(conversation.phase, LumoConversationPhase.idle);
    expect(app.state.settings.microphoneEnabled, false);
    expect(conversation.history.length, 2);
  });

  test('negation and a question containing a number are not submitted answers',
      () {
    final current = task();
    expect(LumoLearningDialogueIntent.parse('Nicht stoppen', current), isNull);
    expect(LumoLearningDialogueIntent.parse('Bitte nicht wiederholen', current),
        isNull);
    expect(
        LumoLearningDialogueIntent.parse('Warum zuerst zwei?', current)?.action,
        LumoLearningAction.explain);
    expect(
        LumoLearningDialogueIntent.parse('Es ist minus vier', current)
            ?.candidate,
        '-4');
    expect(
        LumoLearningDialogueIntent.parse('Ich meinte -4', current)?.candidate,
        '-4');
  });
}

Future<void> waitForRequests(DeferredLessonProxy proxy, int count) async {
  for (var i = 0; i < 200 && proxy.replies.length < count; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(proxy.replies.length, count);
}
