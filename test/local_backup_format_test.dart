import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';
import 'package:lumo_lernen/domain/backup/local_backup.dart';

Map<String, Object> samplePreferences() => {
      'lumo_active_profile': jsonEncode(UserProfile(
              id: 'local-a',
              name: 'Alina',
              age: 8,
              grade: 2,
              createdAt: DateTime.utc(2026, 1, 1),
              lastActiveAt: DateTime.utc(2026, 11, 22))
          .toJson()),
      'lumo_intro_seen': true,
      'lumo_journal_entries': jsonEncode([
        {
          'id': 'entry-1',
          'text': 'Mein eigener Text. 🦊',
          'title': 'Mein Tag',
          'createdAt': 1795300000000,
          'wordCount': 4
        }
      ]),
      'lumo_reward_wallet_v1': jsonEncode(const RewardWallet(
          stars: 42,
          xp: 480,
          totalEarnedStars: 81,
          gameResultIds: ['run-completed-once']).toJson()),
      'lumo_3d_save_salt_v1':
          '0123456789abcdef0123456789abcdef0123456789abcdef',
      'lumo_3d_profile_keys_v1': jsonEncode({
        'version': 1,
        'legacyAvailable': false,
        'owners': {'local-a': 'p_0123456789abcdef0123456789abcdef'},
        'legacy': {}
      }),
      'lumo_progress_skills::local-a': '{"addition":{"correct":12}}',
      'lumo_parent_tasks_v1::local-a':
          '{"version":1,"studentId":"local-a","tasks":[],"activeAttempt":null}',
      'lumo.reward_shop.profile.owner-hash':
          '{"version":1,"items":[],"pending":null}',
      'lumo.reading.recent_story_signatures.local-a': <String>[
        'first',
        'second'
      ],
      'cross_grade_practice_v1:alina:2:Mathematik:Addition:answered': 9,
      'cross_grade_writing_v1:alina:4:aufsatz:draft:0':
          'Mein geschriebener Aufsatz.',
      'lumo_voice_rate': 0.35,
    };

LocalBackup sampleBackup() => LocalBackup.create(
    preferences: samplePreferences(),
    nativeFiles: [
      LocalBackupFile(
          'lumo_game_events.json',
          utf8.encode(
              '{"results":[{"resultId":"pending-win","stars":4,"xp":20,"status":"completed","game":"run"}]}')),
      LocalBackupFile('kart_parcours_session_abc.cfg',
          utf8.encode('[session]\nfinished=false\n')),
      LocalBackupFile('lumo_settlement_owner_1_garden.json',
          utf8.encode('{"version":1,"buildings":["house"]}')),
      LocalBackupFile('kart_geister/Lumo-Geist_Zoey.lumogeist',
          utf8.encode('{"version":1,"name":"Zoey"}')),
    ],
    now: DateTime.utc(2026, 11, 22, 18));

Uint8List altered(void Function(Map<String, dynamic>) change) {
  final outer =
      jsonDecode(utf8.decode(sampleBackup().bytes)) as Map<String, dynamic>;
  final body = jsonDecode(outer['payload'] as String) as Map<String, dynamic>;
  change(body);
  outer['payload'] = jsonEncode(body);
  outer['sha256'] =
      sha256.convert(utf8.encode(outer['payload'] as String)).toString();
  return Uint8List.fromList(utf8.encode(jsonEncode(outer)));
}

class _Oversized extends ListBase<int> {
  @override
  int get length => LocalBackupPolicy.maxArchiveBytes + 1;
  @override
  set length(int value) => throw UnimplementedError();
  @override
  int operator [](int index) => throw StateError('Must reject before reading');
  @override
  void operator []=(int index, int value) => throw UnimplementedError();
}

