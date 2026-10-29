import 'dart:convert';

import 'discovery_progress.dart';
import 'learning_journey.dart';
import 'legacy_learning_data.dart';
import '../domain/learning_intelligence/scene_memory.dart';

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
  Future<LearningJourney> loadJourney() async {
    final raw = await _namespace.read(_journeyKey);
    if (raw == null) return LearningJourney();
    // Bound parsing as well as the decoded collections.
    if (raw.length > 20 * 1024 * 1024) {
      throw const FormatException('Unsupported learning journey size');
    }
    return LearningJourney.fromJson(_readObject(raw));
  }

  Future<void> saveJourney(LearningJourney value) =>
      _namespace.write(_journeyKey, jsonEncode(value.toJson()));

  Future<SceneMemory> loadSceneMemory() async {
    final raw = await _namespace.read('lumo_learning_scenes_v1');
    if (raw == null) return SceneMemory();
    if (raw.length > 1024 * 1024)
      throw const FormatException('Unsupported scene memory size');
    return SceneMemory.fromJson(_readObject(raw));
  }

  Future<void> saveSceneMemory(SceneMemory memory) =>
      _namespace.write('lumo_learning_scenes_v1', jsonEncode(memory.toJson()));

  Future<PendingSceneReceipt?> loadPendingSceneReceipt() async {
    final raw = await _namespace.read('lumo_learning_scene_pending_v1');
    if (raw == null) return null;
    if (raw.length > 32768)
      throw const FormatException('Unsupported pending scene size');
    final decoded = jsonDecode(raw);
    return decoded == null ? null : PendingSceneReceipt.fromJson(decoded);
  }

  Future<void> savePendingSceneReceipt(PendingSceneReceipt receipt) =>
      _namespace.write(
          'lumo_learning_scene_pending_v1', jsonEncode(receipt.toJson()));
  Future<void> clearPendingSceneReceipt() =>
      _namespace.write('lumo_learning_scene_pending_v1', 'null');

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
    // A failed normalization write is not corrupt input. Preserve the
    // existing saved profile and report storage failure so Retry can work.
    await saveSkills(out);
    return out;
  }

  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    final data = <String, Map<String, dynamic>>{};
    for (final entry in skills.entries) {
      final record = entry.value.normalized();
      data[record.skillId] = record.toJson();
    }
    await _namespace.write(_skillsKey, jsonEncode(data));
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
    await saveDiscovery(DiscoveryProgress());
    await saveJourney(LearningJourney());
    await saveSceneMemory(SceneMemory());
    await clearPendingSceneReceipt();
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
    DateTime? lastSeen,
  }) : lastSeen = lastSeen ?? DateTime.now();

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

  int get attempts => correct + wrong;
  double get accuracy => attempts == 0 ? 0.0 : correct / attempts;

  int get mastery {
    if (attempts == 0) return 0;
    final base = accuracy * 100;
    final volumeBonus = (attempts.clamp(0, 20) / 20) * 10;
    final streakBonus = (currentStreak.clamp(0, 5) / 5) * 10;
    return (base * 0.8 + volumeBonus + streakBonus).clamp(0, 100).toInt();
  }

  double get weaknessScore {
    if (attempts < 3) return 0.0;
    final errorRate = wrong / attempts;
    final mastery01 = mastery / 100.0;
    final missesFactor = currentMisses.clamp(0, 5) / 5;
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
    );
    return record.normalized();
  }

  static String makeId(String subject, String unit) =>
      '${subject.toLowerCase()}::${unit.toLowerCase()}';
}
