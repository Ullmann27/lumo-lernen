import 'dart:convert';

/// Sol owns rules and evidence. Animation consumers only render these values.
enum ExplanationMethod { verbal, pictorial, interactive, guided }
enum SceneObjectKind { tenRod, unitCube, wordCard, textCard }
enum LumoSceneGesture { lookAtMaterial, point, think, encourage, celebrate }
enum LumoSceneMood { attentive, thoughtful, encouraging, joyful }
enum SceneInteraction { listen, count, bundleTen, compose, choose, arrange }
enum SceneRuleKind { observe, composePlaceValue, chooseRemainder, matchTextEvidence, arrangeTokens }

class SceneObject {
  const SceneObject({required this.kind, required this.quantity, required this.label});
  final SceneObjectKind kind;
  final int quantity;
  final String label;
  Map<String, Object> toJson() => {'kind': kind.name, 'quantity': quantity, 'label': label};
}

class SceneRule {
  SceneRule({required this.kind, Map<String, Object> expected = const {}})
      : expected = Map.unmodifiable({for (final entry in expected.entries)
          entry.key: entry.value is List ? List<Object>.unmodifiable(entry.value as List) : entry.value}) {
    _validateRule(kind, this.expected);
  }
  const SceneRule.observe() : kind = SceneRuleKind.observe, expected = const {};
  final SceneRuleKind kind;
  final Map<String, Object> expected;
  bool accepts(Map<String, Object?> response) {
    switch (kind) {
      case SceneRuleKind.observe: return false; // Viewing is never scored.
      case SceneRuleKind.composePlaceValue:
        if (!_keys(response, {'tens', 'ones'})) return false;
        final tens = response['tens'], ones = response['ones'];
        return tens is int && ones is int && tens >= 0 && tens <= 9 && ones >= 0 && ones <= 9 && tens * 10 + ones == expected['number'];
      case SceneRuleKind.chooseRemainder:
        return _keys(response, {'ones'}) && response['ones'] is int && response['ones'] == (expected['number'] as int) % 10;
      case SceneRuleKind.matchTextEvidence:
        return _keys(response, {'statement', 'evidence'}) && response['statement'] == expected['statement'] && response['evidence'] == expected['evidence'];
      case SceneRuleKind.arrangeTokens:
        return _keys(response, {'tokens'}) && response['tokens'] is List<String> && jsonEncode(response['tokens']) == jsonEncode(expected['tokens']);
    }
  }
  Map<String, Object> toJson() => {'kind': kind.name, 'expected': expected};
}

class LearningSceneStep {
  const LearningSceneStep({required this.id, required this.goal, required this.instruction,
    required this.interaction, required this.rule, required this.gesture,
    required this.alternative});
  final String id, goal, instruction;
  final SceneInteraction interaction;
  final SceneRule rule;
  final LumoSceneGesture gesture;
  final ExplanationMethod alternative;
  Map<String, Object> toJson() => {'id': id, 'goal': goal, 'instruction': instruction,
    'interaction': interaction.name, 'rule': rule.toJson(), 'gesture': gesture.name, 'alternative': alternative.name};
}

