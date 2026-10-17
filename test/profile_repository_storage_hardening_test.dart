import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:lumo_lernen/core/profile_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';

const _profileKey = 'lumo_active_profile';
const _introKey = 'lumo_intro_seen';
const _walletKey = 'lumo_reward_wallet_v1';
const _journalKey = 'lumo_journal_entries';

class _ControlledProfileStore extends InMemorySharedPreferencesStore {
  _ControlledProfileStore(Map<String, Object> initial)
      : super.withData(
          initial.map((key, value) => MapEntry('flutter.$key', value)),
        );

  String? rejectedKey;
  String? throwingKey;
  int failingReads = 0;

  @override
  Future<Map<String, Object>> getAll() async {
    if (failingReads > 0) {
      failingReads--;
      throw StateError('Controlled profile read failure');
    }
    return super.getAll();
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == throwingKey) {
      throw StateError('Controlled profile write failure');
    }
    if (key == rejectedKey) return false;
    return super.setValue(valueType, key, value);
  }

  Future<Map<String, Object>> snapshot() => super.getAll();
}

UserProfile _profile({String name = 'Anna'}) => UserProfile(
      id: 'child-storage-test',
      name: name,
      age: 8,
      grade: 2,
      createdAt: DateTime.utc(2026, 1, 1),
      lastActiveAt: DateTime.utc(2026, 10, 16),
    );

Map<String, Object> _seed(String raw) => {
      _profileKey: raw,
      _introKey: true,
      _walletKey: '{"stars":8,"xp":20}',
      _journalKey: '[]',
    };

