import 'attempt.dart';
import 'error_patterns.dart';

enum MasteryLevel { unknown, needsHelp, developing, secure }

/// Kennzahlen zu einer Kompetenz.
class CompetencyStat {
  const CompetencyStat({
    required this.competency,
    required this.subject,
    required this.unit,
    required this.attempts,
    required this.correct,
    required this.hints,
    required this.lastAt,
    required this.avgMs,
    this.trend,
    this.patterns = const [],
    this.avgScore,
    this.wordsPerMinute,
  });

  final String competency;
  final String subject;

  /// Thema, in dem die zuletzt gelöste Aufgabe dieser Kompetenz stand.
  final String unit;
  final int attempts;
  final int correct;
  final int hints;
  final DateTime lastAt;
  final int? avgMs;

  /// Veränderung der Trefferquote in Prozentpunkten: die letzten Versuche
  /// gegen die davor (je mindestens vier). null = noch zu wenig Daten.
  final int? trend;

  /// Wiederkehrende Fehlermuster (mindestens zweimal), häufigstes zuerst.
  final List<(String, int)> patterns;

  /// Mittlere Teilbewertung 0..1 (z. B. Lese-Genauigkeit), falls erfasst.
  final double? avgScore;

  /// Lesetempo in Wörtern pro Minute (nur beim Vorlesen von Sätzen).
  final int? wordsPerMinute;

  int get wrong => attempts - correct;
  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  int get percent => (accuracy * 100).round();

  /// Ab fünf Versuchen belastbar; vorher nur „noch unklar“.
  MasteryLevel get level {
    if (attempts < 5) return MasteryLevel.unknown;
    if (accuracy >= .85) return MasteryLevel.secure;
    if (accuracy >= .6) return MasteryLevel.developing;
    return MasteryLevel.needsHelp;
  }
}

enum InsightKind { weakness, strength, comparison, pattern, trend }

class Insight {
  const Insight(this.kind, this.text, {this.competency});
  final InsightKind kind;
  final String text;
  final String? competency;
}

/// Vorschlag für die nächste Übung. Eine Lehrkraft kann ihn bestätigen,
/// ändern oder ignorieren.
class PracticeSuggestion {
  const PracticeSuggestion({
    required this.competency,
    required this.subject,
    required this.minutes,
    required this.text,
  });
  final String competency;
  final String subject;
  final int minutes;
  final String text;
}

/// Kurzer Satz von Lumo an das Kind, mit Thema für den Übungsstart.
class CoachMessage {
  const CoachMessage({
    required this.text,
    required this.subject,
    required this.unit,
    required this.isHelp,
  });
  final String text;
  final String subject;
  final String unit;

  /// true: Lumo bietet Hilfe an; false: Lob für eine sichere Kompetenz.
  final bool isHelp;
}

class DayCount {
  const DayCount(this.day, this.total, this.correct);
  final DateTime day;
  final int total;
  final int correct;
}

class LearningAnalysis {
  const LearningAnalysis({
    required this.stats,
    required this.insights,
    required this.suggestion,
    required this.days,
    required this.totalAttempts,
    required this.totalMinutes,
    required this.lastActivity,
  });

  final List<CompetencyStat> stats;
  final List<Insight> insights;
  final PracticeSuggestion? suggestion;
  final List<DayCount> days;
  final int totalAttempts;

  /// Geschätzte Lernzeit aus den gemessenen Antwortzeiten.
  final int totalMinutes;
  final DateTime? lastActivity;

  List<CompetencyStat> get weak =>
      stats.where((s) => s.level == MasteryLevel.needsHelp).toList();
  List<CompetencyStat> get secure =>
      stats.where((s) => s.level == MasteryLevel.secure).toList();

  static const int minReliable = 5;

