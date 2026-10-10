import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Serializes the short local-storage transactions, including legacy claims.
/// No completed Future is retained across app/test lifetimes.
class LearningStorage {
  static Future<void>? _tail;

  static Future<T> run<T>(Future<T> Function(SharedPreferences) action) {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    Future<T> perform() async {
      if (previous != null) await previous;
      return action(await SharedPreferences.getInstance());
    }

    final result = perform();
    void finish() {
      if (identical(_tail, done.future)) _tail = null;
      done.complete();
    }

    unawaited(result.then<void>((_) => finish(),
        onError: (Object _, StackTrace __) => finish()));
    return result;
  }

  static Future<void> write(
      SharedPreferences prefs, String key, String value) async {
    try {
      if (await prefs.setString(key, value)) return;
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
    // SharedPreferences updates its cache even when the platform returns false.
    // Reload before another operation can mistake that value for durable data.
    await prefs.reload();
    throw StateError('Learning data was not saved');
  }

  static Future<void> remove(SharedPreferences prefs, String key) async {
    try {
      if (await prefs.remove(key)) return;
    } catch (_) {
      await prefs.reload();
      rethrow;
    }
    await prefs.reload();
    throw StateError('Learning data was not removed');
  }
}

class LegacyLearningDataException extends StateError {
  LegacyLearningDataException(this.code) : super(code);
  final String code;
}

class LegacyLearningDataStatus {
  const LegacyLearningDataStatus({
    required this.hasData,
    required this.hasProgress,
    required this.hasCosmos,
    this.assignedStudentId,
    this.pendingAssignment = false,
    this.reservedStudentId,
    this.problem,
  });

  final bool hasData;
  final bool hasProgress;
  final bool hasCosmos;
  final String? assignedStudentId;
  final bool pendingAssignment;
  final String? reservedStudentId;
  final String? problem;

  bool get canAssign =>
      hasData &&
      assignedStudentId == null &&
      !pendingAssignment &&
      problem == null;
}

/// Preserves unowned, device-wide data until an adult chooses its owner.
/// A reservation plus an immutable snapshot makes an interrupted assignment
/// retryable without exposing half a migration or copying it to two children.
class LegacyLearningDataRepository {
  static const localIdKey = 'lumo_learning_local_student_id_v1';
  static const claimKey = 'lumo_learning_legacy_claim_v1';
  static const stageKey = 'lumo_learning_legacy_snapshot_v1';
  static const legacyKeys = <String>[
    'lumo_progress_skills',
    'lumo_progress_daily',
    'lumo_progress_last',
    'lumo_cosmos_items_v1',
    'lumo_cosmos_meta_v1',
  ];

