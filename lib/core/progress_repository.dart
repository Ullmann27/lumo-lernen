import 'dart:convert';

import 'discovery_progress.dart';
import 'learning_journey.dart';
import 'legacy_learning_data.dart';
import 'session_round_resume.dart';
import '../domain/learning_intelligence/scene_memory.dart';
import '../domain/learning/independent_evidence.dart';
import '../domain/learning/skill_evidence.dart';

/// Speichert den Lernfortschritt eines Kindes lokal auf dem Gerät.
/// Offline-first. Keine Cloud. Kein Tracking.
class ProgressRepository {
  ProgressRepository({String? studentId})
      : _namespace = LearningDataNamespace(studentId: studentId);

  final LearningDataNamespace _namespace;
  Future<String> get studentId => _namespace.studentId;

  static const _skillsKey = 'lumo_progress_skills';
  static const _dailyKey = 'lumo_progress_daily';
  static const _lastKey = 'lumo_progress_last';
  static const _discoveryKey = 'lumo_progress_discovery_v1';
  static const _journeyKey = 'lumo_progress_journey_v1';
  static const _tutorResetKey = 'lumo_tutor_reset_pending_v1';

  /// Calendar days on which a topic was solved alone. A separate, additive
  /// key: the saved skill records keep their exact format, and an older app
  /// version simply ignores this entry.
  static const _independentDaysKey = 'lumo_progress_independent_days_v1';
  Future<void> _tutorTail = Future<void>.value();

  // Keep a confirmed deletion durable across a failed write or process exit.
  // Clear tutor evidence and resumable lesson views; real school answers remain.
  Future<void> _finishTutorReset() async {
    if (await _namespace.read(_tutorResetKey) != '1') return;
    await _namespace.write('lumo_learning_scene_pending_v1', 'null');
    await _namespace.write('lumo_photo_lesson_session_v1', 'null');
    await _namespace.write('lumo_learning_lab_session_v1',
        jsonEncode({'version': 1, 'sessions': <String, Object?>{}}));
    await _namespace.write(_journeyKey, jsonEncode(LearningJourney().toJson()));
    await _namespace.write(
        'lumo_learning_scenes_v1', jsonEncode(SceneMemory().toJson()));
    await _namespace.write(_tutorResetKey, '0');
  }

  Future<T> _tutorStorage<T>(Future<T> Function() action) {
    Future<T> run() async {
      await _finishTutorReset();
      return action();
    }

    final operation = _tutorTail.then((_) => run(),
        onError: (Object _, StackTrace __) => run());
    _tutorTail =
        operation.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return operation;
  }

  Future<void> resetTutorObservations() => _tutorStorage(() async {
        await _namespace.write(_tutorResetKey, '1');
        await _finishTutorReset();
      });
  static const _skillFields = {
    'skillId',
    'subject',
    'unit',
    'correct',
    'wrong',
    'hintCount',
    'currentStreak',
    'currentMisses',
    'difficulty',
    'lastSeen',
    'independentEvidence',
  };

