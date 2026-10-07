import 'dart:convert';
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
  MockStreamHandlerEventSink? playerEvents;

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
      if (call.method == 'setSourceUrl') {
        playerEvents?.success({'event': 'audio.onPrepared', 'value': true});
      }
      return null;
    });
    messenger.setMockMethodCallHandler(global, (call) async => null);
    messenger.setMockStreamHandler(
        const EventChannel('xyz.luan/audioplayers/events/lumo-voice'),
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
    LumoVoiceClips.debugSetCatalog({
      LumoVoiceClips.keyFor('Super!'): const LumoVoiceClip(
        id: 'abc123',
        text: 'Super!',
        duration: Duration(milliseconds: 600),
        envelope: [0, .5, 1, .5, 0, 0, .7, .2, 0, 0, 0, 0],
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
    expect(clips.length, greaterThan(40));
    for (final entry in clips.entries) {
      expect(LumoVoiceClips.keyFor(entry.value.text), entry.key);
      expect(File('assets/${entry.value.assetSource}').existsSync(), isTrue,
          reason: entry.value.text);
      expect(entry.value.envelope, isNotEmpty);
      expect(entry.value.duration.inMilliseconds, greaterThan(300));
    }
    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(raw['license'], contains('CC0'));
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

  test('unbekannter Text fällt auf Sprachsynthese zurück', () async {
    await LumoVoice.instance.speak('7 plus 8 ist fünfzehn');
    expect(ttsSpoken.single, contains('fünfzehn'));
    expect(playerCalls, isNot(contains('resume')));
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
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(LumoVoice.instance.status.value, VoiceStatus.idle);
    expect(LumoVoice.instance.clipMouth.value, isNull);
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
