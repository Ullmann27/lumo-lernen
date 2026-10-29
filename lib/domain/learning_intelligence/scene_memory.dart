import 'dart:convert';
import '../../core/learning_journey.dart';
import 'learning_scene_contract.dart';
import 'lesson_scene_engine.dart';

enum SceneOutcome { introduced, notUnderstood, assistedTransfer, independentTransfer }

/// A method observation is not a competence. Only a validated completion can
/// construct a transfer observation; the school journal holds competence.
class SceneObservation {
  const SceneObservation._({required this.id, required this.conceptId, required this.problemId,
    required this.method, required this.outcome, required this.at, this.transferProblemId});
  factory SceneObservation.methodFeedback({required String id, required String conceptId,
      required String problemId, required ExplanationMethod method, required bool understood, required DateTime at}) =>
    SceneObservation._(id: id, conceptId: conceptId, problemId: problemId, method: method,
      outcome: understood ? SceneOutcome.introduced : SceneOutcome.notUnderstood, at: at.toUtc());
  factory SceneObservation.completed({required SceneCompletion proof, required ExplanationMethod method, required DateTime at}) =>
    SceneObservation._(id: proof.evidence.taskId, conceptId: 'math.tens_ones', problemId: proof.sourceProblemId,
      transferProblemId: proof.evidence.problemId, method: method,
      outcome: proof.independent ? SceneOutcome.independentTransfer : SceneOutcome.assistedTransfer, at: at.toUtc());
  final String id, conceptId, problemId;
  final String? transferProblemId;
  final ExplanationMethod method;
  final SceneOutcome outcome;
  final DateTime at;
  Map<String, Object?> toJson() => {'id': id, 'conceptId': conceptId, 'problemId': problemId,
    'method': method.name, 'outcome': outcome.name, 'at': at.toIso8601String(), 'transferProblemId': transferProblemId};
  factory SceneObservation.fromJson(Object? value) {
    try {
      if (value is! Map || !_hasKeys(value, {'id','conceptId','problemId','method','outcome','at','transferProblemId'})) throw const FormatException();
      final id = _identity(value['id']), concept = _identity(value['conceptId']), problem = _identity(value['problemId']);
      final method = ExplanationMethod.values.byName(value['method'] as String);
      final outcome = SceneOutcome.values.byName(value['outcome'] as String);
      final rawDate = value['at'];
      final at = rawDate is String ? DateTime.tryParse(rawDate) : null;
      if (at == null || !at.isUtc || at.year < 2000 || at.year > 2200 || at.toIso8601String() != rawDate) throw const FormatException();
      final transfer = value['transferProblemId'];
      final isTransfer = outcome == SceneOutcome.assistedTransfer || outcome == SceneOutcome.independentTransfer;
      if (isTransfer != (transfer != null)) throw const FormatException();
      return SceneObservation._(id: id, conceptId: concept, problemId: problem, method: method,
        outcome: outcome, at: at, transferProblemId: transfer == null ? null : _identity(transfer));
    } catch (_) { throw const FormatException('Unsupported local scene observation'); }
  }
}

