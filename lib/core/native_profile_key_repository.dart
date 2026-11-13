import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'legacy_learning_data.dart';

class NativeProfileKeyException extends StateError {
  NativeProfileKeyException(this.code) : super(code);
  final String code;
}

class NativeLegacyGameKey {
  const NativeLegacyGameKey({
    required this.key,
    required this.name,
    required this.grade,
  });
  final String key;
  final String name;
  final int grade;
}

class NativeProfileKeys {
  const NativeProfileKeys({
    required this.primaryKey,
    required this.legacyAvailable,
    required this.legacy,
  });
  final String? primaryKey;
  final bool legacyAvailable;
  final List<NativeLegacyGameKey> legacy;
}

/// Owns only the mapping from a stable learning owner to native file identities.
/// No game file is read, copied, renamed, removed or merged by this repository.
class NativeProfileKeyRepository {
  const NativeProfileKeyRepository();

  static const storageKey = 'lumo_3d_profile_keys_v1';
  static const saltKey = 'lumo_3d_save_salt_v1';
  static final _keyPattern = RegExp(r'^p_[a-f0-9]{32}$');

  Future<String> resolve({
    required String ownerId,
    required bool isLocalProfile,
    required String legacyName,
    required int legacyGrade,
    required bool Function() isCurrent,
  }) =>
      LearningStorage.run((prefs) async {
        _checkOwner(ownerId);
        _checkCurrent(isCurrent);
        final existingSalt = prefs.getString(saltKey);
        final registry = _read(prefs, existingSalt != null);
        final existing = registry.owners[ownerId];
        if (existing != null) {
          _checkedSalt(existingSalt);
          return existing;
        }
        if (existingSalt == null && registry.owners.isNotEmpty) {
          throw NativeProfileKeyException('missing-salt');
        }
        var salt = existingSalt;
        if (salt == null) {
          final random = Random.secure();
          salt = List.generate(24,
                  (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
              .join();
          await _write(prefs, saltKey, salt);
        }
        _checkedSalt(salt);
        _checkCurrent(isCurrent);
        var key = _hash('$salt|native-profile-v2|$ownerId');
        // Only the unassigned, sole device profile can retain its exact old
        // identity automatically. A school child never claims this fallback.
        if (isLocalProfile &&
            registry.legacyAvailable &&
            _soleLocalProfile(prefs)) {
          final previous = _legacyKey(salt, legacyName, legacyGrade);
          if (registry.ownerOf(previous) == null) key = previous;
        }
        if (registry.ownerOf(key) != null) {
          throw NativeProfileKeyException('key-already-owned');
        }
        registry.owners[ownerId] = key;
        await _save(prefs, registry, isCurrent);
        return key;
      });

  Future<NativeProfileKeys> inspect(String ownerId) =>
      LearningStorage.run((prefs) async {
        _checkOwner(ownerId);
        final registry = _read(prefs, prefs.getString(saltKey) != null);
        return NativeProfileKeys(
          primaryKey: registry.owners[ownerId],
          legacyAvailable: registry.legacyAvailable,
          legacy: List.unmodifiable([
            for (final entry in registry.legacy.entries)
              if (entry.value.ownerId == ownerId)
                NativeLegacyGameKey(
                    key: entry.key,
                    name: entry.value.name,
                    grade: entry.value.grade),
          ]),
        );
      });

  /// Called only after the existing explicit adult-confirmation UI accepts.
  /// The old key remains separate from this child's normal, stable main key.
  Future<String> assignLegacy({
    required String ownerId,
    required String previousName,
    required int previousGrade,
    required bool Function() isCurrent,
  }) =>
      LearningStorage.run((prefs) async {
        _checkOwner(ownerId);
        _checkCurrent(isCurrent);
        final salt = _checkedSalt(prefs.getString(saltKey));
        final registry = _read(prefs, true);
        if (!registry.legacyAvailable) {
          throw NativeProfileKeyException('no-legacy-identity');
        }
        if (!registry.owners.containsKey(ownerId)) {
          throw NativeProfileKeyException('missing-owner');
        }
        final key = _legacyKey(salt, previousName, previousGrade);
        final previousOwner = registry.ownerOf(key);
        if (previousOwner != null && previousOwner != ownerId) {
          throw NativeProfileKeyException('key-already-owned');
        }
        if (registry.owners[ownerId] == key) {
          throw NativeProfileKeyException('already-primary');
        }
        if (previousOwner == ownerId) return key;
        registry.legacy[key] =
            _LegacyOwner(ownerId, previousName, previousGrade);
        await _save(prefs, registry, isCurrent);
        return key;
      });

  Future<String> authorizedLegacy({
    required String ownerId,
    required String key,
    required bool Function() isCurrent,
  }) =>
      LearningStorage.run((prefs) async {
        _checkOwner(ownerId);
        _checkCurrent(isCurrent);
        final registry = _read(prefs, prefs.getString(saltKey) != null);
        _checkedSalt(prefs.getString(saltKey));
        if (!_keyPattern.hasMatch(key) ||
            registry.legacy[key]?.ownerId != ownerId) {
          throw NativeProfileKeyException('unassigned-legacy-key');
        }
        return key;
      });

  static String _hash(String source) =>
      'p_${sha256.convert(utf8.encode(source)).toString().substring(0, 32)}';

  static String _legacyKey(String salt, String name, int grade) {
    // Do not trim/case-fold the old name: its exact bytes entered v1 hashes.
    if (name.length > 200 || grade < 1 || grade > 4) {
      throw NativeProfileKeyException('invalid-legacy-description');
    }
    return _hash('$salt|$name|$grade');
  }

  static void _checkOwner(String owner) {
    if (owner.trim().isEmpty || owner.length > 300) {
      throw NativeProfileKeyException('invalid-owner');
    }
  }

  static String _checkedSalt(String? salt) {
    if (salt == null || salt.isEmpty) {
      throw NativeProfileKeyException('missing-salt');
    }
    return salt;
  }

  static void _checkCurrent(bool Function() isCurrent) {
    if (!isCurrent()) throw NativeProfileKeyException('profile-changed');
  }

  static bool _soleLocalProfile(SharedPreferences prefs) {
    final selected = prefs.getString('lumo_school_active_student_v1');
    if (selected != null && selected.trim().isNotEmpty) return false;
    final directory = prefs.getString('lumo_school_v1');
    if (directory == null) return true;
    try {
      final data = jsonDecode(directory);
      return data is Map &&
          data['students'] is List &&
          (data['students'] as List).isEmpty;
    } catch (_) {
      // Ambiguous or damaged directory data is preserved, never treated as an
      // empty list merely to unlock an automatic legacy claim.
      return false;
    }
  }

  static _Registry _read(SharedPreferences prefs, bool hadSalt) {
    final raw = prefs.getString(storageKey);
    if (raw == null) return _Registry(hadSalt, {}, {});
    try {
      final data = jsonDecode(raw);
      if (data is! Map ||
          data['version'] != 1 ||
          data['legacyAvailable'] is! bool ||
          data['owners'] is! Map ||
          data['legacy'] is! Map) {
        throw const FormatException();
      }
      final owners = <String, String>{};
      final usedKeys = <String>{};
      for (final entry in (data['owners'] as Map).entries) {
        if (entry.key is! String ||
            entry.value is! String ||
            !_keyPattern.hasMatch(entry.value as String) ||
            !usedKeys.add(entry.value as String)) {
          throw const FormatException();
        }
        _checkOwner(entry.key as String);
        owners[entry.key as String] = entry.value as String;
      }
      final legacy = <String, _LegacyOwner>{};
      for (final entry in (data['legacy'] as Map).entries) {
        final row = entry.value;
        if (entry.key is! String ||
            !_keyPattern.hasMatch(entry.key as String) ||
            !usedKeys.add(entry.key as String) ||
            row is! Map ||
            row['owner'] is! String ||
            !owners.containsKey(row['owner']) ||
            row['name'] is! String ||
            (row['name'] as String).length > 200 ||
            row['grade'] is! int ||
            row['grade'] < 1 ||
            row['grade'] > 4) {
          throw const FormatException();
        }
        legacy[entry.key as String] = _LegacyOwner(
            row['owner'] as String, row['name'] as String, row['grade'] as int);
      }
      return _Registry(data['legacyAvailable'] as bool, owners, legacy);
    } catch (_) {
      throw NativeProfileKeyException('damaged-registry');
    }
  }

  static Future<void> _save(SharedPreferences prefs, _Registry registry,
      bool Function() isCurrent) async {
    _checkCurrent(isCurrent);
    await _write(
        prefs,
        storageKey,
        jsonEncode({
          'version': 1,
          'legacyAvailable': registry.legacyAvailable,
          'owners': registry.owners,
          'legacy': {
            for (final entry in registry.legacy.entries)
              entry.key: {
                'owner': entry.value.ownerId,
                'name': entry.value.name,
                'grade': entry.value.grade
              },
          },
        }));
    // A completed write still belongs to the captured owner if the UI changed
    // during storage. It must never authorize a launch for the next child.
    _checkCurrent(isCurrent);
  }

  static Future<void> _write(
      SharedPreferences prefs, String key, String value) async {
    try {
      await LearningStorage.write(prefs, key, value);
    } catch (_) {
      throw NativeProfileKeyException('write-failed');
    }
  }
}

class _Registry {
  _Registry(this.legacyAvailable, this.owners, this.legacy);
  final bool legacyAvailable;
  final Map<String, String> owners;
  final Map<String, _LegacyOwner> legacy;
  String? ownerOf(String key) {
    for (final entry in owners.entries) {
      if (entry.value == key) return entry.key;
    }
    return legacy[key]?.ownerId;
  }
}

class _LegacyOwner {
  _LegacyOwner(this.ownerId, this.name, this.grade);
  final String ownerId;
  final String name;
  final int grade;
}
