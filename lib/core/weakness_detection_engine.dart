import 'progress_repository.dart';

/// Erkennt Schwächen im Lernfortschritt.
///
/// Regeln (kindgerecht abgestimmt — keine Streak-Angst, kein Druck):
///
///   1. Ein Skill gilt als Schwäche, wenn currentMisses >= 3
///      ODER weaknessScore >= 0.5 bei mind. 3 Versuchen.
///
///   2. Ein Skill gilt als gemeistert, wenn currentStreak >= 5
///      UND mastery >= 75.
///
///   3. Schwächen werden nach Dringlichkeit sortiert:
///      jüngste Misses zuerst, dann höchster weaknessScore.
///
///   4. Difficulty-Anpassung:
///      - 5 in Folge richtig  -> difficulty + 1 (max 5)
///      - 3 in Folge falsch   -> difficulty - 1 (min 1)
///
/// Die Engine ändert keine Daten — sie liest und bewertet nur.
/// Schreibvorgänge passieren explizit über LearningProfileEngine.
class WeaknessDetectionEngine {
  const WeaknessDetectionEngine();

  /// Markiert ob ein Skill aktuell als Schwäche gilt.
  bool isWeak(SkillRecord r) {
    if (r.currentMisses >= 3) return true;
    if (r.attempts >= 3 && r.weaknessScore >= 0.5) return true;
    return false;
  }

  /// Markiert ob ein Skill als gemeistert gilt.
  bool isMastered(SkillRecord r) {
    return r.currentStreak >= 5 && r.mastery >= 75;
  }

  /// Liefert alle Schwächen aus den Records, sortiert nach Dringlichkeit.
  List<SkillRecord> findWeaknesses(Map<String, SkillRecord> skills) {
    final weak = skills.values.where(isWeak).toList();
    weak.sort((a, b) {
      // Jüngste Misses zuerst
      final missCmp = b.currentMisses.compareTo(a.currentMisses);
      if (missCmp != 0) return missCmp;
      // Dann höchster weaknessScore
      return b.weaknessScore.compareTo(a.weaknessScore);
    });
    return weak;
  }

  /// Liefert alle gemeisterten Skills.
  List<SkillRecord> findMastered(Map<String, SkillRecord> skills) {
    return skills.values.where(isMastered).toList();
  }

  /// Schlägt eine neue Schwierigkeitsstufe für den Skill vor,
  /// basierend auf den letzten Antworten. Gibt die unveränderte
  /// difficulty zurück, wenn keine Anpassung nötig ist.
  int suggestDifficulty(SkillRecord r) {
    var newDifficulty = r.difficulty;
    if (r.currentStreak >= 5 && newDifficulty < 5) {
      newDifficulty++;
    } else if (r.currentMisses >= 3 && newDifficulty > 1) {
      newDifficulty--;
    }
    return newDifficulty;
  }

  /// Gibt eine Schwächen-Map subject -> [units] zurück.
  /// Gut für Dashboards und Eltern-Übersicht.
  Map<String, List<String>> weaknessesBySubject(
    Map<String, SkillRecord> skills,
  ) {
    final result = <String, List<String>>{};
    for (final r in findWeaknesses(skills)) {
      result.putIfAbsent(r.subject, () => <String>[]).add(r.unit);
    }
    return result;
  }
}
