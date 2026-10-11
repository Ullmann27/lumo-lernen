import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_offline_voice_client.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/core/lumo_sulafat_client.dart';

import 'helpers/lumo_native_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final native = LumoNativeAudioHarness();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final localCalls = <MethodCall>[];
  const offline = LumoOfflineVoiceClient();
  Completer<Map<String, Object?>>? pending;
  Map<String, Object?> result() => {
        'wav': _testPcmWave(),
        'profile': LumoOfflineVoiceClient.profile,
        'preset': 'F2',
        'language': 'de',
        'sampleRate': 44100,
        'local': true,
      };

  setUpAll(native.install);
  setUp(() async {
    localCalls.clear();
    native.calls.clear();
    native.retiredTtsCalls.clear();
    native.nativePositionMs = 0;
    pending = null;
    messenger.setMockMethodCallHandler(LumoOfflineVoiceClient.channel,
        (call) async {
      localCalls.add(call);
      if (call.method == 'availability') {
        return {...result(), 'available': true};
      }
      if (call.method == 'synthesize') {
        return pending == null ? result() : pending!.future;
      }
      return null;
    });
    await LumoVoice.instance.configure(
      enabled: true,
      identity: LumoVoiceIdentity.freeOffline,
      cloudVoiceEnabled: false,
      localVoiceLicenseAccepted: false,
      rate: .35,
    );
    await LumoVoice.instance.stop();
    LumoVoice.instance.clipsEnabled = true;
    LumoVoiceClips.debugSetFreeCatalog({
      LumoVoiceClips.keyFor('Super!'): const LumoVoiceClip(
        id: 'free_praise',
        text: 'Super!',
        duration: Duration(seconds: 10),
        envelope: [0, .5, .8, 0],
        fps: 20,
        assetDirectory: 'audio/voice/lumo_free',
      ),
      LumoVoiceClips.keyFor('Welche Form ist das?'): const LumoVoiceClip(
        id: 'free_question',
        text: 'Welche Form ist das?',
        duration: Duration(seconds: 10),
        envelope: [0, .5, .8, 0],
        fps: 20,
        assetDirectory: 'audio/voice/lumo_free',
      ),
    });
  });
  tearDown(() async {
    await LumoVoice.instance.stop();
    await LumoVoice.instance
        .configure(cloudVoiceEnabled: false, localVoiceLicenseAccepted: false);
    LumoVoiceClips.debugSetFreeCatalog(null);
    messenger.setMockMethodCallHandler(LumoOfflineVoiceClient.channel, null);
  });

  test('free identity is explicit and not labelled Sulafat', () {
    expect(LumoVoice.instance.identity, LumoVoiceIdentity.freeOffline);
    expect(LumoVoice.instance.selectedVoiceName, 'Lumo Frei');
    expect(LumoVoice.instance.selectedLocale, 'de-DE');
  });

  test('every supplied free clip has real pinned bytes and one preset', () {
    final catalog =
        jsonDecode(File(LumoVoiceClips.freeCatalogAsset).readAsStringSync());
    final parsed = LumoVoiceClips.parseCatalog(jsonEncode(catalog));
    expect(parsed.length, greaterThanOrEqualTo(150));
    expect(catalog['preset'], 'F2');
    expect(catalog['speaker_id'], 1);
    expect(catalog['machine_generated'], true);
    expect(catalog['aliases'], isEmpty,
        reason:
            'A new sentence must not masquerade as a generic old recording.');
    for (final entry in parsed.entries) {
      final clip = entry.value;
      final bytes = File('assets/${clip.assetSource}').readAsBytesSync();
      expect(sha256.convert(bytes).toString(),
          catalog['clips'][entry.key]['asset_sha256']);
      expect(clip.assetSource, startsWith('audio/voice/lumo_free/'));
      expect(clip.duration.inMilliseconds, greaterThan(300));
      expect(clip.envelope, isNotEmpty);
      expect(catalog['clips'][entry.key]['preset'], 'F2');
    }
  });

  test('catalogs cannot inject another voice folder or path traversal', () {
    const clip = {
      'id': '../secret',
      'text': 'Hallo',
      'ms': 1000,
      'env': '012',
      'fps': 20,
    };
    expect(
        () => LumoVoiceClips.parseCatalog(jsonEncode({
              'clips': {'hallo': clip}
            })),
        throwsFormatException);
    expect(
        () => LumoVoiceClips.parseCatalog(jsonEncode({
              'asset_directory': 'audio/voice/alien',
              'clips': const <String, Object?>{},
            })),
        throwsFormatException);
  });

  test('old saved settings do not silently accept a model or cloud license',
      () {
    final old = AppSettings.fromJson({
      'voiceEnabled': true,
      'voiceRate': .45,
      'cloudVoiceEnabled': true,
      'microphoneEnabled': false,
      'scannerEnabled': false,
      'aiProxyEnabled': false,
    });
    expect(old.localVoiceLicenseAccepted, false);
    expect(old.cloudVoiceEnabled, true,
        reason: 'Historical settings are preserved, not rewritten.');
    expect(old.voiceRate, .45);
    final approved = old.copyWith(localVoiceLicenseAccepted: true);
    expect(AppSettings.fromJson(approved.toJson()).localVoiceLicenseAccepted,
        true);
    expect(approved.microphoneEnabled, false);
    expect(approved.scannerEnabled, false);
    expect(approved.aiProxyEnabled, false);
  });

  test('absent license never starts native synthesis', () async {
    await expectLater(
        offline.synthesize(
          text: 'Neue Aufgabe',
          style: 'question',
          localLicenseAccepted: false,
        ),
        throwsA(isA<LumoOfflineSpeechException>()));
    expect(localCalls.where((c) => c.method == 'synthesize'), isEmpty);
  });

  test('local reply must confirm German F2 PCM at the actual sample rate',
      () async {
    final bytes = await offline.synthesize(
        text: 'Hallo!', style: 'greeting', localLicenseAccepted: true);
    expect(bytes, isNotEmpty);
    expect(localCalls.last.arguments['localLicenseAccepted'], true);
    for (final wrong in [
      {...result(), 'preset': 'M2'},
      {...result(), 'profile': LumoSulafatClient.referenceProfile},
      {...result(), 'local': false},
      {...result(), 'language': 'en'},
      {...result(), 'wav': Uint8List(44)},
      {...result(), 'wav': _testPcmWave(sampleRate: 24000)},
    ]) {
      messenger.setMockMethodCallHandler(LumoOfflineVoiceClient.channel,
          (call) async => call.method == 'synthesize' ? wrong : null);
      await expectLater(
          offline.synthesize(
              text: 'Hallo!', style: 'warm', localLicenseAccepted: true),
          throwsA(isA<LumoOfflineSpeechException>()));
    }
  });

  test('question waits for feedback completion instead of cutting praise',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    final starts = voice.startedPlaybackCount;
    final stops = native.calls.where((c) => c.method == 'stop').length;
    final question = voice.speak('Welche Form ist das?');
    await Future<void>.delayed(Duration.zero);
    expect(voice.startedPlaybackCount, starts);
    expect(native.calls.where((c) => c.method == 'stop').length, stops);
    native.complete();
    await question;
    expect(voice.startedPlaybackCount, starts + 1);
    expect(voice.lastStartedAudioIdentity,
        'Lumo Frei / F2 / lokale Aufnahme free_question.m4a');
  });

  test('stop cancels a waiting next question and cannot resurrect audio',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    final starts = voice.startedPlaybackCount;
    final question = voice.speak('Welche Form ist das?');
    await Future<void>.delayed(Duration.zero);
    await voice.stop();
    await question;
    expect(voice.startedPlaybackCount, starts);
    expect(voice.status.value, VoiceStatus.idle);
  });

  test('stopping a bundled clip never opens or cancels a synthesis channel',
      () async {
    final voice = LumoVoice.instance;
    await voice.speak('Super!');
    await voice.stop();
    expect(localCalls, isEmpty);
    expect(voice.status.value, VoiceStatus.idle);
  });

  test('dynamic free audio has zero HTTP, parent-session or system-TTS calls',
      () async {
    final noNetwork = _NoNetwork();
    var parentRequests = 0;
    final voice = LumoVoice.instance;
    await voice.configure(
      // Even an old enabled preference MUST NOT call the billable provider.
      cloudVoiceEnabled: true,
      localVoiceLicenseAccepted: true,
      parentSpeechAuthorization: () async {
        parentRequests++;
        throw StateError(
            'Free local speech must not ask for an online session.');
      },
    );
    final speaking = _waitFor(VoiceStatus.speaking);
    await HttpOverrides.runZoned(
      () async {
        await voice.speak('Von acht bis zehn fehlen zwei.',
            style: VoiceStyle.explain);
        await speaking;
        native.complete();
      },
      createHttpClient: noNetwork.createHttpClient,
    );
    expect(noNetwork.attempts, 0);
    expect(parentRequests, 0);
    expect(localCalls.where((c) => c.method == 'synthesize'), hasLength(1));
    expect(native.retiredTtsCalls, isEmpty);
    expect(voice.lastStartedAudioIdentity, 'Lumo Frei / F2 / lokale Synthese');
  });

  test('mute during local inference discards the late WAV', () async {
    final voice = LumoVoice.instance;
    pending = Completer<Map<String, Object?>>();
    await voice.configure(localVoiceLicenseAccepted: true);
    final starts = voice.startedPlaybackCount;
    await voice.speak('Eine neue Erklärung.', freshLocalAudio: true);
    await Future<void>.delayed(Duration.zero);
    await voice.configure(enabled: false);
    pending!.complete(result());
    await Future<void>.delayed(Duration.zero);
    expect(voice.startedPlaybackCount, starts);
    expect(voice.status.value, VoiceStatus.idle);
    expect(native.retiredTtsCalls, isEmpty);
  });

  test('pure local segmentation preserves text under the native size bound',
      () {
    final input = List.filled(100, 'Schritt für Schritt.').join(' ');
    final chunks = LumoSulafatClient.segments(input, limit: 180);
    expect(chunks.join(' '), input);
    expect(chunks.every((chunk) => chunk.length <= 180), true);
    expect(
        () => LumoSulafatClient.segments(input, limit: 2), throwsArgumentError);
  });
}

// Artificial PCM only for the platform contract parser. Not a listening proof.
Uint8List _testPcmWave({int sampleRate = 44100}) {
  final count = sampleRate ~/ 2;
  final result = Uint8List(44 + count * 2);
  final bytes = ByteData.sublistView(result);
  void tag(int offset, String text) =>
      result.setRange(offset, offset + text.length, text.codeUnits);
  tag(0, 'RIFF');
  bytes.setUint32(4, result.length - 8, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  bytes.setUint32(40, count * 2, Endian.little);
  for (var i = 0; i < count; i++) {
    bytes.setInt16(44 + i * 2, i.isEven ? 1200 : -1200, Endian.little);
  }
  return result;
}

Future<void> _waitFor(VoiceStatus expected) async {
  final status = LumoVoice.instance.status;
  if (status.value == expected) return;
  final finished = Completer<void>();
  void listener() {
    if (status.value == expected && !finished.isCompleted) finished.complete();
  }

  status.addListener(listener);
  try {
    await finished.future.timeout(const Duration(seconds: 3));
  } finally {
    status.removeListener(listener);
  }
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('No speech upload is allowed.');
  }
}