  /// Read errors are not permission to reset a child's history. Never pass the
  /// stored bytes into an exception/log or overwrite a bad/newer format.
  static Map<String, dynamic> _readObject(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException(
          'Saved learning data could not be read safely');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unsupported saved learning data format');
    }
    return decoded;
  }

  /// A new per-child field in this repository, never a second database.
  /// Bad/newer bytes are not normalized, overwritten or deleted on read.
  Future<DiscoveryProgress> loadDiscovery() async {
    final raw = await _namespace.read(_discoveryKey);
    if (raw == null) return DiscoveryProgress();
    return DiscoveryProgress.fromJson(jsonDecode(raw));
  }

  Future<void> saveDiscovery(DiscoveryProgress value) =>
      _namespace.write(_discoveryKey, jsonEncode(value.toJson()));

  /// Additive, per-child evidence. A read never rewrites bad or newer bytes.
  Future<LearningJourney> loadJourney() => _tutorStorage(() async {
        final raw = await _namespace.read(_journeyKey);
        if (raw == null) return LearningJourney();
        // Bound parsing as well as the decoded collections.
        if (raw.length > 20 * 1024 * 1024) {
          throw const FormatException('Unsupported learning journey size');
        }
        return LearningJourney.fromJson(_readObject(raw));
      });

  Future<void> saveJourney(LearningJourney value) => _tutorStorage(
      () => _namespace.write(_journeyKey, jsonEncode(value.toJson())));

  Future<SceneMemory> loadSceneMemory() => _tutorStorage(() async {
        final raw = await _namespace.read('lumo_learning_scenes_v1');
        if (raw == null) return SceneMemory();
        if (raw.length > 1024 * 1024) {
          throw const FormatException('Unsupported scene memory size');
        }
        return SceneMemory.fromJson(_readObject(raw));
      });

  Future<void> saveSceneMemory(SceneMemory memory) => _tutorStorage(() =>
      _namespace.write('lumo_learning_scenes_v1', jsonEncode(memory.toJson())));

  Future<PendingSceneReceipt?> loadPendingSceneReceipt() =>
      _tutorStorage(() async {
        final raw = await _namespace.read('lumo_learning_scene_pending_v1');
        if (raw == null) return null;
        if (raw.length > 32768) {
          throw const FormatException('Unsupported pending scene size');
        }
        final decoded = jsonDecode(raw);
        return decoded == null ? null : PendingSceneReceipt.fromJson(decoded);
      });

  Future<void> savePendingSceneReceipt(PendingSceneReceipt receipt) =>
      _tutorStorage(() => _namespace.write(
          'lumo_learning_scene_pending_v1', jsonEncode(receipt.toJson())));
  Future<void> clearPendingSceneReceipt() => _tutorStorage(
      () => _namespace.write('lumo_learning_scene_pending_v1', 'null'));

  Future<Map<String, SkillRecord>> loadSkills() async {
    final raw = await _namespace.read(_skillsKey);
    if (raw == null || raw.trim().isEmpty) return <String, SkillRecord>{};
    final out = <String, SkillRecord>{};
    for (final value in _readObject(raw).values) {
      if (value is! Map<String, dynamic> ||
          value.keys.any((key) => !_skillFields.contains(key))) {
        throw const FormatException('Unsupported saved skill record');
      }
      late SkillRecord record;
      try {
        record = SkillRecord.fromJson(value).normalized();
      } catch (_) {
        throw const FormatException(
            'Saved skill record could not be read safely');
      }
      if (out.containsKey(record.skillId)) {
        throw const FormatException('Conflicting saved skill records');
      }
      out[record.skillId] = record;
    }
    final days = await _loadIndependentDays();
    for (final entry in days.entries) {
      out[entry.key]?.independentDays = entry.value;
    }
    // A failed normalization write is not corrupt input. Preserve the
    // existing saved profile and report storage failure so Retry can work.
    await saveSkills(out);
    return out;
  }

  /// Auxiliary evidence only. Unreadable or newer content counts as "no day
  /// known yet" and never blocks the child's saved answers.
  Future<Map<String, List<String>>> _loadIndependentDays() async {
    final raw = await _namespace.read(_independentDaysKey);
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['version'] != 1) return const {};
      final days = decoded['days'];
      if (days is! Map) return const {};
      final out = <String, List<String>>{};
      for (final entry in days.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! List) continue;
        out[entry.key as String] = SkillRecord.cleanDays(value);
      }
      return out;
    } on FormatException {
      return const {};
    }
  }

  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    final data = <String, Map<String, dynamic>>{};
    final days = <String, List<String>>{};
    for (final entry in skills.entries) {
      final record = entry.value.normalized();
      data[record.skillId] = record.toJson();
      if (record.independentDays.isNotEmpty) {
        days[record.skillId] = record.independentDays;
      }
    }
    await _namespace.write(_skillsKey, jsonEncode(data));
    // Written only once a topic was actually solved alone, so profiles
    // without such evidence keep exactly their previous stored entries.
    if (days.isNotEmpty) {
      await _namespace.write(
          _independentDaysKey, jsonEncode({'version': 1, 'days': days}));
    }
  }

  Future<Map<String, int>> loadDaily() async {
    final raw = await _namespace.read(_dailyKey);
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    final out = <String, int>{};
    for (final entry in _readObject(raw).entries) {
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(entry.key)) {
        throw const FormatException('Unsupported saved daily progress key');
      }
      final value = entry.value;
      final count = value is num && value.isFinite
          ? value.toInt()
          : value is String
              ? int.tryParse(value)
              : null;
      if (count == null) {
        throw const FormatException('Unsupported saved daily progress count');
      }
      out[entry.key] = count.clamp(0, 500).toInt();
    }
    await saveDaily(out);
    return out;
  }

  Future<void> saveDaily(Map<String, int> daily) async {
    final clean = <String, int>{};
    daily.forEach((key, value) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
        clean[key] = value.clamp(0, 500).toInt();
      }
    });
    await _namespace.write(_dailyKey, jsonEncode(clean));
  }

  Future<Map<String, String>> loadLastTopics() async {
    final raw = await _namespace.read(_lastKey);
    if (raw == null || raw.trim().isEmpty) return <String, String>{};
    final out = <String, String>{};
    for (final entry in _readObject(raw).entries) {
      final value = entry.value;
      if (value is! String ||
          entry.key.trim().isEmpty ||
          value.trim().isEmpty) {
        throw const FormatException('Unsupported saved last-topic record');
      }
      out[entry.key.trim()] = value.trim();
    }
    await saveLastTopics(out);
    return out;
  }

  Future<void> saveLastTopics(Map<String, String> last) async {
    final clean = <String, String>{};
    last.forEach((key, value) {
      final k = key.trim();
      final v = value.trim();
      if (k.isNotEmpty && v.isNotEmpty) clean[k] = v;
    });
    await _namespace.write(_lastKey, jsonEncode(clean));
  }

  Future<void> resetAll() async {
    await _namespace.write(_skillsKey, '{}');
    await _namespace.write(_dailyKey, '{}');
    await _namespace.write(_lastKey, '{}');
    await _namespace.write(_independentDaysKey,
        jsonEncode({'version': 1, 'days': <String, Object?>{}}));
    await _namespace.write(SessionRoundResumeStore.storageKey,
        SessionRoundResumeStore.emptyValue);
    await saveDiscovery(DiscoveryProgress());
    await saveJourney(LearningJourney());
    await saveSceneMemory(SceneMemory());
    await clearPendingSceneReceipt();
    await _namespace.write('lumo_photo_lesson_session_v1', 'null');
    await _namespace.write('lumo_learning_lab_session_v1',
        jsonEncode({'version': 1, 'sessions': <String, Object?>{}}));
  }
}

