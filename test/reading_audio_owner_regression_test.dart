import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/reading/reading_content.dart';
import 'package:lumo_lernen/features/reading/reading_lesson_companion.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

/// Controlled transport completions exercise the actual reading widgets and
/// their installed callbacks. They do not claim real device audio playback.
class _Voice extends Fake implements LumoVoice {
  int revision = 0, stops = 0;
  final playbacks = <({String text, Completer<void> done})>[];

  @override
  int get requestRevision => revision;
  @override
  Future<void> speakAndWait(String text,
      {VoiceStyle style = VoiceStyle.warm, double speedFactor = 1}) {
    revision++;
    final done = Completer<void>();
    playbacks.add((text: text, done: done));
    return done.future;
  }

  @override
  Future<void> stop() async {
    revision++;
    stops++;
  }

  void finishAll() {
    for (final playback in playbacks) {
      if (!playback.done.isCompleted) playback.done.complete();
    }
  }
}

class _Speech extends LumoSpeechListener {
  @override
  Future<void> cancel() async {}
}

const _settings = AppSettings(
    voiceEnabled: true,
    autoReadEnabled: false,
    soundEnabled: false,
    microphoneEnabled: false,
    calmMode: true);

Future<void> _frames(WidgetTester tester, [int count = 10]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
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
  });

  Future<void> open(WidgetTester tester, Widget child) async {
    await tester.binding.setSurfaceSize(const Size(800, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.runAsync(() async {
      await app.ensureSettingsLoaded();
      await app.loadLearningProfile();
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    await _frames(tester);
  }

  Future<void> tap(WidgetTester tester, String key) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await _frames(tester);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    voice.finishAll();
    await _frames(tester);
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

  Widget companion({Future<void> Function()? before}) => SingleChildScrollView(
          child: ReadingLessonCompanion(
        appState: app,
        taskId: 'reading-audio-owner',
        unit: 'Lesen',
        prompt: 'Mama liest ein Buch.',
        helpSteps: const ['Lies den sichtbaren Satz Wort für Wort.'],
        beforeInteraction: before ?? () async {},
        voice: voice,
        child: const Text('Mama liest ein Buch.'),
      ));

  for (final action in ['stop', 'pause', 'dispose']) {
    testWidgets('reading companion $action preserves a newer voice owner',
        (tester) async {
      await open(tester, companion());
      await tap(tester, 'reading-lumo-repeat');
      expect(voice.playbacks.single.text, 'Mama liest ein Buch.');
      final old = voice.playbacks.single.done;
      unawaited(voice.speakAndWait('Jetzt spricht die neue Seite.'));
      final request = voice.requestRevision;
      switch (action) {
        case 'stop':
          await tap(tester, 'reading-lumo-stop');
        case 'pause':
          pause(tester);
          await _frames(tester);
          resume(tester);
          await _frames(tester);
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
          await _frames(tester);
      }
      expect(voice.stops, 0);
      expect(voice.requestRevision, request);
      old.complete();
      await _frames(tester);
      expect(voice.stops, 0);
      expect(voice.requestRevision, request,
          reason: 'The retired completion cannot cancel the newer transport.');
      await close(tester);
      expect(voice.stops, 0);
    });
  }

  testWidgets('delayed reading preparation cannot replace a newer request',
      (tester) async {
    final gate = Completer<void>();
    await open(tester, companion(before: () => gate.future));
    await tap(tester, 'reading-lumo-repeat');
    expect(voice.playbacks, isEmpty);
    unawaited(voice.speakAndWait('Die neue Seite hat bereits begonnen.'));
    gate.complete();
    await _frames(tester);
    expect(voice.playbacks, hasLength(1));
    expect(voice.stops, 0);
    await close(tester);
  });

  testWidgets('sentence page and its nested companion release only their audio',
      (tester) async {
    await open(
        tester,
        ReadingContent(
            appState: app,
            onBack: () {},
            speechListener: _Speech(),
            voice: voice));
    expect(voice.playbacks, hasLength(1));
    expect(voice.playbacks.first.text, startsWith('Wir lesen jetzt'));
    final sentence = bus.taskContext.value!.prompt;
    await tap(tester, 'reading-lumo-repeat');
    expect(voice.stops, 1,
        reason: 'The child companion correctly retires this page greeting.');
    expect(voice.playbacks.last.text, sentence);
    unawaited(voice.speakAndWait('Eine andere Seite erklärt jetzt.'));
    final request = voice.requestRevision;
    await close(tester);
    expect(voice.stops, 1);
    expect(voice.requestRevision, request);
    expect(app.learningDailyDone(), 0);
  });

  testWidgets('sentence page pause cannot stop a newer preparing speaker',
      (tester) async {
    await open(
        tester,
        ReadingContent(
            appState: app,
            onBack: () {},
            speechListener: _Speech(),
            voice: voice));
    expect(voice.playbacks, hasLength(1));
    unawaited(voice.speakAndWait('Neue Ausgabe während der Vorbereitung.'));
    final request = voice.requestRevision;
    pause(tester);
    await _frames(tester);
    expect(voice.stops, 0);
    expect(voice.requestRevision, request);
    resume(tester);
    await _frames(tester);
    await close(tester);
    expect(voice.stops, 0);
    expect(app.learningDailyDone(), 0);
  });
}
