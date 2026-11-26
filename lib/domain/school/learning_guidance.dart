import 'adaptive_practice_plan.dart';
import 'attempt.dart';
import 'learning_analysis.dart';

/// Ein Thema, das das Kind in den letzten Tagen tatsächlich geübt hat.
class GuidancePracticeTopic {
  const GuidancePracticeTopic({
    required this.subject,
    required this.unit,
    required this.answers,
    required this.assisted,
    required this.independentCorrect,
    required this.lastAt,
  });

  final String subject;
  final String unit;
  final int answers;
  final int assisted;
  final int independentCorrect;
  final DateTime lastAt;

  int get independent => answers - assisted;
}

/// Eine Kompetenz mit mindestens [LearningAnalysis.minReliable] Antworten ohne
/// Hilfe: Stärke (sicher) oder Förderbedarf (braucht Hilfe / wird besser).
class GuidanceCompetency {
  const GuidanceCompetency({
    required this.subject,
    required this.unit,
    required this.competency,
    required this.level,
    required this.independentAttempts,
    required this.independentCorrect,
    this.pattern,
  });

  final String subject;
  final String unit;
  final String competency;
  final MasteryLevel level;
  final int independentAttempts;
  final int independentCorrect;

  /// Wiederkehrender Fehler (mindestens zweimal beobachtet), sonst null.
  final String? pattern;

  int get percent => independentAttempts == 0
      ? 0
      : (independentCorrect * 100 / independentAttempts).round();
}

/// Empfehlung mit Ziel-Lernmodul ([subject] und [unit] wie im Übungsbereich).
class GuidanceRecommendation {
  const GuidanceRecommendation({
    required this.step,
    required this.supportTip,
  });

  final AdaptivePracticeStep step;

  /// Konkreter Satz für Eltern oder Lehrkraft: wie sie unterstützen können.
  final String supportTip;

  String get subject => step.subject;
  String get unit => step.unit;
  String get competency => step.competency;
  PracticeFocus get focus => step.focus;

  /// „Gemeinsam üben“ öffnet die Nachhilfe-Stunde, alles andere eine kurze
  /// Übungsrunde.
  bool get guided => step.focus == PracticeFocus.guidedPractice;
}

/// Vorher/zuletzt-Vergleich der selbstständigen Trefferquote einer Kompetenz.
class GuidanceDevelopment {
  const GuidanceDevelopment({
    required this.subject,
    required this.competency,
    required this.earlierCorrect,
    required this.earlierTotal,
    required this.recentCorrect,
    required this.recentTotal,
  });

  final String subject;
  final String competency;
  final int earlierCorrect;
  final int earlierTotal;
  final int recentCorrect;
  final int recentTotal;

  double get earlierRate => earlierCorrect / earlierTotal;
  double get recentRate => recentCorrect / recentTotal;

  /// Veränderung in Prozentpunkten (positiv = besser).
  int get changePoints => ((recentRate - earlierRate) * 100).round();
}

/// Überblick für Eltern und berechtigte Lehrkräfte: was das Kind gerade übt,
/// Stärken, Förderbedarf, Lernplan mit Ziel-Lernmodulen und Lernentwicklung.
///
/// Abgeleitet ausschließlich aus dem lokalen Aufgabenprotokoll genau eines
/// Kindes. Demo-Kinder, andere Profile, doppelte Einträge, Zukunftszeiten und
/// reine Messfächer (Knobel-Test) werden verworfen. Bei wenigen Daten bleiben
/// Stärken, Förderbedarf, Empfehlungen und Entwicklung leer – es wird nichts
/// behauptet. Keine Netzwerkzugriffe, keine Geräte-Synchronisierung.
class LearningGuidance {
  const LearningGuidance._({
    required this.studentId,
    required this.asOf,
    required this.total,
    required this.independentTotal,
    required this.current,
    required this.strengths,
    required this.needs,
    required this.recommendations,
    required this.development,
  });

  /// Präfix der Demo-Kinder in der Lehrkräfte-Demo. Ihre Daten gehören nie in
  /// eine echte Auswertung.
  static const demoStudentPrefix = 'demo-kind-';

  /// Zeitraum für „gerade geübt“.
  static const currentWindow = Duration(days: 7);
  static const maxCurrent = 4;
  static const maxListed = 4;

  /// Für „vorher/zuletzt“ braucht jede Hälfte mindestens vier Antworten.
  static const minDevelopment = 8;

  final String studentId;
  final DateTime asOf;
  final int total;
  final int independentTotal;
  final List<GuidancePracticeTopic> current;
  final List<GuidanceCompetency> strengths;
  final List<GuidanceCompetency> needs;
  final List<GuidanceRecommendation> recommendations;
  final List<GuidanceDevelopment> development;

  /// Erst ab fünf selbstständigen Antworten insgesamt gibt es Aussagen über
  /// Stärken oder Förderbedarf.
  bool get hasReliableEvidence =>
      strengths.isNotEmpty ||
      needs.isNotEmpty ||
      recommendations.isNotEmpty ||
      development.isNotEmpty;

  static bool isDemoStudent(String id) => id.startsWith(demoStudentPrefix);