/// Lernrekord pro Skill (Subject + Unit).
class SkillRecord {
  SkillRecord({
    required this.skillId,
    required this.subject,
    required this.unit,
    this.correct = 0,
    this.wrong = 0,
    this.hintCount = 0,
    this.currentStreak = 0,
    this.currentMisses = 0,
    this.difficulty = 1,
    this.independentEvidence,
    List<String> independentDays = const <String>[],
    DateTime? lastSeen,
  })  : lastSeen = lastSeen ?? DateTime.now(),
        independentDays = cleanDays(independentDays);

  final String skillId;
  final String subject;
  final String unit;
  int correct;
  int wrong;
  int hintCount;
  int currentStreak;
  int currentMisses;
  int difficulty;
  DateTime lastSeen;
  IndependentEvidence? independentEvidence;

  /// The most recent calendar days (yyyy-MM-dd) on which this topic was
  /// solved alone. Stored beside the skill records, never inside them.
  List<String> independentDays;

  static const int maxIndependentDays = 7;
  static final RegExp _dayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static List<String> cleanDays(Iterable<Object?> raw) {
    final days = <String>{
      for (final day in raw)
        if (day is String && _dayPattern.hasMatch(day)) day,
    }.toList()
      ..sort();
    return days.length <= maxIndependentDays
        ? days
        : days.sublist(days.length - maxIndependentDays);
  }

  /// Remembers that a task of this topic was solved alone on [day].
  void noteIndependentDay(String day) {
    if (independentDays.contains(day)) return;
    independentDays = cleanDays([...independentDays, day]);
  }

  /// Days with a task solved alone. Records saved before days were kept
  /// count their existing independent successes as one day: honest, because
  /// at least one such day happened, and one more day confirms "sicher".
  int get independentDayCount => independentDays.isNotEmpty
      ? independentDays.length
      : assessed.correct > 0
          ? 1
          : 0;

  /// Evidence-based stage instead of a percentage (see [SkillEvidence]).
  SkillEvidence get evidence => SkillEvidence.from(
        answers: attempts,
        independent: assessed,
        independentDays: independentDayCount,
      );

