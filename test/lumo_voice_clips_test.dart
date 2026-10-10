import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const tts = MethodChannel('flutter_tts');
  const players = MethodChannel('xyz.luan/audioplayers');
  const global = MethodChannel('xyz.luan/audioplayers.global');
  final ttsSpoken = <String>[];
  final playerCalls = <String>[];
  final playbackRates = <double>[];
  int nativePositionMs = 0;
  MockStreamHandlerEventSink? playerEvents;
  Completer<void>? startingPlayback;
  Completer<void>? playbackEntered;

  // Der Lumo-Player ist ein Singleton: Plattform-Mocks einmal registrieren,
  // damit sein Ereignisstrom über alle Tests offen bleibt.
  setUpAll(() {
    AudioCache.instance = _FakeAudioCache();
    messenger.setMockMethodCallHandler(tts, (call) async {
      if (call.method == 'getVoices') return const [];
      if (call.method == 'speak') ttsSpoken.add('${call.arguments}');
      return 1;
    });
    messenger.setMockMethodCallHandler(players, (call) async {
      playerCalls.add(call.method);
      if (call.method == 'setPlaybackRate') {
        playbackRates.add((call.arguments['playbackRate'] as num).toDouble());
      }
      if (call.method == 'getCurrentPosition') return nativePositionMs;
      if (call.method == 'resume' && startingPlayback != null) {
        playbackEntered!.complete();
        await startingPlayback!.future;
      }
      if (call.method == 'setSourceUrl') {
        playerEvents?.success({'event': 'audio.onPrepared', 'value': true});
      }
      return null;
    });
    messenger.setMockMethodCallHandler(global, (call) async => null);
    messenger.setMockStreamHandler(
        const EventChannel('xyz.luan/audioplayers/events/lumo-sulafat'),
        MockStreamHandler.inline(onListen: (_, sink) {
      playerEvents = sink;
    }));
    messenger.setMockStreamHandler(
        const EventChannel('xyz.luan/audioplayers.global/events'),
        MockStreamHandler.inline(onListen: (_, __) {}));
  });

  setUp(() {
    ttsSpoken.clear();
    playerCalls.clear();
    playbackRates.clear();
    nativePositionMs = 0;
    LumoVoiceClips.debugSetCatalog({
      LumoVoiceClips.keyFor('Super!'): const LumoVoiceClip(
        id: 'abc123',
        text: 'Super!',
        duration: Duration(milliseconds: 600),
        envelope: [0, .5, 1, .5, 0, 0, .7, .2, 0, 0, 0, 0],
        fps: 20,
      ),
      LumoVoiceClips.keyFor(
              'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!'):
          const LumoVoiceClip(
        id: 'c3034465f7dd',
        text:
            'Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues!',
        duration: Duration(milliseconds: 6379),
        envelope: [0, .5, 1, .7, .5, .2, 0],
        fps: 20,
      ),
    });
    LumoVoice.instance
      ..clipsEnabled = true
      ..isEnabled = true;
  });

  tearDown(() async {
    await LumoVoice.instance.stop();
    LumoVoice.instance.clipsEnabled = false;
    LumoVoiceClips.debugSetCatalog(null);
  });

  test('Schlüssel ignorieren Satzzeichen, Groß-/Kleinschreibung und Abstände',
      () {
    expect(
        LumoVoiceClips.keyFor('  Fast! Schau nochmal.'), 'fast schau nochmal');
    expect(LumoVoiceClips.keyFor('3 plus 4 - wie viel ist das?'),
        '3 plus 4 wie viel ist das');
    expect(LumoVoiceClips.keyFor('Schön, dass du da bist'),
        'schön dass du da bist');
  });

  test('ausgelieferter Katalog ist gültig und jede Datei existiert', () {
    final file = File(LumoVoiceClips.catalogAsset);
    expect(file.existsSync(), isTrue, reason: 'Katalog fehlt');
    final clips = LumoVoiceClips.parseCatalog(file.readAsStringSync());
    expect(clips.length, greaterThanOrEqualTo(6));
    for (final entry in clips.entries) {
      expect(LumoVoiceClips.keyFor(entry.value.text), entry.key);
      expect(File('assets/${entry.value.assetSource}').existsSync(), isTrue,
          reason: entry.value.text);
      expect(entry.value.envelope, isNotEmpty);
      expect(entry.value.duration.inMilliseconds, greaterThan(300));
    }
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(raw['generation'], 'Gemini TTS / Sulafat');
    expect(raw['license'], isNot(contains('CC0')));
    // Feste Lob-/Trostsätze der App sind abgedeckt.
    for (final phrase in [
      'Super!',
      'Fast! Schau nochmal.',
      'Du schaffst das'
    ]) {
      final hit =
          clips.keys.any((k) => k.contains(LumoVoiceClips.keyFor(phrase)));
      expect(hit, isTrue, reason: phrase);
    }
  });

  test('bekannter Satz spielt Lumo-Clip, bewegt den Mund und stoppt sauber',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    expect(ttsSpoken, isEmpty, reason: 'Clip statt Geräte-Stimme');
    expect(playerCalls, contains('resume'));
    expect(voice.status.value, VoiceStatus.speaking);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    expect(voice.clipMouth.value, isNotNull);
    await voice.stop();
    expect(voice.status.value, VoiceStatus.idle);
    expect(voice.clipMouth.value, isNull);
    expect(playerCalls, contains('stop'));
  });

  test('unbekannter Text fällt niemals auf die alte Android-Stimme zurück',
      () async {
    await LumoVoice.instance.configure(cloudVoiceEnabled: false);
    await LumoVoice.instance.speak('7 plus 8 ist fünfzehn');
    expect(ttsSpoken, isEmpty);
    expect(playerCalls, isNot(contains('resume')));
    expect(LumoVoice.instance.status.value, VoiceStatus.error);
  });

  test('Eltern-Stimmprobe verwendet die originale Lumo-Stimme', () async {
    final voice = LumoVoice.instance;
    final startsBefore = voice.startedPlaybackCount;
    await voice.configure(enabled: true, rate: 0.50, pitch: 1.15);
    await voice.test();
    expect(ttsSpoken, isEmpty,
        reason: 'Lumo-Stimmprobe nicht durch TTS ersetzen');
    expect(playerCalls, contains('resume'),
        reason: 'Originalaufnahme erwartet');
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.startedPlaybackCount, startsBefore + 1);
    expect(voice.lastStartedAudioIdentity, 'Originalaufnahme c3034465f7dd.m4a');
    await voice.stop();
    await voice.configure(rate: 0.35, pitch: 1.0);
  });

  test('every supported tempo reaches native audio without an upper plateau',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    for (final rate in [.25, .35, .50, .55]) {
      await voice.configure(rate: rate);
      expect(playbackRates.last, closeTo(rate / .35, .00001));
    }
    await voice.configure(rate: .90);
    expect(playbackRates.last, 1.60);
    await voice.configure(rate: .10);
    expect(playbackRates.last, .70);
    await voice.configure(rate: .35);
  });

  test('speakAndWait awaits actual native completion, not only resume',
      () async {
    var completed = false;
    final speaking =
        LumoVoice.instance.speakAndWait('Super!').then((_) => completed = true);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(LumoVoice.instance.status.value, VoiceStatus.speaking);
    expect(completed, isFalse);
    playerEvents!.success({'event': 'audio.onComplete'});
    await speaking;
    expect(completed, isTrue);
    expect(LumoVoice.instance.status.value, VoiceStatus.idle);
  });

  test('mouth follows native media position and closes in waveform silence',
      () async {
    nativePositionMs = 100;
    await LumoVoice.instance.speak('Super!');
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(LumoVoice.instance.clipMouth.value, closeTo(1, .001));
    nativePositionMs = 200;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    expect(LumoVoice.instance.clipMouth.value, 0);
  });

  test(
      'allen Modulen stehen unterschiedliche emotionale Sprechweisen zur Verfuegung',
      () {
    expect(LumoVoice.suggestedStyle('Super!'), VoiceStyle.celebrate);
    expect(
        LumoVoice.suggestedStyle('Fast! Schau nochmal.'), VoiceStyle.comfort);
    expect(LumoVoice.suggestedStyle('Hallo!'), VoiceStyle.greeting);
    expect(
        LumoVoice.suggestedStyle('Wie viele sind das?'), VoiceStyle.question);
    expect(LumoVoice.suggestedStyle('Schau mal so:'), VoiceStyle.explain);
    expect(LumoVoice.suggestedStyle('Drei plus vier ist sieben.'),
        VoiceStyle.warm);
  });

  test('stumm geschaltet spricht weder Clip noch Synthese', () async {
    LumoVoice.instance.isEnabled = false;
    await LumoVoice.instance.speak('Super!');
    expect(ttsSpoken, isEmpty);
    expect(playerCalls, isNot(contains('resume')));
    LumoVoice.instance.isEnabled = true;
  });

  test('Clip endet nach seiner Dauer auch ohne Abschluss-Ereignis', () async {
    await LumoVoice.instance.speak('Super!');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(LumoVoice.instance.status.value, VoiceStatus.idle);
    expect(LumoVoice.instance.clipMouth.value, isNull);
  });

  test('mute during native playback startup stops the late-starting clip',
      () async {
    startingPlayback = Completer<void>();
    playbackEntered = Completer<void>();
    final voice = LumoVoice.instance;
    final startsBefore = voice.startedPlaybackCount;
    final speaking = voice.speak('Super!');
    await playbackEntered!.future;
    await voice.configure(enabled: false);
    startingPlayback!.complete();
    await speaking;
    startingPlayback = null;
    playbackEntered = null;
    expect(playerCalls.where((call) => call == 'stop').length,
        greaterThanOrEqualTo(2));
    expect(voice.status.value, VoiceStatus.idle);
    expect(voice.clipMouth.value, isNull);
    expect(voice.startedPlaybackCount, startsBefore);
    expect(ttsSpoken, isEmpty);
  });

  test('Musik wird während Lumo spricht abgesenkt', () async {
    final voice = LumoVoice.instance;
    final music = LumoMusic.instance;
    expect(music.targetVolume, greaterThan(LumoMusic.duckedVolume));
    await voice.speak('Super!');
    expect(music.targetVolume, LumoMusic.duckedVolume);
    await voice.stop();
    expect(music.targetVolume, greaterThan(LumoMusic.duckedVolume));
  });

  testWidgets('Seite verlassen beendet Lumos Sprechen', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      navigatorObservers: [LumoVoiceRouteObserver()],
      home: const SizedBox(),
    ));
    key.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Aufgabe'))));
    await tester.pumpAndSettle();
    await tester.runAsync(() => LumoVoice.instance.speak('Super!'));
    expect(LumoVoice.instance.status.value, VoiceStatus.speaking);
    key.currentState!.pop();
    // Kein pumpAndSettle: der echte Clip-Takt läuft außerhalb der Testuhr.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(LumoVoice.instance.status.value, VoiceStatus.idle);
  });
}

/// Liefert Clip-Pfade ohne Asset-Kopie in ein Temp-Verzeichnis.
class _FakeAudioCache extends AudioCache {
  @override
  Future<Uri> load(String fileName) async => Uri.file('/tmp/$fileName');
}