  /// Persönliche Nachricht für das Kind: zuerst Hilfe bei der größten
  /// Schwäche, sonst Lob für eine sichere Kompetenz. Nie ohne belastbare Daten.
  CoachMessage? get coachMessage {
    final weakest = weak.isEmpty ? null : weak.first;
    if (weakest != null) {
      return CoachMessage(
        text:
            'Bei „${weakest.competency}“ passieren dir noch Fehler. Wollen wir zwei leichte Aufgaben gemeinsam machen?',
        subject: weakest.subject,
        unit: weakest.unit,
        isHelp: true,
      );
    }
    final best = secure.isEmpty ? null : secure.last;
    if (best != null) {
      return CoachMessage(
        text: 'Bei „${best.competency}“ bist du schon richtig sicher.',
        subject: best.subject,
        unit: best.unit,
        isHelp: false,
      );
    }
    return null;
  }

  /// Hilfsmittel je Kompetenz für die Empfehlung.
  static String _aidFor(String competency) {
    if (competency.contains('Zehnerübergang')) {
      return 'visuellen Zehnerfeldern';
    }
    if (competency == 'Einmaleins') return 'Malreihen zum Anschauen';
    if (competency == 'Sätze vorlesen' || competency == 'Text vorlesen') {
      return 'Lumo liest vor, du liest nach';
    }
    if (competency == 'Buchstaben schreiben') return 'Buchstaben nachspuren';
    if (competency.contains('Rechtschreib') || competency.contains('Diktat')) {
      return 'Silben zum Mitklatschen';
    }
    return 'Lumos Bildern und Beispielen';
  }

