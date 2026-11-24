import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/legacy_learning_data.dart';
import 'package:lumo_lernen/core/progress_repository.dart';

const _fixturePath =
    'tools/android_qa/tests/fixtures/update_2017_2018_independent_evidence.json';
const _fixtureSha256 =
    '8815f517552ebdde7908ff98b1bb389147a4857ccb4a75cabd65e2142eb3338a';
const _skill = 'mathematik::plus bis 10';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fixtureBytes = File(_fixturePath).readAsBytesSync();
  final fixture = jsonDecode(utf8.decode(fixtureBytes)) as Map<String, dynamic>;
  final metadata = fixture['metadata'] as Map<String, dynamic>;
  final before = fixture['before'] as Map<String, dynamic>;
  final after = fixture['after'] as Map<String, dynamic>;
  final prefixedKey = metadata['skill_preference_key'] as String;
  final key = prefixedKey.substring('flutter.'.length);
  final originalRaw = before[prefixedKey] as String;
  final actualMigratedRaw = after[prefixedKey] as String;
  final original = (jsonDecode(originalRaw) as Map<String, dynamic>)[_skill]
      as Map<String, dynamic>;
  final foreignKey =
      LearningDataNamespace.keyFor('lumo_progress_skills', 'another-child');

  Map<String, Object> seed({String? raw}) => {
        // Only string preferences are relevant to this real repository. The
        // fixture retains the probe's null value for the unrelated XML bool.
        for (final entry in before.entries)
          if (entry.value is String)
            entry.key.substring('flutter.'.length): entry.value as String,
        foreignKey: originalRaw,
        if (raw != null) key: raw,
      };

  Future<void> expectOtherBytes(Map<String, Object> initial) async {
    final prefs = await SharedPreferences.getInstance();
    for (final entry in initial.entries) {
      if (entry.key != key) {
        expect(prefs.get(entry.key), entry.value,
            reason:
                'Loading one skill namespace must not change ${entry.key}.');
      }
    }
  }

  test('actual Android fixture and original skill bytes retain their hashes',
      () {
    expect(sha256.convert(fixtureBytes).toString(), _fixtureSha256);
    expect(metadata['workflow_run_id'], 43395154888);
    expect(metadata['artifact_id'], 14022392802);
    expect(metadata['baseline_version'], 2017);
    expect(metadata['candidate_version'], 2018);
    expect(sha256.convert(utf8.encode(originalRaw)).toString(),
        metadata['skill_raw_sha256']['before']);
    expect(sha256.convert(utf8.encode(actualMigratedRaw)).toString(),
        metadata['skill_raw_sha256']['after']);
    expect(original, hasLength(10));
    expect(original.containsKey('independentEvidence'), isFalse);
  });

  test('actual 2017 lesson persists exactly the observed 2018 JSON', () async {
    final initial = seed();
    SharedPreferences.setMockInitialValues(initial);
    // No explicit ID: exercise the production primary namespace resolution.
    final repository = ProgressRepository();
    final loaded = await repository.loadSkills();
    final prefs = await SharedPreferences.getInstance();
    expect(loaded.keys, [_skill]);
    expect(prefs.getString(key), actualMigratedRaw,
        reason:
            'Compare against actual Android bytes, not a recreated formula.');
    final record = loaded[_skill]!;
    for (final entry in original.entries) {
      expect(record.toJson()[entry.key], entry.value);
    }
    expect(record.assessed.correct, 1);
    expect(record.assessed.wrong, 0);
    expect(record.assessed.correctStreak, 1);
    expect(record.correct, 1);
    expect(record.hintCount, 0);
    expect(record.lastSeen.toIso8601String(), original['lastSeen']);
    await expectOtherBytes(initial);
    await repository.loadSkills();
    expect(prefs.getString(key), actualMigratedRaw,
        reason: 'A second read must preserve the already migrated bytes.');
  });

  test(
      'helped legacy answer remains history without invented independent proof',
      () async {
    final helped = {...original, 'hintCount': 1};
    final raw = jsonEncode({_skill: helped});
    final initial = seed(raw: raw);
    SharedPreferences.setMockInitialValues(initial);
    final record = (await ProgressRepository().loadSkills())[_skill]!;
    final persisted =
        jsonDecode((await SharedPreferences.getInstance()).getString(key)!)
            as Map<String, dynamic>;
    expect(persisted[_skill], {
      ...helped,
      'independentEvidence': {
        'version': 1,
        'correct': 0,
        'wrong': 0,
        'correctStreak': 0,
        'wrongStreak': 0,
      },
    });
    expect(record.correct, 1);
    expect(record.currentStreak, 1);
    expect(record.difficulty, 1);
    expect(record.assessed.attempts, 0);
    expect(record.mastery, 0);
    await expectOtherBytes(initial);
  });

  test('persisted valid 2018 evidence remains byte exact on restart read',
      () async {
    final initial = seed(raw: actualMigratedRaw);
    SharedPreferences.setMockInitialValues(initial);
    final record = (await ProgressRepository().loadSkills())[_skill]!;
    expect(record.assessed.correct, 1);
    expect((await SharedPreferences.getInstance()).getString(key),
        actualMigratedRaw);
    await expectOtherBytes(initial);
  });

  for (final (label, evidence) in <(String, Object?)>[
    (
      'future version',
      {
        'version': 2,
        'correct': 1,
        'wrong': 0,
        'correctStreak': 1,
        'wrongStreak': 0,
      }
    ),
    (
      'unknown field',
      {
        'version': 1,
        'correct': 1,
        'wrong': 0,
        'correctStreak': 1,
        'wrongStreak': 0,
        'future': true,
      }
    ),
    ('missing counts', {'version': 1}),
    (
      'non-integer count',
      {
        'version': 1,
        'correct': 1.0,
        'wrong': 0,
        'correctStreak': 1,
        'wrongStreak': 0,
      }
    ),
    (
      'count exceeds stored practice',
      {
        'version': 1,
        'correct': 2,
        'wrong': 0,
        'correctStreak': 1,
        'wrongStreak': 0,
      }
    ),
    ('null evidence', null),
  ]) {
    test('persisted $label is rejected without changing either child',
        () async {
      final raw = jsonEncode({
        _skill: {...original, 'independentEvidence': evidence}
      });
      final initial = seed(raw: raw);
      SharedPreferences.setMockInitialValues(initial);
      await expectLater(
          ProgressRepository().loadSkills(), throwsFormatException);
      expect((await SharedPreferences.getInstance()).getString(key), raw);
      await expectOtherBytes(initial);
    });
  }
}
