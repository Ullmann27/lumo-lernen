import 'package:shared_preferences/shared_preferences.dart';

import 'parent_pin_service.dart';

class LocalDataWipeReport {
  const LocalDataWipeReport({
    required this.removedKeys,
    required this.keptKeys,
  });

  final List<String> removedKeys;
  final List<String> keptKeys;

  int get removedCount => removedKeys.length;
}

class LocalDataWipeService {
  const LocalDataWipeService({this.parentPinService = const ParentPinService()});

  final ParentPinService parentPinService;

  static const Set<String> _childDataExactKeys = <String>{
    'lumo_progress_skills',
    'lumo_progress_daily',
    'lumo_progress_last',
  };

  static const Set<String> _childDataPrefixes = <String>{
    'lumo_recent_tasks_',
    'lumo_recent_units_',
    'lumo_ai_tasks_',
    'lumo_ai_tasks_meta_',
    'lumo_scan_',
    'lumo_ocr_',
    'lumo_audit_',
    'lumo_rewards_',
    'lumo_reward_',
    'lumo_wallet_',
    'lumo_voucher_',
  };

  static const Set<String> _pinKeys = <String>{
    ParentPinService.saltKey,
    ParentPinService.hashKey,
    ParentPinService.createdAtKey,
  };

  Future<LocalDataWipeReport> wipeChildData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList(growable: false)..sort();
    final removed = <String>[];
    final kept = <String>[];

    for (final key in keys) {
      if (_pinKeys.contains(key)) {
        kept.add(key);
        continue;
      }
      if (_isChildDataKey(key)) {
        await prefs.remove(key);
        removed.add(key);
      } else {
        kept.add(key);
      }
    }

    return LocalDataWipeReport(removedKeys: removed, keptKeys: kept);
  }

  Future<LocalDataWipeReport> wipeEverythingIncludingParentPin() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList(growable: false)..sort();
    await prefs.clear();
    return LocalDataWipeReport(removedKeys: keys, keptKeys: const <String>[]);
  }

  bool _isChildDataKey(String key) {
    if (_childDataExactKeys.contains(key)) return true;
    return _childDataPrefixes.any(key.startsWith);
  }
}
