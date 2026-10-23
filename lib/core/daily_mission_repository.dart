import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'legacy_learning_data.dart';

/// A station is completed by assessed correct answers, including solved work
/// with help. Opening a lesson, wrong taps and game rewards are not evidence.
class DailyMissionStation {
  const DailyMissionStation({
    required this.subject,
    required this.completed,
    required this.target,
  });

  final String subject;
  final int completed;
  final int target;
  bool get isComplete => completed >= target;
}

/// Only successfully persisted snapshots are returned by the repository.
class DailyMissionSnapshot {
  DailyMissionSnapshot._({
    required this.studentId,
    required this.dayKey,
    required this.lastSeenAt,
    required List<DailyMissionStation> stations,
    required Set<String> acceptedTaskIds,
    this.clockUncertain = false,
  })  : stations = List.unmodifiable(stations),
        _acceptedTaskIds = Set.unmodifiable(acceptedTaskIds);

  final String studentId;
  final String dayKey;
  final DateTime lastSeenAt;
  final List<DailyMissionStation> stations;

  /// A backward wall-clock or calendar change cannot start an earlier mission
  /// or add evidence until time catches up with the persisted high watermark.
  final bool clockUncertain;
  final Set<String> _acceptedTaskIds;

  int get completedCount =>
      stations.fold(0, (total, station) => total + station.completed);
  int get targetCount =>
      stations.fold(0, (total, station) => total + station.target);
  bool get isComplete => stations.every((station) => station.isComplete);

  Map<String, Object> _toJson() => {
        'version': 1,
        'dayKey': dayKey,
        'lastSeenAt': lastSeenAt.toUtc().toIso8601String(),
        'stations': [
          for (final station in stations)
            {
              'subject': station.subject,
              'completed': station.completed,
              'target': station.target,
            },
        ],
        'acceptedTaskIds': _acceptedTaskIds.toList(growable: false),
      };
}

/// Additive local tracking in the existing learning-storage namespace.
///
/// Each transaction re-reads durable bytes while holding LearningStorage's
/// queue, so two repository instances cannot overwrite each other's answers.
/// IDs are retained across day changes; at capacity we refuse new evidence
/// instead of evicting old IDs and making old sessions replayable.
///
/// This detects backward clock changes. Offline wall time cannot authenticate
/// forward jumps or time after reboot; this is not a trusted-time service.
class DailyMissionRepository {
  DailyMissionRepository({
    required String studentId,
    DateTime Function()? now,
  })  : studentId = studentId.trim(),
        _now = now ?? DateTime.now {
    if (this.studentId.isEmpty) throw ArgumentError('Missing mission owner');
  }

  final String studentId;
  final DateTime Function() _now;
  static const _base = 'lumo_daily_mission_v1';
  static const _maxIds = 50000;

  Future<DailyMissionSnapshot> load({int tasksPerStation = 4}) =>
      _transaction(tasksPerStation: tasksPerStation);

