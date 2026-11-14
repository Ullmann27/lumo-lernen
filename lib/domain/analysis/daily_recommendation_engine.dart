import '../../core/progress_repository.dart';
import 'lumo_analysis_domain.dart';

class DailyRecommendationEngine {
  const DailyRecommendationEngine();

  DailyRecommendationPlan buildPlan({
    required String childId,
    required Map<String, SkillRecord> skills,
    required List<ReadingAnalysisSummary> readingSummaries,
    int dailyGoalTarget = 5,
  }) {
    final weakSkills = skills.values.toList(growable: false)
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    final strongSkills = skills.values.where((skill) => skill.mastery >= 70 && skill.attempts >= 3).toList(growable: false)
      ..sort((a, b) => b.mastery.compareTo(a.mastery));
    final blocks = <DailyRecommendationBlock>[];

    if (weakSkills.isNotEmpty && weakSkills.first.weaknessScore > .25) {
      final weak = weakSkills.first;
      blocks.add(DailyRecommendationBlock(
        title: 'Foerderblock: ${weak.unit}',
        description: 'Kurz und ruhig üben. Lumo nimmt zuerst einen leichteren Schritt.',
        subject: weak.subject,
        unit: weak.unit,
        minutes: 6,
        kind: RecommendationKind.tutoring,
        priority: 100,
      ));
    } else {
      blocks.add(const DailyRecommendationBlock(
        title: 'Sanfter Start',
        description: 'Fuenf gemischte Aufgaben zum Reinkommen.',
        subject: 'Alle',
        unit: 'Alle',
        minutes: 5,
        kind: RecommendationKind.practice,
        priority: 80,
      ));
    }

    // ASR summaries have no assessment provenance. Keep the public argument
    // for existing callers, but offer reading as a neutral practice routine.
    blocks.add(const DailyRecommendationBlock(
      title: 'Lesefuchs-Runde',
      description: 'Eine kurze Geschichte Satz für Satz lesen.',
      subject: 'Lesen',
      unit: 'Aktives Lesen',
      minutes: 6,
      kind: RecommendationKind.reading,
      priority: 90,
    ));

    if (strongSkills.isNotEmpty) {
      final strong = strongSkills.first;
      blocks.add(DailyRecommendationBlock(
        title: 'Erfolgsblock: ${strong.unit}',
        description: 'Etwas, das schon gut klappt, damit Lernen positiv endet.',
        subject: strong.subject,
        unit: strong.unit,
        minutes: 4,
        kind: RecommendationKind.success,
        priority: 50,
      ));
    }

    final missingMinutes = dailyGoalTarget <= 5 ? 0 : 3;
    if (missingMinutes > 0) {
      blocks.add(const DailyRecommendationBlock(
        title: 'Mini-Wiederholung',
        description: 'Ein kleiner Abschluss mit bekannten Aufgaben.',
        subject: 'Alle',
        unit: 'Wiederholung',
        minutes: 3,
        kind: RecommendationKind.review,
        priority: 30,
      ));
    }

    blocks.sort((a, b) => b.priority.compareTo(a.priority));
    final limited = blocks.take(4).toList(growable: false);
    final headline = limited.isEmpty ? 'Heute ruhig starten' : 'Morgen: ${limited.first.title}';
    final lumoMessage = _lumoMessage(limited);
    final parentNote = _parentNote(weakSkills);

    return DailyRecommendationPlan(
      childId: childId,
      date: DateTime.now().add(const Duration(days: 1)),
      headline: headline,
      lumoMessage: lumoMessage,
      blocks: limited,
      parentNote: parentNote,
    );
  }

  String _lumoMessage(List<DailyRecommendationBlock> blocks) {
    if (blocks.any((block) => block.kind == RecommendationKind.tutoring)) {
      return 'Morgen machen wir zuerst den wackeligen Schritt kleiner. Danach kommt etwas, das du schon gut kannst.';
    }
    return 'Morgen starten wir kurz, freundlich und mit einer Aufgabe, die zu dir passt.';
  }

  String _parentNote(List<SkillRecord> weakSkills) {
    final parts = <String>[];
    if (weakSkills.isNotEmpty && weakSkills.first.weaknessScore > .25) {
      final weak = weakSkills.first;
      parts.add('${weak.subject}/${weak.unit} priorisieren: Trefferquote ${(weak.accuracy * 100).round()}%, ${weak.wrong} Fehler.');
    }
    if (parts.isEmpty) return 'Keine klare Schwachstelle. Kurze gemischte Uebung und positives Ende empfehlen.';
    return parts.join(' ');
  }
}

