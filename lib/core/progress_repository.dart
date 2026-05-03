import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Speichert den Lernfortschritt eines Kindes lokal auf dem Gerät.
/// Offline-first. Keine Cloud. Kein Tracking.
class ProgressRepository {
  static const _skillsKey = 'lumo_progress_skills';
  static const _dailyKey = 'lumo_progress_daily';
  static const _lastKey = 'lumo_progress_last';

  Future<Map<String, SkillRecord>> loadSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_skillsKey);
    if (raw == null || raw.trim().isEmpty) return <String, SkillRecord>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs.remove(_skillsKey);
        return <String, SkillRecord>{};
      }
      final out = <String, SkillRecord>{};
      decoded.forEach((key, value) {
        if (value is! Map) return;
        final record = SkillRecord.fromJson(Map<String, dynamic>.from(value)).normalized();
        out[record.skillId] = record;
      });
      await saveSkills(out);
      return out;
    } catch (_) {
      await prefs.remove(_skillsKey);
      return <String, SkillRecord>{};
    }
  }

  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, Map<String, dynamic>>{};
    for (final entry in skills.entries) {
      final record = entry.value.normalized();
      data[record.skillId] = record.toJson();
    }
    await prefs.setString(_skillsKey, jsonEncode(data));
  }

  Future<Map<String, int>> loadDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyKey);
    if (raw == null || raw.trim().isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs.remove(_dailyKey);
        return <String, int>{};
      }
      final out = <String, int>{};
      decoded.forEach((key, value) {
        final textKey = key.toString();
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(textKey)) return;
        final count = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
        out[textKey] = count.clamp(0, 500).toInt();
      });
      await saveDaily(out);
      return out;
    } catch (_) {
      await prefs.remove(_dailyKey);
      return <String, int>{};
    }
  }

  Future<void> saveDaily(Map<String, int> daily) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = <String, int>{};
    daily.forEach((key, value) {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(key)) {
        clean[key] = value.clamp(0, 500).toInt();
      }
    });
    await prefs.setString(_dailyKey, jsonEncode(clean));
  }

  Future<Map<String, String>> loadLastTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null || raw.trim().isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs.remove(_lastKey);
        return <String, String>{};
      }
      final out = <String, String>{};
      decoded.forEach((key, value) {
        final k = key.toString().trim();
        final v = value?.toString().trim() ?? '';
        if (k.isNotEmpty && v.isNotEmpty) out[k] = v;
      });
      await saveLastTopics(out);
      return out;
    } catch (_) {
      await prefs.remove(_lastKey);
      return <String, String>{};
    }
  }

  Future<void> saveLastTopics(Map<String, String> last) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = <String, String>{};
    last.forEach((key, value) {
      final k = key.trim();
      final v = value.trim();
      if (k.isNotEmpty && v.isNotEmpty) clean[k] = v;
    });
    await prefs.setString(_lastKey, jsonEncode(clean));
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_skillsKey);
    await prefs.remove(_dailyKey);
    await prefs.remove(_lastKey);
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
    return (errorRate * 0.5 + (1.0 - mastery01) * 0.3 + missesFactor * 0.2).clamp(0.0, 1.0);
  }

  SkillRecord normalized() {
    final cleanSubject = subject.trim().isEmpty ? 'Mathematik' : subject.trim();
    final cleanUnit = unit.trim().isEmpty ? 'Allgemein' : unit.trim();
    final cleanSkillId = skillId.trim().isEmpty || skillId == 'unknown' ? makeId(cleanSubject, cleanUnit) : skillId.trim();
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
      correct: (json['correct'] as num?)?.toInt() ?? int.tryParse(json['correct']?.toString() ?? '') ?? 0,
      wrong: (json['wrong'] as num?)?.toInt() ?? int.tryParse(json['wrong']?.toString() ?? '') ?? 0,
      hintCount: (json['hintCount'] as num?)?.toInt() ?? int.tryParse(json['hintCount']?.toString() ?? '') ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? int.tryParse(json['currentStreak']?.toString() ?? '') ?? 0,
      currentMisses: (json['currentMisses'] as num?)?.toInt() ?? int.tryParse(json['currentMisses']?.toString() ?? '') ?? 0,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? int.tryParse(json['difficulty']?.toString() ?? '') ?? 1,
      lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ?? DateTime.now(),
    );
    return record.normalized();
  }

  static String makeId(String subject, String unit) => '${subject.toLowerCase()}::${unit.toLowerCase()}';
}
