import '../../core/progress_repository.dart';
import 'attempt.dart';
import 'learning_analysis.dart';
import 'learning_guidance.dart';

/// Die vier Kennzahlen oben im Elternbereich („Lumo Insight“).
///
/// Grundlage ist dieselbe wie bei „Auf einen Blick“: das Aufgabenprotokoll
/// genau eines Kindes, gefiltert mit [LearningGuidance.relevantAttempts]
/// (ohne Demo-Kinder, fremde Profile, doppelte Einträge, Zukunftszeiten und
/// Messfächer). Ältere Lernstände aus der Zeit vor dem Aufgabenprotokoll
/// (2026-10) liegen nur als Zähler pro Thema ([SkillRecord]) und Tageszähler
/// vor. Sie bleiben gültig und werden so zusammengeführt:
///
/// * [answers]: protokollierte Antworten plus die Antworten, die ein
///   Themenzähler mehr enthält als das Protokoll für dasselbe Thema
///   ([olderAnswers]). Nichts wird doppelt gezählt.
/// * [streakDays]: Lerntage in Folge bis heute, wie überall in der App ein
///   Tag mit mindestens einer richtigen Antwort. Tageszähler und Protokoll
///   ergänzen sich.
/// * [strengths] und [needs]: nur aus dem Protokoll und genau wie
///   „Auf einen Blick“ (Kompetenz mit mindestens
///   [LearningAnalysis.minReliable] Antworten ohne Hilfe; Stärke ab 85 %,
///   darunter Förderbedarf). Ältere Zähler haben weder Datum noch Kompetenz
///   und werden dort nicht eingeordnet. Solange keine Kompetenz einordenbar
///   ist, sind beide Werte `null` („noch offen“) statt 0.
class ParentInsightMetrics {
  const ParentInsightMetrics._({
    required this.loggedAnswers,
    required this.loggedIndependent,
    required this.loggedIndependentCorrect,
    required this.olderAnswers,
    required this.streakDays,
    required this.lastPracticeDay,
    required this.strengths,
    required this.needs,
  });

  /// Echte Antworten im Aufgabenprotokoll dieses Profils.
  final int loggedAnswers;

  /// Davon ohne Hilfe beantwortet.
  final int loggedIndependent;

  /// Davon ohne Hilfe richtig.
  final int loggedIndependentCorrect;

  /// Antworten, die nur in älteren Themenzählern stehen (ohne Datum).
  final int olderAnswers;

  /// Aufeinanderfolgende Tage bis einschließlich heute mit mindestens einer
  /// richtigen Antwort.
  final int streakDays;

  /// Letzter Tag mit einer Antwort (Datum ohne Uhrzeit), sonst `null`.
  final DateTime? lastPracticeDay;

  /// Sichere Kompetenzen; `null`, solange keine Kompetenz einordenbar ist.
  final int? strengths;

  /// Kompetenzen mit Förderbedarf; `null`, solange keine einordenbar ist.
  final int? needs;

  int get answers => loggedAnswers + olderAnswers;
  int get loggedAssisted => loggedAnswers - loggedIndependent;
  bool get isEmpty => answers == 0;

  factory ParentInsightMetrics.from({
    required Iterable<Attempt> attempts,
    required String studentId,
    required DateTime now,
    Map<String, SkillRecord> skills = const <String, SkillRecord>{},
    Map<String, int> daily = const <String, int>{},
  }) {
    if (studentId.trim().isEmpty ||
        LearningGuidance.isDemoStudent(studentId)) {
      return const ParentInsightMetrics._(
        loggedAnswers: 0,
        loggedIndependent: 0,
        loggedIndependentCorrect: 0,
        olderAnswers: 0,
        streakDays: 0,
        lastPracticeDay: null,
        strengths: null,
        needs: null,
      );
    }
    final source = attempts.toList(growable: false);
    final logged = LearningGuidance.relevantAttempts(source,
        studentId: studentId, now: now);

    // Jede gespeicherte Antwort dieses Profils je Thema, auch solche mit
    // falscher Uhrzeit: Sie stehen im Protokoll und dürfen über den
    // Themenzähler nicht ein zweites Mal hereinkommen.
    final seen = <String>{};
    final perTopic = <String, int>{};
    for (final a in source) {
      if (a.studentId != studentId || !seen.add(a.id)) continue;
      final id = SkillRecord.makeId(a.subject.trim(), a.unit.trim());
      perTopic[id] = (perTopic[id] ?? 0) + 1;
    }
    var older = 0;
    for (final record in skills.values) {
      final clean = record.normalized();
      final counted = clean.correct + clean.wrong;
      final inLog =
          perTopic[SkillRecord.makeId(clean.subject, clean.unit)] ?? 0;
      if (counted > inLog) older += counted - inLog;
    }

    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _dayKey(today);
    final successDays = <String>{
      for (final entry in daily.entries)
        if (entry.value > 0 && entry.key.compareTo(todayKey) <= 0) entry.key,
      for (final a in logged)
        if (a.correct) _dayKey(a.at.toLocal()),
    };
    var streak = 0;
    var day = today;
    while (successDays.contains(_dayKey(day))) {
      streak++;
      day = DateTime(day.year, day.month, day.day - 1);
    }

    DateTime? last;
    for (final key in daily.keys) {
      if ((daily[key] ?? 0) <= 0 || key.compareTo(todayKey) > 0) continue;
      final parsed = DateTime.tryParse(key);
      if (parsed != null && (last == null || parsed.isAfter(last))) {
        last = parsed;
      }
    }
    for (final a in logged) {
      final at = a.at.toLocal();
      final d = DateTime(at.year, at.month, at.day);
      if (last == null || d.isAfter(last)) last = d;
    }

    final stats = LearningAnalysis.analyze(logged, now: now).stats;
    final classified =
        stats.where((s) => s.level != MasteryLevel.unknown).toList();
    return ParentInsightMetrics._(
      loggedAnswers: logged.length,
      loggedIndependent: logged.where((a) => !a.hintUsed).length,
      loggedIndependentCorrect:
          logged.where((a) => !a.hintUsed && a.correct).length,
      olderAnswers: older,
      streakDays: streak,
      lastPracticeDay: last,
      strengths: classified.isEmpty
          ? null
          : classified.where((s) => s.level == MasteryLevel.secure).length,
      needs: classified.isEmpty
          ? null
          : classified.where((s) => s.level != MasteryLevel.secure).length,
    );
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
