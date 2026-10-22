import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/profile_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';

UserProfile _child() => UserProfile(
      id: 'safe-child',
      name: 'Lumo Test',
      age: 7,
      grade: 2,
      createdAt: DateTime.utc(2026, 1, 1),
      lastActiveAt: DateTime.utc(2026, 10, 16),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => SharedPreferences.setMockInitialValues({}));

  test('a damaged previous profile cannot be overwritten by onboarding',
      () async {
    const damaged = '{"id": "child-original", "grade":';
    SharedPreferences.setMockInitialValues({
      'lumo_active_profile': damaged,
      'lumo_intro_seen': true,
      'lumo_reward_wallet_v1': '{"stars":80,"xp":50}',
      'lumo_journal_entries': '[{"note":"keep"}]',
    });
    final repository = ProfileRepository();
    expect(await repository.loadProfile(), isNull);
    await expectLater(repository.saveProfile(_child()), throwsStateError);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_active_profile'), damaged);
    expect(prefs.getBool('lumo_intro_seen'), true);
    expect(prefs.getString('lumo_reward_wallet_v1'), '{"stars":80,"xp":50}');
    expect(prefs.getString('lumo_journal_entries'), '[{"note":"keep"}]');
  });

  test('reading an older valid profile never silently rewrites its raw data',
      () async {
    final existing = jsonEncode({
      ..._child().toJson(),
      'unrecognized_future_profile_field': {'migration': 'preserve'},
    });
    SharedPreferences.setMockInitialValues({
      'lumo_active_profile': existing,
      'lumo_intro_seen': true,
    });
    final loaded = await ProfileRepository().loadProfile();
    expect(loaded?.id, 'safe-child');
    expect(loaded?.grade, 2);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lumo_active_profile'), existing);
  });

  test('explicit saving a valid profile preserves its identity and grade',
      () async {
    final repository = ProfileRepository();
    await repository.saveProfile(_child());
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('lumo_intro_seen'), true);
    final saved = jsonDecode(prefs.getString('lumo_active_profile')!)
        as Map<String, dynamic>;
    expect(saved['id'], 'safe-child');
    expect(saved['name'], 'Lumo Test');
    expect(saved['grade'], 2);
  });
}
