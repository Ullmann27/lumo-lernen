import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning_intelligence/scene_memory.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lumo_intelligence_engine.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';

void main() {
  const engine = LumoIntelligenceEngine();
  final now = DateTime.utc(2026, 10, 29);
  test('first failed explanation chooses a distinct appropriate alternative', () {
    final memory = SceneMemory().record(SceneObservation.methodFeedback(id: 'first',
      conceptId: 'math.tens_ones', problemId: 'problem-84', method: ExplanationMethod.verbal,
      understood: false, at: now));
    final decision = engine.decide(conceptId: 'math.tens_ones', problemId: 'problem-84',
      memory: memory, explicitRequest: true);
    expect(decision.action, IntelligenceAction.explain);
    expect(decision.method, ExplanationMethod.pictorial);
    expect(decision.reason, contains('noch nicht geholfen'));
    expect(decision.confirmedCompetence, isFalse);
  });
  test('thinking time, refusal and exams never cause an unsolicited scene', () {
    for (final exam in [false, true]) {
      final d = engine.decide(conceptId: 'math.tens_ones', problemId: 'problem-84',
        memory: SceneMemory(), explicitRequest: false, isExam: exam);
      expect(d.action, exam ? IntelligenceAction.blocked : IntelligenceAction.wait);
      expect(d.method, isNull);
    }
  });
  test('all failed methods suggest another task/pause without diagnosing a child', () {
    var memory = SceneMemory();
    for (final method in ExplanationMethod.values) {
      memory = memory.record(SceneObservation.methodFeedback(id: method.name,
        conceptId: 'math.tens_ones', problemId: 'problem-84', method: method, understood: false, at: now));
    }
    final d = engine.decide(conceptId: 'math.tens_ones', problemId: 'problem-84', memory: memory, explicitRequest: true);
    expect(d.action, IntelligenceAction.offerPause);
    expect(d.reason, isNot(contains('Schwäche')));
    expect(d.confirmedCompetence, isFalse);
    expect(memory.records, hasLength(4));
    expect(SceneMemory.fromJson(memory.toJson()).toJson(), memory.toJson());
    expect(() => SceneMemory.fromJson({...memory.toJson(), 'version': 2}), throwsFormatException);
  });
}
