import 'progress_repository.dart';
import 'weakness_detection_engine.dart';

/// Erzeugt kindgerechte Empfehlungen, die Lumo dem Kind sagen kann.
///
/// Die Engine ist regelbasiert und arbeitet komplett offline.
/// Sie hat keinen Zugriff auf Cloud-Services. Die Empfehlungen sind
/// freundlich formuliert, niemals wertend ("du bist schlecht in X"),
/// und immer mit konkretem nächsten Schritt.
class RecommendationEngine {
  RecommendationEngine({WeaknessDetectionEngine? detector})
      : _detector = detector ?? const WeaknessDetectionEngine();

  final WeaknessDetectionEngine _detector;

  /// Liefert die wichtigste aktuelle Empfehlung — oder null wenn keine
  /// nötig (z.B. Kind hat gerade erst gestartet, alles im grünen Bereich).
  Recommendation? topRecommendation(
    Map<String, SkillRecord> skills, {
    int dailyGoalDone = 0,
    int dailyGoalTarget = 5,
  }) {
    final all = recommendations(
      skills,
      dailyGoalDone: dailyGoalDone,
      dailyGoalTarget: dailyGoalTarget,
    );
    return all.isEmpty ? null : all.first;
  }

  /// Liefert alle aktuellen Empfehlungen, nach Priorität sortiert.
  List<Recommendation> recommendations(
    Map<String, SkillRecord> skills, {
    int dailyGoalDone = 0,
    int dailyGoalTarget = 5,
  }) {
    final result = <Recommendation>[];

    // Priorität 1: aktuelle Schwächen ansprechen
    final weak = _detector.findWeaknesses(skills);
    if (weak.isNotEmpty) {
      final w = weak.first;
      result.add(Recommendation(
        kind: RecommendationKind.weaknessFocus,
        priority: 100,
        subject: w.subject,
        unit: w.unit,
        suggestedDifficulty: 1, // bewusst leicht starten
        message: _weaknessMessage(w),
        cta: 'Komm, drei leichte Aufgaben',
      ));
    }

    // Priorität 2: Tagesziel anstoßen
    if (dailyGoalDone < dailyGoalTarget) {
      final remaining = dailyGoalTarget - dailyGoalDone;
      result.add(Recommendation(
        kind: RecommendationKind.dailyGoal,
        priority: 60,
        message: dailyGoalDone == 0
            ? 'Heute haben wir noch nichts gelernt. '
                'Sollen wir mit ein paar leichten Aufgaben starten?'
            : 'Du hast schon $dailyGoalDone Aufgaben geschafft! '
                'Noch $remaining bis zum Tagesziel.',
        cta: dailyGoalDone == 0 ? 'Los geht\'s' : 'Weitermachen',
      ));
    } else {
      result.add(Recommendation(
        kind: RecommendationKind.dailyGoalDone,
        priority: 40,
        message: 'Stark! Tagesziel geschafft. '
            'Wenn du noch Lust hast, üben wir freiwillig weiter.',
        cta: 'Bonusrunde',
      ));
    }

    // Priorität 3: gemeisterte Skills anerkennen
    final mastered = _detector.findMastered(skills);
    if (mastered.isNotEmpty) {
      final m = mastered.first;
      result.add(Recommendation(
        kind: RecommendationKind.mastered,
        priority: 30,
        subject: m.subject,
        unit: m.unit,
        suggestedDifficulty: m.difficulty,
        message: '${m.unit} sitzt richtig gut! '
            'Wollen wir es etwas schwerer machen?',
        cta: 'Schwerer probieren',
      ));
    }

    // Priorität 4: Wiedereinstieg vorschlagen, wenn ein Skill länger
    // als 3 Tage nicht mehr geübt wurde.
    final stale = _findStaleSkills(skills);
    if (stale.isNotEmpty) {
      final s = stale.first;
      result.add(Recommendation(
        kind: RecommendationKind.refresh,
        priority: 20,
        subject: s.subject,
        unit: s.unit,
        suggestedDifficulty: s.difficulty,
        message: '${s.unit} haben wir schon länger nicht geübt. '
            'Sollen wir kurz auffrischen?',
        cta: 'Kurz auffrischen',
      ));
    }

    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  String _weaknessMessage(SkillRecord r) {
    // Mehrere Varianten, damit Lumo nicht immer dasselbe sagt
    final variants = <String>[
      'Ich habe gesehen, dass ${r.unit} gerade noch schwer ist. '
          'Lass uns drei leichte Aufgaben zusammen machen.',
      'Bei ${r.unit} bist du noch am Lernen — das ist völlig okay. '
          'Wir gehen es Schritt für Schritt an.',
      'Komm, wir schauen uns ${r.unit} nochmal in Ruhe an. '
          'Ich helfe dir.',
    ];
    // Pseudo-zufällig anhand der bisherigen Versuche, damit es deterministisch
    // bleibt aber abwechselt.
    final idx = r.attempts % variants.length;
    return variants[idx];
  }

  List<SkillRecord> _findStaleSkills(Map<String, SkillRecord> skills) {
    final cutoff = DateTime.now().subtract(const Duration(days: 3));
    final stale = skills.values
        .where((r) =>
            r.attempts >= 3 &&
            r.lastSeen.isBefore(cutoff) &&
            !_detector.isWeak(r))
        .toList();
    stale.sort((a, b) => a.lastSeen.compareTo(b.lastSeen));
    return stale;
  }
}

/// Eine Empfehlung, die Lumo aussprechen kann.
class Recommendation {
  const Recommendation({
    required this.kind,
    required this.priority,
    required this.message,
    required this.cta,
    this.subject,
    this.unit,
    this.suggestedDifficulty,
  });

  final RecommendationKind kind;
  final int priority;
  final String message;
  final String cta;
  final String? subject;
  final String? unit;
  final int? suggestedDifficulty;
}

enum RecommendationKind {
  weaknessFocus,
  dailyGoal,
  dailyGoalDone,
  mastered,
  refresh,
}
