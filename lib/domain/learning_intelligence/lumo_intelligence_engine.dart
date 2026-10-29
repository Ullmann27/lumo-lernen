import '../../core/learning_journey.dart';
import 'concept_graph.dart';
import 'learning_scene_contract.dart';
import 'scene_memory.dart';

enum IntelligenceAction { explain, wait, blocked, offerPause }

enum ConceptCertainty { unobserved, observed, transferConfirmed, retained }

class IntelligenceDecision {
  const IntelligenceDecision(
      {required this.action, required this.reason, this.method});
  final IntelligenceAction action;
  final ExplanationMethod? method;
  final String reason;
  // Choosing an explanation never creates a competence claim.
  bool get confirmedCompetence => false;
}

class ConceptAssessment {
  const ConceptAssessment(this.certainty, this.observedAttempts, this.reason);
  final ConceptCertainty certainty;
  final int observedAttempts;
  final String reason;
}

class LumoIntelligenceEngine {
  const LumoIntelligenceEngine();
  static final _graph = LumoConceptGraph.reference();
  IntelligenceDecision decide(
      {required String conceptId,
      required String problemId,
      required SceneMemory memory,
      required bool explicitRequest,
      bool isExam = false,
      ExplanationMethod? preferredMethod}) {
    if (_graph[conceptId] == null)
      return const IntelligenceDecision(
          action: IntelligenceAction.blocked,
          reason: 'Dieses Lernziel ist noch nicht geprüft zugeordnet.');
    if (isExam)
      return const IntelligenceDecision(
          action: IntelligenceAction.blocked,
          reason: 'Während des Lernchecks geben wir keine fachliche Hilfe.');
    if (!explicitRequest)
      return const IntelligenceDecision(
          action: IntelligenceAction.wait,
          reason:
              'Lumo lässt Zeit zum Nachdenken und wartet auf deinen Wunsch.');
    final previous = memory.forProblem(conceptId, problemId);
    final tried = previous.map((r) => r.method).toSet();
    if (preferredMethod != null && !tried.contains(preferredMethod)) {
      return IntelligenceDecision(
          action: IntelligenceAction.explain,
          method: preferredMethod,
          reason:
              'Du hast diesen Lernweg angefordert. Wir machen das Lernziel damit sichtbar.');
    }
    if (previous.isEmpty) {
      final useful = memory.records
          .where((r) =>
              r.conceptId == conceptId &&
              r.outcome == SceneOutcome.independentTransfer)
          .toList();
      if (useful.isNotEmpty)
        return IntelligenceDecision(
            action: IntelligenceAction.explain,
            method: useful.last.method,
            reason:
                'Nach dieser Darstellung gelang früher eine neue Aufgabe selbstständig. Wir probieren sie wieder.');
    }
    for (final method in ExplanationMethod.values) {
      if (tried.contains(method)) continue;
      return IntelligenceDecision(
          action: IntelligenceAction.explain,
          method: method,
          reason: previous.any((r) => r.outcome == SceneOutcome.notUnderstood)
              ? 'Die bisherige Erklärung hat noch nicht geholfen. Wir probieren eine andere Darstellung.'
              : 'Du hast um Hilfe gebeten. Wir probieren einen passenden Lernschritt.');
    }
    return const IntelligenceDecision(
        action: IntelligenceAction.offerPause,
        reason:
            'Wir haben mehrere Wege ausprobiert. Du kannst eine andere Aufgabe wählen oder eine kurze Pause machen.');
  }

  ConceptAssessment assess(
      LumoConcept node, Map<String, JourneySkill> journey) {
    final records = journey.values
        .where((r) => r.subject == node.subject && node.units.contains(r.unit))
        .toList();
    final attempts = records.fold<int>(0, (sum, r) => sum + r.attempts);
    final certainty = records.any((r) => r.status == JourneyStatus.retained)
        ? ConceptCertainty.retained
        : records.any((r) => r.status == JourneyStatus.independentlyChecked)
            ? ConceptCertainty.transferConfirmed
            : attempts > 0
                ? ConceptCertainty.observed
                : ConceptCertainty.unobserved;
    return ConceptAssessment(
        certainty,
        attempts,
        switch (certainty) {
          ConceptCertainty.unobserved =>
            'Hier liegt noch keine geprüfte Beobachtung vor.',
          ConceptCertainty.observed =>
            '$attempts Versuche beobachtet; eine bestätigte Übertragung ist noch offen.',
          ConceptCertainty.transferConfirmed =>
            'Verschiedene Aufgaben und eine neue Übertragung gelangen ohne Hilfe.',
          ConceptCertainty.retained =>
            'Zusätzlich gelang eine unabhängige Wiederholung nach einer Pause.',
        });
  }

  /// Select an actually new transfer number within the verified two-digit
  /// domain. Exhaustion offers a different task instead of recycling evidence.
  int? transferNumber(int source, SceneMemory memory) {
    if (source < 10 || source > 99)
      throw ArgumentError('Expected two-digit source');
    final preferred = source > 55 ? source - 27 : source + 27;
    for (var i = 0; i < 90; i++) {
      final candidate = 10 + (preferred - 10 + i) % 90;
      if (candidate != source &&
          !memory.transferProblems.contains('place-value:$candidate'))
        return candidate;
    }
    return null;
  }
}