class ParentReportEngine {
  const ParentReportEngine();

  ParentReportSummary buildReport({
    required String childName,
    required Map<String, SkillRecord> skills,
    required List<ReadingAnalysisSummary> readingSummaries,
  }) {
    // Persisted summaries contain ASR observations, not confirmed reading
    // assessments or a verified current-profile binding. Leave them intact
    // and derive competence only from the supplied learning SkillRecords.
    final reading = _readingBlock(skills);
    final math = _subjectBlock('Mathematik', skills);
    final german = _germanBlock(skills);
    final nextSteps = <String>[
      reading.recommendedAction,
      math.recommendedAction,
      german.recommendedAction,
    ].where((step) => step.trim().isNotEmpty).toSet().take(4).toList(growable: false);

    return ParentReportSummary(
      childName: childName,
      generatedAt: DateTime.now(),
      summary: 'Lumo hat Lernen, Lesen und Fehlerbilder lokal ausgewertet. Die Empfehlungen bleiben kurz, kindgerecht und ohne Druck.',
      reading: reading,
      math: math,
      german: german,
      nextSteps: nextSteps.isEmpty ? const <String>['Kurze gemischte Einheit mit positivem Abschluss.'] : nextSteps,
    );
  }

  SubjectAnalysisBlock _readingBlock(Map<String, SkillRecord> skills) {
    if (!skills.values.any((skill) => skill.subject == 'Lesen')) {
      return const SubjectAnalysisBlock(
        subject: 'Lesen',
        strengths: <String>['Lesemodus bereit'],
        weaknesses: <String>[],
        errorPatterns: <String>[],
        recommendedAction: 'Eine kurze aktive Leserunde starten.',
        priority: 70,
      );
    }
    return _subjectBlock('Lesen', skills);
  }

  SubjectAnalysisBlock _subjectBlock(String subject, Map<String, SkillRecord> skills) {
    final records = skills.values.where((skill) => skill.subject == subject).toList(growable: false);
    if (records.isEmpty) {
      return SubjectAnalysisBlock(
        subject: subject,
        strengths: const <String>[],
        weaknesses: const <String>['Noch keine gespeicherten Aufgaben'],
        errorPatterns: const <String>[],
        recommendedAction: '$subject mit 5 kurzen Aufgaben starten.',
        priority: 50,
      );
    }
    final weak = records.where((skill) => skill.weaknessScore > .25).toList(growable: false)
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    final strong = records.where((skill) => skill.mastery >= 70).toList(growable: false)
      ..sort((a, b) => b.mastery.compareTo(a.mastery));
    return SubjectAnalysisBlock(
      subject: subject,
      strengths: strong.take(3).map((skill) => '${skill.unit} (${skill.mastery}%)').toList(growable: false),
      weaknesses: weak.take(3).map((skill) => '${skill.unit}: ${skill.wrong} Fehler').toList(growable: false),
      errorPatterns: weak.take(3).map((skill) => skill.unit).toList(growable: false),
      recommendedAction: weak.isEmpty ? '$subject mit Erfolgsblock festigen.' : '${weak.first.unit} in kleinen Schritten wiederholen.',
      priority: weak.isEmpty ? 40 : 85,
    );
  }

  SubjectAnalysisBlock _germanBlock(Map<String, SkillRecord> skills) {
    final deutsch = skills.values.where((skill) => skill.subject == 'Deutsch' || skill.subject == 'Lesen' || skill.subject == 'Rechtschreibung').toList(growable: false);
    final weak = deutsch.where((skill) => skill.weaknessScore > .25).toList(growable: false)
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    final strengths = deutsch.where((skill) => skill.mastery >= 70).take(3).map((skill) => '${skill.unit} (${skill.mastery}%)').toList(growable: true);
    final weaknesses = weak.take(3).map((skill) => '${skill.unit}: ${skill.wrong} Fehler').toList(growable: true);
    return SubjectAnalysisBlock(
      subject: 'Deutsch/Lesen',
      strengths: strengths,
      weaknesses: weaknesses,
      errorPatterns: weak.take(2).map((skill) => skill.unit).toList(growable: false),
      recommendedAction: weaknesses.isEmpty ? 'Kurze Leseeinheit zur Stabilisierung.' : '${weak.first.unit} in kleinen Schritten wiederholen.',
      priority: weaknesses.isEmpty ? 45 : 90,
    );
  }
}
