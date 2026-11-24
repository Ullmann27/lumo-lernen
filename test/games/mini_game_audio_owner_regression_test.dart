import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/domain/games/game_level_catalog.dart';
import 'package:lumo_lernen/features/games/mini_games/mini_game_learning_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

import '../helpers/mini_game_learning.dart';

/// The real widget handles controlled transport completions. This fixture does
/// not substitute for audible playback verification on an Android device.
class _Voice extends Fake implements LumoVoice {
  int revision = 0, stops = 0, configurations = 0;
  Completer<void>? pendingStop;
  final playbacks =
      <({String text, double speedFactor, Completer<void> done})>[];

  @override
  final status = ValueNotifier<VoiceStatus>(VoiceStatus.idle);
  @override
  int get requestRevision => revision;

  @override
  Future<void> stop() async {
    revision++;
    stops++;
    final pending = pendingStop;
    pendingStop = null;
    if (pending != null) await pending.future;
  }

  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) {
    revision++;
    final done = Completer<void>();
    playbacks.add((text: text, speedFactor: speedFactor, done: done));
    return done.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #configure) {
      configurations++;
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
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
    soundEnabled: false,
    microphoneEnabled: false,
    calmMode: true);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  final level = GameLevelCatalog.byId(25)!;
  late LumoAppState app;
  late _Voice voice;

  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'lumo_app_settings_v1': jsonEncode(_settings.toJson())});
    bus.clearLearningScope();
    app = LumoAppState();
    voice = _Voice();
  });

  tearDown(() {
    voice.finishAll();
    app.dispose();
    voice.status.dispose();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
    });
    await tester.pumpWidget(MaterialApp(
        home:
            MiniGameLearningScreen(appState: app, level: level, voice: voice)));
    await settleMiniGame(tester);
    expect(find.byKey(const ValueKey('mini-game-listen')), findsOneWidget);
    expect(bus.taskContext.value?.activity, 'mini_game');
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    voice.finishAll();
    await settleMiniGame(tester);
    expect(tester.takeException(), isNull);
  }

  void pause(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void resume(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  for (final action in ['stop', 'pause', 'dispose']) {
    testWidgets('mini-game $action preserves a newer audio owner',
        (tester) async {
      await open(tester);
      final round = await savedMiniGameRound(level);
      await tapMiniGameKey(tester, 'mini-game-listen');
      expect(voice.playbacks.single.text, round.task.speech);
      expect(voice.stops, 1);
      final old = voice.playbacks.single.done;
      unawaited(voice.speakAndWait('Jetzt spricht die neue Seite.'));
      final request = voice.requestRevision;
      switch (action) {
        case 'stop':
          await tapMiniGameKey(tester, 'mini-game-stop');
        case 'pause':
          pause(tester);
          await settleMiniGame(tester);
          resume(tester);
          await settleMiniGame(tester);
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
          await settleMiniGame(tester);
      }
      expect(voice.stops, 1);
      expect(voice.requestRevision, request);
      old.complete();
      await settleMiniGame(tester);
      expect(voice.stops, 1);
      expect(voice.requestRevision, request,
          reason: 'A retired completion cannot cancel the newer request.');
      expect(voice.configurations, 0,
          reason: 'Old cleanup must not change another speaker\'s tempo.');
      final saved = await savedMiniGameRound(level);
      expect(saved.index, round.index);
      expect(saved.response.attempts, isEmpty);
      expect(saved.rewarded, isFalse);
      expect(app.state.stars, 0);
      await close(tester);
      expect(voice.stops, 1);
      expect(voice.requestRevision, request);
    });
  }

  testWidgets('delayed mini-game stop cannot start over a newer speaker',
      (tester) async {
    await open(tester);
    final gate = Completer<void>();
    voice.pendingStop = gate;
    await tapMiniGameKey(tester, 'mini-game-listen');
    expect(voice.playbacks, isEmpty);
    expect(voice.stops, 1);
    unawaited(voice.speakAndWait('Die neue Seite hat bereits begonnen.'));
    final request = voice.requestRevision;
    gate.complete();
    await settleMiniGame(tester);
    expect(voice.playbacks, hasLength(1));
    expect(voice.requestRevision, request);
    expect(voice.configurations, 0);
    await close(tester);
    expect(voice.stops, 1);
    expect(voice.requestRevision, request);
  });

  testWidgets('Stop invalidates a mini-game read still awaiting its transport',
      (tester) async {
    await open(tester);
    final gate = Completer<void>();
    voice.pendingStop = gate;
    await tapMiniGameKey(tester, 'mini-game-listen');
    await tapMiniGameKey(tester, 'mini-game-stop');
    expect(voice.stops, 2);
    gate.complete();
    await settleMiniGame(tester);
    expect(voice.playbacks, isEmpty);
    expect(voice.configurations, 0);
    await close(tester);
    expect(voice.stops, 2);
  });

  testWidgets('slower is scoped and an old completion cannot retire the replay',
      (tester) async {
    await open(tester);
    await tapMiniGameKey(tester, 'mini-game-listen');
    expect(voice.playbacks.single.speedFactor, 1);
    final old = voice.playbacks.single.done;
    await tapMiniGameKey(tester, 'mini-game-slower');
    expect(voice.playbacks, hasLength(2));
    expect(voice.playbacks.last.speedFactor, .75);
    expect(voice.playbacks.last.text, voice.playbacks.first.text);
    expect(voice.stops, 2);
    old.complete();
    await settleMiniGame(tester);
    await tapMiniGameKey(tester, 'mini-game-stop');
    expect(voice.stops, 3,
        reason: 'The current replay still belongs to this visible screen.');
    expect(voice.configurations, 0);
    await close(tester);
    expect(voice.stops, 3);
  });
}
