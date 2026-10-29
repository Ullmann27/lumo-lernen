import 'package:flutter/foundation.dart';

import '../../../../domain/learning_intelligence/lesson_scene_engine.dart';

import '../learning_scene_contract.dart';

/// Ergebnis der selbstständigen Transferprüfung in der Zehner-Werkstatt.
class LumoPlaceValueTransfer {
  const LumoPlaceValueTransfer({
    required this.number,
    required this.correct,
    required this.independent,
    this.proof,
  });
  final int number;
  final bool correct;
  final bool independent;

  /// Only Sol's lesson-session validator may create this independent receipt.
  final SceneCompletion? proof;
}

/// Sols didaktische Regeln der Zehner-Werkstatt als Szenen-Engine.
///
/// Die Regeln, Texte und Abläufe stammen unverändert aus Sols
/// `LumoPlaceValueWorkshop` (Stand 9fdfc3f1): Zählen oder Bündeln sind nie
/// eine Wertung; erst eine andere, selbst gebaute Zahl plus Verständnisfrage
/// meldet ein Ergebnis über [onTransferChecked]. Ein Fehler beim Bauen oder
/// Erklären macht das Ergebnis zu „mit Übung geschafft“.
///
/// Neu ist nur das Vorzeigen durch Lumo ([LearningSceneInput.replayDemonstration]):
/// eine Animation ohne Wertung und ohne Einfluss auf das Ergebnis.
class PlaceValueSceneDirector extends ChangeNotifier
    implements LearningSceneDirector {
  PlaceValueSceneDirector({
    required this.number,
    this.onTransferChecked,
    PlaceValueLessonSession? lesson,
  })  : assert(number >= 10 && number <= 99),
        lesson = lesson ??
            PlaceValueLessonSession(
              sourceNumber: number,
              targetNumber: number > 55 ? number - 27 : number + 27,
              sourceProblemId: 'place-value:$number',
            ),
        sceneId = 'place-value-$number' {
    if (this.lesson.sourceNumber != number) {
      throw ArgumentError('Lesson source number must match visual scene');
    }
  }

  final int number;
  final PlaceValueLessonSession lesson;
  final ValueChanged<LumoPlaceValueTransfer>? onTransferChecked;
  @override
  final String sceneId;

  final Set<int> _counted = {};
  final Set<int> _selected = {};
  LearningSceneStage _stage = LearningSceneStage.explore;
  bool _bundleMode = false;
  bool _bundled = false;
  bool _independent = true;
  int _builtTens = 0;
  int _builtOnes = 0;
  int _demonstrations = 0;
  String? _feedback;
  int _revision = 0;
  LumoPerformanceIntent _lumo = LumoPerformanceIntent.explain;
  String? _lumoFocus = 'ten-0';
  LearningSceneRequest? _request;

  int get tens => number ~/ 10;
  int get ones => number % 10;

  /// Die andere Zahl, die das Kind ohne Lumos Hilfe baut.
  int get target => lesson.targetNumber;
  bool get _countComplete => _counted.length == tens;

  @override
  LearningSceneRequest get request => _request ??= _build();

  @override
  bool handle(LearningSceneEvent event) {
    if (event.sceneId != sceneId ||
        event.revision != request.revision ||
        !request.allows(event.input)) {
      return false;
    }
    final changed = _apply(event);
    if (changed) {
      _revision++;
      _request = null;
      notifyListeners();
    }
    return changed;
  }

  bool _apply(LearningSceneEvent event) {
    switch (event.input) {
      case LearningSceneInput.startCounting:
        _bundleMode = false;
        _lumo = LumoPerformanceIntent.explain;
        _lumoFocus = 'ten-0';
      case LearningSceneInput.countObject:
        final index = _index(event.objectId, 'ten-', tens);
        if (index == null) return false;
        if (!_counted.add(index)) _counted.remove(index);
        _lumo = _countComplete
            ? LumoPerformanceIntent.approve
            : LumoPerformanceIntent.listen;
        _lumoFocus = 'ten-$index';
      case LearningSceneInput.resetCount:
        _counted.clear();
        _lumo = LumoPerformanceIntent.explain;
        _lumoFocus = 'ten-0';
      case LearningSceneInput.startBundling:
        _bundleMode = true;
        _lumo = LumoPerformanceIntent.think;
        _lumoFocus = 'loose';
      case LearningSceneInput.replayDemonstration:
        _demonstrations++;
        _lumo = LumoPerformanceIntent.demonstrate;
        _lumoFocus = 'loose';
      case LearningSceneInput.selectObject:
        final index = _index(event.objectId, 'loose-', ones + 10);
        if (index == null) return false;
        if (!_selected.add(index)) _selected.remove(index);
        _lumo = LumoPerformanceIntent.listen;
        _lumoFocus = 'loose-$index';
      case LearningSceneInput.bundleTen:
        _bundled = true;
        _selected.clear();
        _lumo = LumoPerformanceIntent.approve;
        _lumoFocus = 'ten-${tens - 1}';
      case LearningSceneInput.startConstruction:
        lesson.beginTransfer();
        _stage = LearningSceneStage.construct;
        _feedback = null;
        _lumo = LumoPerformanceIntent.idea;
        _lumoFocus = 'build';
      case LearningSceneInput.addTen:
        _builtTens++;
        _lumo = LumoPerformanceIntent.listen;
        _lumoFocus = 'build';
      case LearningSceneInput.removeTen:
        _builtTens--;
        _lumo = LumoPerformanceIntent.listen;
        _lumoFocus = 'build';
      case LearningSceneInput.addOne:
        _builtOnes++;
        _lumo = LumoPerformanceIntent.listen;
        _lumoFocus = 'build';
      case LearningSceneInput.removeOne:
        _builtOnes--;
        _lumo = LumoPerformanceIntent.listen;
        _lumoFocus = 'build';
      case LearningSceneInput.submitConstruction:
        // Never create a score or independent evidence in the visual layer.
        // The exact process rule comes only from the profile-scoped Sol session.
        final check = lesson.submitConstruction(
            tens: _builtTens, ones: _builtOnes);
        if (check.processCorrect) {
          _stage = LearningSceneStage.explain;
          _feedback = null;
          _lumo = LumoPerformanceIntent.listen;
          _lumoFocus = 'child';
        } else {
          _independent = false;
          _feedback =
              'Schau noch einmal: Jede Stange zählt zehn. Du darfst umbauen.';
          _lumo = LumoPerformanceIntent.encourage;
          _lumoFocus = 'build';
        }
      case LearningSceneInput.answerChoice:
        final value = event.value;
        if (value == null || value < 0 || value > 9) return false;
        final proof = lesson.submitComprehension(value);
        if (proof != null) {
          _independent = proof.independent;
          _stage = LearningSceneStage.done;
          _feedback = null;
          _lumo = proof.independent
              ? LumoPerformanceIntent.celebrate
              : LumoPerformanceIntent.encourage;
          _lumoFocus = 'child';
          onTransferChecked?.call(LumoPlaceValueTransfer(
              number: target,
              correct: true,
              independent: proof.independent,
              proof: proof));
        } else {
          _independent = false;
          _feedback =
              'Zehner sind volle Bündel. Überlege, was einzeln übrig bleibt.';
          _lumo = LumoPerformanceIntent.encourage;
          _lumoFocus = 'build';
        }
    }
    return true;
  }

  static int? _index(String? id, String prefix, int count) {
    if (id == null || !id.startsWith(prefix)) return null;
    final value = int.tryParse(id.substring(prefix.length));
    return value == null || value < 0 || value >= count ? null : value;
  }

  LearningSceneRequest _build() {
    final allowed = <LearningSceneInput>{};
    final objects = <LearningSceneObject>[];
    late String instruction;
    switch (_stage) {
      case LearningSceneStage.explore:
        allowed.addAll({
          LearningSceneInput.startCounting,
          LearningSceneInput.startBundling
        });
        if (!_bundleMode) {
          allowed.add(LearningSceneInput.countObject);
          if (_counted.isNotEmpty) allowed.add(LearningSceneInput.resetCount);
          for (var i = 0; i < tens; i++) {
            objects.add(LearningSceneObject(
                id: 'ten-$i', type: 'ten_rod', marked: _counted.contains(i)));
          }
          for (var i = 0; i < ones; i++) {
            objects.add(LearningSceneObject(id: 'one-$i', type: 'unit_cube'));
          }
          instruction =
              'Wir bauen $number. Tippe jede blaue Zehnerstange einmal an und zähle die vollen Zehner.';
        } else {
          final rods = _bundled ? tens : tens - 1;
          final loose = _bundled ? ones : ones + 10;
          for (var i = 0; i < rods; i++) {
            objects.add(LearningSceneObject(id: 'ten-$i', type: 'ten_rod'));
          }
          for (var i = 0; i < loose; i++) {
            objects.add(LearningSceneObject(
                id: 'loose-$i',
                type: 'unit_cube',
                marked: _selected.contains(i)));
          }
          if (!_bundled) {
            allowed.addAll({
              LearningSceneInput.selectObject,
              LearningSceneInput.replayDemonstration
            });
            if (_selected.length == 10) {
              allowed.add(LearningSceneInput.bundleTen);
            }
          }
          instruction = _bundled
              ? 'Die Zahl bleibt gleich: $tens Zehner und $ones Einer.'
              : 'Wir öffnen eine Stange. Wähle genau zehn lose Würfel und bündle sie wieder. Die Zahl bleibt $number.';
        }
        if (_countComplete || _bundled) {
          allowed.add(LearningSceneInput.startConstruction);
        }
      case LearningSceneStage.construct:
        if (_builtTens < 9) allowed.add(LearningSceneInput.addTen);
        if (_builtTens > 0) allowed.add(LearningSceneInput.removeTen);
        if (_builtOnes < 9) allowed.add(LearningSceneInput.addOne);
        if (_builtOnes > 0) allowed.add(LearningSceneInput.removeOne);
        allowed.add(LearningSceneInput.submitConstruction);
        for (var i = 0; i < _builtTens; i++) {
          objects.add(LearningSceneObject(id: 'built-ten-$i', type: 'ten_rod'));
        }
        for (var i = 0; i < _builtOnes; i++) {
          objects
              .add(LearningSceneObject(id: 'built-one-$i', type: 'unit_cube'));
        }
        instruction = 'Baue $target mit Zehnerstangen und einzelnen Würfeln.';
      case LearningSceneStage.explain:
        allowed.add(LearningSceneInput.answerChoice);
        instruction =
            'Du hast $target gebaut. Wie viele Einer bleiben außerhalb der vollen Zehner?';
      case LearningSceneStage.done:
        instruction = _independent
            ? 'Du hast eine neue Zahl selbst gebaut und Lumo erklärt. Das ist ein zusätzlicher Hinweis auf dein Verständnis.'
            : 'Mit Übung geschafft! Beim nächsten Mal probieren wir wieder eine neue Zahl selbstständig.';
    }
    return LearningSceneRequest(
      sceneId: sceneId,
      kind: LearningSceneKind.placeValue,
      stage: _stage,
      revision: _revision,
      instruction: instruction,
      feedback: _feedback,
      facts: {
        'number': number,
        'tens': tens,
        'ones': ones,
        'counted': _counted.length,
        'selected': _selected.length,
        'bundleMode': _bundleMode ? 1 : 0,
        'bundled': _bundled ? 1 : 0,
        'demonstrations': _demonstrations,
        if (_stage != LearningSceneStage.explore) 'target': target,
        if (_stage == LearningSceneStage.construct) ...{
          'builtTens': _builtTens,
          'builtOnes': _builtOnes,
        },
        if (_stage == LearningSceneStage.done)
          'independent': _independent ? 1 : 0,
      },
      objects: List.unmodifiable(objects),
      allowedInputs: Set.unmodifiable(allowed),
      choices: _stage == LearningSceneStage.explain
          ? List.generate(10, (i) => i)
          : const [],
      lumo: _lumo,
      lumoFocus: _lumoFocus,
    );
  }
}
