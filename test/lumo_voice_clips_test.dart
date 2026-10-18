import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/features/learning_modules/lumo_phrases.dart';
import 'package:lumo_lernen/widgets/lumo_speech_controls.dart';

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
  Completer<void>? pausingPlayback;
  Completer<void>? pauseEntered;
  Completer<void>? stoppingPlayback;
  Completer<void>? stopEntered;

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
        if (!playbackEntered!.isCompleted) playbackEntered!.complete();
        await startingPlayback!.future;
      }
      if (call.method == 'pause' && pausingPlayback != null) {
        if (!pauseEntered!.isCompleted) pauseEntered!.complete();
        await pausingPlayback!.future;
      }
      if (call.method == 'stop' && stoppingPlayback != null) {
        final stopping = stoppingPlayback!;
        stoppingPlayback = null;
        stopEntered!.complete();
        await stopping.future;
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

  setUp(() async {
    await LumoVoice.instance.configure(
      identity: LumoVoiceIdentity.sulafatOriginal,
      localVoiceLicenseAccepted: false,
    );
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
    await LumoVoice.instance.clearParentSpeechAuthorization();
    await LumoVoice.instance.configure(cloudVoiceEnabled: false);
    LumoVoice.instance.clipsEnabled = false;
    LumoVoiceClips.debugSetCatalog(null);
    await LumoVoice.instance.configure(identity: LumoVoiceIdentity.freeOffline);
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

  test('all six original voice binaries retain their verified SHA-256', () {
    const expected = {
      'c3034465f7dd':
          'ac64224d3db9cfb34130606ec737a17dd0107debd80182c33c1bc641809929ef',
      '341f8117fda1':
          'ad54dd28afc9e15321040fbeed99c36542c3894dd2cb0fe7b81b78ad75588090',
      'a3e9510a5f01':
          '9a38d73f589b661cb0694e23d3acd58c378c95a991d4c50358254e1ec4f30bd9',
      '19495758a130':
          '17812be55870e7594f377f83772b2dfdbd49759d439b594548a7e55369fc85c2',
      '06e26a73d0b4':
          'db3fdf84925f80319e946e978f860ce97020e8bafd944ef02046e5fc9f48e8f8',
      'b79005f3d3d8':
          '465d0c1544803137f48f64af1949495246ab22215824b05dbf62631a9a582e49',
    };
    for (final entry in expected.entries) {
      expect(
          sha256
              .convert(File(
                'assets/audio/voice/lumo/${entry.key}.m4a',
              ).readAsBytesSync())
              .toString(),
          entry.value,
          reason: entry.key);
    }
  });

  test('fixed emotional feedback uses only semantically appropriate originals',
      () async {
    LumoVoiceClips.debugSetCatalog(null);
    await LumoVoiceClips.ensureLoaded();
    final phrases = <String>[
      for (var i = 0; i < 12; i++) LumoPhrases.correct(),
      for (var i = 0; i < 7; i++) LumoPhrases.wrongGentle(),
      for (var i = 0; i < 5; i++) LumoPhrases.greeting(),
      for (var i = 0; i < 5; i++) LumoPhrases.celebrate(),
      for (var i = 0; i < 5; i++) LumoPhrases.comfort(),
    ];
    for (final text in phrases) {
      expect(LumoVoiceClips.lookup(text), isNotNull, reason: text);
    }
    for (final text in [
      'Von acht bis zehn fehlen zwei. Wie viele bleiben von sechs übrig?',
      'Sieben plus fünf ist zwölf.',
      'Lies das Wort Sonne.',
      'Lumo, warum ist sieben plus fünf gleich zwölf?',
      for (var i = 0; i < 5; i++) LumoPhrases.hint(),
    ]) {
      expect(LumoVoiceClips.lookup(text), isNull,
          reason:
              'A generic clip cannot masquerade as this explanation: $text');
    }
    expect(LumoVoiceClips.count, 6,
        reason: 'Aliases are not newly recorded sentences.');
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

  test('missing next-task audio must not cut off an original feedback clip',
      () async {
    final voice = LumoVoice.instance;
    await voice.configure(cloudVoiceEnabled: false);
    await voice.speak('Super!');
    final stopsBefore = playerCalls.where((call) => call == 'stop').length;
    final startsBefore = voice.startedPlaybackCount;

    await voice.speak('Acht plus sechs. Wie viel ist das?');

    expect(playerCalls.where((call) => call == 'stop').length, stopsBefore,
        reason: 'A missing lesson recording is not a replacement for praise.');
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.startedPlaybackCount, startsBefore);
    expect(voice.lastError.value, isNotNull,
        reason: 'The unavailable next utterance must remain understandable.');
    expect(ttsSpoken, isEmpty);
  });

  test(
      'an online toggle without a parent session neither uploads nor cuts praise',
      () async {
    final voice = LumoVoice.instance;
    await voice.clearParentSpeechAuthorization();
    await voice.configure(cloudVoiceEnabled: true);
    await voice.speak('Super!');
    final stopsBefore = playerCalls.where((call) => call == 'stop').length;
    var connections = 0;
    await HttpOverrides.runZoned(
      () => voice.speak('Von acht bis zehn fehlen zwei.'),
      createHttpClient: (_) {
        connections++;
        throw StateError('No parent session, no upload.');
      },
    );
    expect(connections, 0);
    expect(playerCalls.where((call) => call == 'stop').length, stopsBefore);
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.lastError.value, contains('Elternanmeldung'));
    expect(ttsSpoken, isEmpty);
  });

  test('a missing parent session from the adapter keeps learning text local',
      () async {
    final voice = LumoVoice.instance;
    await voice.configure(
      cloudVoiceEnabled: true,
      parentSpeechAuthorization: () async => null,
    );
    var connections = 0;
    await HttpOverrides.runZoned(
      () => voice.speak('Hier sind drei Gruppen mit jeweils zwei Äpfeln.'),
      createHttpClient: (_) {
        connections++;
        throw StateError('An adapter without a session cannot upload.');
      },
    );
    expect(connections, 0);
    expect(voice.status.value, VoiceStatus.error);
    expect(voice.lastError.value, contains('Elternanmeldung'));
    expect(playerCalls, isNot(contains('resume')));
  });

  test(
      'navigation cancels a late parent session before any learning text upload',
      () async {
    final voice = LumoVoice.instance;
    final session = Completer<String?>();
    final entered = Completer<void>();
    await voice.configure(
      cloudVoiceEnabled: true,
      parentSpeechAuthorization: () {
        entered.complete();
        return session.future;
      },
    );
    var connections = 0;
    final operation = HttpOverrides.runZoned(
      () => voice.speak('Probiere zuerst den Schritt bis zum Zehner.'),
      createHttpClient: (_) {
        connections++;
        throw StateError('A cancelled task cannot upload.');
      },
    );
    await entered.future;
    await voice.stop();
    session.complete('fake-parent-session-only-in-local-tests');
    await operation;
    expect(connections, 0);
    expect(voice.status.value, VoiceStatus.idle);
    expect(playerCalls, isNot(contains('resume')));
  });

  test('saving an unchanged offline consent must not stop the voice sample',
      () async {
    final voice = LumoVoice.instance;
    await voice.configure(cloudVoiceEnabled: false);
    await voice.test();
    final stopsBefore = playerCalls.where((call) => call == 'stop').length;

    await voice.configure(cloudVoiceEnabled: false, rate: .50);

    expect(playerCalls.where((call) => call == 'stop').length, stopsBefore,
        reason: 'A speed setting may update playback, not cut the sample.');
    expect(voice.status.value, VoiceStatus.speaking);
    expect(playbackRates.last, closeTo(.50 / .35, .00001));
    await voice.configure(rate: .35);
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

  test('watchdog stops missing native completion without claiming success',
      () async {
    final completionsBefore = LumoVoice.instance.completedPlaybackCount;
    await LumoVoice.instance.speak('Super!');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(LumoVoice.instance.status.value, VoiceStatus.error);
    expect(LumoVoice.instance.clipMouth.value, isNull);
    expect(LumoVoice.instance.completedPlaybackCount, completionsBefore);
    expect(LumoVoice.instance.lastError.value, contains('nicht bestätigt'));
  });

  test('pause survives wall-clock timeout and resumes the same native source',
      () async {
    final voice = LumoVoice.instance;
    var finished = false;
    final completionsBefore = voice.completedPlaybackCount;
    final speaking = voice.speakAndWait('Super!').then((_) => finished = true);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final startsBefore = voice.startedPlaybackCount;
    final sourcesBefore =
        playerCalls.where((call) => call == 'setSourceUrl').length;
    await voice.pause();

    expect(voice.status.value, VoiceStatus.paused);
    expect(voice.clipMouth.value, 0);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(voice.status.value, VoiceStatus.paused);
    expect(finished, isFalse);
    expect(voice.completedPlaybackCount, completionsBefore);

    await voice.resume();
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.startedPlaybackCount, startsBefore);
    expect(playerCalls.where((call) => call == 'setSourceUrl').length,
        sourcesBefore,
        reason: 'Resume cannot seek, upload or create another source.');
    playerEvents!.success({'event': 'audio.onComplete'});
    await speaking;
    expect(voice.completedPlaybackCount, completionsBefore + 1);
    expect(voice.status.value, VoiceStatus.idle);
  });

  test('a missing offline sentence cannot destroy a paused recording',
      () async {
    final voice = LumoVoice.instance;
    await voice.configure(cloudVoiceEnabled: false);
    await voice.speak('Super!');
    await voice.pause();
    final stopsBefore = playerCalls.where((call) => call == 'stop').length;
    await voice.speak('Hier sind drei Gruppen mit jeweils zwei Äpfeln.');
    expect(voice.status.value, VoiceStatus.paused);
    expect(playerCalls.where((call) => call == 'stop').length, stopsBefore);
    await voice.resume();
    expect(voice.status.value, VoiceStatus.speaking);
  });

  test('stop cancels a paused source and late resume cannot revive it',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    await voice.pause();
    await voice.stop();
    final callsBefore = playerCalls.length;
    await voice.resume();
    expect(voice.status.value, VoiceStatus.idle);
    expect(playerCalls.length, callsBefore);
  });

  test('a new source waits for an older native stop acknowledgement', () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    final startsBefore = voice.startedPlaybackCount;
    final stopping = stoppingPlayback = Completer<void>();
    stopEntered = Completer<void>();
    final stopped = voice.stop();
    await stopEntered!.future;

    final next = voice.test();
    // Drain the method-channel work while the previous stop is held open.
    // No newer native source may start and then be reset by its late reply.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final startsWhileStopping = voice.startedPlaybackCount;
    stopping.complete();
    await stopped;
    await next;
    stopEntered = null;

    expect(startsWhileStopping, startsBefore,
        reason: 'An unacknowledged stop still owns the native player.');
    expect(voice.startedPlaybackCount, startsBefore + 1);
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.lastStartedAudioIdentity, 'Originalaufnahme c3034465f7dd.m4a');
    expect(voice.clipMouth.value, isNotNull);
  });

  test('late native pause cannot pause or relabel a newly selected source',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    pausingPlayback = Completer<void>();
    pauseEntered = Completer<void>();
    final pausing = voice.pause();
    await pauseEntered!.future;
    final next = voice.test();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(voice.lastStartedAudioIdentity, 'Originalaufnahme abc123.m4a');
    final gate = pausingPlayback!;
    pausingPlayback = null;
    pauseEntered = null;
    gate.complete();
    await pausing;
    await next;
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.lastStartedAudioIdentity, 'Originalaufnahme c3034465f7dd.m4a');
  });

  test('mute during a late native resume stops it again without a new start',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    await voice.pause();
    final startsBefore = voice.startedPlaybackCount;
    startingPlayback = Completer<void>();
    playbackEntered = Completer<void>();
    final resuming = voice.resume();
    await playbackEntered!.future;
    await voice.configure(enabled: false);
    final stopsBefore = playerCalls.where((call) => call == 'stop').length;
    final gate = startingPlayback!;
    startingPlayback = null;
    playbackEntered = null;
    gate.complete();
    await resuming;
    expect(playerCalls.where((call) => call == 'stop').length, stopsBefore + 1);
    expect(voice.status.value, VoiceStatus.idle);
    expect(voice.startedPlaybackCount, startsBefore);
    expect(voice.clipMouth.value, isNull);
    expect(ttsSpoken, isEmpty);
  });

  test('missing text during native preparation still allows the original clip',
      () async {
    final voice = LumoVoice.instance;
    await voice.configure(cloudVoiceEnabled: false);
    startingPlayback = Completer<void>();
    playbackEntered = Completer<void>();
    final speaking = voice.speak('Super!');
    await playbackEntered!.future;
    await voice.speak('Welche Jahreszeit kommt nach dem Winter?');
    final gate = startingPlayback!;
    startingPlayback = null;
    playbackEntered = null;
    gate.complete();
    await speaking;
    expect(voice.status.value, VoiceStatus.speaking);
    expect(voice.lastStartedAudioIdentity, 'Originalaufnahme abc123.m4a');
    expect(voice.lastError.value, isNotNull);
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
    await voice.pause();
    expect(music.targetVolume, greaterThan(LumoMusic.duckedVolume));
    await voice.resume();
    expect(music.targetVolume, LumoMusic.duckedVolume);
    await voice.stop();
    expect(music.targetVolume, greaterThan(LumoMusic.duckedVolume));
  });

  testWidgets(
      'visible speech controls pause, resume and stop the actual player',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LumoSpeechControls(showStopWhenIdle: true)),
    ));
    await tester.runAsync(() => LumoVoice.instance.speak('Super!'));
    await tester.pump();
    // Native audio callbacks belong to the real event loop, not Flutter's
    // fake animation clock. Wait for the observed state after the real tap.
    await tester.runAsync(() async {
      final paused = _waitForVoiceStatus(VoiceStatus.paused);
      await tester.tap(find.text('Pause'));
      await paused;
    });
    await tester.pump();
    expect(LumoVoice.instance.status.value, VoiceStatus.paused);
    expect(find.text('Fortsetzen'), findsOneWidget);
    await tester.runAsync(() async {
      final speaking = _waitForVoiceStatus(VoiceStatus.speaking);
      await tester.tap(find.text('Fortsetzen'));
      await speaking;
    });
    await tester.pump();
    expect(LumoVoice.instance.status.value, VoiceStatus.speaking);
    await tester.runAsync(() async {
      final idle = _waitForVoiceStatus(VoiceStatus.idle);
      await tester.tap(find.text('Stopp'));
      await idle;
    });
    await tester.pump();
    expect(LumoVoice.instance.status.value, VoiceStatus.idle);
    expect(ttsSpoken, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Seite verlassen beendet Lumos Sprechen', (tester) async {
    final key = GlobalKey<NavigatorState>();
    // The observer stops native audio even for the initial route. Build and
    // navigate on the same real event loop as playback, not the fake clock.
    await tester.runAsync(() => tester.pumpWidget(MaterialApp(
          navigatorKey: key,
          navigatorObservers: [LumoVoiceRouteObserver()],
          home: const SizedBox(),
        )));
    await tester.runAsync(() async {
      key.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Aufgabe'))));
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() => LumoVoice.instance.speak('Super!'));
    expect(LumoVoice.instance.status.value, VoiceStatus.speaking);
    await tester.runAsync(() async => key.currentState!.pop());
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

Future<void> _waitForVoiceStatus(VoiceStatus expected) async {
  final status = LumoVoice.instance.status;
  if (status.value == expected) return;
  final completed = Completer<void>();
  void changed() {
    if (status.value == expected && !completed.isCompleted) {
      completed.complete();
    }
  }

  status.addListener(changed);
  try {
    await completed.future.timeout(const Duration(seconds: 2));
  } finally {
    status.removeListener(changed);
  }
}