  static LearningAnalysis analyze(List<Attempt> attempts, {DateTime? now}) {
    final today = now ?? DateTime.now();
    const detector = ErrorPatternDetector();
    final byComp = <String, List<Attempt>>{};
    for (final a in attempts) {
      byComp.putIfAbsent(a.competency, () => []).add(a);
    }
    final stats = <CompetencyStat>[];
    byComp.forEach((name, list) {
      final timed = list.where((a) => a.durationMs != null).toList();
      final avg = timed.isEmpty
          ? null
          : (timed.map((a) => a.durationMs!).reduce((x, y) => x + y) /
                  timed.length)
              .round();
      final ordered = [...list]..sort((x, y) => x.at.compareTo(y.at));
      int? trend;
      if (ordered.length >= 8) {
        final half = (ordered.length / 2).floor().clamp(4, 10).toInt();
        final recent = ordered.sublist(ordered.length - half);
        final before = ordered.sublist(
            (ordered.length - 2 * half).clamp(0, ordered.length).toInt(),
            ordered.length - half);
        double rate(List<Attempt> l) =>
            l.where((a) => a.correct).length / l.length;
        if (before.length >= 4) {
          trend = ((rate(recent) - rate(before)) * 100).round();
        }
      }
      final counts = <String, int>{};
      for (final a in list) {
        final p = detector.detect(a);
        if (p != null) counts[p] = (counts[p] ?? 0) + 1;
      }
      final patterns = [
        for (final e in counts.entries)
          if (e.value >= 2) (e.key, e.value),
      ]..sort((x, y) => y.$2.compareTo(x.$2));
      final scored = list.where((a) => a.score != null).toList();
      final avgScore = scored.isEmpty
          ? null
          : scored.map((a) => a.score!).reduce((x, y) => x + y) / scored.length;
      int? wpm;
      if (list.first.subject == 'Lesen') {
        var words = 0, ms = 0;
        for (final a in timed) {
          final n = a.prompt.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
          if (n == 0 || a.durationMs! < 500) continue;
          words += n;
          ms += a.durationMs!;
        }
        if (words > 0 && ms > 0) wpm = (words / (ms / 60000)).round();
      }
      stats.add(CompetencyStat(
        competency: name,
        subject: list.first.subject,
        unit: list.last.unit,
        attempts: list.length,
        correct: list.where((a) => a.correct).length,
        hints: list.where((a) => a.hintUsed).length,
        lastAt: list.map((a) => a.at).reduce((x, y) => x.isAfter(y) ? x : y),
        avgMs: avg,
        trend: trend,
        patterns: patterns,
        avgScore: avgScore,
        wordsPerMinute: wpm,
      ));
    });
    stats.sort((a, b) => a.accuracy.compareTo(b.accuracy));

    final insights = <Insight>[];
    for (final s in stats) {
      if (s.level == MasteryLevel.needsHelp) {
        insights.add(Insight(
          InsightKind.weakness,
          'Bei ${s.attempts} Aufgaben zu „${s.competency}“ gab es ${s.wrong} Fehler.',
          competency: s.competency,
        ));
        final sibling = _sibling(s, stats);
        if (sibling != null) {
          insights.add(Insight(
            InsightKind.comparison,
            'Bei „${sibling.competency}“ liegt die Trefferquote dagegen bei ${sibling.percent}\u00A0%.',
            competency: sibling.competency,
          ));
        }
      }
    }
    for (final s in stats.reversed) {
      if (s.level == MasteryLevel.secure) {
        insights.add(Insight(
          InsightKind.strength,
          '„${s.competency}“ sitzt sicher (${s.percent}\u00A0% richtig bei ${s.attempts} Aufgaben).',
          competency: s.competency,
        ));
      }
    }

    for (final s in stats) {
      if (s.patterns.isNotEmpty) {
        final (name, count) = s.patterns.first;
        insights.add(Insight(
          InsightKind.pattern,
          'Wiederholter Fehler bei „${s.competency}“: $name ($count×).',
          competency: s.competency,
        ));
      }
      final t = s.trend;
      if (t != null && t.abs() >= 15) {
        insights.add(Insight(
          InsightKind.trend,
          t > 0
              ? '„${s.competency}“ wird besser (+$t Prozentpunkte).'
              : '„${s.competency}“ ist zuletzt schwächer geworden (−${-t} Prozentpunkte).',
          competency: s.competency,
        ));
      }
    }

    PracticeSuggestion? suggestion;
    CompetencyStat? focus;
    for (final level in [MasteryLevel.needsHelp, MasteryLevel.developing]) {
      for (final s in stats) {
        if (s.level == level) {
          focus = s;
          break;
        }
      }
      if (focus != null) break;
    }
    if (focus != null) {
      suggestion = PracticeSuggestion(
        competency: focus.competency,
        subject: focus.subject,
        minutes: 10,
        text:
            'Empfehlung: 10 Minuten „${focus.competency}“ mit ${_aidFor(focus.competency)}.',
      );
    }

    final days = <DayCount>[];
    for (var i = 13; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final same = attempts.where((a) =>
          a.at.year == d.year && a.at.month == d.month && a.at.day == d.day);
      days.add(DayCount(d, same.length, same.where((a) => a.correct).length));
    }

    final ms = attempts
        .where((a) => a.durationMs != null)
        // Pausen zählen nicht als Lernzeit.
        .fold<int>(0, (sum, a) => sum + a.durationMs!.clamp(0, 60000));
    return LearningAnalysis(
      stats: stats,
      insights: insights,
      suggestion: suggestion,
      days: days,
      totalAttempts: attempts.length,
      totalMinutes: (ms / 60000).round(),
      lastActivity: attempts.isEmpty
          ? null
          : attempts.map((a) => a.at).reduce((x, y) => x.isAfter(y) ? x : y),
    );
  }

  /// Gegenstück „ohne“ zu „mit“ (z. B. Zehnerübergang), falls belastbar.
  static CompetencyStat? _sibling(
      CompetencyStat s, List<CompetencyStat> all) {
    String? other;
    if (s.competency.contains(' mit ')) {
      other = s.competency.replaceFirst(' mit ', ' ohne ');
    }
    if (other == null) return null;
    for (final candidate in all) {
      if (candidate.competency == other &&
          candidate.attempts >= minReliable) {
        return candidate;
      }
    }
    return null;
  }
}