  Future<String> localStudentId() => LearningStorage.run((prefs) async {
        final existing = prefs.getString(localIdKey)?.trim();
        if (existing != null && existing.isNotEmpty) return existing;
        final random = Random.secure();
        final suffix = List.generate(16,
                (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'))
            .join();
        final id = 'local-$suffix';
        try {
          await LearningStorage.write(prefs, localIdKey, id);
        } catch (_) {
          throw LegacyLearningDataException('write-failed');
        }
        return id;
      });

  Future<LegacyLearningDataStatus> inspect() =>
      LearningStorage.run((prefs) async => _inspect(prefs));

  Future<void> assignTo(String studentId) => LearningStorage.run(
      (prefs) => _assign(prefs, _checkedStudentId(studentId)));

  static String _checkedStudentId(String value) {
    final id = value.trim();
    if (id.isEmpty) throw LegacyLearningDataException('invalid-student');
    return id;
  }

  static Map<String, String> _originals(SharedPreferences prefs) => {
        for (final key in legacyKeys)
          if (prefs.getString(key) case final String value)
            if (value.trim().isNotEmpty) key: value,
      };

  static Map<String, dynamic>? _claim(SharedPreferences prefs) {
    final raw = prefs.getString(claimKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map<String, dynamic> &&
          data['version'] == 1 &&
          data['owner'] is String &&
          (data['owner'] as String).trim().isNotEmpty &&
          (data['state'] == 'prepared' || data['state'] == 'committed')) {
        return data;
      }
    } catch (_) {}
    throw LegacyLearningDataException('damaged-claim');
  }

  static Map<String, String>? _snapshot(SharedPreferences prefs, String owner) {
    final raw = prefs.getString(stageKey);
    if (raw == null) return null;
    try {
      final snapshot = jsonDecode(raw);
      if (snapshot is Map &&
          snapshot['owner'] == owner &&
          snapshot['data'] is Map) {
        final data = Map<String, String>.from(snapshot['data'] as Map);
        if (data.isNotEmpty &&
            data.keys.every(legacyKeys.contains) &&
            _validData(data)) {
          return data;
        }
      }
    } catch (_) {}
    throw LegacyLearningDataException('damaged-claim');
  }

  static bool _validData(Map<String, String> originals) {
    try {
      for (final entry in originals.entries) {
        final decoded = jsonDecode(entry.value);
        if (entry.key == 'lumo_cosmos_items_v1') {
          if (decoded is! List) return false;
          for (final item in decoded) {
            if (item is! Map ||
                item['t'] is! int ||
                (item['t'] as int) < 0 ||
                (item['t'] as int) >= 13 ||
                ![
                  'x',
                  'y',
                  's'
                ].every((k) => item[k] is num && (item[k] as num).isFinite) ||
                (item['r'] != null && item['r'] is! num)) {
              return false;
            }
          }
        } else {
          if (decoded is! Map) return false;
          if (entry.key == 'lumo_progress_skills') {
            for (final row in decoded.values) {
              if (row is! Map ||
                  ['skillId', 'subject', 'unit', 'lastSeen']
                      .any((key) => row[key] != null && row[key] is! String) ||
                  [
                    'correct',
                    'wrong',
                    'hintCount',
                    'currentStreak',
                    'currentMisses',
                    'difficulty'
                  ].any((key) => row[key] != null && row[key] is! num)) {
                return false;
              }
            }
          }
          if (entry.key == 'lumo_cosmos_meta_v1' &&
              (['c', 's'].any(
                      (key) => decoded[key] != null && decoded[key] is! int) ||
                  (decoded['d'] != null && decoded['d'] is! String))) {
            return false;
          }
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static LegacyLearningDataStatus _inspect(SharedPreferences prefs) {
    final originals = _originals(prefs);
    Map<String, dynamic>? claim;
    String? problem;
    try {
      claim = _claim(prefs);
      if (claim?['state'] == 'committed' &&
          _snapshot(prefs, claim!['owner'] as String) == null) {
        problem = 'damaged-claim';
      } else if (claim?['state'] == 'prepared') {
        _snapshot(prefs, claim!['owner'] as String);
      }
    } on LegacyLearningDataException catch (error) {
      problem = error.code;
    }
    if (problem == null && !_validData(originals)) problem = 'damaged-legacy';
    return LegacyLearningDataStatus(
      hasData: originals.isNotEmpty,
      hasProgress:
          originals.keys.any((key) => key.startsWith('lumo_progress_')),
      hasCosmos: originals.keys.any((key) => key.startsWith('lumo_cosmos_')),
      assignedStudentId: claim?['state'] == 'committed' && problem == null
          ? claim!['owner'] as String
          : null,
      pendingAssignment: claim?['state'] == 'prepared',
      reservedStudentId:
          claim?['state'] == 'prepared' ? claim!['owner'] as String : null,
      problem: problem,
    );
  }

  static Future<void> _assign(SharedPreferences prefs, String owner) async {
    final status = _inspect(prefs);
    if (status.problem != null) {
      throw LegacyLearningDataException(status.problem!);
    }
    final claimed = status.assignedStudentId ?? status.reservedStudentId;
    if (claimed != null && claimed != owner) {
      throw LegacyLearningDataException('reserved-for-another-student');
    }
    if (status.assignedStudentId == owner) return;
    if (!status.hasData) throw LegacyLearningDataException('missing-legacy');
    // An adult may only assign to an untouched destination. Never merge
    // unrelated counters, append duplicate Cosmos objects, or replace progress.
    final destinationKeys = [...legacyKeys, 'lumo_cosmos_v2'];
    if (destinationKeys.any(
        (key) => prefs.containsKey(LearningDataNamespace.keyFor(key, owner)))) {
      throw LegacyLearningDataException('destination-not-empty');
    }
    try {
      if (!status.pendingAssignment) {
        await LearningStorage.write(
            prefs,
            claimKey,
            jsonEncode({
              'version': 1,
              'owner': owner,
              'state': 'prepared',
            }));
      }
      if (_snapshot(prefs, owner) == null) {
        await LearningStorage.write(
            prefs,
            stageKey,
            jsonEncode({
              'owner': owner,
              'data': _originals(prefs),
            }));
      }
      // Only this final durable marker exposes the complete snapshot.
      await LearningStorage.write(
          prefs,
          claimKey,
          jsonEncode({
            'version': 1,
            'owner': owner,
            'state': 'committed',
          }));
    } on LegacyLearningDataException {
      rethrow;
    } catch (_) {
      throw LegacyLearningDataException('write-failed');
    }
  }

  static bool _soleUnassignedLocal(SharedPreferences prefs, String owner) {
    if (prefs.getString(localIdKey) != owner ||
        (prefs.getString('lumo_school_active_student_v1')?.trim().isNotEmpty ??
            false)) {
      return false;
    }
    final school = prefs.getString('lumo_school_v1');
    if (school == null || school.trim().isEmpty) return true;
    try {
      final decoded = jsonDecode(school);
      return decoded is Map &&
          decoded['students'] is List &&
          (decoded['students'] as List).isEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _prepareLocal(
      SharedPreferences prefs, String owner) async {
    if (!_soleUnassignedLocal(prefs, owner)) return;
    final status = _inspect(prefs);
    final hasDestination = [
      ...legacyKeys,
      'lumo_cosmos_v2'
    ].any((key) => prefs.containsKey(LearningDataNamespace.keyFor(key, owner)));
    if ((status.canAssign && !hasDestination) ||
        (status.pendingAssignment &&
            status.reservedStudentId == owner &&
            status.problem == null)) {
      await _assign(prefs, owner);
    }
  }

  static String? _readCommitted(
      SharedPreferences prefs, String owner, String key) {
    final claim = _claim(prefs);
    if (claim?['owner'] != owner) return null;
    if (claim?['state'] == 'prepared') {
      throw StateError('Legacy assignment is awaiting completion');
    }
    final snapshot = _snapshot(prefs, owner);
    if (snapshot == null) throw LegacyLearningDataException('damaged-claim');
    return snapshot[key];
  }

  static void _checkWritable(SharedPreferences prefs, String owner) {
    final claim = _claim(prefs);
    if (claim?['owner'] == owner && claim?['state'] == 'prepared') {
      throw StateError('Legacy assignment is awaiting completion');
    }
  }
}

/// Immutable namespace. An omitted ID resolves once to the persisted primary
/// local ID, never to a display name, grade, or whatever child is active later.
class LearningDataNamespace {
  LearningDataNamespace({String? studentId})
      : _explicitId = studentId == null
            ? null
            : LegacyLearningDataRepository._checkedStudentId(studentId);

  final String? _explicitId;
  Future<String>? _localId;

  Future<String> get studentId {
    if (_explicitId != null) return Future<String>.value(_explicitId);
    return _localId ??= _resolveLocalId();
  }

  Future<String> _resolveLocalId() async {
    try {
      return await LegacyLearningDataRepository().localStudentId();
    } catch (_) {
      _localId = null;
      rethrow;
    }
  }

  static String keyFor(String base, String studentId) =>
      '$base::${Uri.encodeComponent(studentId)}';

  Future<String?> read(String base) async {
    final owner = await studentId;
    return LearningStorage.run((prefs) async {
      await LegacyLearningDataRepository._prepareLocal(prefs, owner);
      LegacyLearningDataRepository._checkWritable(prefs, owner);
      return prefs.getString(keyFor(base, owner)) ??
          LegacyLearningDataRepository._readCommitted(prefs, owner, base);
    });
  }

  Future<void> write(String base, String value) async {
    final owner = await studentId;
    return LearningStorage.run((prefs) async {
      await LegacyLearningDataRepository._prepareLocal(prefs, owner);
      LegacyLearningDataRepository._checkWritable(prefs, owner);
      await LearningStorage.write(prefs, keyFor(base, owner), value);
    });
  }
}
