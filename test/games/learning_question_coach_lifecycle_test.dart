import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning/widgets/learning_question_coach.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

/// Controlled transport Futures test ownership, not real device audio.
class _Voice extends Fake implements LumoVoice {
  int revision = 0, stops = 0;
  final texts = <String>[];
  final rates = <double>[];
  final playing = <Completer<void>>[];
  @override
  int get requestRevision => revision;
  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) {
    revision++;
    texts.add(text);
    rates.add(speedFactor);
    final done = Completer<void>();
    playing.add(done);
    return done.future;
  }

  @override
  Future<void> stop() async {
    revision++;
    stops++;
  }

  void finish() {
    for (final operation in playing) {
      if (!operation.isCompleted) operation.complete();
    }
  }
}

const _settings = AppSettings(
    voiceEnabled: false,
    soundEnabled: false,
    microphoneEnabled: false,
    autoReadEnabled: false,
    calmMode: true);

Future<void> _frames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  late LumoAppState app;
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(_settings.toJson()),
    });
    bus.clearLearningScope();
    LumoVoice.instance.isEnabled = false;
    app = LumoAppState()..updateSettings(_settings);
  });
  tearDown(() {
    app.dispose();
    LumoVoice.instance.isEnabled = true;
    debugDefaultTargetPlatformOverride = null;
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))));
    await _frames(tester);
  }

  LearningQuestionCoach coach(
    ValueChanged<int> answer, {
    String prompt = '8 + 5 = ?',
    String step = 'answer',
    _Voice? voice,
  }) =>
      LearningQuestionCoach(
          appState: app,
          taskId: 'same-owner-task',
          subject: 'Mathematik',
          unit: 'Zehnerbrücke',
          prompt: prompt,
          stepId: step,
          choices: const {7: '12', 9: '13'},
          voice: voice,
          onConfirmedChoice: answer,
          child: Text(prompt));

  void propose([String candidate = '13']) {
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: bus.learningIdentity.value!, candidate: candidate),
        isTrue);
  }

  testWidgets(
      'Stop removes the candidate and invalidates an old confirmation callback',
      (tester) async {
    final answers = <int>[];
    await mount(tester, coach(answers.add));
    propose();
    await _frames(tester);
    final oldIdentity = bus.learningIdentity.value!;
    final oldConfirm = tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Diese Karte wählen'))
        .onPressed!;
    await tester.tap(find.widgetWithText(OutlinedButton, 'Stopp'));
    await _frames(tester);
    oldConfirm();
    expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
    expect(answers, isEmpty);
    expect(bus.taskContext.value!.prompt, '8 + 5 = ?');
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: oldIdentity, candidate: '13'),
        isFalse);
    expect(app.state.stars, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a retired button cannot confirm a replacement proposal',
      (tester) async {
    final answers = <int>[];
    await mount(tester, coach(answers.add));
    propose('12');
    await _frames(tester);
    final oldConfirm = tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Diese Karte wählen'))
        .onPressed!;
    propose('13');
    await _frames(tester);
    oldConfirm();
    await _frames(tester);
    expect(answers, isEmpty);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('game-answer-proposal')))
            .controller!
            .text,
        '13');
    final current = find.widgetWithText(OutlinedButton, 'Diese Karte wählen');
    await tester.ensureVisible(current);
    await tester.tap(current);
    await _frames(tester);
    expect(answers, [9]);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'same task ID cannot retain a proposal across a step or prompt change',
      (tester) async {
    final answers = <int>[];
    var prompt = '8 + 5 = ?';
    var step = 'answer';
    late StateSetter update;
    await mount(tester, StatefulBuilder(builder: (_, set) {
      update = set;
      return coach(answers.add, prompt: prompt, step: step);
    }));
    for (final change in ['step', 'prompt']) {
      propose();
      await _frames(tester);
      final oldConfirm = tester
          .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Diese Karte wählen'))
          .onPressed!;
      update(() {
        if (change == 'step') step = 'second-step';
        if (change == 'prompt') prompt = '9 + 4 = ?';
      });
      await _frames(tester);
      oldConfirm();
      expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
      expect(answers, isEmpty);
    }
    propose('12');
    await _frames(tester);
    await tester.enterText(
        find.byKey(const ValueKey('game-answer-proposal')), '13');
    final confirm = find.widgetWithText(OutlinedButton, 'Diese Karte wählen');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await _frames(tester);
    expect(answers, [9],
        reason: 'Only explicit confirmation reaches the original choice key.');
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pause clears the scope and queued work; resume does not revive the candidate',
      (tester) async {
    final answers = <int>[];
    final voice = _Voice();
    addTearDown(voice.finish);
    await mount(tester, coach(answers.add, voice: voice));
    propose();
    await _frames(tester);
    final before = bus.learningIdentity.value!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester);
    expect(bus.taskContext.value, isNull);
    expect(
        bus.requestLearningAction(LumoLearningAction.proposeAnswer,
            identity: before, candidate: '13'),
        isFalse);
    expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester);
    expect(bus.taskContext.value!.taskId, before.taskId);
    expect(before.matches(bus.learningIdentity.value), isFalse);
    expect(answers, isEmpty);
    expect(voice.texts, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a newer preparing transport survives disposal of the old audio owner',
      (tester) async {
    final voice = _Voice();
    addTearDown(voice.finish);
    app.updateSettings(_settings.copyWith(voiceEnabled: true));
    await mount(tester, coach((_) {}, voice: voice));
    await tester.tap(find.widgetWithText(OutlinedButton, 'Langsamer'));
    await _frames(tester);
    expect(voice.texts, ['8 + 5 = ?']);
    expect(voice.rates, [.7]);
    unawaited(voice.speakAndWait('Die neue Seite spricht schon.'));
    final currentRevision = voice.requestRevision;
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(voice.requestRevision, currentRevision);
    expect(voice.stops, 0);
    voice.playing.first.complete();
    await _frames(tester);
    expect(voice.stops, 0,
        reason: 'The late old completion must not touch the new transport.');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Stop cancels a deferred read before it can begin',
      (tester) async {
    final voice = _Voice();
    addTearDown(voice.finish);
    app.updateSettings(_settings.copyWith(voiceEnabled: true));
    await mount(tester, coach((_) {}, voice: voice));
    tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Noch einmal'))
        .onPressed!();
    tester
        .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Stopp'))
        .onPressed!();
    await _frames(tester);
    expect(voice.texts, isEmpty);
    expect(voice.stops, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
  });

  testWidgets(
      'native entry records existing help and keeps the exact scope during native pause',
      (tester) async {
    const channel = MethodChannel('lumo_lernen/bridge');
    final messenger = tester.binding.defaultBinaryMessenger;
    final returned = Completer<Map<String, dynamic>>();
    Map<Object?, Object?>? launch;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'launch3D') {
        launch = Map<Object?, Object?>.from(call.arguments as Map);
        return returned.future;
      }
      return null;
    });
    addTearDown(() {
      if (!returned.isCompleted) returned.complete({'destination': 'learning'});
      messenger.setMockMethodCallHandler(channel, null);
    });
    var help = 0;
    await mount(
        tester,
        StatefulBuilder(
            builder: (_, set) => LearningQuestionCoach(
                  appState: app,
                  taskId: 'native-question',
                  subject: 'Deutsch',
                  unit: 'Lesen',
                  prompt: 'Welches Wort beginnt mit B?',
                  choices: const {0: 'Banane', 1: 'Apfel'},
                  helpUsed: help > 0,
                  helpText: help > 0 ? 'Höre auf den ersten Laut.' : null,
                  onHint: () => set(() => help++),
                  child: const Text('Welches Wort beginnt mit B?'),
                )));
    final native = find.byKey(const ValueKey('question-lumo-native'));
    expect(tester.getSize(native).height, greaterThanOrEqualTo(48));
    await tester.ensureVisible(native);
    await tester.tap(native);
    await _frames(tester, 40);
    expect(help, 1);
    expect(launch, isNotNull);
    expect(launch!['scene'], 'learning');
    final lesson = launch!['learning'] as Map;
    expect(lesson['sourceTaskId'], 'native-question');
    expect(lesson['explanation'], 'Höre auf den ersten Laut.');
    final identity = bus.learningIdentity.value!;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester);
    expect(identity.matches(bus.learningIdentity.value), isTrue);
    expect(bus.taskContext.value!.answering, isTrue);
    returned.complete({'destination': 'learning'});
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _frames(tester, 20);
    expect(bus.taskContext.value!.taskId, 'native-question');
    expect(app.state.stars, 0);
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));
}
