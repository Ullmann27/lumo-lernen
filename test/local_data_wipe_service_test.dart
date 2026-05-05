import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/core/local_data_wipe_service.dart';
import 'package:lumo_lernen/core/parent_pin_service.dart';

void main() {
  group('LocalDataWipeService', () {
    const service = LocalDataWipeService();
    const pinService = ParentPinService();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('wipeChildData removes progress, caches and rewards but keeps parent PIN', () async {
      final prefs = await SharedPreferences.getInstance();
      await pinService.createPin('2468');
      await prefs.setString('lumo_progress_skills', '{"x":1}');
      await prefs.setString('lumo_progress_daily', '{"2026-05-05":1}');
      await prefs.setString('lumo_recent_tasks_local_lena_1_mathematik', 'a|b');
      await prefs.setString('lumo_ai_tasks_local_lena_1_mathematik', '[]');
      await prefs.setString('lumo_rewards_wallet', '{"stars":10}');
      await prefs.setString('lumo_app_settings_v1', '{"voiceEnabled":true}');

      final report = await service.wipeChildData();

      expect(report.removedKeys, contains('lumo_progress_skills'));
      expect(report.removedKeys, contains('lumo_recent_tasks_local_lena_1_mathematik'));
      expect(report.removedKeys, contains('lumo_ai_tasks_local_lena_1_mathematik'));
      expect(report.removedKeys, contains('lumo_rewards_wallet'));
      expect(prefs.containsKey('lumo_progress_skills'), isFalse);
      expect(prefs.containsKey('lumo_recent_tasks_local_lena_1_mathematik'), isFalse);
      expect(prefs.containsKey('lumo_ai_tasks_local_lena_1_mathematik'), isFalse);
      expect(prefs.containsKey('lumo_rewards_wallet'), isFalse);
      expect(prefs.containsKey('lumo_app_settings_v1'), isTrue);
      expect(await pinService.isPinSet(), isTrue);
    });

    test('wipeEverythingIncludingParentPin clears all keys', () async {
      final prefs = await SharedPreferences.getInstance();
      await pinService.createPin('1357');
      await prefs.setString('lumo_progress_skills', '{"x":1}');
      await prefs.setString('lumo_app_settings_v1', '{"voiceEnabled":true}');

      final report = await service.wipeEverythingIncludingParentPin();

      expect(report.removedKeys, isNotEmpty);
      expect(prefs.getKeys(), isEmpty);
      expect(await pinService.isPinSet(), isFalse);
    });

    test('wipeChildData is idempotent', () async {
      await service.wipeChildData();
      final second = await service.wipeChildData();

      expect(second.removedKeys, isEmpty);
    });
  });
}
