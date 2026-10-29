import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/learning_intelligence/learning_scene_contract.dart';
import 'package:lumo_lernen/domain/learning_intelligence/lesson_scene_engine.dart';

void main() {
  const engine = LessonSceneEngine();
  test('four methods have distinct verifiable scenes and preserve accessibility', () {
    final scenes = [for (final method in ExplanationMethod.values)
      engine.placeValue(number: 84, method: method, reduceMotion: true)];
    expect(scenes.map((s) => s.method).toSet(), hasLength(4));
    expect(scenes.first.objects, isEmpty);
    expect(scenes[1].objects.any((o) => o.kind == SceneObjectKind.tenRod && o.quantity == 8), isTrue);
    expect(scenes[2].steps.first.interaction, SceneInteraction.bundleTen);
    expect(scenes[3].steps.length, greaterThan(1));
    for (final scene in scenes) {
      expect(scene.reduceMotion, isTrue);
      expect(scene.accessibilityLabel, isNotEmpty);
      expect(LumoLearningScene.fromJson(scene.toJson()).toJson(), scene.toJson());
      final future = {...scene.toJson(), 'version': 99};
      expect(() => LumoLearningScene.fromJson(future), throwsFormatException);
    }
  });
  test('rules check actual process and result without evaluating arbitrary text', () {
    const rule = SceneRule(kind: SceneRuleKind.composePlaceValue, expected: {'number': 84});
    expect(rule.accepts({'tens': 8, 'ones': 4}), isTrue);
    expect(rule.accepts({'tens': 7, 'ones': 14}), isFalse);
    expect(rule.accepts({'tens': 4, 'ones': 8}), isFalse);
    expect(rule.accepts({'tens': '8', 'ones': 4}), isFalse);
    expect(rule.accepts({'tens': 8, 'ones': 4, 'untrusted': true}), isFalse);
    expect(() => engine.placeValue(number: 184, method: ExplanationMethod.verbal), throwsArgumentError);
  });
  test('reading evidence, syllables and sentence order have exact answer conditions', () {
    const reading = SceneRule(kind: SceneRuleKind.matchTextEvidence,
      expected: {'statement': 'Mia ist im Garten.', 'evidence': 'Mia gießt die Blumen im Garten.'});
    expect(reading.accepts({'statement': 'Mia ist im Garten.', 'evidence': 'Mia gießt die Blumen im Garten.'}), isTrue);
    expect(reading.accepts({'statement': 'Mia ist im Garten.', 'evidence': 'Die Sonne scheint.'}), isFalse);
    const syllables = SceneRule(kind: SceneRuleKind.arrangeTokens, expected: {'tokens': ['Ba', 'na', 'ne']});
    expect(syllables.accepts({'tokens': ['Ba', 'na', 'ne']}), isTrue);
    expect(syllables.accepts({'tokens': ['Ba', 'ne', 'na']}), isFalse);
  });
}
