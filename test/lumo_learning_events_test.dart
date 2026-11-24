import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/lumo_context_engine.dart';
import 'package:lumo_lernen/core/lumo_conversation_controller.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = LumoCompanionRequests.instance;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    requests.clearLearningScope();
    LumoCompanionRequests.instance.tutor.activateProfile(0);
    LumoVoice.instance.isEnabled = false;
  });
  tearDown(requests.clearLearningScope);

  LumoCompanionTaskContext task(
          {String id = 'local-task', int attempt = 0, int generation = 0}) =>
      LumoCompanionTaskContext(
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        prompt: '4 + 3 = ?',
        taskId: id,
        attempts: attempt,
        profileGeneration: generation,
        ownerSection: 'learn',
        lastAnswer: attempt == 0 ? null : '6',
        localHelp: 'Zähle von vier aus drei Schritte weiter.',
      );

  test('one task starts once; changes retain actual local answer context', () {
    requests.publishTask(task());
    requests.publishTask(task(attempt: 1));
    expect(requests.learningEvents.value.single.kind,
        LumoLearningEventKind.taskStarted);
    expect(requests.taskContext.value!.lastAnswer, '6');
    requests.recordLearningEvent(LumoLearningEventKind.answerIncorrect);
    final event = requests.learningEvents.value.last;
    expect(event.attempt, 1);
    expect(event.subject, 'Mathematik');
    expect(event.unit, 'Plus bis 10');
    expect(event.taskId, 'local-task');
    requests.publishTask(task(id: 'next-task'));
    expect(requests.learningEvents.value.last.kind,
        LumoLearningEventKind.taskStarted);
  });

  test('semantic trace is bounded and immutable; no task transcript is stored',
      () {
    requests.publishTask(task());
    for (var i = 0; i < 50; i++) {
      requests.recordLearningEvent(LumoLearningEventKind.hintRequested);
    }
    expect(requests.learningEvents.value, hasLength(24));
    expect(() => requests.learningEvents.value.clear(), throwsUnsupportedError);
    expect(
        requests.learningEvents.value.every((event) =>
            event.kind.wireName == 'hint_requested' &&
            event.taskId == 'local-task' &&
            event.attempt == 0),
        isTrue);
  });

  test('the learning view supplies genuine task context without cloud consent',
      () async {
    final app = LumoAppState();
    final context = LumoContextEngine(app);
    final conversation = LumoConversationController(context);
    addTearDown(() {
      conversation.dispose();
      context.dispose();
      app.dispose();
    });
    app.setSection(LumoSection.learn);
    requests.publishTask(task());
    expect(context.task?.prompt, '4 + 3 = ?');
    expect(context.remoteContext, {'section': 'learn'});
    final reply = await conversation.ask('Lumo, hilf mir bei der Aufgabe.');
    expect(reply.reply, contains('drei Schritte'));
    expect(requests.learningEvents.value.last.kind,
        LumoLearningEventKind.childAskedQuestion);
    expect(app.learningDailyDone(), 0);
    expect(app.state.settings.microphoneEnabled, isFalse);
  });

  test('screen and generation boundaries hide stale task context', () {
    final app = LumoAppState();
    final context = LumoContextEngine(app);
    addTearDown(() {
      context.dispose();
      app.dispose();
    });
    app.setSection(LumoSection.learn);
    requests.publishTask(task(generation: app.profileGeneration + 1));
    expect(context.task, isNull);
    requests.publishTask(task(generation: app.profileGeneration));
    expect(context.task, isNotNull);
    app.setSection(LumoSection.games);
    expect(context.task, isNull);
  });

  test('selecting another real profile clears transient task and event memory',
      () async {
    final app = LumoAppState();
    addTearDown(app.dispose);
    await app.school.setActiveStudent('a');
    await app.loadLearningProfile();
    requests.publishTask(task(generation: app.profileGeneration));
    await app.school.setActiveStudent('b');
    await app.loadLearningProfile();
    expect(requests.taskContext.value, isNull);
    expect(requests.learningEvents.value, isEmpty);
  });

  test('late disposal cannot clear the newly visible task', () {
    final old = task();
    final current = task(id: 'new-task');
    requests.publishTask(old);
    requests.publishTask(current);
    requests.clearTask(old);
    expect(requests.taskContext.value, same(current));
    requests.clearTask(current);
    expect(requests.taskContext.value, isNull);
  });

  test('unsafe questions never become canonical child-question events',
      () async {
    final app = LumoAppState();
    final context = LumoContextEngine(app);
    final conversation = LumoConversationController(context);
    addTearDown(() {
      conversation.dispose();
      context.dispose();
      app.dispose();
    });
    final reply =
        await conversation.ask('Meine Telefonnummer ist 0664 1234567.');
    expect(reply.blocked, isTrue);
    expect(requests.learningEvents.value, isEmpty);
  });
}
