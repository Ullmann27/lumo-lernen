import 'dart:convert';
import 'dart:io';
import 'legacy_tutor_9fdf.dart' as baseline;
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/tutor_coordination_engine.dart';
import 'package:lumo_lernen/core/learning_journey.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lumo_intelligence_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/concept_graph.dart';

void main() {
  test('synthetic trajectory bank compares safety decisions against existing tutor', () {
    final rows = <Map<String, Object>>[];
    baseline.TutorCoordinationEngine old({bool exam = false}) => baseline.TutorCoordinationEngine()
      ..activateProfile(1)
      ..enterTask(baseline.TutorTaskScope(generation: 1, taskId: 'old', problemId: 'hashed-84', subject: 'Mathematik', unit: 'Zehner und Einer', isExam: exam))
      ..requestHelp();
    void row(String name, bool baseline, bool candidate, bool expected, String limit) {
      rows.add({'case': name, 'baseline_accepts': baseline, 'candidate_accepts': candidate,
        'expected': expected, 'passed': candidate == expected,
        'comparison': baseline == candidate ? 'unchanged' : 'changed', 'scope': limit});
    }
    var legacy = old();
    final wrongProcess = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57, sourceProblemId: 'hashed-84', sourceTaskId: 'old', generation: 1)..beginTransfer();
    final process = wrongProcess.submitConstruction(tens: 4, ones: 17);
    row('correct_total_wrong_place_value_process', legacy.checkTransfer(problemId: 'place-value:57', correct: true, independent: true)!.transferCheck,
      process.processCorrect && wrongProcess.submitComprehension(7) != null, false,
      'Domain-interface synthetic input; original UI normally caps ones at nine. No empirical child-performance claim.');
    legacy = old();
    var rejectedSame = false;
    try { PlaceValueLessonSession(sourceNumber: 84, targetNumber: 84, sourceProblemId: 'hashed-84'); } on ArgumentError { rejectedSame = true; }
    row('same_problem_different_id_spelling', legacy.checkTransfer(problemId: 'place-value:84', correct: true, independent: true)!.transferCheck,
      !rejectedSame, false, 'Previously boolean/ID-only API versus validated source/target domain.');
    legacy = old();
    final guessing = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57, sourceProblemId: 'hashed-84', sourceTaskId: 'old', generation: 1)..beginTransfer();
    guessing.submitConstruction(tens: 5, ones: 7); guessing.submitComprehension(6);
    row('correct_after_guess', legacy.checkTransfer(problemId: 'place-value:57', correct: true, independent: false)!.transferCheck,
      guessing.submitComprehension(7)!.evidence.transferCheck, false, 'Both implementations must keep corrected work assisted.');
    TutorCoordinationEngine current({bool exam = false}) => TutorCoordinationEngine()
      ..activateProfile(1)..enterTask(TutorTaskScope(generation: 1, taskId: 'old', problemId: 'hashed-84', subject: 'Mathematik', unit: 'Zehner und Einer', isExam: exam))..requestHelp();
    final tutor = current();
    final valid = PlaceValueLessonSession(sourceNumber: 84, targetNumber: 57, sourceProblemId: 'hashed-84', sourceTaskId: 'old', generation: 1)..beginTransfer();
    valid.submitConstruction(tens: 5, ones: 7); final proof = valid.submitComprehension(7)!;
    row('new_independent_construction_and_explanation', old().checkTransfer(problemId: 'place-value:57', correct: true, independent: true)!.transferCheck,
      tutor.checkSceneTransfer(proof)!.transferCheck, true, 'One observation, not a mastery claim.');
    final replayBaseline = old();
    replayBaseline.checkTransfer(problemId: 'place-value:57', correct: true, independent: true);
    row('replayed_receipt', replayBaseline.checkTransfer(problemId: 'place-value:57', correct: true, independent: true) != null,
      tutor.checkSceneTransfer(proof) != null, false, 'Duplicate submissions do not add independent evidence.');
    row('test_mode', old(exam: true).checkTransfer(problemId: 'place-value:57', correct: true, independent: true) != null,
      current(exam: true).checkSceneTransfer(proof) != null, false, 'Exams suppress help and transfer workshop.');
    var memory = SceneMemory().record(SceneObservation.methodFeedback(id: 'first-failed', conceptId: 'math.tens_ones',
      problemId: 'hashed-84', method: ExplanationMethod.verbal, understood: false, at: DateTime.utc(2026,10,29)));
    final decision = const LumoIntelligenceEngine().decide(conceptId: 'math.tens_ones', problemId: 'hashed-84', memory: memory, explicitRequest: true);
    row('different_method_after_failure', old().requestHelp() == 2,
      decision.method == ExplanationMethod.pictorial, true, 'Alternative selection differs; pedagogical superiority is not established.');
    memory = memory.record(SceneObservation.completed(proof: proof, method: decision.method!, at: proof.completedAt));
    final restored = SceneMemory.fromJson(jsonDecode(jsonEncode(memory.toJson())));
    row('method_receipt_survives_serialization', false,
      restored.records.any((r) => r.outcome == SceneOutcome.independentTransfer && r.method == ExplanationMethod.pictorial), true,
      'Old tutor has no durable method receipt; actual filesystem/profile cases run in storage tests.');
    final at = DateTime.utc(2026,10,29);
    var journey = LearningJourney();
    for (var i = 0; i < 3; i++) {
      journey = journey.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer', now: at.add(Duration(days: i * 2)),
        evidence: LearningEvidence(taskId: 'retained-$i', problemId: 'problem-$i', correct: true, transferCheck: i == 1));
    }
    journey = journey.recordEvidence(subject: 'Mathematik', unit: 'Zehner und Einer', now: at.add(const Duration(days: 9)),
      evidence: const LearningEvidence(taskId: 'forgotten', correct: false));
    final checked = const LumoIntelligenceEngine().assess(LumoConceptGraph.reference()['math.tens_ones']!, journey.records);
    row('forgotten_after_delay_is_not_retained', journey.records.values.single.status == JourneyStatus.retained,
      checked.certainty == ConceptCertainty.retained, false, 'A delayed failure removes retained status without diagnosing a weakness.');
    row('unknown_sibling_has_no_confirmed_concept', false,
      const LumoIntelligenceEngine().assess(LumoConceptGraph.reference()['math.tens_ones']!, {}).certainty == ConceptCertainty.transferConfirmed,
      false, 'Empty sibling map; real namespace separation is covered by separate persistence tests.');
    final targetDir = Platform.environment['LUMO_INTELLIGENCE_EVIDENCE'];
    if (targetDir != null) {
      final file = File('$targetDir/synthetic-trajectories.json'); file.parent.createSync(recursive: true);
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert({'synthetic': true, 'cases': rows,
        'limits': 'Deterministic software cases, not a scientific validation of learning effectiveness or a diagnosis.'}));
    }
    expect(rows.where((r) => r['passed'] != true), isEmpty);
    expect(rows, hasLength(10));
  });
}
