import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:lumo_lernen/core/native_profile_key_repository.dart';

const salt = 'synthetic-2017-native-salt';
const repository = NativeProfileKeyRepository();
String oldKey(String name, int grade) =>
    'p_${sha256.convert(utf8.encode('$salt|$name|$grade')).toString().substring(0, 32)}';
Future<String> resolve(String owner,
        {bool local = false,
        String name = 'Testkind',
        int grade = 2,
        bool Function()? current}) =>
    repository.resolve(
        ownerId: owner,
        isLocalProfile: local,
        legacyName: name,
        legacyGrade: grade,
        isCurrent: current ?? () => true);
Matcher code(String expected) => isA<NativeProfileKeyException>()
    .having((error) => error.code, 'code', expected);

class ControlledStore extends InMemorySharedPreferencesStore {
  ControlledStore()
      : super.withData({
          'flutter.${NativeProfileKeyRepository.saltKey}': salt,
        });
  String? reject;
  bool pause = false;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == reject) return false;
    if (pause && key == 'flutter.${NativeProfileKeyRepository.storageKey}') {
      entered.complete();
      await release.future;
      pause = false;
    }
    return super.setValue(valueType, key, value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({
        NativeProfileKeyRepository.saltKey: salt,
        'synthetic-existing-game-data': '{"version":1,"moves":17}',
      }));

  test(
      'sole local 2017 profile keeps exact file key through rename, grade and reload',
      () async {
    final key = await resolve('local-persistent-id', local: true);
    expect(key, oldKey('Testkind', 2));
    expect('user://lumo_puzzle_$key.json',
        'user://lumo_puzzle_${oldKey('Testkind', 2)}.json');
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    expect(
        await const NativeProfileKeyRepository().resolve(
            ownerId: 'local-persistent-id',
            isLocalProfile: true,
            legacyName: 'Neuer Name',
            legacyGrade: 4,
            isCurrent: () => true),
        key);
    expect(prefs.getString('synthetic-existing-game-data'),
        '{"version":1,"moves":17}');
    expect(prefs.getString(NativeProfileKeyRepository.saltKey), salt);
  });

  test('same-name school pupils get different stable main keys', () async {
    final first = await resolve('school-a');
    final second = await resolve('school-b');
    expect(first, isNot(second));
    expect(first, isNot(oldKey('Testkind', 2)));
    expect(second, isNot(oldKey('Testkind', 2)));
    expect(await resolve('school-a', name: 'Renamed', grade: 4), first);
    expect(await resolve('school-b', grade: 3), second);
  });

  test(
      'local fallback never auto-claims legacy when school directory is ambiguous',
      () async {
    final prefs = await SharedPreferences.getInstance();
    for (final raw in ['{"students":[{"id":"school-a"}]}', '{broken']) {
      await prefs.setString('lumo_school_v1', raw);
      final key = await resolve('local-$raw', local: true);
      expect(key, isNot(oldKey('Testkind', 2)));
      expect(prefs.getString('lumo_school_v1'), raw);
    }
  });

  test(
      'active school selection blocks automatic solo fallback even without directory',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lumo_school_active_student_v1', 'school-a');
    expect(
        await resolve('local-id', local: true), isNot(oldKey('Testkind', 2)));
  });

  test(
      'adult legacy assignment is separate, exclusive and reopens exact historical key',
      () async {
    final primary = await resolve('school-a');
    await resolve('school-b');
    final key = await repository.assignLegacy(
        ownerId: 'school-a',
        previousName: 'Testkind',
        previousGrade: 2,
        isCurrent: () => true);
    expect(key, oldKey('Testkind', 2));
    expect(await resolve('school-a'), primary);
    expect((await repository.inspect('school-a')).legacy.single.key, key);
    expect(
        await repository.authorizedLegacy(
            ownerId: 'school-a', key: key, isCurrent: () => true),
        key);
    await expectLater(
        repository.assignLegacy(
            ownerId: 'school-b',
            previousName: 'Testkind',
            previousGrade: 2,
            isCurrent: () => true),
        throwsA(code('key-already-owned')));
    await expectLater(
        repository.authorizedLegacy(
            ownerId: 'school-b', key: key, isCurrent: () => true),
        throwsA(code('unassigned-legacy-key')));
    expect(
        await repository.assignLegacy(
            ownerId: 'school-a',
            previousName: 'Testkind',
            previousGrade: 2,
            isCurrent: () => true),
        key);
  });

  test('a retained solo key cannot also be assigned to a school child',
      () async {
    await resolve('local-id', local: true);
    await resolve('school-a');
    await expectLater(
        repository.assignLegacy(
            ownerId: 'school-a',
            previousName: 'Testkind',
            previousGrade: 2,
            isCurrent: () => true),
        throwsA(code('key-already-owned')));
  });

  test('concurrent claims cannot bind an old key to two owners', () async {
    await resolve('school-a');
    await resolve('school-b');
    final results = await Future.wait([
      for (final owner in ['school-a', 'school-b'])
        repository
            .assignLegacy(
                ownerId: owner,
                previousName: 'Old',
                previousGrade: 1,
                isCurrent: () => true)
            .then<Object>((key) => key, onError: (Object error) => error),
    ]);
    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<NativeProfileKeyException>(), hasLength(1));
  });

  test(
      'rejected persistence reloads optimistic cache and permits a durable retry',
      () async {
    final store = ControlledStore()
      ..reject = 'flutter.${NativeProfileKeyRepository.storageKey}';
    SharedPreferencesStorePlatform.instance = store;
    await expectLater(resolve('school-a'), throwsA(code('write-failed')));
    expect((await repository.inspect('school-a')).primaryKey, isNull);
    store.reject = null;
    final key = await resolve('school-a');
    expect((await repository.inspect('school-a')).primaryKey, key);
    store.reject = 'flutter.${NativeProfileKeyRepository.storageKey}';
    await expectLater(
        repository.assignLegacy(
            ownerId: 'school-a',
            previousName: 'Old',
            previousGrade: 1,
            isCurrent: () => true),
        throwsA(code('write-failed')));
    expect((await repository.inspect('school-a')).legacy, isEmpty);
    expect(await resolve('school-a'), key);
  });

  test('stale lease before write leaves registry untouched', () async {
    final prefs = await SharedPreferences.getInstance();
    await expectLater(resolve('school-a', current: () => false),
        throwsA(code('profile-changed')));
    expect(prefs.getString(NativeProfileKeyRepository.storageKey), isNull);
  });

  test('switch during persistence never returns a key for the next child',
      () async {
    final store = ControlledStore()..pause = true;
    SharedPreferencesStorePlatform.instance = store;
    var current = true;
    final operation = resolve('school-a', current: () => current);
    final observed = expectLater(operation, throwsA(code('profile-changed')));
    await store.entered.future;
    current = false;
    store.release.complete();
    await observed;
    final first = (await repository.inspect('school-a')).primaryKey;
    final second = await resolve('school-b');
    expect(first, isNotNull);
    expect(second, isNot(first));
  });

  test('corrupt registry and missing salt fail closed without discarding data',
      () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(NativeProfileKeyRepository.storageKey, '{broken');
    await expectLater(resolve('school-a'), throwsA(code('damaged-registry')));
    expect(prefs.getString(NativeProfileKeyRepository.storageKey), '{broken');
    await prefs.remove(NativeProfileKeyRepository.storageKey);
    await resolve('school-a');
    final original = prefs.getString(NativeProfileKeyRepository.storageKey);
    await prefs.remove(NativeProfileKeyRepository.saltKey);
    await expectLater(resolve('school-a'), throwsA(code('missing-salt')));
    expect(prefs.getString(NativeProfileKeyRepository.storageKey), original);
    expect(prefs.getString(NativeProfileKeyRepository.saltKey), isNull);
  });

  test('fresh installation has no invented historical identity', () async {
    SharedPreferences.setMockInitialValues({});
    final key = await resolve('local-id', local: true);
    expect(key, matches(r'^p_[a-f0-9]{32}$'));
    expect((await repository.inspect('local-id')).legacyAvailable, isFalse);
    await expectLater(
        repository.assignLegacy(
            ownerId: 'local-id',
            previousName: 'Old',
            previousGrade: 1,
            isCurrent: () => true),
        throwsA(code('no-legacy-identity')));
  });
}
