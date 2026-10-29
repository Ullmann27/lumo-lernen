import '../../core/learning_attempt_id.dart';
import '../../core/learning_journey.dart';
import 'learning_scene_contract.dart';

class LessonSceneEngine {
  const LessonSceneEngine();
  LumoLearningScene placeValue({required int number, required ExplanationMethod method,
      bool reduceMotion = false}) {
    _checkNumber(number);
    final tens = number ~/ 10, ones = number % 10;
    final next = ExplanationMethod.values[(method.index + 1) % 4];
    LearningSceneStep step(String id, String instruction, SceneInteraction action,
        {SceneRule rule = const SceneRule(kind: SceneRuleKind.observe)}) => LearningSceneStep(
      id: id, goal: 'Zehnerbündel und einzelne Einer unterscheiden', instruction: instruction,
      interaction: action, rule: rule, gesture: method == ExplanationMethod.verbal
          ? LumoSceneGesture.lookAtMaterial : LumoSceneGesture.point, alternative: next);
    final steps = switch (method) {
      ExplanationMethod.verbal => [step('say', 'Zehn einzelne Würfel bilden eine Zehnerstange. Bei $number gibt es $tens volle Zehner und $ones einzelne Einer.', SceneInteraction.listen)],
      ExplanationMethod.pictorial => [step('see', 'Schau auf die Stangen. Jede enthält zehn kleine Würfel. Zähle die Stangen, dann die einzelnen Würfel.', SceneInteraction.count)],
      ExplanationMethod.interactive => [step('bundle', 'Wähle zehn einzelne Würfel und fasse sie zu einer Zehnerstange zusammen. Die Zahl bleibt gleich.', SceneInteraction.bundleTen)],
      ExplanationMethod.guided => [
        step('count-rods', 'Schritt 1: Berühre jede volle Zehnerstange genau einmal.', SceneInteraction.count),
        step('count-ones', 'Schritt 2: Welche Würfel liegen außerhalb der vollen Zehner?', SceneInteraction.choose,
          rule: SceneRule(kind: SceneRuleKind.chooseRemainder, expected: {'number': number})),
        step('decompose', 'Schritt 3: Baue die Zahl aus vollen Zehnern und einzelnen Einern.', SceneInteraction.compose,
          rule: SceneRule(kind: SceneRuleKind.composePlaceValue, expected: {'number': number})),
      ],
    };
    return LumoLearningScene(id: 'place-value-$number-${method.name}', conceptId: 'math.tens_ones',
      method: method, reduceMotion: reduceMotion, accessibilityLabel: 'Zehner und Einer von $number',
      objects: method == ExplanationMethod.verbal ? const [] : [
        SceneObject(kind: SceneObjectKind.tenRod, quantity: method == ExplanationMethod.interactive ? tens - 1 : tens, label: 'Zehnerstangen mit je zehn Einheiten'),
        SceneObject(kind: SceneObjectKind.unitCube, quantity: method == ExplanationMethod.interactive ? ones + 10 : ones, label: 'Einzelne Würfel'),
      ], steps: steps);
  }
}

enum TransferStage { explanation, construction, comprehension, completed }

class ConstructionCheck {
  const ConstructionCheck(this.resultCorrect, this.processCorrect);
  final bool resultCorrect;
  final bool processCorrect;
}

/// Only the local validator can construct a receipt. Rendering/animation cannot
/// set competence, change the solution key, or issue an independent receipt.
class SceneCompletion {
  SceneCompletion._({required this.sourceNumber, required this.number,
    required this.sourceProblemId, required this.independent, required this.evidence});
  final int sourceNumber;
  final int number;
  final String sourceProblemId;
  final bool independent;
  final LearningEvidence evidence;
}

/// The complete reference implementation for "Erklär es Lumo".
class PlaceValueLessonSession {
  PlaceValueLessonSession({required this.sourceNumber, required this.targetNumber,
      required this.sourceProblemId, String? sessionId}) : _id = sessionId ?? newLearningAttemptId() {
    _checkNumber(sourceNumber); _checkNumber(targetNumber);
    if (sourceNumber == targetNumber || sourceProblemId.isEmpty) throw ArgumentError('Transfer requires a different known problem');
  }
  final int sourceNumber, targetNumber;
  final String sourceProblemId, _id;
  TransferStage _stage = TransferStage.explanation;
  int _constructionAttempts = 0, _explanationAttempts = 0;
  bool _helpDuringTransfer = false;
  SceneCompletion? _completion;
  TransferStage get stage => _stage;
  SceneCompletion? get completion => _completion;
  int get constructionAttempts => _constructionAttempts;
  int get explanationAttempts => _explanationAttempts;
  void beginTransfer() {
    if (_stage == TransferStage.explanation) _stage = TransferStage.construction;
  }
  void markTransferHelp() { _helpDuringTransfer = true; }
  ConstructionCheck submitConstruction({required int tens, required int ones}) {
    if (_stage != TransferStage.construction) return const ConstructionCheck(false, false);
    _constructionAttempts++;
    final total = tens >= 0 && ones >= 0 && tens * 10 + ones == targetNumber;
    final process = SceneRule(kind: SceneRuleKind.composePlaceValue, expected: {'number': targetNumber})
        .accepts({'tens': tens, 'ones': ones});
    if (process) _stage = TransferStage.comprehension;
    return ConstructionCheck(total, process);
  }
  SceneCompletion? submitComprehension(int ones) {
    if (_stage != TransferStage.comprehension) return null;
    _explanationAttempts++;
    final correct = SceneRule(kind: SceneRuleKind.chooseRemainder, expected: {'number': targetNumber}).accepts({'ones': ones});
    if (!correct) return null;
    final independent = _constructionAttempts == 1 && _explanationAttempts == 1 && !_helpDuringTransfer;
    _stage = TransferStage.completed;
    return _completion = SceneCompletion._(sourceNumber: sourceNumber, number: targetNumber,
      sourceProblemId: sourceProblemId, independent: independent,
      evidence: LearningEvidence(taskId: '$_id-transfer', problemId: 'place-value:$targetNumber',
        correct: true, helpLevel: independent ? 0 : 3, transferCheck: independent));
  }
}
void _checkNumber(int number) { if (number < 10 || number > 99) throw ArgumentError('Expected a two-digit number'); }
