import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_learning_session_contract.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/domain/tutoring/guided_lesson_catalog.dart';
import 'package:lumo_lernen/features/learning/lab/learning_manipulatives.dart';
import 'package:lumo_lernen/features/learning/learning_content.dart';
import 'package:lumo_lernen/features/tutoring/guided_lesson_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

class _Playback {
  _Playback(this.text, this.revision, this.speedFactor);
  final String text;
  final int revision;
  final double speedFactor;
  final done = Completer<void>();
}

/// Native completion and stop gates are controlled independently. This proves
/// widget ownership, not real speaker output or microphone operation.
class _Voice extends Fake implements LumoVoice {
  int revision = 0, stops = 0, completed = 0, configurations = 0;
  int availabilityCalls = 0;
  Completer<void>? nextStop;
  Completer<bool>? availability;
  final playbacks = <_Playback>[];
  @override
  final status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  @override
  final lastError = ValueNotifier<String?>(null);
  @override
  int get requestRevision => revision;
  @override
  int get completedPlaybackCount => completed;
  @override
  bool get isEnabled => true;

  @override
  Future<bool> localSpeechAvailable() {
    availabilityCalls++;
    return availability?.future ?? Future.value(true);
  }

  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) {
    final playback = _Playback(text, ++revision, speedFactor);
    playbacks.add(playback);
    status.value = VoiceStatus.preparing;
    return playback.done.future;
  }

  @override
  Future<void> stop() {
    revision++;
    stops++;
    status.value = VoiceStatus.idle;
    final gate = nextStop;
    nextStop = null;
    return gate?.future ?? Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #configure) {
      configurations++;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }

  void start(_Playback playback) {
    if (revision == playback.revision) status.value = VoiceStatus.speaking;
  }

  void finish(_Playback playback) {
    if (revision == playback.revision) {
      completed++;
      status.value = VoiceStatus.idle;
    }
    if (!playback.done.isCompleted) playback.done.complete();
  }

  void finishAll() {
    for (final playback in playbacks) {
      if (!playback.done.isCompleted) playback.done.complete();
    }
  }
}

const _settings = AppSettings(
  voiceEnabled: true,
  autoReadEnabled: false,
  localVoiceLicenseAccepted: true,
  aiProxyEnabled: false,
  soundEnabled: false,
  calmMode: true,
  reduceAnimations: true,
);

