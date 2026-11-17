import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_context_engine.dart';
import 'package:lumo_lernen/core/lumo_conversation_controller.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  final voice = LumoVoice.instance;
  late LumoAppState app;
  late LumoContextEngine context;
  late LumoConversationController conversation;
  late bool savedVoiceEnabled;
  late bool savedClips;

  const settings = AppSettings(
    microphoneEnabled: true,
    voiceEnabled: true,
    autoReadEnabled: false,
    reduceAnimations: true,
    localVoiceLicenseAccepted: false,
  );

  LumoCompanionTaskContext task({
    String id = 'eight-plus-five',
    String step = 'bridge',
  }) =>
      LumoCompanionTaskContext(
        taskId: id,
        stepId: step,
        profileGeneration: app.profileGeneration,
        subject: 'Mathematik',
        unit: 'Plus bis 20',
        prompt: '8 + 5',
        explanation: 'Ergänze zuerst zur Zehn, dann bleiben drei übrig.',
        isExplanation: true,
        objectIds: const ['ten_frame', 'bridge_two'],
        allowedActions: const {
          ...lumoDefaultLearningActions,
          LumoLearningAction.look,
          LumoLearningAction.point,
        },
      );

  void present(LumoLearningIdentity identity) {
    expect(
        bus.publishLearningPresentation(LumoLearningPresentation(
          identity: identity,
          turnId: 9,
          utteranceId: 4,
          pointObjectId: 'bridge_two',
          animationState: 'explaining',
        )),
        isTrue);
    expect(
        bus.publishLearningAudio(LumoLearningAudioFrame(
          identity: identity,
          turnId: 9,
          utteranceId: 4,
          state: 'preparing',
          subtitle: 'Neuer eigener Lernschritt.',
        )),
        isTrue);
  }

  setUp(() async {
    savedVoiceEnabled = voice.isEnabled;
    savedClips = voice.clipsEnabled;
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(settings.toJson()),
    });
    bus.clearLearningScope();
    app = LumoAppState();
    await app.ensureSettingsLoaded();
    app.update(app.state.copyWith(
      section: LumoSection.exercises,
      subject: 'Mathematik',
      unit: 'Plus bis 20',
    ));
    // Real request ownership is tested during preflight. No native playback,
    // audible speech or synthetic mouth movement is claimed by this fixture.
    voice.clipsEnabled = false;
    await voice.configure(enabled: true, localVoiceLicenseAccepted: false);
    bus.tutor.activateProfile(app.profileGeneration);
    context = LumoContextEngine(app);
    conversation = LumoConversationController(context);
  });

  tearDown(() async {
    conversation.dispose();
    context.dispose();
    app.dispose();
    bus.clearLearningScope();
    voice.clipsEnabled = savedClips;
    voice.isEnabled = savedVoiceEnabled;
    await voice.stop();
  });

  test('task change has one bus invalidation, not a second old-owner stop',
      () async {
    bus.publishTask(task());
    await conversation.ask('Warum zuerst zwei?');
    final previous = bus.learningIdentity.value!;
    bus.publishTask(task(id: 'next-task'));
    final next = bus.learningIdentity.value!;
    expect(next.taskId, 'next-task');
    expect(next.revision, previous.revision + 1);
    expect(next.cancelEpoch, previous.cancelEpoch + 1,
        reason: 'Only the new task publication may retire the previous lease.');
    expect(bus.learningCancellation.value?.reason, 'task_changed');
    expect(bus.learningAction.value, isNull);
  });

  for (final ending in ['pause', 'dispose']) {
    test('old $ending preserves the new task, gesture and audio request',
        () async {
      bus.publishTask(task());
      final response = await conversation.ask('Warum zuerst zwei?');
      final oldSpeech = conversation.speak(response.reply);
      bus.publishTask(task(id: 'next-task'));
      final next = bus.learningIdentity.value!;
      present(next);
      final presentation = bus.learningPresentation.value;
      final audio = bus.learningAudio.value;
      final newSpeech =
          voice.speakAndWait('Ein neuer Auftrag bereitet Ton vor.');
      final owner = voice.requestRevision;
      if (ending == 'pause') {
        conversation.pause();
      } else {
        conversation.dispose();
      }
      expect(voice.requestRevision, owner,
          reason: 'An old owner cannot stop a newer request during preflight.');
      expect(bus.learningIdentity.value, same(next));
      expect(bus.learningPresentation.value, same(presentation));
      expect(bus.learningAudio.value, same(audio));
      await Future.wait([oldSpeech, newSpeech]);
      expect(voice.requestRevision, owner,
          reason: 'Late completion cannot reclaim transport ownership.');
      expect(bus.learningIdentity.value, same(next));
      expect(bus.learningPresentation.value, same(presentation));
      expect((app.state.stars, app.state.xp), (0, 0));
      expect(app.state.solved, isEmpty);
    });
  }

  test('a replaced controller cannot cancel its successor on the same task',
      () async {
    bus.publishTask(task());
    await conversation.ask('Warum zuerst zwei?');
    final replacement = LumoConversationController(context);
    addTearDown(replacement.dispose);
    final response = await replacement.ask('Bitte langsamer.');
    final current = replacement.responseIdentity!;
    final presentation = bus.learningPresentation.value;
    final speaking = replacement.speak(response.reply);
    final owner = voice.requestRevision;
    conversation.dispose();
    expect(voice.requestRevision, owner);
    expect(bus.isCurrentLearningIdentity(current), isTrue);
    expect(bus.learningPresentation.value, same(presentation));
    expect(replacement.responseMaySpeak, isTrue);
    await speaking;
  });

  test('explicit current Stop still cancels voice, mouth and figure together',
      () async {
    bus.publishTask(task());
    final response = await conversation.ask('Warum zuerst zwei?');
    final identity = conversation.responseIdentity!;
    final speaking = conversation.speak(response.reply);
    final owner = voice.requestRevision;
    expect(bus.learningPresentation.value, isNotNull);
    final stopped = await conversation.ask('Stopp');
    expect(stopped.source, 'local_stopped');
    expect(voice.requestRevision, greaterThan(owner));
    expect(bus.isCurrentLearningIdentity(identity), isFalse);
    expect(bus.learningPresentation.value, isNull);
    expect(bus.learningAudio.value, isNull);
    expect(voice.clipMouth.value, isNull);
    expect(conversation.responseMaySpeak, isFalse);
    await speaking;
    expect((app.state.stars, app.state.xp), (0, 0));
    expect(app.state.solved, isEmpty);
  });

  testWidgets('disposing the old Agent preserves a newer task and transport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    bus.publishTask(task());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LumoAgentContent(appState: app, onSection: (_) {}),
      ),
    ));
    await tester.pump();
    bus.publishTask(task(id: 'next-task'));
    final next = bus.learningIdentity.value!;
    present(next);
    final presentation = bus.learningPresentation.value;
    final audio = bus.learningAudio.value;
    final speaking =
        voice.speakAndWait('Eine andere Seite beginnt zu sprechen.');
    final owner = voice.requestRevision;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(voice.requestRevision, owner);
    expect(bus.learningIdentity.value, same(next));
    expect(bus.learningPresentation.value, same(presentation));
    expect(bus.learningAudio.value, same(audio));
    await tester.runAsync(() => speaking);
    expect(tester.takeException(), isNull);
  });

  for (final interruption in ['foreign route', 'new audio owner']) {
    testWidgets('pending microphone initialization rejects $interruption',
        (tester) async {
      const channel = MethodChannel('plugin.csdcorp.com/speech_to_text');
      final messenger = tester.binding.defaultBinaryMessenger;
      final locales = Completer<List<String>>();
      final calls = <String>[];
      var localeCalls = 0;
      var listens = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'locales') {
          localeCalls++;
          return locales.future;
        }
        return switch (call.method) {
          'initialize' => true,
          'listen' => ++listens > 0,
          'stop' || 'cancel' => null,
          _ => throw StateError('Unexpected speech method: ${call.method}'),
        };
      });
      addTearDown(() async {
        if (!locales.isCompleted) locales.complete([]);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        messenger.setMockMethodCallHandler(channel, null);
        await tester.binding.setSurfaceSize(null);
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LumoAgentContent(appState: app, onSection: (_) {}),
        ),
      ));
      await tester.pump();
      final speak = find.widgetWithText(FilledButton, 'Sprechen');
      await tester.ensureVisible(speak);
      await tester.tap(speak);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      for (var i = 0; i < 10 && localeCalls == 0; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(localeCalls, 1,
          reason: 'The real initialization must reach the held native reply; '
              'calls=$calls, microphone=${app.state.settings.microphoneEnabled}.');
      expect(locales.isCompleted, isFalse);
      expect(listens, 0);
      Future<void>? otherSpeech;
      if (interruption == 'foreign route') {
        unawaited(Navigator.of(tester.element(find.byType(LumoAgentContent)))
            .push<void>(MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Text('Andere Aufgabe')))));
      } else {
        otherSpeech =
            voice.speakAndWait('Ein fremder Auftrag ist jetzt aktiv.');
      }
      final owner = voice.requestRevision;
      locales.complete(['de_AT:Deutsch (Österreich)']);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(listens, 0,
          reason: 'Native initialization cannot promote an obsolete tap.');
      expect(voice.requestRevision, owner);
      if (otherSpeech != null) await tester.runAsync(() => otherSpeech!);
      expect(tester.takeException(), isNull);
    });
  }
}
