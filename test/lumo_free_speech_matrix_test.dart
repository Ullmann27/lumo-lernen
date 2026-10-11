import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/lumo_voice_clips.dart';
import 'package:lumo_lernen/features/learning_modules/lumo_phrases.dart';

import 'helpers/lumo_native_audio_harness.dart';

/// Actual shipped audio bytes and routing, with a MOCKED native player.
/// Audible Android and human emotional acceptance are separate release gates.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final harness = LumoNativeAudioHarness();
  final noNetwork = _NoNetwork();
  final rows = <Map<String, Object?>>[];
  late Map<String, dynamic> catalog;
  HttpOverrides? previousHttp;
  final scenarios = <(String, String, String)>[
    for (var i = 0; i < 12; i++)
      ('Mathematik / Deutsch', 'Richtige Antwort', LumoPhrases.correct()),
    for (var i = 0; i < 7; i++)
      (
        'Mathematik / Sachunterricht',
        'Falsche Antwort',
        LumoPhrases.wrongGentle()
      ),
    for (var i = 0; i < 5; i++)
      ('Navigation / Lernen', 'Modul öffnen', LumoPhrases.greeting()),
    for (var i = 0; i < 5; i++)
      ('Lernabschluss', 'Erfolg', LumoPhrases.celebrate()),
    for (var i = 0; i < 5; i++)
      ('Nachhilfe', 'Ermutigung', LumoPhrases.comfort()),
    ('Plus bis 10', 'Aufgabenstellung', '3 plus 4 - wie viel ist das?'),
    ('Minus bis 10', 'Aufgabenstellung', '8 minus 3. Wie viele bleiben?'),
    ('Zahlen bis 10', 'Mengenaufgabe', 'Wie viele Punkte siehst du?'),
    ('Formen', 'Aufgabenstellung', 'Welche Form ist das?'),
    ('Uhrzeit', 'Aufgabenstellung', 'Wie spät ist es?'),
    ('Geld', 'Aufgabenstellung', 'Wie viel Geld siehst du?'),
    ('Einmaleins', 'Aufgabenstellung', '3 mal 2. Wie viel ist das?'),
    ('Bruchrechnen', 'Aufgabenstellung', 'Welcher Bruch wurde gegessen?'),
    (
      'Deutsch / Artikel',
      'Aufgabenstellung',
      'Welcher Artikel passt zu Sonne?'
    ),
    (
      'Deutsch / Mehrzahl',
      'Aufgabenstellung',
      'Wie heißt die Mehrzahl von Haus?'
    ),
    (
      'Deutsch / Wortarten',
      'Aufgabenstellung',
      'Ist "Haus" ein Nomen, Verb oder Adjektiv?'
    ),
    (
      'Deutsch / Zeitformen',
      'Aufgabenstellung',
      'In welcher Zeit steht der Satz?'
    ),
    ('Schreibcoach', 'Aufgabenstellung', 'Schreib ein A!'),
    ('Sachunterricht / Tiere', 'Aufgabenstellung', 'Welches Tier ist das?'),
    (
      'Sachunterricht / Jahreszeiten',
      'Aufgabenstellung',
      'Welche Jahreszeit zeigt das Bild?'
    ),
    (
      'Sachunterricht / Wetter',
      'Aufgabenstellung',
      'Welches Wetter siehst du?'
    ),
  ];

  setUpAll(() async {
    harness.install();
    previousHttp = HttpOverrides.current;
    HttpOverrides.global = noNetwork;
    LumoVoiceClips.debugSetFreeCatalog(null);
    await LumoVoiceClips.ensureFreeLoaded();
    catalog =
        jsonDecode(File(LumoVoiceClips.freeCatalogAsset).readAsStringSync())
            as Map<String, dynamic>;
    await LumoVoice.instance.configure(
      identity: LumoVoiceIdentity.freeOffline,
      enabled: true,
      cloudVoiceEnabled: false,
      localVoiceLicenseAccepted: false,
      rate: .35,
    );
  });
  tearDownAll(() async {
    await LumoVoice.instance.stop();
    HttpOverrides.global = previousHttp;
    final directory = Platform.environment['LUMO_SPEECH_AUDIT_DIR'];
    if (directory != null) {
      final output = File('$directory/Lumo-Frei-50-Situationen.json');
      await output.parent.create(recursive: true);
      await output.writeAsString(const JsonEncoder.withIndent('  ').convert({
        'run_utc': DateTime.now().toUtc().toIso8601String(),
        'source_commit': Platform.environment['LUMO_AUDIT_SOURCE_COMMIT'],
        'runtime': 'Flutter Linux test runner',
        'native_audio': 'MethodChannel mock; NOT audible Android playback',
        'voice_profile': catalog['variant'],
        'preset': 'F2',
        'scenario_count': rows.length,
        'public_clip_count': LumoVoiceClips.freeCount,
        'network_attempts': noNetwork.attempts,
        'synthesis_api_calls': 0,
        'local_dynamic_synthesis': 'Separately tested in actual JVM inference',
        'human_emotional_acceptance': 'NOT TESTED',
        'rows': rows,
      }));
    }
  });

  test('free matrix has 50 distinct actual-library or existing-module texts',
      () {
    expect(scenarios, hasLength(50));
    expect(scenarios.map((row) => row.$3).toSet(), hasLength(50));
    expect(LumoVoiceClips.freeCount, 155);
  });
  for (var i = 0; i < scenarios.length; i++) {
    final (area, occasion, text) = scenarios[i];
    test('free speech ${i + 1}: $area / $occasion / $text', () async {
      final voice = LumoVoice.instance;
      await voice.stop();
      final clip = LumoVoiceClips.freeLookup(text);
      expect(clip, isNotNull,
          reason: 'Each listed situation needs its own shipped audio asset.');
      expect(LumoVoiceClips.keyFor(clip!.text), LumoVoiceClips.keyFor(text),
          reason: 'Generic aliases are not a new verbatim recording.');
      final starts = voice.startedPlaybackCount;
      final completions = voice.completedPlaybackCount;
      await voice.speak(text);
      expect(voice.status.value, VoiceStatus.speaking);
      expect(voice.startedPlaybackCount, starts + 1);
      expect(voice.lastStartedAudioIdentity,
          'Lumo Frei / F2 / lokale Aufnahme ${clip.id}.m4a');
      harness.nativePositionMs = clip.duration.inMilliseconds;
      harness.complete();
      await Future<void>.delayed(Duration.zero);
      expect(voice.completedPlaybackCount, completions + 1);
      expect(voice.status.value, VoiceStatus.idle);
      expect(harness.retiredTtsCalls, isEmpty);
      expect(noNetwork.attempts, 0);
      final raw = File('assets/${clip.assetSource}').readAsBytesSync();
      rows.add({
        'id': 'free-speech-${(i + 1).toString().padLeft(2, '0')}',
        'area': area,
        'occasion': occasion,
        'requested_text': text,
        'display_text': clip.text,
        'producer_spoken_text': catalog['clips'][LumoVoiceClips.keyFor(text)]
            ['spoken_text'],
        'asset': clip.assetSource,
        'asset_sha256': sha256.convert(raw).toString(),
        'duration_ms': clip.duration.inMilliseconds,
        'preset': 'F2',
        'exact_display_catalog_mapping': true,
        'route_contract': 'PASS',
        'native_start_mock_observed': true,
        'native_completion_mock_observed': true,
        'audible_android_test': 'NOT TESTED',
      });
    });
  }
}

class _NoNetwork extends HttpOverrides {
  int attempts = 0;
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    attempts++;
    throw StateError('An offline speech matrix must not upload its text.');
  }
}