  factory LearningGuidance.fromAttempts(
    Iterable<Attempt> source, {
    required String studentId,
    required DateTime now,
  }) {
    final asOf = now;
    final seen = <String>{};
    final attempts = <Attempt>[];
    if (studentId.trim().isNotEmpty && !isDemoStudent(studentId)) {
      for (final a in source) {
        if (a.studentId != studentId ||
            a.id.trim().isEmpty ||
            a.subject.trim().isEmpty ||
            a.competency.trim().isEmpty ||
            LearningAnalysis.assessmentSubjects.contains(a.subject) ||
            a.at.isAfter(asOf) ||
            !seen.add(a.id)) {
          continue;
        }
        attempts.add(a);
      }
    }
    final independentTotal = attempts.where((a) => !a.hintUsed).length;

    // Gerade geübt: Themen der letzten sieben Tage, neueste zuerst.
    final since = asOf.subtract(currentWindow);
    final recentGroups = <(String, String), List<Attempt>>{};
    for (final a in attempts) {
      if (a.at.isBefore(since) || a.unit.trim().isEmpty) continue;
      recentGroups.putIfAbsent((a.subject, a.unit), () => []).add(a);
    }
    final current = [
      for (final e in recentGroups.entries)
        GuidancePracticeTopic(
          subject: e.key.$1,
          unit: e.key.$2,
          answers: e.value.length,
          assisted: e.value.where((a) => a.hintUsed).length,
          independentCorrect:
              e.value.where((a) => a.correct && !a.hintUsed).length,
          lastAt: e.value
              .map((a) => a.at)
              .reduce((x, y) => x.isAfter(y) ? x : y),
        ),
    ]..sort((a, b) {
        final byTime = b.lastAt.compareTo(a.lastAt);
        return byTime != 0 ? byTime : b.answers.compareTo(a.answers);
      });

    final analysis = LearningAnalysis.analyze(attempts, now: asOf);
    GuidanceCompetency competency(CompetencyStat s) => GuidanceCompetency(
          subject: s.subject,
          unit: s.unit,
          competency: s.competency,
          level: s.level,
          independentAttempts: s.independentAttempts,
          independentCorrect: s.independentCorrect,
          pattern: s.patterns.isEmpty ? null : s.patterns.first.$1,
        );
    // analysis.stats ist nach Trefferquote aufsteigend sortiert.
    final strengths = [
      for (final s in analysis.stats.reversed)
        if (s.level == MasteryLevel.secure) competency(s),
    ].take(maxListed).toList(growable: false);
    final needs = [
      for (final level in [MasteryLevel.needsHelp, MasteryLevel.developing])
        for (final s in analysis.stats)
          if (s.level == level) competency(s),
    ].take(maxListed).toList(growable: false);

    final plan = AdaptivePracticePlan.fromAttempts(attempts,
        studentId: studentId, now: asOf);
    final recommendations = [
      for (final step in plan.steps)
        GuidanceRecommendation(step: step, supportTip: _supportTip(step)),
    ];

    final byCompetency = <(String, String), List<Attempt>>{};
    for (final a in attempts) {
      if (a.hintUsed) continue;
      byCompetency.putIfAbsent((a.subject, a.competency), () => []).add(a);
    }
    final development = <GuidanceDevelopment>[];
    for (final e in byCompetency.entries) {
      final list = e.value
        ..sort((x, y) {
          final t = x.at.compareTo(y.at);
          return t != 0 ? t : x.id.compareTo(y.id);
        });
      if (list.length < minDevelopment) continue;
      final half = (list.length ~/ 2).clamp(4, 10);
      final recent = list.sublist(list.length - half);
      final earlier = list.sublist(list.length - 2 * half, list.length - half);
      development.add(GuidanceDevelopment(
        subject: e.key.$1,
        competency: e.key.$2,
        earlierCorrect: earlier.where((a) => a.correct).length,
        earlierTotal: earlier.length,
        recentCorrect: recent.where((a) => a.correct).length,
        recentTotal: recent.length,
      ));
    }
    development.sort((a, b) {
      final change = b.changePoints.abs().compareTo(a.changePoints.abs());
      if (change != 0) return change;
      final subject = a.subject.compareTo(b.subject);
      return subject != 0 ? subject : a.competency.compareTo(b.competency);
    });

    return LearningGuidance._(
      studentId: studentId,
      asOf: asOf,
      total: attempts.length,
      independentTotal: independentTotal,
      current: List.unmodifiable(current.take(maxCurrent)),
      strengths: List.unmodifiable(strengths),
      needs: List.unmodifiable(needs),
      recommendations: List.unmodifiable(recommendations),
      development: List.unmodifiable(development.take(maxListed)),
    );
  }

  /// Unterstützung zu Hause oder in der Schule, passend zum Schwerpunkt.
  static String _supportTip(AdaptivePracticeStep step) {
    final label = '${step.subject} ${step.unit} ${step.competency}'
        .toLowerCase();
    final base = switch (step.focus) {
      PracticeFocus.guidedPractice =>
        'Nicht vorrechnen: erst gemeinsam mit Lumos Material eine Aufgabe '
            'anschauen, dann das Kind selbst probieren lassen. ',
      PracticeFocus.consolidate =>
        'Kurz und regelmäßig üben (etwa 10 Minuten an verschiedenen Tagen). ',
      PracticeFocus.review =>
        'Länger nicht geübt: ein paar bekannte Aufgaben auffrischen. ',
      PracticeFocus.extend =>
        'Sitzt sicher: ruhig eine etwas schwierigere Aufgabe anbieten. ',
    };
    final extra = label.contains('zehnerübergang') || label.contains('plus') ||
            label.contains('minus')
        ? 'Fragen Sie: „Wie viele fehlen bis zum nächsten Zehner?“'
        : label.contains('einmaleins') || label.contains('mal')
            ? 'Fragen Sie nach einer Kernaufgabe: „Was ist 5 mal? Was ist 10 mal?“'
            : label.contains('lesen') || label.contains('silben')
                ? 'Abwechselnd lesen: Sie einen Satz, Ihr Kind den nächsten.'
                : label.contains('schreib') || label.contains('recht')
                    ? 'Wörter in Silben sprechen und dabei mitklatschen.'
                    : 'Das Kind erklären lassen, wie es gerechnet oder '
                        'gedacht hat.';
    return '$base$extra';
  }
}
