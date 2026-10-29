import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/domain/learning_intelligence/concept_graph.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lumo_intelligence_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';

void main() {
  const engine = LumoIntelligenceEngine();
  final graph = LumoConceptGraph.reference();
  final at = DateTime.utc(2026, 10, 29);

  LearningJourney checkedUnit(String subject, String unit) {
    var journey = LearningJourney();
    for (var i = 0; i < 2; i++) {
      journey = journey.recordEvidence(subject: subject, unit: unit, now: at,
          evidence: LearningEvidence(taskId: 'answer-$i', problemId: 'problem-$i',
              correct: true, transferCheck: i == 1));
    }
    return journey;
  }

  test('practice-unit success cannot confirm any unvalidated process concept', () {
    for (final node in graph.nodes) {
      final journey = checkedUnit(node.subject, node.units.first);
      expect(journey.records.values.single.status, JourneyStatus.independentlyChecked);
      expect(engine.assess(node, journey.records).certainty, ConceptCertainty.observed,
          reason: '${node.id} needs its own process validator');
    }
  });

  test('number-word success cannot hide contradictory place-value evidence', () {
    final journey = checkedUnit('Mathematik', 'Zahl in Worten').recordEvidence(
        subject: 'Mathematik', unit: 'Zehner und Einer', now: at,
        evidence: const LearningEvidence(taskId: 'place-wrong', correct: false));
    expect(engine.assess(graph['math.place_value']!, journey.records).certainty,
        ConceptCertainty.observed);
  });

  test('only a matching validator receipt plus varied independent work confirms tens and ones', () {
    final lesson = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57,
        sourceProblemId: 'source')..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    final memory = SceneMemory().record(SceneObservation.completed(
        proof: proof, method: ExplanationMethod.pictorial, at: at));
    final single = LearningJourney().recordEvidence(subject: 'Mathematik',
        unit: 'Zehner und Einer', now: at, evidence: proof.evidence);
    final varied = single.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer', now: at,
        evidence: const LearningEvidence(taskId: 'other', problemId: 'place-value:42', correct: true));
    expect(engine.assess(graph['math.tens_ones']!, single.records, memory: memory).certainty,
        ConceptCertainty.observed);
    expect(engine.assess(graph['math.tens_ones']!, varied.records, memory: memory).certainty,
        ConceptCertainty.transferConfirmed);
    expect(engine.assess(graph['math.place_value']!, varied.records, memory: memory).certainty,
        ConceptCertainty.observed);
    final unrelated = checkedUnit('Mathematik', 'Zehner und Einer');
    expect(engine.assess(graph['math.tens_ones']!, unrelated.records, memory: memory).certainty,
        ConceptCertainty.observed, reason: 'receipt identity must belong to this journal');
    final failed = varied.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer', now: at,
        evidence: const LearningEvidence(taskId: 'new-failure', correct: false));
    expect(engine.assess(graph['math.tens_ones']!, failed.records, memory: memory).certainty,
        ConceptCertainty.observed);
  });

  test('later answer-only recall does not imply retained process understanding', () {
    final lesson = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57,
        sourceProblemId: 'source')..beginTransfer();
    lesson.submitConstruction(tens: 5, ones: 7);
    final proof = lesson.submitComprehension(7)!;
    var memory = SceneMemory().record(SceneObservation.completed(
        proof: proof, method: ExplanationMethod.interactive, at: at));
    var journey = LearningJourney().recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer',
        now: at, evidence: proof.evidence).recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer',
        now: at, evidence: const LearningEvidence(taskId: 'another', problemId: 'place-value:42', correct: true));
    journey = journey.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer',
        now: at.add(const Duration(days: 2)),
        evidence: const LearningEvidence(taskId: 'later-answer', correct: true));
    expect(journey.records.values.single.status, JourneyStatus.retained);
    expect(engine.assess(graph['math.tens_ones']!, journey.records, memory: memory).certainty,
        ConceptCertainty.transferConfirmed);
    final repeat = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 63,
        sourceProblemId: 'later-source')..beginTransfer();
    repeat.submitConstruction(tens: 6, ones: 3);
    final laterProof = repeat.submitComprehension(3)!;
    final later = at.add(const Duration(days: 3));
    memory = memory.record(SceneObservation.completed(proof: laterProof,
        method: ExplanationMethod.pictorial, at: later));
    journey = journey.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer', now: later,
        evidence: laterProof.evidence);
    expect(engine.assess(graph['math.tens_ones']!, journey.records, memory: memory).certainty,
        ConceptCertainty.retained);
  });
}