/// Bounded recent methods in the existing per-child progress namespace. Never
/// stores names, raw tasks, answers, recordings, touch positions or diagnoses.
class SceneMemory {
  SceneMemory() : records = const [];
  SceneMemory._(List<SceneObservation> values) : records = List.unmodifiable(values);
  static const version = 1, capacity = 256;
  final List<SceneObservation> records;
  SceneMemory record(SceneObservation observation) {
    SceneObservation.fromJson(observation.toJson()); // Validate on write as well.
    for (final previous in records) {
      if (previous.id != observation.id) continue;
      if (jsonEncode(previous.toJson()) != jsonEncode(observation.toJson())) throw StateError('Conflicting scene observation identity');
      return this;
    }
    return SceneMemory._([...records.skip(records.length >= capacity ? 1 : 0), observation]);
  }
  List<SceneObservation> forProblem(String conceptId, String problemId) => List.unmodifiable(
    records.where((r) => r.conceptId == conceptId && r.problemId == problemId));
  Set<ExplanationMethod> tried(String conceptId, String problemId) => Set.unmodifiable(
    forProblem(conceptId, problemId).map((r) => r.method));
  Set<String> get transferProblems => Set.unmodifiable(records.map((r) => r.transferProblemId).whereType<String>());
  Map<String, Object> toJson() => {'version': version, 'records': records.map((r) => r.toJson()).toList()};
  factory SceneMemory.fromJson(Object? raw) {
    if (raw is! Map || !_hasKeys(raw, {'version','records'}) || raw['version'] != version || raw['records'] is! List || (raw['records'] as List).length > capacity) {
      throw const FormatException('Unsupported local scene memory');
    }
    final records = (raw['records'] as List).map(SceneObservation.fromJson).toList();
    if (records.map((r) => r.id).toSet().length != records.length) throw const FormatException('Duplicate scene observation');
    return SceneMemory._(records);
  }
}
bool _hasKeys(Map map, Set<String> keys) => map.length == keys.length && map.keys.every(keys.contains);
String _identity(Object? value) {
  if (value is! String || !RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:/-]{0,127}$').hasMatch(value)) throw const FormatException();
  return value;
}

/// Durable write-ahead receipt in the same child namespace. It is removed only
/// after both the existing competence journal and method memory are saved.
class PendingSceneReceipt {
  const PendingSceneReceipt._(this.subject, this.unit, this.observation, this.evidence);
  factory PendingSceneReceipt.completed({required String subject, required String unit,
      required SceneCompletion proof, required ExplanationMethod method}) =>
    PendingSceneReceipt.fromJson({'version': 1, 'subject': subject, 'unit': unit,
      'observation': SceneObservation.completed(proof: proof, method: method, at: proof.completedAt).toJson(),
      'evidence': _evidenceJson(proof.evidence)});
  final String subject, unit;
  final SceneObservation observation;
  final LearningEvidence evidence;
  Map<String, Object> toJson() => {'version': 1, 'subject': subject, 'unit': unit,
    'observation': observation.toJson(), 'evidence': _evidenceJson(evidence)};
  factory PendingSceneReceipt.fromJson(Object? raw) {
    try {
      if (raw is! Map || !_hasKeys(raw, {'version','subject','unit','observation','evidence'}) || raw['version'] != 1) throw const FormatException();
      String label(Object? value) {
        if (value is! String || value.trim().isEmpty || value.length > 128 || value.contains('::') || RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) throw const FormatException();
        return value;
      }
      final observation = SceneObservation.fromJson(raw['observation']);
      final e = raw['evidence'];
      if (e is! Map || !_hasKeys(e, {'taskId','problemId','correct','helpLevel','transferCheck'}) || e['correct'] != true || e['helpLevel'] is! int || e['transferCheck'] is! bool) throw const FormatException();
      final evidence = LearningEvidence(taskId: _identity(e['taskId']), problemId: _identity(e['problemId']),
        correct: true, helpLevel: e['helpLevel'] as int, transferCheck: e['transferCheck'] as bool);
      evidence.validate();
      final independent = observation.outcome == SceneOutcome.independentTransfer;
      if (observation.transferProblemId == null || observation.id != evidence.taskId || observation.transferProblemId != evidence.problemId ||
          (evidence.helpLevel == 0) != independent || evidence.transferCheck != independent) throw const FormatException();
      return PendingSceneReceipt._(label(raw['subject']), label(raw['unit']), observation, evidence);
    } catch (_) { throw const FormatException('Unsupported pending local scene receipt'); }
  }
}
Map<String, Object> _evidenceJson(LearningEvidence e) => {'taskId': e.taskId,
  'problemId': e.problemId!, 'correct': e.correct, 'helpLevel': e.helpLevel, 'transferCheck': e.transferCheck};
