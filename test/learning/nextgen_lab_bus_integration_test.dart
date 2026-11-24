import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_ai_proxy_client.dart';
import 'package:lumo_lernen/core/lumo_context_engine.dart';
import 'package:lumo_lernen/core/lumo_conversation_controller.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/agent/lumo_agent_content.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_lab_screen.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../learning_lab_runtime_test.dart' show frames, mountLab, tap;
import '../lumo_context_conversation_test.dart' show ControlledProxy;

void main() {
  final bus = LumoCompanionRequests.instance;
  setUp(bus.clearLearningScope);
  tearDown(bus.clearLearningScope);

  testWidgets(
      'own lab conversation keeps the stopped task and explains why two',
      (tester) async {
    final app = await mountLab(tester);
    app.setSection(LumoSection.learn);
    await frames(tester);
    await tap(tester, 'lab-help');
    await tap(tester, 'lab-stop');
    final before = bus.taskContext.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    final hiddenModelChange = tester
        .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
        .onChanged;

    await tap(tester, 'lab-ask-lumo');
    hiddenModelChange(1);
    await frames(tester);
    final conversation = find.byType(LumoAgentContent);
    final input =
        find.descendant(of: conversation, matching: find.byType(TextField));
    await tester.ensureVisible(input);
    await tester.pump();
    await tester.enterText(input, 'Warum zuerst zwei?');
    tester.testTextInput.hide();
    await frames(tester);
    final send = find.descendant(
        of: conversation,
        matching: find.widgetWithText(FilledButton, 'Senden'));
    await tester.ensureVisible(send);
    await frames(tester);
    expect(send.hitTestable(), findsOneWidget);
    await tester.tap(send);
    await frames(tester);
    expect(tester.widget<TextField>(input).controller!.text, isEmpty,
        reason:
            'The real send button must have consumed the entered question.');

    expect(
        find.descendant(
            of: conversation,
            matching:
                find.byKey(const ValueKey('lumo-conversation-current-task'))),
        findsOneWidget);
    expect(
        find.descendant(of: conversation, matching: find.text(before.prompt)),
        findsOneWidget);
    expect(
        find.descendant(
            of: conversation,
            matching: find.textContaining(
                'Bis zur Zehn fehlen 2, denn 10 minus 8 ist 2')),
        findsOneWidget);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(bus.taskContext.value!.stepId, before.stepId);
    expect(bus.taskContext.value!.profileGeneration, before.profileGeneration);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);

    await tester.tap(find.byTooltip('Zurück zur Aufgabe'));
    await frames(tester);
    expect(find.byType(LumoAgentContent), findsNothing);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        0);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('own conversation completion preserves a newer voice request',
      (tester) async {
    final app = await mountLab(tester);
    app.setSection(LumoSection.learn);
    await frames(tester);
    await tap(tester, 'lab-ask-lumo');
    final route = ModalRoute.of(tester.element(find.byType(LumoAgentContent)))!;
    final voice = LumoVoice.instance;
    final savedEnabled = voice.isEnabled, savedClips = voice.clipsEnabled;
    voice.clipsEnabled = false;
    await voice.configure(localVoiceLicenseAccepted: false);
    addTearDown(() async {
      voice.clipsEnabled = savedClips;
      voice.isEnabled = savedEnabled;
      await voice.stop();
    });
    int? newerRequest;
    Future<void>? preparing;
    // Registered before popping, so this new request starts after agent
    // disposal but before the host's await(route.completed) resumes.
    unawaited(route.completed.then((_) {
      voice.isEnabled = true;
      preparing = voice.speakAndWait('Neuer Sprechauftrag nach der Rückkehr.');
      newerRequest = voice.requestRevision;
    }));
    await tester.tap(find.byTooltip('Zurück zur Aufgabe'));
    await frames(tester);
    expect(newerRequest, isNotNull);
    expect(voice.requestRevision, newerRequest,
        reason: 'The closing host must not stop another owner’s preparation.');
    await tester.runAsync(() => preparing!);
    expect(tester.takeException(), isNull);
  });

  for (final boundary in ['foreign route', 'pause', 'profile', 'dispose']) {
    testWidgets('own lab conversation rejects late reply after $boundary',
        (tester) async {
      final app = await mountLab(tester);
      app.setSection(LumoSection.learn);
      await frames(tester);
      await tap(tester, 'lab-ask-lumo');
      final before = bus.taskContext.value!;
      app.updateSettings(const AppSettings(
          voiceEnabled: false,
          autoReadEnabled: false,
          reduceAnimations: true,
          aiProxyEnabled: true,
          aiLearningMode: AiLearningMode.learningHelp));
      await frames(tester);
      final profile = await tester.runAsync(() => app.captureLearningProfile());
      final completed = profile!.profile.dailyDone();
      final rewards = (app.state.stars, app.state.xp);
      final context = LumoContextEngine(app);
      final proxy = ControlledProxy();
      final controller = LumoConversationController(context, proxy: proxy);
      addTearDown(() {
        if (!proxy.reply.isCompleted) {
          proxy.reply.complete(LumoConversationController.cancelled);
        }
        controller.dispose();
        context.dispose();
      });
      final pending = controller.ask('Welche Bedeutung hat Addition?');
      await frames(tester);
      expect(proxy.entered.isCompleted, isTrue);
      expect(proxy.extras?['taskPrompt'], before.prompt);
      final identity = bus.learningIdentity.value!;
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));

      switch (boundary) {
        case 'foreign route':
          navigator.push<void>(MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Anderer Bereich'))));
          expect(bus.taskContext.value, isNull,
              reason:
                  'Cover must retire the exact modal scope before a frame.');
        case 'pause':
          addTearDown(() {
            if (tester.binding.lifecycleState == AppLifecycleState.paused) {
              tester.binding
                  .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
            }
            if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
              tester.binding
                  .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            }
            tester.binding
                .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
          });
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
          tester.binding
              .handleAppLifecycleStateChanged(AppLifecycleState.paused);
        case 'profile':
          await tester.runAsync(
              () => app.school.setActiveStudent('conversation-other-profile'));
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
      }
      await frames(tester);
      expect(bus.taskContext.value, isNull);
      expect(proxy.request?.cancelled, isTrue);
      expect(
          bus.requestLearningAction(LumoLearningAction.hint,
              identity: identity),
          isFalse);
      proxy.reply.complete(const LumoAiProxyResponse(
          reply: 'Diese verspätete Antwort darf nicht erscheinen.',
          blocked: false,
          source: 'openai_proxy'));
      expect((await pending).source, 'cancelled');
      expect(controller.history, isEmpty);
      expect(controller.responseMaySpeak, isFalse);
      expect(profile.profile.dailyDone(), completed);
      expect((app.state.stars, app.state.xp), rewards);

      if (boundary == 'foreign route') {
        navigator.pop();
      } else if (boundary == 'pause') {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      }
      await frames(tester);
      if (boundary == 'foreign route' || boundary == 'pause') {
        expect(bus.taskContext.value!.taskId, before.taskId);
        expect(bus.taskContext.value!.stepId, before.stepId);
        expect(
            bus.taskContext.value!.profileGeneration, before.profileGeneration);
        expect(
            bus.requestLearningAction(LumoLearningAction.hint,
                identity: identity),
            isFalse,
            reason:
                'An old reply cannot regain its former identity on return.');
        await tester.tap(find.byTooltip('Zurück zur Aufgabe'));
        await frames(tester);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('lab retires hidden bindings and restores the same model',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    final before = bus.taskContext.value!;
    final identity = bus.learningIdentity.value!;
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());

    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await frames(tester);
    expect(bus.taskContext.value, isNull,
        reason: 'A paused lab must release its command receiver.');
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await frames(tester);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(bus.taskContext.value!.prompt, before.prompt);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);
    await tester.binding.setSurfaceSize(const Size(344, 882));
    await frames(tester);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    final visibleIdentity = bus.learningIdentity.value!;
    navigator.push<void>(MaterialPageRoute(
        builder: (_) => const Scaffold(body: Text('Anderer Bereich'))));
    await frames(tester);
    expect(bus.taskContext.value, isNull,
        reason: 'A covered lab must not consume the visible route’s requests.');
    navigator.pop();
    await frames(tester);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: visibleIdentity),
        isFalse);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lab proposal needs confirmation and stop discards its candidate',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    await tap(tester, 'quantity-add');
    await tap(tester, 'lab-check-model');
    await tap(tester, 'lab-next');
    final identity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: identity, candidate: '16'),
        isTrue);
    await frames(tester);
    final field = find.byKey(const ValueKey('lab-answer'));
    expect(tester.widget<TextField>(field).controller!.text, '16');
    expect(app.learningDailyDone(), 0);

    final proposedIdentity = bus.learningIdentity.value!;
    expect(
        bus.requestLearningAction(LumoLearningAction.stop,
            identity: proposedIdentity),
        isTrue);
    await frames(tester);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: proposedIdentity, candidate: '16'),
        isFalse);
    expect(app.learningDailyDone(), 0);

    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: '16'),
        isTrue);
    await frames(tester);
    expect(app.learningDailyDone(), 0);
    await tap(tester, 'lab-check-answer');
    expect(app.learningDailyDone(), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the lab restores its saved model without new rewards',
      (tester) async {
    final app = await mountLab(tester);
    await tap(tester, 'lab-next');
    await tap(tester, 'quantity-add');
    expect(
        bus.requestLearningAction(LumoLearningAction.hint,
            identity: bus.learningIdentity.value!),
        isTrue);
    await frames(tester);
    final before = bus.taskContext.value!;
    final identity = bus.learningIdentity.value!;
    final rewards = (app.state.stars, app.state.xp, app.learningDailyDone());
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
    await tester.pumpWidget(MaterialApp(
        home: LearningLabScreen(
            appState: app, topic: LabCatalog.topics.first, seed: 0)));
    await frames(tester);
    expect(find.byKey(const ValueKey('lab-phase-build')), findsOneWidget);
    expect(
        tester
            .widget<QuantityBridgeBoard>(find.byType(QuantityBridgeBoard))
            .moved,
        1);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(bus.taskContext.value!.helpLevel, before.helpLevel);
    expect(
        bus.requestLearningAction(LumoLearningAction.hint, identity: identity),
        isFalse);
    expect((app.state.stars, app.state.xp, app.learningDailyDone()), rewards);
    expect(tester.takeException(), isNull);
  });
}
