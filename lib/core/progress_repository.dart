import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Speichert den Lernfortschritt eines Kindes lokal auf dem Gerät.
///
/// Datenstruktur (alles JSON in SharedPreferences):
///   - lumo_progress_skills    Map skillId -> SkillRecord
///   - lumo_progress_daily     Map yyyy-mm-dd -> int (richtige Antworten)
///   - lumo_progress_last      Map subject -> last skillId/unit
///
/// SkillRecord enthält:
///   - correct, wrong, hintCount
///   - lastSeen
///   - currentStreak (consecutive correct)
///   - currentMisses (consecutive wrong)
///   - difficulty 1..5
///
/// Offline-first. Keine Cloud. Kein Tracking.
class ProgressRepository {
  static const _skillsKey = 'lumo_progress_skills';
  static const _dailyKey = 'lumo_progress_daily';
  static const _lastKey = 'lumo_progress_last';

  Future<Map<String, SkillRecord>> loadSkills() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_skillsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map((k, v) =>
          MapEntry(k, SkillRecord.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveSkills(Map<String, SkillRecord> skills) async {
    final prefs = await SharedPreferences.getInstance();
    final data = skills.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_skillsKey, jsonEncode(data));
  }

  Future<Map<String, int>> loadDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_dailyKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveDaily(Map<String, int> daily) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dailyKey, jsonEncode(daily));
  }

  Future<Map<String, String>> loadLastTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> saveLastTopics(Map<String, String> last) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, jsonEncode(last));
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

  /// Schwierigkeitsstufe von 1 (sehr leicht) bis 5 (Herausforderung).
  int difficulty;
  DateTime lastSeen;

  int get attempts => correct + wrong;

  /// Trefferquote 0.0 bis 1.0. Bei null Versuchen 0.0.
  double get accuracy => attempts == 0 ? 0.0 : correct / attempts;

  /// Mastery 0..100 — gewichtet nach Trefferquote, Versuchen und aktueller
  /// Streak. So wirken viele saubere Versuche stärker als Glückstreffer.
  int get mastery {
    if (attempts == 0) return 0;
    final base = accuracy * 100;
    final volumeBonus = (attempts.clamp(0, 20) / 20) * 10;
    final streakBonus = (currentStreak.clamp(0, 5) / 5) * 10;
    return (base * 0.8 + volumeBonus + streakBonus).clamp(0, 100).toInt();
  }

  /// Schwächen-Indikator: hoch, wenn fehlerquote hoch und mastery niedrig.
  /// Werte: 0.0 (kein Problem) bis 1.0 (klare Schwäche).
  double get weaknessScore {
    if (attempts < 3) return 0.0;
    final errorRate = wrong / attempts;
    final mastery01 = mastery / 100.0;
    final missesFactor = (currentMisses.clamp(0, 5) / 5);
    return (errorRate * 0.5 + (1.0 - mastery01) * 0.3 + missesFactor * 0.2)
        .clamp(0.0, 1.0);
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

  factory SkillRecord.fromJson(Map<String, dynamic> json) => SkillRecord(
        skillId: json['skillId'] as String? ?? 'unknown',
        subject: json['subject'] as String? ?? 'Mathematik',
        unit: json['unit'] as String? ?? 'Allgemein',
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        wrong: (json['wrong'] as num?)?.toInt() ?? 0,
        hintCount: (json['hintCount'] as num?)?.toInt() ?? 0,
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        currentMisses: (json['currentMisses'] as num?)?.toInt() ?? 0,
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        lastSeen: DateTime.tryParse(json['lastSeen'] as String? ?? '') ??
            DateTime.now(),
      );

  /// Generiert eine konsistente skillId aus subject + unit.
  static String makeId(String subject, String unit) =>
      '${subject.toLowerCase()}::${unit.toLowerCase()}';
}
