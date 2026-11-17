import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_speech_listener.dart';
import 'package:lumo_lernen/core/lumo_story_generator.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/story/lumo_story_reader_screen.dart';
import 'package:lumo_lernen/widgets/fox/lumo_companion_requests.dart';

/// Controlled transport completions exercise the actual story screen; this
/// fixture does not claim that Android audio has been heard on a device.
class _Voice extends Fake implements LumoVoice {
  int revision = 0, stops = 0, configurations = 0;
  Completer<void>? pendingStop;
  final playbacks =
      <({String text, double speedFactor, Completer<void> done})>[];

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

class _Speech extends LumoSpeechListener {
  @override
  Future<void> cancel() async {}
}

class _StoryState extends LumoAppState {
  int generation = 0;
  @override
  int get profileGeneration => generation;
  @override
  Future<void> ensureSettingsLoaded() async {}

  void changeProfile() {
    generation++;
    notifyListeners();
  }
}

const _story = LumoStory(
  title: 'Lumo und das Buch',
  heroName: 'Lumo',
  location: 'Wald',
  theme: 'Lesen',
  gradeLevel: 2,
  newWords: [],
  pages: [
    LumoStoryPage(
        pageNum: 1, text: 'Lumo findet ein Buch im Wald.', imagePrompt: ''),
    LumoStoryPage(
        pageNum: 2, text: 'Lumo liest das Buch am Bach.', imagePrompt: ''),
  ],
  bookQuestions: [
    StoryBookQuestion('Wo liest Lumo?', 'am Bach', ['am Bach', 'im Haus'], 2),
  ],
);

Future<void> _frames(WidgetTester tester) async {
  await tester.pump();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump(const Duration(milliseconds: 400));
  expect(tester.takeException(), isNull);
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pump();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await _frames(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bus = LumoCompanionRequests.instance;
  late _StoryState app;
  late _Voice voice;
  late _Speech speech;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bus.clearLearningScope();
    app = _StoryState();
    app.state.settings = const AppSettings(
        voiceEnabled: true,
        autoReadEnabled: false,
        microphoneEnabled: false,
        soundEnabled: false,
        calmMode: true,
        reduceAnimations: true);
    voice = _Voice();
    speech = _Speech();
  });

  tearDown(() {
    voice.finishAll();
    speech.dispose();
    app.dispose();
  });

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
        home: LumoStoryReaderScreen(
            story: _story,
            storyId: 'audio-owner-book',
            appState: app,
            speechListener: speech,
            voice: voice)));
    await _frames(tester);
    expect(bus.taskContext.value?.activity, 'story_reading');
    expect(voice.playbacks, isEmpty);
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    voice.finishAll();
    await _frames(tester);
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

  for (final action in [
    'stop',
    'pause',
    'dispose',
    'profile',
    'next-page',
    'book-questions',
  ]) {
    testWidgets('story $action preserves a newer audio owner', (tester) async {
      await open(tester);
      if (action == 'book-questions') {
        await _tap(tester, 'lumo-story-continue');
      }
      await _tap(tester, 'story-repeat');
      expect(voice.playbacks.single.text,
          _story.pages[action == 'book-questions' ? 1 : 0].text);
      expect(voice.stops, 1);
      final old = voice.playbacks.single.done;
      unawaited(voice.speakAndWait('Jetzt spricht die neue Seite.'));
      final request = voice.requestRevision;
      switch (action) {
        case 'stop':
          await _tap(tester, 'story-stop');
        case 'pause':
          pause(tester);
          await _frames(tester);
          resume(tester);
          await _frames(tester);
        case 'dispose':
          await tester.pumpWidget(const SizedBox.shrink());
          await _frames(tester);
        case 'profile':
          app.changeProfile();
          await _frames(tester);
        case 'next-page':
        case 'book-questions':
          await _tap(tester, 'lumo-story-continue');
          expect(bus.taskContext.value!.taskId,
              endsWith(action == 'next-page' ? ':page:1' : ':question:0'));
      }
      expect(voice.stops, 1);
      expect(voice.requestRevision, request);
      old.complete();
      await _frames(tester);
      expect(voice.stops, 1);
      expect(voice.requestRevision, request);
      expect(voice.configurations, 0,
          reason: 'Retired cleanup must not change the new speaker\'s tempo.');
      expect(app.state.stars, 0);
      expect(app.state.xp, 0);
      await close(tester);
      expect(voice.stops, 1);
      expect(voice.requestRevision, request);
    });
  }

  testWidgets('delayed story preparation cannot replace a newer speaker',
      (tester) async {
    await open(tester);
    final gate = Completer<void>();
    voice.pendingStop = gate;
    await _tap(tester, 'story-repeat');
    expect(voice.playbacks, isEmpty);
    unawaited(voice.speakAndWait('Die neue Seite erklärt schon.'));
    final request = voice.requestRevision;
    gate.complete();
    await _frames(tester);
    expect(voice.playbacks, hasLength(1));
    expect(voice.requestRevision, request);
    expect(voice.configurations, 0);
    await close(tester);
    expect(voice.stops, 1);
    expect(voice.requestRevision, request);
  });

  for (final boundary in ['stop', 'next-page', 'covered-route', 'task-owner']) {
    testWidgets('story $boundary rejects speech awaiting stop completion',
        (tester) async {
      await open(tester);
      final gate = Completer<void>();
      voice.pendingStop = gate;
      await _tap(tester, 'story-repeat');
      expect(voice.playbacks, isEmpty);
      switch (boundary) {
        case 'stop':
          await _tap(tester, 'story-stop');
        case 'next-page':
          await _tap(tester, 'lumo-story-continue');
        case 'covered-route':
          final context = tester.element(find.byType(LumoStoryReaderScreen));
          unawaited(Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Andere Seite')))));
          await _frames(tester);
        case 'task-owner':
          bus.publishTask(const LumoCompanionTaskContext(
              subject: 'Deutsch',
              unit: 'Lesen',
              prompt: 'Eine andere Aufgabe.',
              taskId: 'another-reading-task',
              ownerSection: 'reading',
              profileGeneration: 0));
          await _frames(tester);
      }
      gate.complete();
      await _frames(tester);
      expect(voice.playbacks, isEmpty);
      expect(voice.configurations, 0);
      expect(app.state.stars, 0);
      expect(app.state.xp, 0);
      await close(tester);
    });
  }

  testWidgets('slower is scoped and the current story replay still stops',
      (tester) async {
    await open(tester);
    await _tap(tester, 'story-repeat');
    expect(voice.playbacks.single.speedFactor, 1);
    final old = voice.playbacks.single.done;
    await _tap(tester, 'story-slower');
    expect(voice.playbacks, hasLength(2));
    expect(voice.playbacks.last.text, _story.pages.first.text);
    expect(voice.playbacks.last.speedFactor, .75);
    expect(voice.stops, 2);
    old.complete();
    await _frames(tester);
    await _tap(tester, 'story-stop');
    expect(voice.stops, 3,
        reason: 'The old completion cannot retire the current replay.');
    expect(voice.configurations, 0);
    await close(tester);
    expect(voice.stops, 3);
  });
}
