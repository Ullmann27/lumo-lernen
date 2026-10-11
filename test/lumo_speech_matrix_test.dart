import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/features/learning_modules/lumo_phrases.dart';

import 'helpers/lumo_native_audio_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = LumoNativeAudioHarness();
  final rows = <Map<String, Object?>>[];
  final noNetwork = _NoNetwork();
  HttpOverrides? previousHttp;
  final scenarios = <(String, String, String, bool)>[
    for (var i = 0; i < 12; i++)
      ('Mathematik / Deutsch', 'Richtige Antwort', LumoPhrases.correct(), true),
    for (var i = 0; i < 7; i++)
      (
        'Mathematik / Sachunterricht',
        'Falsche Antwort',
        LumoPhrases.wrongGentle(),
        true
      ),
    for (var i = 0; i < 5; i++)
      ('Navigation / Lernen', 'Modul öffnen', LumoPhrases.greeting(), true),
    for (var i = 0; i < 5; i++)
      ('Lernabschluss', 'Erfolg', LumoPhrases.celebrate(), true),
    for (var i = 0; i < 5; i++)
      ('Nachhilfe', 'Ermutigung', LumoPhrases.comfort(), true),
    ('Plus bis 10', 'Aufgabenstellung', '3 plus 4 - wie viel ist das?', false),
    (
      'Minus bis 10',
      'Aufgabenstellung',
      '8 minus 3. Wie viele bleiben?',
      false
    ),
    ('Zahlen bis 10', 'Mengenaufgabe', 'Wie viele Punkte siehst du?', false),
    ('Formen', 'Aufgabenstellung', 'Welche Form ist das?', false),
    ('Uhrzeit', 'Aufgabenstellung', 'Wie spät ist es?', false),
    ('Geld', 'Aufgabenstellung', 'Wie viel Geld siehst du?', false),
    ('Einmaleins', 'Aufgabenstellung', '3 mal 2. Wie viel ist das?', false),
    (
      'Bruchrechnen',
      'Aufgabenstellung',
      'Welcher Bruch wurde gegessen?',
      false
    ),
    (
      'Deutsch / Artikel',
      'Aufgabenstellung',
      'Welcher Artikel passt zu Sonne?',
      false
    ),
    (
      'Deutsch / Mehrzahl',
      'Aufgabenstellung',
      'Wie heißt die Mehrzahl von Haus?',
      false
    ),
    (
      'Deutsch / Wortarten',
      'Aufgabenstellung',
      'Ist "Haus" ein Nomen, Verb oder Adjektiv?',
      false
    ),
    (
      'Deutsch / Zeitformen',
      'Aufgabenstellung',
      'In welcher Zeit steht der Satz?',
      false
    ),
    ('Schreibcoach', 'Aufgabenstellung', 'Schreib ein A!', false),
    (
      'Sachunterricht / Tiere',
      'Aufgabenstellung',
      'Welches Tier ist das?',
      false
    ),
    (
      'Sachunterricht / Jahreszeiten',
      'Aufgabenstellung',
      'Welche Jahreszeit zeigt das Bild?',
      false
    ),
    (
      'Sachunterricht / Wetter',
      'Aufgabenstellung',
      'Welches Wetter siehst du?',
      false
    ),
  ];

  setUpAll(() async {
    harness.install();
    previousHttp = HttpOverrides.current;
    HttpOverrides.global = noNetwork;
    LumoVoiceClips.debugSetCatalog(null);
    await LumoVoiceClips.ensureLoaded();
    await LumoVoice.instance
        .configure(identity: LumoVoiceIdentity.sulafatOriginal);
  });
  tearDownAll(() async {
    await LumoVoice.instance.stop();
    await LumoVoice.instance.configure(identity: LumoVoiceIdentity.freeOffline);
    HttpOverrides.global = previousHttp;
    final directory = Platform.environment['LUMO_SPEECH_AUDIT_DIR'];
    if (directory != null) {
      final report = {
        'run_utc': DateTime.now().toUtc().toIso8601String(),
        'source_commit': Platform.environment['LUMO_AUDIT_SOURCE_COMMIT'],
        'runtime': 'Flutter Linux test runner',
        'native_audio':
            'MethodChannel platform mock; NOT audible device playback',
        'online_parent_consent': false,
        'provider_synthesis_calls': 0,
        'network_attempts': noNetwork.attempts,
        'original_clip_count': LumoVoiceClips.count,
        'scenario_count': rows.length,
        'android_listening_acceptance': 'NOT TESTED',
        'dynamic_sulafat_acceptance': 'BLOCKED: live /speech returns HTTP 404',
        'rows': rows,
      };
      final output = File('$directory/Sulafat-50-Situationen.json');
      await output.parent.create(recursive: true);
      await output
          .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    }
  });

  test('matrix has 50 distinct real-library or existing-module utterances', () {
    expect(scenarios, hasLength(50));
    expect(scenarios.map((s) => s.$3).toSet(), hasLength(50));
  });
  for (var i = 0; i < scenarios.length; i++) {
    final (area, occasion, text, available) = scenarios[i];
    test('speech situation ${i + 1}: $area / $occasion / $text', () async {
      final voice = LumoVoice.instance;
      await voice.stop();
      await voice.configure(enabled: true, cloudVoiceEnabled: false, rate: .35);
      voice.clipsEnabled = true;
      final clip = LumoVoiceClips.lookup(text);
      expect(clip != null, available);
      final starts = voice.startedPlaybackCount;
      final completions = voice.completedPlaybackCount;
      await voice.speak(text);
      if (available) {
        expect(voice.status.value, VoiceStatus.speaking);
        expect(voice.startedPlaybackCount, starts + 1);
        harness.nativePositionMs = clip!.duration.inMilliseconds;
        harness.complete();
        await Future<void>.delayed(Duration.zero);
        expect(voice.status.value, VoiceStatus.idle);
        expect(voice.completedPlaybackCount, completions + 1);
      } else {
        expect(voice.status.value, VoiceStatus.error);
        expect(voice.startedPlaybackCount, starts);
        expect(voice.completedPlaybackCount, completions);
        expect(voice.lastError.value, contains('keine Originalaufnahme'));
      }
      expect(harness.retiredTtsCalls, isEmpty);
      expect(noNetwork.attempts, 0);
      final sourceBytes = clip == null
          ? null
          : File('assets/${clip.assetSource}').readAsBytesSync();
      rows.add({
        'id': 'speech-${(i + 1).toString().padLeft(2, '0')}',
        'area': area,
        'occasion': occasion,
        'requested_text': text,
        'offline_result': available
            ? 'ORIGINAL_ROUTE_CONTRACT_PASSED'
            : 'NO_MATCHING_ORIGINAL: CONSCIOUS_SILENCE_VERIFIED',
        'actually_recorded_text': clip?.text,
        'verbatim': clip == null
            ? null
            : LumoVoiceClips.keyFor(text) == LumoVoiceClips.keyFor(clip.text),
        'asset': clip?.assetSource,
        'asset_sha256':
            sourceBytes == null ? null : sha256.convert(sourceBytes).toString(),
        'native_start_mock_observed': voice.startedPlaybackCount > starts,
        'native_completion_mock_observed':
            voice.completedPlaybackCount > completions,
        'android_audible_test': 'NOT TESTED',
        'dynamic_voice_test': 'NOT RUN: no paid synthesis or online consent',
      });
    });
  }
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('An offline speech test must never transmit its text.');
  }
}