void _expectUnrelatedData(Map<String, Object> disk) {
  expect(disk['flutter.$_walletKey'], '{"stars":8,"xp":20}');
  expect(disk['flutter.$_journalKey'], '[]');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  test('valid existing profile is restored without changing its identity',
      () async {
    final raw = jsonEncode(_profile().toJson());
    final store = _ControlledProfileStore(_seed(raw));
    SharedPreferencesStorePlatform.instance = store;

    final loaded = await ProfileRepository().loadProfile();

    expect(loaded?.id, 'child-storage-test');
    expect(loaded?.name, 'Anna');
    expect(loaded?.grade, 2);
    final disk = await store.snapshot();
    expect(disk['flutter.$_introKey'], isTrue);
    _expectUnrelatedData(disk);
  });

  for (final entry in <String, String>{
    'invalid JSON': '{broken',
    'array instead of profile': '[]',
    'number instead of profile': '42',
  }.entries) {
    test('${entry.key} is preserved rather than implicitly deleted', () async {
      final store = _ControlledProfileStore(_seed(entry.value));
      SharedPreferencesStorePlatform.instance = store;

      try {
        await ProfileRepository().loadProfile();
      } catch (_) {
        // This regression specifies data preservation, not the UI error API.
      }

      final disk = await store.snapshot();
      expect(disk['flutter.$_profileKey'], entry.value);
      expect(disk['flutter.$_introKey'], isTrue);
      _expectUnrelatedData(disk);
    });
  }

  test('a transient platform read error never removes an existing profile',
      () async {
    final raw = jsonEncode(_profile().toJson());
    final store = _ControlledProfileStore(_seed(raw))..failingReads = 1;
    SharedPreferencesStorePlatform.instance = store;

    try {
      await ProfileRepository().loadProfile();
    } catch (_) {
      // Returning an error must remain non-destructive too.
    }

    final disk = await store.snapshot();
    expect(disk['flutter.$_profileKey'], raw);
    expect(disk['flutter.$_introKey'], isTrue);
    _expectUnrelatedData(disk);
  });

  test('reading a valid profile does not depend on a successful intro write',
      () async {
    final raw = jsonEncode(_profile().toJson());
    final store = _ControlledProfileStore(_seed(raw))
      ..throwingKey = 'flutter.$_introKey';
    SharedPreferencesStorePlatform.instance = store;

    final loaded = await ProfileRepository().loadProfile();

    expect(loaded?.id, 'child-storage-test');
    final disk = await store.snapshot();
    expect(disk['flutter.$_profileKey'], raw);
    expect(disk['flutter.$_introKey'], isTrue);
    _expectUnrelatedData(disk);
  });

  test('native false for the profile write is reported as failure', () async {
    final raw = jsonEncode(_profile().toJson());
    final store = _ControlledProfileStore(_seed(raw))
      ..rejectedKey = 'flutter.$_profileKey';
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(
      ProfileRepository().saveProfile(_profile(name: 'Updated')),
      throwsStateError,
    );

    final disk = await store.snapshot();
    expect(disk['flutter.$_profileKey'], raw);
    _expectUnrelatedData(disk);
  });

  test('a thrown profile write keeps the previous stored profile', () async {
    final raw = jsonEncode(_profile().toJson());
    final store = _ControlledProfileStore(_seed(raw))
      ..throwingKey = 'flutter.$_profileKey';
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(
      ProfileRepository().saveProfile(_profile(name: 'Updated')),
      throwsStateError,
    );

    final disk = await store.snapshot();
    expect(disk['flutter.$_profileKey'], raw);
    _expectUnrelatedData(disk);
  });

  test('native false for intro completion is not a completed save', () async {
    final store = _ControlledProfileStore({
      ..._seed(jsonEncode(_profile().toJson())),
      _introKey: false,
    })..rejectedKey = 'flutter.$_introKey';
    SharedPreferencesStorePlatform.instance = store;

    await expectLater(
      ProfileRepository().saveProfile(_profile(name: 'Updated')),
      throwsStateError,
    );

    final disk = await store.snapshot();
    expect(disk['flutter.$_introKey'], isFalse);
    _expectUnrelatedData(disk);
  });

  test('retry saves the same profile identity after a rejected write',
      () async {
    final store = _ControlledProfileStore(
      _seed(jsonEncode(_profile().toJson())),
    )..rejectedKey = 'flutter.$_profileKey';
    SharedPreferencesStorePlatform.instance = store;
    final repository = ProfileRepository();
    final update = _profile(name: 'Updated');

    await expectLater(repository.saveProfile(update), throwsStateError);
    store.rejectedKey = null;
    await repository.saveProfile(update);

    final disk = await store.snapshot();
    final saved = jsonDecode(disk['flutter.$_profileKey']! as String)
        as Map<String, dynamic>;
    expect(saved['id'], 'child-storage-test');
    expect(saved['name'], 'Updated');
    expect(disk['flutter.$_introKey'], isTrue);
    _expectUnrelatedData(disk);
  });

  for (final field in <String, Object>{
    'id': 123,
    'name': <String>[],
    'createdAt': 42,
    'lastActiveAt': <String>[],
  }.entries) {
    test('unreadable ${field.key} cannot be overwritten by a normal save',
        () async {
      final raw = jsonEncode({
        ..._profile().toJson(),
        field.key: field.value,
      });
      final store = _ControlledProfileStore({
        ..._seed(raw),
        _introKey: false,
      });
      SharedPreferencesStorePlatform.instance = store;
      final repository = ProfileRepository();

      expect(await repository.loadProfile(), isNull);
      await expectLater(
        repository.saveProfile(_profile(name: 'Updated')),
        throwsStateError,
      );

      final disk = await store.snapshot();
      expect(disk['flutter.$_profileKey'], raw);
      expect(disk['flutter.$_introKey'], isFalse);
      _expectUnrelatedData(disk);
    });
  }

  test('valid legacy data with extra fields stays readable and updatable',
      () async {
    final raw = jsonEncode({
      ..._profile(name: ' Anna ').toJson(),
      'futureField': {'preserveOnRead': true},
    });
    final store = _ControlledProfileStore(_seed(raw));
    SharedPreferencesStorePlatform.instance = store;
    final repository = ProfileRepository();

    final loaded = await repository.loadProfile();
    expect(loaded?.id, 'child-storage-test');
    expect(loaded?.name, 'Anna');
    expect(loaded?.grade, 2);
    expect((await store.snapshot())['flutter.$_profileKey'], raw);

    await repository.saveProfile(_profile(name: 'Updated'));
    final disk = await store.snapshot();
    final saved = jsonDecode(disk['flutter.$_profileKey']! as String)
        as Map<String, dynamic>;
    expect(saved['id'], 'child-storage-test');
    expect(saved['name'], 'Updated');
    expect(saved['grade'], 2);
    expect(disk['flutter.$_introKey'], isTrue);
    _expectUnrelatedData(disk);
  });
}