class LumoLearningScene {
  LumoLearningScene({required this.id, required this.conceptId, required this.method,
    required List<SceneObject> objects, required List<LearningSceneStep> steps,
    this.mood = LumoSceneMood.attentive, this.reduceMotion = false,
    this.accessibilityLabel = 'Lumo erklärt Schritt für Schritt', this.animationState = 'ready'})
    : objects = List.unmodifiable(objects), steps = List.unmodifiable(steps);
  static const version = 1;
  final String id, conceptId, accessibilityLabel, animationState;
  final ExplanationMethod method;
  final List<SceneObject> objects;
  final List<LearningSceneStep> steps;
  final LumoSceneMood mood;
  final bool reduceMotion;
  Map<String, Object> toJson() => {'version': version, 'id': id, 'conceptId': conceptId,
    'method': method.name, 'objects': objects.map((o) => o.toJson()).toList(),
    'steps': steps.map((s) => s.toJson()).toList(), 'mood': mood.name, 'reduceMotion': reduceMotion,
    'accessibilityLabel': accessibilityLabel, 'animationState': animationState};
  factory LumoLearningScene.fromJson(Object? raw) {
    try {
      final d = _object(raw, {'version','id','conceptId','method','objects','steps','mood','reduceMotion','accessibilityLabel','animationState'});
      if (d['version'] != version || d['reduceMotion'] is! bool || d['objects'] is! List || d['steps'] is! List) throw const FormatException();
      if ((d['objects'] as List).length > 32 || (d['steps'] as List).isEmpty || (d['steps'] as List).length > 16) throw const FormatException();
      return LumoLearningScene(id: _label(d['id']), conceptId: _label(d['conceptId']),
        method: ExplanationMethod.values.byName(d['method'] as String), mood: LumoSceneMood.values.byName(d['mood'] as String),
        reduceMotion: d['reduceMotion'] as bool, accessibilityLabel: _label(d['accessibilityLabel']), animationState: _label(d['animationState']),
        objects: [for (final rawObject in d['objects'] as List) _parseObject(rawObject)],
        steps: [for (final rawStep in d['steps'] as List) _parseStep(rawStep)]);
    } catch (_) { throw const FormatException('Unsupported Lumo Learning Scene Contract'); }
  }
}

SceneObject _parseObject(Object? raw) {
  final d = _object(raw, {'kind','quantity','label'});
  if (d['quantity'] is! int || (d['quantity'] as int) < 0 || (d['quantity'] as int) > 100) throw const FormatException();
  return SceneObject(kind: SceneObjectKind.values.byName(d['kind'] as String), quantity: d['quantity'] as int, label: _label(d['label']));
}
LearningSceneStep _parseStep(Object? raw) {
  final d = _object(raw, {'id','goal','instruction','interaction','rule','gesture','alternative'});
  final r = _object(d['rule'], {'kind','expected'});
  final kind = SceneRuleKind.values.byName(r['kind'] as String);
  if (r['expected'] is! Map) throw const FormatException();
  final expected = Map<String, Object>.from(r['expected'] as Map);
  return LearningSceneStep(id: _label(d['id']), goal: _label(d['goal']), instruction: _label(d['instruction']),
    interaction: SceneInteraction.values.byName(d['interaction'] as String), rule: SceneRule(kind: kind, expected: Map.unmodifiable(expected)),
    gesture: LumoSceneGesture.values.byName(d['gesture'] as String), alternative: ExplanationMethod.values.byName(d['alternative'] as String));
}
void _validateRule(SceneRuleKind kind, Map<String, Object> expected) {
  switch (kind) {
    case SceneRuleKind.observe: if (expected.isNotEmpty) throw const FormatException();
    case SceneRuleKind.composePlaceValue:
    case SceneRuleKind.chooseRemainder:
      if (!_keys(expected, {'number'}) || expected['number'] is! int || (expected['number'] as int) < 10 || (expected['number'] as int) > 99) throw const FormatException();
    case SceneRuleKind.matchTextEvidence:
      if (!_keys(expected, {'statement','evidence'})) throw const FormatException();
      _label(expected['statement']); _label(expected['evidence']);
    case SceneRuleKind.arrangeTokens:
      if (!_keys(expected, {'tokens'}) || expected['tokens'] is! List || (expected['tokens'] as List).isEmpty || (expected['tokens'] as List).length > 20) throw const FormatException();
      for (final token in expected['tokens'] as List) { _label(token); }
  }
}
Map _object(Object? value, Set<String> fields) {
  if (value is! Map || !_keys(value, fields)) throw const FormatException();
  return value;
}
bool _keys(Map value, Set<String> fields) => value.length == fields.length && value.keys.every(fields.contains);
String _label(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 600 || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) throw const FormatException();
  return value;
}