void main() {
  test(
      'portable roundtrip preserves journal, IDs, parents, wallet and native bytes',
      () {
    final backup = sampleBackup();
    final restored = LocalBackup.parse(backup.bytes);
    expect(restored.preferences, samplePreferences());
    expect(restored.profileNames, ['Alina']);
    expect(restored.createdAt, DateTime.utc(2026, 11, 22, 18));
    expect(restored.nativeFiles.map((f) => f.path),
        backup.nativeFiles.map((f) => f.path));
    for (var i = 0; i < backup.nativeFiles.length; i++) {
      expect(restored.nativeFiles[i].bytes, backup.nativeFiles[i].bytes);
    }
    expect(restored.digest, backup.digest);
  });

  test('export removes secrets and device grants while retaining identity salt',
      () {
    final source = samplePreferences()
      ..addAll({
        'lumo_api_key': 'private',
        'lumo.auth.token': 'private',
        'lumo_parent_pin': '123456',
        'lumo_premium_entitlement': true,
        'outside_plugin_setting': 'not ours',
        'lumo_app_settings_v1': jsonEncode(const AppSettings(
                microphoneEnabled: true,
                scannerEnabled: true,
                cloudVoiceEnabled: true,
                localVoiceLicenseAccepted: true,
                lanPlayEnabled: true,
                ghostDuelEnabled: true,
                aiProxyEnabled: true,
                aiProxyUrl: 'https://private.example/path',
                largeText: true,
                dailyGoal: 5)
            .toJson()),
      });
    final backup = LocalBackup.create(preferences: source, nativeFiles: []);
    expect(backup.preferences.containsKey('lumo_api_key'), false);
    expect(backup.preferences.containsKey('lumo.auth.token'), false);
    expect(backup.preferences.containsKey('lumo_parent_pin'), false);
    expect(backup.preferences.containsKey('lumo_premium_entitlement'), false);
    expect(backup.preferences.containsKey('outside_plugin_setting'), false);
    expect(backup.preferences['lumo_3d_save_salt_v1'],
        source['lumo_3d_save_salt_v1']);
    final settings =
        jsonDecode(backup.preferences[LocalBackupPolicy.settingsKey] as String)
            as Map;
    for (final flag in LocalBackupPolicy.privateSettings) {
      expect(settings[flag], false);
    }
    expect(settings['largeText'], true);
    expect(settings['dailyGoal'], 5);
    expect(settings['aiProxyUrl'], AppSettings.defaultAiProxyUrl);
    expect(
        (jsonDecode(source[LocalBackupPolicy.settingsKey] as String)
            as Map)['microphoneEnabled'],
        true);
  });

  test('old HTML format and a future version are rejected without conversion',
      () {
    expect(() => LocalBackup.parse(utf8.encode('{"st":{"stars":50}}')),
        throwsFormatException);
    final root = jsonDecode(utf8.decode(sampleBackup().bytes)) as Map;
    root['version'] = 2;
    expect(() => LocalBackup.parse(utf8.encode(jsonEncode(root))),
        throwsFormatException);
  });

  test('outer checksum, individual file checksum and byte count are enforced',
      () {
    final root = jsonDecode(utf8.decode(sampleBackup().bytes)) as Map;
    root['sha256'] = '0' * 64;
    expect(() => LocalBackup.parse(utf8.encode(jsonEncode(root))),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(
            altered((b) => (b['nativeFiles'] as List)[0]['sha256'] = '0' * 64)),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(
            altered((b) => (b['nativeFiles'] as List)[0]['bytes'] = 1)),
        throwsFormatException);
  });

  test(
      'paths, duplicate files, transient tokens and forbidden preferences fail closed',
      () {
    for (final path in [
      '../settings.cfg',
      '/settings.cfg',
      'kart_geister/../secret.json',
      'lumo_cards_table_v1/session/state.json',
      'lumo_game_events.lock',
      'secret.json'
    ]) {
      expect(
          () => LocalBackup.parse(
              altered((b) => (b['nativeFiles'] as List)[0]['path'] = path)),
          throwsFormatException);
    }
    expect(
        () => LocalBackup.parse(altered((b) =>
            (b['nativeFiles'] as List).add((b['nativeFiles'] as List).first))),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) => (b['preferences']
            as Map)['lumo_secret'] = {'type': 'string', 'value': 'x'})),
        throwsFormatException);
  });

  test(
      'wrong types, reserved plugin encodings and malformed learning JSON are rejected',
      () {
    expect(
        () => LocalBackup.parse(altered((b) =>
            (b['preferences'] as Map)['lumo_intro_seen']['value'] = 'true')),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) => (b['preferences']
            as Map)['lumo_journal_entries']['value'] = '{broken')),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) => (b['preferences']
            as Map)['lumo_reward_wallet_v1']['value'] = '{"stars":-1,"xp":2}')),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) =>
            (b['preferences'] as Map)['lumo_3d_save_salt_v1']['value'] =
                'VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu![]')),
        throwsFormatException);
  });

  test('native profile mapping must remain complete and unique', () {
    expect(
        () => LocalBackup.parse(altered(
            (b) => (b['preferences'] as Map).remove('lumo_3d_save_salt_v1'))),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) {
              final prefs = b['preferences'] as Map;
              final registry = jsonDecode(
                  prefs['lumo_3d_profile_keys_v1']['value'] as String) as Map;
              registry['owners']['other-child'] = registry['owners']['local-a'];
              prefs['lumo_3d_profile_keys_v1']['value'] = jsonEncode(registry);
            })),
        throwsFormatException);
  });

  test('oversize and excessive nesting reject before processing', () {
    expect(() => LocalBackup.parse(_Oversized()), throwsFormatException);
    expect(() => LocalBackupPolicy.decodeJson('${'[' * 65}0${']' * 65}'),
        throwsFormatException);
    expect(
        () => LocalBackup.parse(altered((b) => (b['nativeFiles'] as List)[0]
            ['bytes'] = LocalBackupPolicy.maxFileBytes + 1)),
        throwsFormatException);
  });

  test('duplicate JSON object keys cannot be hidden behind a valid checksum',
      () {
    const payload = '{"preferences":{},"preferences":{},"nativeFiles":[]}';
    final bytes = utf8.encode(jsonEncode({
      'format': 'lumo-local-backup',
      'version': 1,
      'createdAt': '2026-11-22T18:00:00.000Z',
      'payload': payload,
      'sha256': sha256.convert(utf8.encode(payload)).toString()
    }));
    expect(() => LocalBackup.parse(bytes), throwsFormatException);
  });

  test('all current native persistent families are accepted', () {
    for (final path in [
      'settings.cfg',
      'progress.cfg',
      'lumo_game_events.json',
      'lumo_host_pending_rewards.cfg',
      'lumo_soundscape.cfg',
      'lumo_sternenjagd.cfg',
      'kart_preferences.cfg',
      'kart_parcours_abc.cfg',
      'kart_parcours_session_abc.cfg',
      'kart_track_pass_abc.cfg',
      'kart_workshop_p_abc.cfg',
      'run_replay_abc_course.cfg',
      'skypost_owner_freiflug.cfg',
      'jump_owner_2_mathe.cfg',
      'lumo_cards_abc.json',
      'lumo_chess_abc.json',
      'lumo_build_p_abc_1.json',
      'lumo_settlement_abc_1_garden.json',
      'lumo_puzzle_p_abc.json',
      'lumo_rhythm_p_abc.cfg',
      'lumo_treasure_p_abc.json',
      'lumo_first_run_abc.cfg',
      'kart_geister/Lumo-Geist_Zoey.lumogeist'
    ]) {
      expect(LocalBackupPolicy.allowsNativePath(path), true, reason: path);
    }
  });
}
