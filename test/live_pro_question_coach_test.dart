import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/live/lumo_live_pro_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

/// Synthetic device callbacks exercise the actual LivePro screen and evaluator.
/// These are not a microphone recording or Android recognition acceptance.
class _Speech extends LumoSpeechListener {
  final finals = <ValueChanged<String>>[];
  ValueChanged<String>? partial;
  Completer<bool>? pendingInitialize;
  bool active = false;
  int starts = 0;
  @override
  bool get listening => active;
  @override
  bool get available => true;
  @override
  Future<bool> initialize() => pendingInitialize?.future ?? Future.value(true);
  @override
  Future<void> startListening(
      {ValueChanged<String>? onResult,
      ValueChanged<String>? onFinalResult,
      VoidCallback? onNoMatch}) async {
    starts++;
    active = true;
    partial = onResult;
    finals.add(onFinalResult!);
    notifyListeners();
  }

  void finish(String text) {
    active = false;
    finals.last(text);
    notifyListeners();
  }

  @override
  Future<void> cancel() async {
    active = false;
  }
}

const _settings = AppSettings(
    voiceEnabled: false,
    autoReadEnabled: false,
    microphoneEnabled: true,
    soundEnabled: false,
    calmMode: true);

Future<void> _frames(WidgetTester tester, [int count = 12]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  late LumoAppState app;
  late _Speech speech;
  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'lumo_app_settings_v1': jsonEncode(_settings.toJson())});
    bus.clearLearningScope();
    LumoVoice.instance.isEnabled = false;
    speech = _Speech();
    app = LumoAppState(walletRepository: RewardWalletRepository());
  });
  tearDown(() {
    speech.dispose();
    app.dispose();
    LumoVoice.instance.isEnabled = true;
  });

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
    });
    await tester.pumpWidget(MaterialApp(
        home: LumoLiveProScreen(appState: app, speechListener: speech)));
    await _frames(tester);
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final action = find.text(text).last;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await _frames(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await _frames(tester);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
      'final text replaces a partial and participation follows only a corrected confirmation',
      (tester) async {
    await open(tester);
    expect(bus.taskContext.value!.ownerSection, 'live');
    expect(bus.taskContext.value!.subject, 'Deutsch');
    await tap(tester, 'Sprechen');
    expect(speech.starts, 1);
    speech.partial!('Drei');
    await _frames(tester);
    expect((app.state.stars, app.state.xp), (0, 0));
    speech.finish('dreizehn');
    await _frames(tester);
    final input = find.byKey(const ValueKey('game-answer-proposal'));
    expect(tester.widget<TextField>(input).controller!.text, 'dreizehn');
    expect((app.state.stars, app.state.xp), (0, 0));
    await tester.ensureVisible(input);
    await tester.enterText(input, 'Haus');
    final oldConfirm = tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Antwort bestätigen'))
        .onPressed!;
    await tap(tester, 'Antwort bestätigen');
    expect(bus.taskContext.value!.lastAnswer, 'Haus');
    expect(bus.taskContext.value!.lastCorrect, isNull,
        reason: 'Word exploration is participation, not invented correctness.');
    expect((app.state.stars, app.state.xp), (1, 5));
    speech.finals.single('Drei');
    oldConfirm();
    await _frames(tester);
    expect((app.state.stars, app.state.xp), (1, 5));
    await close(tester);
  });

  testWidgets(
      'Stop invalidates a final candidate and delayed old recognizer callbacks',
      (tester) async {
    await open(tester);
    await tap(tester, 'Sprechen');
    speech.finish('Banane');
    await _frames(tester);
    final oldIdentity = bus.learningIdentity.value!;
    final oldConfirm = tester
        .widget<OutlinedButton>(
            find.widgetWithText(OutlinedButton, 'Antwort bestätigen'))
        .onPressed!;
    await tap(tester, 'Stopp');
    speech.finals.single('Banane');
    oldConfirm();
    await _frames(tester);
    expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
    expect(bus.isCurrentLearningIdentity(oldIdentity), isFalse);
    expect((app.state.stars, app.state.xp), (0, 0));
    await close(tester);
  });

  testWidgets('same-mode return and Safari skip reject former task recognition',
      (tester) async {
    await open(tester);
    await tap(tester, 'Sprechen');
    final old = speech.finals.single;
    final wordTask = bus.taskContext.value!.taskId;
    await tap(tester, 'Tier-Safari');
    expect(bus.taskContext.value!.subject, 'Sachunterricht');
    final safariTask = bus.taskContext.value!.taskId;
    await tap(tester, 'Sprechen');
    final safariFinal = speech.finals.last;
    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await _frames(tester);
    expect(bus.taskContext.value!.taskId, isNot(safariTask));
    safariFinal('ein blaues Fahrrad');
    await tap(tester, 'Wort-Magie');
    old('Banane');
    await _frames(tester);
    expect(bus.taskContext.value!.taskId, isNot(wordTask));
    expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
    expect((app.state.stars, app.state.xp), (0, 0));
    await close(tester);
  });

  testWidgets(
      'pause during recognizer initialization cannot start capture after resume',
      (tester) async {
    speech.pendingInitialize = Completer<bool>();
    await open(tester);
    await tap(tester, 'Sprechen');
    expect(speech.starts, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await _frames(tester);
    expect(bus.taskContext.value, isNull);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    speech.pendingInitialize!.complete(true);
    await _frames(tester);
    expect(speech.starts, 0);
    expect(find.byKey(const ValueKey('game-answer-proposal')), findsNothing);
    expect((app.state.stars, app.state.xp), (0, 0));
    await close(tester);
  });
}