Future<void> _frames(WidgetTester tester, [int count = 8]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The shared catalog Future must originate outside an individual test's
  // FakeAsync zone, so later widget tests can await the same loaded catalog.
  setUpAll(LumoVoiceClips.ensureFreeLoaded);
  final bus = LumoCompanionRequests.instance;
  late LumoAppState app;
  late _Voice voice;

  Future<void> open(WidgetTester tester, String page,
      {GuidedLesson lesson = GuidedLessonCatalog.plantParts}) async {
    SharedPreferences.setMockInitialValues(
        {'lumo_app_settings_v1': jsonEncode(_settings.toJson())});
    bus.clearLearningScope();
    voice = _Voice();
    await tester.binding.setSurfaceSize(const Size(840, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.ensureSettingsLoaded();
      await app.school.setActiveStudent('voice-owner-fixture');
      await app.loadLearningProfile();
      app.updateSettings(_settings);
      app.update(app.state.copyWith(
        grade: 1,
        subject: 'Mathematik',
        unit: 'Plus bis 10',
        sessionKind: LumoSessionKind.quickPractice,
      ));
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: page == 'adaptive'
            ? LearningContent(appState: app, voice: voice)
            : GuidedLessonScreen(
                appState: app, lesson: lesson, discovery: false, voice: voice),
      ),
    ));
    await _frames(tester);
    expect(bus.learningIdentity.value, isNotNull);
    expect(voice.playbacks, isEmpty);
    addTearDown(() async {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(const SizedBox.shrink());
      voice.finishAll();
      await _frames(tester);
      app.dispose();
      bus.clearLearningScope();
      voice.status.dispose();
      voice.lastError.dispose();
    });
  }

  Future<void> request(WidgetTester tester, LumoLearningAction action) async {
    expect(
        bus.requestLearningAction(action,
            identity: bus.learningIdentity.value!),
        isTrue);
    await _frames(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await _frames(tester);
  }

  Future<void> banana(WidgetTester tester) async {
    await open(tester, 'guided', lesson: GuidedLessonCatalog.syllables);
    await tap(tester, 'guided-continue');
    await tap(tester, 'guided-continue');
    expect(
        tester
            .widget<SyllableLearningBoard>(find.byType(SyllableLearningBoard))
            .word,
        'Banane');
  }

  for (final page in ['adaptive', 'guided']) {
    for (final action in ['stop', 'pause', 'dispose']) {
      testWidgets('$page $action cannot stop a newer voice owner',
          (tester) async {
        await open(tester, page);
        await request(tester, LumoLearningAction.repeat);
        expect(voice.playbacks, hasLength(1));
        final old = voice.playbacks.single;
        unawaited(voice.speakAndWait('Die nächste Seite spricht.'));
        final newerRequest = voice.requestRevision;
        final stops = voice.stops;
        switch (action) {
          case 'stop':
            await request(tester, LumoLearningAction.stop);
          case 'pause':
            tester.binding
                .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
            tester.binding
                .handleAppLifecycleStateChanged(AppLifecycleState.hidden);
            tester.binding
                .handleAppLifecycleStateChanged(AppLifecycleState.paused);
            await _frames(tester);
          case 'dispose':
            await tester.pumpWidget(const SizedBox.shrink());
            await _frames(tester);
        }
        expect(voice.stops, stops);
        expect(voice.requestRevision, newerRequest);
        voice.finish(old);
        await _frames(tester);
        expect(voice.requestRevision, newerRequest);
        expect(voice.playbacks, hasLength(2));
        expect(voice.configurations, 0,
            reason: 'Old completions must not restore a global playback rate.');
        expect(app.learningDailyDone(), 0);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$page stop cancels its own pending transport', (tester) async {
      await open(tester, page);
      await request(tester, LumoLearningAction.slower);
      expect(voice.playbacks, hasLength(1));
      expect(voice.playbacks.single.speedFactor, .7);
      final stops = voice.stops;
      await request(tester, LumoLearningAction.stop);
      expect(voice.stops, stops + 1);
      voice.finish(voice.playbacks.single);
      await _frames(tester);
      expect(voice.playbacks, hasLength(1));
      expect(voice.configurations, 0);
    });
  }

  for (final segmented in [false, true]) {
    testWidgets(
        'guided delayed stop cannot restart ${segmented ? "syllables" : "speech"} over a newer owner',
        (tester) async {
      if (segmented) {
        await banana(tester);
      } else {
        await open(tester, 'guided');
      }
      final gate = Completer<void>();
      voice.nextStop = gate;
      await request(tester, LumoLearningAction.repeat);
      expect(voice.playbacks, isEmpty);
      unawaited(voice.speakAndWait('Neue Erklärung während des Stopps.'));
      final newer = voice.requestRevision;
      gate.complete();
      await _frames(tester);
      expect(voice.playbacks, hasLength(1));
      expect(voice.requestRevision, newer);
      expect(voice.configurations, 0);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('adaptive delayed preparation cannot replace a newer owner',
      (tester) async {
    await open(tester, 'adaptive');
    voice.availability = Completer<bool>();
    await request(tester, LumoLearningAction.repeat);
    expect(voice.availabilityCalls, 1);
    expect(voice.playbacks, isEmpty);
    unawaited(voice.speakAndWait('Eine neue Seite hat die Stimme übernommen.'));
    final newer = voice.requestRevision;
    voice.availability!.complete(true);
    await _frames(tester);
    expect(voice.playbacks, hasLength(1));
    expect(voice.requestRevision, newer);
    expect(voice.stops, 0);
  });

  testWidgets(
      'adaptive delayed native handoff cannot stop or replace a newer owner',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    var launches = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      if (call.method == 'launch3D') launches++;
      return <String, Object?>{'destination': 'learn'};
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
    });
    await open(tester, 'adaptive');
    await request(tester, LumoLearningAction.repeat);
    expect(voice.playbacks, hasLength(1));
    final gate = Completer<void>();
    voice.nextStop = gate;
    await tap(tester, 'adaptive-open-3d');
    expect(voice.stops, 1);
    expect(launches, 0);
    unawaited(voice.speakAndWait('Die neue Seite ist bereits aktiv.'));
    final newer = voice.requestRevision;
    gate.complete();
    await _frames(tester);
    expect(voice.stops, 1);
    expect(voice.requestRevision, newer);
    expect(launches, 0);
    expect(voice.playbacks, hasLength(2));
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('Banane keeps real segment events and a request-local slow rate',
      (tester) async {
    await banana(tester);
    await request(tester, LumoLearningAction.slower);
    int? active() => tester
        .widget<SyllableLearningBoard>(find.byType(SyllableLearningBoard))
        .activeIndex;
    for (var i = 0; i < 3; i++) {
      expect(voice.playbacks, hasLength(i + 1));
      final segment = voice.playbacks.last;
      expect(segment.text, ['Ba', 'na', 'ne'][i]);
      expect(segment.speedFactor, .7);
      expect(active(), isNull,
          reason: 'Preparation alone does not highlight an audible syllable.');
      voice.start(segment);
      await _frames(tester);
      expect(active(), i);
      voice.finish(segment);
      await _frames(tester);
    }
    expect(active(), isNull);
    expect(
        voice.playbacks.map((playback) => playback.text), ['Ba', 'na', 'ne']);
    expect(voice.configurations, 0);
    expect(app.learningDailyDone(), 0);
  });

  testWidgets('Banane never advances on another owner audio or old completion',
      (tester) async {
    await banana(tester);
    await request(tester, LumoLearningAction.repeat);
    final first = voice.playbacks.single;
    voice.start(first);
    await _frames(tester);
    expect(
        tester
            .widget<SyllableLearningBoard>(find.byType(SyllableLearningBoard))
            .activeIndex,
        0);
    unawaited(voice.speakAndWait('Eine andere Aufgabe spricht.'));
    voice.start(voice.playbacks.last);
    await _frames(tester);
    expect(
        tester
            .widget<SyllableLearningBoard>(find.byType(SyllableLearningBoard))
            .activeIndex,
        isNull);
    final newer = voice.requestRevision;
    voice.finish(first);
    await _frames(tester);
    expect(voice.playbacks.map((playback) => playback.text),
        ['Ba', 'Eine andere Aufgabe spricht.']);
    expect(voice.requestRevision, newer);
    expect(voice.configurations, 0);
  });
}