  IndependentEvidence get assessed =>
      independentEvidence ??
      IndependentEvidence.fromLegacy(
          correct: correct,
          wrong: wrong,
          helpCount: hintCount,
          correctStreak: currentStreak,
          wrongStreak: currentMisses);

  int get attempts => correct + wrong;
  double get accuracy => attempts == 0 ? 0.0 : correct / attempts;

  int get mastery {
    final evidence = assessed;
    if (evidence.attempts == 0) return 0;
    final base = evidence.accuracy * 100;
    final volumeBonus = (evidence.attempts.clamp(0, 20) / 20) * 10;
    final streakBonus = (evidence.correctStreak.clamp(0, 5) / 5) * 10;
    return (base * 0.8 + volumeBonus + streakBonus).clamp(0, 100).toInt();
  }

  double get weaknessScore {
    final evidence = assessed;
    if (evidence.attempts < 3) return 0.0;
    final errorRate = evidence.wrong / evidence.attempts;
    final mastery01 = mastery / 100.0;
    final missesFactor = evidence.wrongStreak.clamp(0, 5) / 5;
    return (errorRate * 0.5 + (1.0 - mastery01) * 0.3 + missesFactor * 0.2)
        .clamp(0.0, 1.0);
  }

  SkillRecord normalized() {
    final cleanSubject = subject.trim().isEmpty ? 'Mathematik' : subject.trim();
    final cleanUnit = unit.trim().isEmpty ? 'Allgemein' : unit.trim();
    final cleanSkillId = skillId.trim().isEmpty || skillId == 'unknown'
        ? makeId(cleanSubject, cleanUnit)
        : skillId.trim();
    return SkillRecord(
      skillId: cleanSkillId,
      subject: cleanSubject,
      unit: cleanUnit,
      correct: correct.clamp(0, 10000).toInt(),
      wrong: wrong.clamp(0, 10000).toInt(),
      hintCount: hintCount.clamp(0, 10000).toInt(),
      currentStreak: currentStreak.clamp(0, 1000).toInt(),
      currentMisses: currentMisses.clamp(0, 1000).toInt(),
      difficulty: difficulty.clamp(1, 5).toInt(),
      lastSeen: lastSeen,
      independentEvidence: assessed,
      independentDays: independentDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'skillId': skillId,
        'subject': subject,
        'unit': unit,
        'correct': correct,
        'wrong': wrong,
        'hintCount': hintCount,
        'currentStreak': currentStreak,
        'currentMisses': currentMisses,
        'difficulty': difficulty,
        'lastSeen': lastSeen.toIso8601String(),
        'independentEvidence': assessed.toJson(),
      };

  factory SkillRecord.fromJson(Map<String, dynamic> json) {
    final record = SkillRecord(
      skillId: json['skillId'] as String? ?? 'unknown',
      subject: json['subject'] as String? ?? 'Mathematik',
      unit: json['unit'] as String? ?? 'Allgemein',
      correct: (json['correct'] as num?)?.toInt() ??
          int.tryParse(json['correct']?.toString() ?? '') ??
          0,
      wrong: (json['wrong'] as num?)?.toInt() ??
          int.tryParse(json['wrong']?.toString() ?? '') ??
          0,
      hintCount: (json['hintCount'] as num?)?.toInt() ??
          int.tryParse(json['hintCount']?.toString() ?? '') ??
          0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ??
          int.tryParse(json['currentStreak']?.toString() ?? '') ??
          0,
      currentMisses: (json['currentMisses'] as num?)?.toInt() ??
          int.tryParse(json['currentMisses']?.toString() ?? '') ??
          0,
      difficulty: (json['difficulty'] as num?)?.toInt() ??
          int.tryParse(json['difficulty']?.toString() ?? '') ??
          1,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ??
          DateTime.now(),
      independentEvidence: json.containsKey('independentEvidence')
          ? IndependentEvidence.fromJson(json['independentEvidence'])
          : json.containsKey('hintCount')
              ? null
              : const IndependentEvidence(),
    );
    if (record.assessed.correct > record.correct.clamp(0, 10000) ||
        record.assessed.wrong > record.wrong.clamp(0, 10000)) {
      throw const FormatException(
          'Independent evidence exceeds practice history');
    }
    return record.normalized();
  }

  static String makeId(String subject, String unit) =>
      '${subject.toLowerCase()}::${unit.toLowerCase()}';
}
