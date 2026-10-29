import 'package:flutter/material.dart';
import '../../../app/app_state.dart';
import '../../../domain/learning_intelligence/concept_graph.dart';
import '../../../domain/learning_intelligence/scene_memory.dart';
import '../../../domain/learning_intelligence/lumo_intelligence_engine.dart';
import '../../../domain/learning_intelligence/learning_scene_contract.dart';

/// Local reasons and evidence, scoped exactly like the rest of the parent
/// report. Method feedback alone never becomes a confirmed competence.
class LumoTutorEvidenceCard extends StatelessWidget {
  const LumoTutorEvidenceCard({super.key, required this.appState});
  final LumoAppState appState;
  @override
  Widget build(BuildContext context) {
    if (!appState.learningProfileLoaded) return const SizedBox.shrink();
    final memory = appState.learningProfile.sceneMemory;
    final pending = appState.learningProfile.hasPendingSceneReceipt;
    if (memory.records.isEmpty && !pending) return const SizedBox.shrink();
    final graph = LumoConceptGraph.reference();
    final latest = <String, SceneObservation>{};
    for (final row in memory.records.reversed) {
      if (graph[row.conceptId] != null)
        latest.putIfAbsent(row.conceptId, () => row);
      if (latest.length == 3) break;
    }
    return Container(
        key: const ValueKey('lumo-parent-scene-evidence'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xEF082849),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xA065DEFF))),
        child: DefaultTextStyle(
            style: const TextStyle(
                color: Colors.white, fontFamily: 'Nunito', height: 1.4),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Warum Lumo diesen Lernweg wählt',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const Text('Gespeicherte Beobachtungen, keine Diagnose.',
                  style: TextStyle(color: Color(0xFF9EEAFF))),
              if (pending) ...[
                const Text('Ein Lernbeleg wartet noch aufs Speichern.'),
                TextButton(
                    onPressed: () async {
                      try {
                        await appState.flushLearningProgress();
                      } catch (_) {/* The pending status remains visible. */}
                    },
                    style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: const Color(0xFFBFEFFF)),
                    child: const Text('Speichern erneut versuchen')),
              ],
              for (final row in latest.values) ...[
                const SizedBox(height: 12),
                Text(graph[row.conceptId]!.goal,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${switch (row.method) {
                  ExplanationMethod.verbal => 'Sprachlich',
                  ExplanationMethod.pictorial => 'Bildlich',
                  ExplanationMethod.interactive => 'Mit Material',
                  ExplanationMethod.guided => 'Schrittweise'
                }}: ${switch (row.outcome) {
                  SceneOutcome.introduced =>
                    'Diese Darstellung wurde ausprobiert.',
                  SceneOutcome.notUnderstood =>
                    'Das Kind bat um einen anderen Erklärweg.',
                  SceneOutcome.assistedTransfer =>
                    'Die Folgeaufgabe gelang nach Unterstützung oder Korrektur.',
                  SceneOutcome.independentTransfer =>
                    'Eine andere Zahl wurde selbst gebaut und richtig erklärt.',
                }}'),
                Text(
                    const LumoIntelligenceEngine()
                        .assess(
                            graph[row.conceptId]!, appState.learningJourney())
                        .reason,
                    style: const TextStyle(color: Color(0xFFBFEFFF))),
              ],
            ])));
  }
}