  Future<DailyMissionSnapshot> recordAnswer({
    required String taskId,
    required String subject,
    required bool correct,
    int tasksPerStation = 4,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.:/-]{0,159}$')
        .hasMatch(taskId)) {
      throw ArgumentError('A stable opaque task identity is required');
    }
    return _transaction(
      tasksPerStation: tasksPerStation,
      taskHash: sha256.convert(utf8.encode(taskId)).toString(),
      subject: subject,
      correct: correct,
    );
  }

  Future<void> reset() => LearningStorage.run((prefs) async {
        await LearningStorage.remove(
            prefs, LearningDataNamespace.keyFor(_base, studentId));
      });

  Future<DailyMissionSnapshot> _transaction({
    required int tasksPerStation,
    String? taskHash,
    String? subject,
    bool correct = false,
  }) async {
    if (!const [2, 4, 6].contains(tasksPerStation)) {
      throw ArgumentError('Unsupported mission size');
    }
    return LearningStorage.run((prefs) async {
      final now = _now();
      if (now.year < 2000 || now.year > 2200) {
        throw StateError('Device time cannot be used for a daily mission');
      }
      final day = _dayKey(now);
      final key = LearningDataNamespace.keyFor(_base, studentId);
      final raw = prefs.getString(key);
      final saved = raw == null ? null : _read(raw);
      if (saved != null &&
          (now.toUtc().isBefore(saved.lastSeenAt) ||
              day.compareTo(saved.dayKey) < 0)) {
        return DailyMissionSnapshot._(
          studentId: studentId,
          dayKey: saved.dayKey,
          lastSeenAt: saved.lastSeenAt,
          stations: saved.stations,
          acceptedTaskIds: saved._acceptedTaskIds,
          clockUncertain: true,
        );
      }
      final sameDay = saved?.dayKey == day;
      final previousStations = sameDay
          ? saved!.stations
          : [
              for (final name in _subjectsFor(day))
                DailyMissionStation(
                    subject: name, completed: 0, target: tasksPerStation),
            ];
      final accepted = {...?saved?._acceptedTaskIds};
      final eligible = correct &&
          taskHash != null &&
          const ['Mathematik', 'Deutsch', 'Englisch', 'Sachunterricht']
              .contains(subject) &&
          !accepted.contains(taskHash);
      if (eligible) {
        if (accepted.length >= _maxIds) {
          throw StateError('Mission evidence capacity reached');
        }
        // Consume every supported assessed task, even beyond a full station,
        // so retagging/replaying it on a later day cannot grant new credit.
        accepted.add(taskHash);
      }
      final next = DailyMissionSnapshot._(
        studentId: studentId,
        dayKey: day,
        lastSeenAt: now.toUtc(),
        stations: [
          for (final station in previousStations)
            DailyMissionStation(
              subject: station.subject,
              target: station.target,
              completed: station.completed +
                  (eligible &&
                          station.subject == subject &&
                          !station.isComplete
                      ? 1
                      : 0),
            ),
        ],
        acceptedTaskIds: accepted,
      );
      final encoded = jsonEncode(next._toJson());
      if (encoded != raw) await LearningStorage.write(prefs, key, encoded);
      return next;
    });
  }

  DailyMissionSnapshot _read(String raw) {
    if (raw.length > 8 * 1024 * 1024) {
      throw const FormatException('Unsupported mission size');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> ||
        decoded.keys.toSet().difference(const {
          'version', 'dayKey', 'lastSeenAt', 'stations', 'acceptedTaskIds'
        }).isNotEmpty ||
        decoded['version'] != 1) {
      throw const FormatException('Unsupported daily mission format');
    }
    final day = decoded['dayKey'];
    final seenValue = decoded['lastSeenAt'];
    final rawStations = decoded['stations'];
    final rawIds = decoded['acceptedTaskIds'];
    if (day is! String ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ||
        seenValue is! String ||
        rawStations is! List ||
        rawStations.length != 3 ||
        rawIds is! List ||
        rawIds.length > _maxIds) {
      throw const FormatException('Invalid daily mission evidence');
    }
    final date = DateTime.tryParse('${day}T00:00:00Z');
    final seen = DateTime.tryParse(seenValue);
    if (date == null ||
        _dayKey(date) != day ||
        date.year < 2000 || date.year > 2200 ||
        seen == null || seen.year < 2000 || seen.year > 2200) {
      throw const FormatException('Invalid daily mission time');
    }
    final names = _subjectsFor(day);
    final stations = <DailyMissionStation>[];
    for (var i = 0; i < 3; i++) {
      final value = rawStations[i];
      if (value is! Map<String, dynamic> ||
          value.keys.toSet().difference(
              const {'subject', 'completed', 'target'}).isNotEmpty ||
          value['subject'] != names[i] ||
          value['target'] is! int ||
          !const [2, 4, 6].contains(value['target']) ||
          value['completed'] is! int ||
          value['completed'] < 0 ||
          value['completed'] > value['target']) {
        throw const FormatException('Invalid daily mission station');
      }
      stations.add(DailyMissionStation(
          subject: names[i],
          completed: value['completed'] as int,
          target: value['target'] as int));
    }
    if (stations.any((station) => station.target != stations.first.target) ||
        rawIds.any((value) => value is! String ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) ||
        rawIds.toSet().length != rawIds.length ||
        stations.fold<int>(0, (sum, station) => sum + station.completed) >
            rawIds.length) {
      throw const FormatException('Inconsistent daily mission evidence');
    }
    return DailyMissionSnapshot._(
        studentId: studentId,
        dayKey: day,
        lastSeenAt: seen.toUtc(),
        stations: stations,
        acceptedTaskIds: rawIds.cast<String>().toSet());
  }

  static String _dayKey(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-'
      '${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  static List<String> _subjectsFor(String day) {
    final date = DateTime.parse('${day}T00:00:00Z');
    final english = date.difference(DateTime.utc(2000)).inDays.isEven;
    return ['Mathematik', 'Deutsch', english ? 'Englisch' : 'Sachunterricht'];
  }
}
