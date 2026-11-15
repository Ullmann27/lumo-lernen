import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../../../widgets/design/lumo_task_object_art.dart';
import '../lab/learning_manipulatives.dart';

/// A local presentation event. The owning lesson translates it into its
/// companion contract and remains responsible for assessment and persistence.
/// No child identifier, recording, or generated answer is sent by this widget.
class TaskWorkspaceInteraction {
  const TaskWorkspaceInteraction({
    required this.taskId,
    required this.objectId,
    required this.action,
    required this.visibleState,
    required this.explanation,
    this.isHelp = false,
  });

  final String taskId;
  final String objectId;
  final String action;
  final Map<String, Object?> visibleState;
  final String explanation;
  final bool isHelp;
}

enum _WorkspaceKind {
  bridge,
  subtraction,
  groups,
  numberLine,
  comparison,
  syllables,
  pattern,
  numberPattern,
  tokens,
  shapes,
  plant,
  evidence,
}

/// Manipulatives for the actual task, shared by regular and cross-grade lessons.
///
/// Structured values are checked before a mathematical model is rendered.
/// Unrecognised tasks retain their existing visual and offer text inspection;
/// they are never silently turned into a different exercise. All actions are
/// exploratory. Only the owning lesson evaluates a submitted answer.
class InteractiveTaskWorkspace extends StatefulWidget {
  const InteractiveTaskWorkspace({
    super.key,
    required this.task,
    this.fallback,
    this.onInteraction,
    this.enabled = true,
    this.reduceMotion = false,
    this.helpLevel = 0,
    this.showSolution = false,
    this.activeObjectId,
    this.slow = false,
    this.replaySerial = 0,
  });

  final TaskInstance task;
  final Widget? fallback;
  final ValueChanged<TaskWorkspaceInteraction>? onInteraction;
  final bool enabled;
  final bool reduceMotion;
  final int helpLevel;
  final bool showSolution;
  final bool slow;
  final int replaySerial;

  /// A speech/animation host may highlight its actual current segment. There
  /// is deliberately no guessed audio timer in this presentation widget.
  final String? activeObjectId;

  static String goalFor(TaskInstance task) {
    final data = task.visualPayload.data;
    if (data['operation'] == 'addition') {
      final left = _integer(data['left']);
      final right = _integer(data['right']);
      return left != null && right != null && left < 10 && left + right > 10
          ? 'Mengen zusammenlegen und den nächsten Zehner nutzen.'
          : 'Mengen zusammenlegen und die gesamte Menge bestimmen.';
    }
    if (data['operation'] == 'subtraction') {
      return 'Etwas wegnehmen und die übrige Menge bestimmen.';
    }
    if (data['operation'] == 'multiplication') {
      return 'Gleich große Gruppen erkennen und zusammenzählen.';
    }
    if (data['operation'] == 'division') {
      return 'Eine Menge gleichmäßig auf Gruppen verteilen.';
    }
    if (task.visualPayload.type == VisualType.syllables ||
        task.visualPayload.type == VisualType.syllableClap) {
      return 'Ein Wort in seine gesprochenen Silben gliedern.';
    }
    if (task.visualPayload.type == VisualType.sequence ||
        task.parameters['unit'] == 'Muster') {
      return 'Die wiederkehrende Gruppe finden und das Muster fortsetzen.';
    }
    if (task.taskType == TaskType.writingCanvas) {
      return 'Die vorgegebene Form aufmerksam ansehen und selbst schreiben.';
    }
    if (task.taskType == TaskType.shapeTrace) {
      return 'Der Form folgen und sie anschließend selbst nachzeichnen.';
    }
    return switch (task.subject) {
      LearningSubject.mathematik =>
        'Die gegebenen Zahlen untersuchen und deinen Rechenweg finden.',
      LearningSubject.deutsch =>
        'Genau lesen, auf Wörter und Laute achten und deine Wahl begründen.',
      LearningSubject.sachkunde =>
        'Genau beobachten und passende Zusammenhänge erkennen.',
      LearningSubject.englisch =>
        'Wörter verstehen und zur Bedeutung der Aufgabe zuordnen.',
      LearningSubject.logik =>
        'Die Regel oder Reihenfolge erkennen und deine Wahl prüfen.',
    };
  }

  @override
  State<InteractiveTaskWorkspace> createState() =>
      _InteractiveTaskWorkspaceState();
}

class _InteractiveTaskWorkspaceState extends State<InteractiveTaskWorkspace> {
  late _WorkspaceModel _model;
  int _moved = 0;
  final Set<int> _removed = {};
  final Set<int> _marked = {};
  List<int> _allocations = [];
  List<int> _tokenOrder = [];
  int? _focus;
  int? _linePosition;
  String? _relation;
  bool _unfolded = false;
  bool _slow = false;
  bool _groupVisible = false;
  bool _arranging = false;
  bool _useLine = false;

  bool get _quiet => widget.reduceMotion || LumoMotion.reduced(context);
  Duration get _duration =>
      _quiet ? Duration.zero : Duration(milliseconds: _slow ? 420 : 180);

  @override
  void initState() {
    super.initState();
    _resetValues();
    _announceReady();
  }

  @override
  void didUpdateWidget(covariant InteractiveTaskWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.taskInstanceId != widget.task.taskInstanceId ||
        oldWidget.task.prompt != widget.task.prompt ||
        oldWidget.replaySerial != widget.replaySerial) {
      _resetValues();
      _announceReady();
    } else if (oldWidget.helpLevel != widget.helpLevel) {
      if (_model.kind == _WorkspaceKind.bridge && widget.helpLevel > 1) {
        _useLine = !_useLine;
        _linePosition ??= _model.left;
      }
      _announceReady(action: 'helpStateChanged');
    }
    if (oldWidget.slow != widget.slow) _slow = widget.slow;
  }

  void _resetValues() {
    _model = _WorkspaceModel.from(widget.task);
    _moved = 0;
    _removed.clear();
    _marked.clear();
    _allocations = List.filled(_model.groupCount, 0);
    _tokenOrder = [];
    _focus = null;
    _linePosition = null;
    _relation = null;
    _unfolded = false;
    _slow = widget.slow;
    _groupVisible = false;
    _arranging = false;
    _useLine = false;
  }

  void _announceReady({String action = 'workspaceReady'}) {
    final taskId = widget.task.taskInstanceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.task.taskInstanceId == taskId) {
        _emit(action, 'task-workspace');
      }
    });
  }

  Map<String, Object?> get _visibleState => Map.unmodifiable({
        'kind': _model.kind.name,
    'objectIds': List<String>.unmodifiable(_visibleObjectIds),
        'helpLevel': widget.helpLevel,
        'slow': _slow,
        'reducedMotion': _quiet,
        if (_model.left != null) 'left': _model.left,
        if (_model.right != null) 'right': _model.right,
        if (_model.kind == _WorkspaceKind.bridge) ...{
          'representation': _useLine ? 'numberLine' : 'counters',
          'moved': _moved,
          'inFrame': math.min(10, _model.left! + _moved),
          'overflow': math.max(0, _model.left! + _moved - 10),
          'inSupply': _model.right! - _moved,
          'freePlaces': math.max(0, 10 - _model.left! - _moved),
          if (!_useLine)
            'objects': List.unmodifiable([
              for (var i = 0; i < _model.left!; i++)
                {'id': 'initial-$i', 'location': 'ten-frame'},
              for (var i = 0; i < _model.right!; i++)
                {
                  'id': 'addend-$i',
                  'location': i >= _moved
                      ? 'supply'
                      : _model.left! + i < 10
                          ? 'ten-frame'
                          : 'overflow',
                },
            ]),
        },
        if (_model.kind == _WorkspaceKind.subtraction) ...{
          'remaining': _model.left! - _removed.length,
          'removed': List.unmodifiable(_removed.toList()..sort()),
          'stillToRemove': _model.right! - _removed.length,
        },
        if (_model.kind == _WorkspaceKind.groups) ...{
          'operation': _model.operation,
          'groupCount': _model.groupCount,
          'allocations': List.unmodifiable(_allocations),
          'supply': _model.total - _allocations.fold(0, (a, b) => a + b),
        },
        if (_model.kind == _WorkspaceKind.syllables) ...{
          'word': _model.word,
          'syllablesVisible': _unfolded || widget.helpLevel > 1,
          'syllables': List.unmodifiable(_model.tokens),
          'activeSyllable': _activeSyllable,
          'arranged': List.unmodifiable(_tokenOrder),
        },
        if (_model.kind == _WorkspaceKind.pattern) ...{
          'sequence': List.unmodifiable(_model.tokens),
          'groupVisible': _groupVisible || widget.helpLevel > 1,
          'focusedIndex': _focus,
        },
        if (_model.kind == _WorkspaceKind.numberPattern) ...{
          'sequence': List.unmodifiable(_model.tokens),
          'stepVisible': _groupVisible || widget.helpLevel > 0,
          'focusedIndex': _focus,
        },
        if (_model.kind == _WorkspaceKind.tokens)
          'arranged': List.unmodifiable(_tokenOrder),
        if (_model.kind == _WorkspaceKind.numberLine || _useLine)
          'linePosition': _linePosition,
        if (_model.kind == _WorkspaceKind.comparison)
          'selectedRelation': _relation,
        if (_model.kind == _WorkspaceKind.plant)
          'focusedPart': _focus == null ? null : _plantParts[_focus!].id,
        if (_model.kind == _WorkspaceKind.evidence)
          'markedEvidence': List.unmodifiable([
            for (final index in _marked) _model.tokens[index],
          ]),
      });

  int? get _activeSyllable {
    final id = widget.activeObjectId;
    if (id != null && id.startsWith('syllable-')) {
      final value = int.tryParse(id.substring('syllable-'.length));
      if (value != null && value >= 0 && value < _model.tokens.length) {
        return value;
      }
    }
    return _focus;
  }

  String get _explanation {
    switch (_model.kind) {
      case _WorkspaceKind.bridge:
        final start = _model.left!;
        final addend = _model.right!;
        if (_useLine) {
          return _linePosition == null
              ? 'Starte auf dem Zahlenstrahl bei $start und gehe $addend Schritte weiter.'
              : 'Deine Markierung steht auf $_linePosition. '
                  'Die Aufgabe beginnt bei $start. Gehe insgesamt $addend Schritte weiter.';
        }
        final inFrame = math.min(10, start + _moved);
        final rest = start + addend - inFrame;
        if (_moved == 0) {
          return widget.helpLevel > 0
              ? 'Im Zehnerfeld liegen $start Steine. '
                  '${10 - start} Plätze sind frei. '
                  'Nimm diese Steine aus dem Vorrat.'
              : 'Im Zehnerfeld liegen $start Steine. '
                  'Daneben liegen $addend. Verschiebe einzelne Steine.';
        }
        if (inFrame < 10) {
          return 'Jetzt liegen $inFrame Steine im Feld. '
              '${10 - inFrame} Plätze sind noch frei. '
              '${addend - _moved} Steine sind im Vorrat.';
        }
        return 'Der Zehner ist voll. Daneben bleiben $rest Steine. '
            'Rechne jetzt 10 + $rest'
            '${widget.showSolution ? ' = ${widget.task.correctAnswer}.' : '.'}';
      case _WorkspaceKind.subtraction:
        final remaining = _model.left! - _removed.length;
        final missing = _model.right! - _removed.length;
        return _removed.isEmpty
            ? 'Hier liegen ${_model.left} Steine. '
                'Lege ${_model.right} davon weg.'
            : missing == 0
                ? 'Du hast ${_model.right} Steine weggelegt. '
                    'Zähle die Steine, die geblieben sind.'
                : 'Du hast ${_removed.length} weggelegt. '
                    'Lege noch $missing weg. Zurzeit liegen $remaining da.';
      case _WorkspaceKind.groups:
        final supply = _model.total - _allocations.fold(0, (a, b) => a + b);
        if (_model.operation == 'multiplication') {
          return 'Baue ${_model.left} Gruppen mit je ${_model.right} Steinen. '
              'Prüfe jede Gruppe und zähle danach alle zusammen.';
        }
        return supply == 0
            ? 'Alle Steine sind verteilt. '
                'Prüfe, ob jede Gruppe gleich viele Steine enthält.'
            : '${_model.total} Steine gehören zu ${_model.groupCount} Gruppen. '
                'Im Vorrat liegen noch $supply. Verteile einen nach dem anderen.';
      case _WorkspaceKind.syllables:
        final active = _activeSyllable;
        return active == null
            ? 'Sprich ${_model.word} langsam. '
                'Du kannst die Silben erkunden oder selbst ordnen.'
            : '${_model.tokens[active]} ist die markierte Sprecheinheit. '
                'Sprich sie und finde die nächste im Wort ${_model.word}.';
      case _WorkspaceKind.pattern:
        return _groupVisible || widget.helpLevel > 1
            ? 'Die umrahmte Gruppe wiederholt sich. '
                'Vergleiche die Stellen mit demselben Zeichen. '
                'Welche Form kommt als Nächstes?'
            : 'Schau dir die Formen der Reihe nach an. '
                'Welche Gruppe kommt immer wieder?';
      case _WorkspaceKind.numberPattern:
        return _groupVisible || widget.helpLevel > 0
            ? 'Der Abstand ist jedes Mal ${_model.period}. '
                'Gehe von der letzten gegebenen Zahl noch einmal so weit.'
            : 'Vergleiche zwei aufeinanderfolgende Zahlen. '
                'Wie groß ist der Schritt? Prüfe ihn an den nächsten Zahlen.';
      case _WorkspaceKind.numberLine:
        return _linePosition == null
            ? 'Jeder Abstand auf dem Zahlenstrahl bedeutet einen Schritt. '
                'Tippe auf eine Zahl und gehe vor oder zurück.'
            : 'Deine Markierung steht auf $_linePosition. '
                'Prüfe den nächsten Schritt mit der Aufgabe.';
      case _WorkspaceKind.comparison:
        return 'Vergleiche ${_model.left} und ${_model.right}. '
            'Das offene Ende von > oder < zeigt zur größeren Zahl. '
            'Gleich große Zahlen verbindest du mit =.';
      case _WorkspaceKind.tokens:
        return 'Lege die gegebenen Bausteine in eine passende Reihenfolge. '
            'Tippe einen gelegten Baustein an, um ihn zurückzulegen.';
      case _WorkspaceKind.shapes:
        return 'Untersuche die Formen. '
            'Achte auf Ecken, gerade Seiten und Rundungen.';
      case _WorkspaceKind.plant:
        return _focus == null
            ? 'Schau dir die Pflanze an. Tippe ein Teil an und untersuche seine Aufgabe.'
            : _plantParts[_focus!].description;
      case _WorkspaceKind.evidence:
        return _marked.isEmpty
            ? 'Welche Wörter oder Angaben helfen dir? '
                'Markiere eine Stelle und vergleiche sie mit der Frage.'
            : 'Du hast ${_marked.length} '
                '${_marked.length == 1 ? 'Stelle' : 'Stellen'} markiert. '
                'Prüfe, wie sie zu deiner Antwort passen.';
    }
  }

  void _emit(String action, String objectId, {bool isHelp = false}) {
    widget.onInteraction?.call(
      TaskWorkspaceInteraction(
        taskId: widget.task.taskInstanceId,
        objectId: objectId,
        action: action,
        visibleState: _visibleState,
        explanation: _explanation,
        isHelp: isHelp,
      ),
    );
  }

  void _change(
    VoidCallback change,
    String action,
    String objectId, {
    bool isHelp = false,
  }) {
    if (!widget.enabled) return;
    setState(change);
    _emit(action, objectId, isHelp: isHelp);
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_model.kind) {
      _WorkspaceKind.bridge => _bridge(),
      _WorkspaceKind.subtraction => _subtraction(),
      _WorkspaceKind.groups => _groups(),
      _WorkspaceKind.numberLine => _numberLine(),
      _WorkspaceKind.comparison => _comparison(),
      _WorkspaceKind.syllables => _syllables(),
      _WorkspaceKind.pattern => _pattern(),
      _WorkspaceKind.numberPattern => _numberPattern(),
      _WorkspaceKind.tokens => _tokens(),
      _WorkspaceKind.shapes => _shapes(),
      _WorkspaceKind.plant => _plant(),
      _WorkspaceKind.evidence => _evidence(),
    };
    return Semantics(
      container: true,
      label: 'Lernfläche: ${InteractiveTaskWorkspace.goalFor(widget.task)}',
      child: Column(
        key: ValueKey('interactive-workspace-${_model.kind.name}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (_model.kind != _WorkspaceKind.evidence || _unfolded) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _explanation,
                key: const ValueKey('workspace-explanation'),
                style: _bodyStyle,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _action(
                  key: 'workspace-reset',
                  icon: Icons.restart_alt_rounded,
                  label: 'Noch einmal',
                  onPressed: () =>
                      _change(_resetValues, 'reset', 'task-workspace'),
                ),
                _action(
                  key: 'workspace-slow',
                  icon: _slow ? Icons.speed_rounded : Icons.slow_motion_video,
                  label: _slow ? 'Normales Tempo' : 'Langsamer',
                  selected: _slow,
                  onPressed: () => _change(
                    () => _slow = !_slow,
                    'changeSpeed',
                    'task-workspace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bridge() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_useLine)
            QuantityBridgeBoard(
              start: _model.left!,
              addend: _model.right!,
              moved: _moved,
              enabled: widget.enabled,
              reduceMotion: _quiet,
              reveal: widget.helpLevel > 0,
              onChanged: (value) => _change(
                () {
                  _moved = value.clamp(0, _model.right!);
                },
                'moveCounter',
                'ten-frame',
              ),
            )
          else
            _numberLine(),
          const SizedBox(height: 8),
          _action(
            key: 'workspace-change-representation',
            icon: _useLine ? Icons.grid_view_rounded : Icons.linear_scale,
            label:
                _useLine ? 'Mit Steinen erklären' : 'Am Zahlenstrahl versuchen',
            onPressed: () => _change(
              () {
                _useLine = !_useLine;
                _linePosition = _model.left;
              },
              'changeRepresentation',
              _useLine ? 'ten-frame' : 'number-line',
              isHelp: true,
            ),
          ),
        ],
      );

  Widget _subtraction() => _surface(
        title: 'Wegnehmen und nachzählen',
        icon: Icons.remove_circle_outline_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Diese Steine liegen noch da', style: _labelStyle),
            const SizedBox(height: 8),
            _counterTray(
              key: 'remaining-tray',
              children: [
                for (var i = 0; i < _model.left!; i++)
                  if (!_removed.contains(i))
                    _counter(
                      'remaining-counter-$i',
                      'Stein ${i + 1}, weglegen',
                      _gold,
                      onTap: _removed.length < _model.right!
                          ? () => _removeCounter(i)
                          : null,
                    ),
              ],
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.remove_rounded, color: _muted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Weggelegt · nicht mehr mitzählen',
                    style: _bodyStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _counterTray(
              key: 'removed-tray',
              children: [
                for (var i = 0; i < _model.left!; i++)
                  if (_removed.contains(i))
                    _counter(
                      'removed-counter-$i',
                      'Weggelegter Stein ${i + 1}, zurücklegen',
                      _violet,
                      removed: true,
                      onTap: () => _change(
                        () => _removed.remove(i),
                        'restoreCounter',
                        'counter-$i',
                      ),
                    ),
              ],
            ),
          ],
        ),
      );

  void _removeCounter(int index) {
    if (_removed.contains(index) || _removed.length >= _model.right!) return;
    _change(() => _removed.add(index), 'removeCounter', 'counter-$index');
  }

  void _allocate(int group, int delta) {
    if (group < 0 || group >= _allocations.length) return;
    final allocated = _allocations.fold(0, (a, b) => a + b);
    if (delta > 0 && allocated >= _model.total) return;
    if (delta < 0 && _allocations[group] == 0) return;
    _change(() => _allocations[group] += delta,
        delta > 0 ? 'addToGroup' : 'returnFromGroup', 'group-$group');
  }

  Widget _groups() {
    final allocated = _allocations.fold(0, (a, b) => a + b);
    final supply = _model.total - allocated;
    return _surface(
      title: 'Gleich große Gruppen bauen',
      icon: Icons.workspaces_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Vorrat', style: _labelStyle),
          const SizedBox(height: 6),
          _counterTray(
            key: 'group-supply',
            children: [
              for (var i = 0; i < supply; i++)
                _counter('group-bank-$i', 'Vorratsstein ${i + 1}', _gold),
            ],
          ),
          const SizedBox(height: 12),
          for (var group = 0; group < _model.groupCount; group++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF091F3E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _cyan.withValues(alpha: .38)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Gruppe ${group + 1}', style: _labelStyle),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < _allocations[group]; i++)
                            _counter(
                              'group-$group-counter-$i',
                              'Stein ${i + 1} in Gruppe ${group + 1}, zurücklegen',
                              _cyan,
                              onTap: () => _allocate(group, -1),
                            ),
                          _action(
                            key: 'group-$group-add',
                            icon: Icons.add,
                            label: 'Einen dazulegen',
                            onPressed:
                                supply > 0 ? () => _allocate(group, 1) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _numberLine() {
    final minimum = _model.lineMin;
    final maximum = _model.lineMax;
    final position = _linePosition;
    return _surface(
      title: 'Schritt für Schritt auf der Linie',
      icon: Icons.linear_scale,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Jede Zahl hat ihren Platz. Wische, um weiterzuschauen.',
            style: _bodyStyle,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            key: const ValueKey('workspace-number-line'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var n = minimum; n <= maximum; n++)
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        _tile(
                          key: 'number-line-$n',
                          label: 'Zahl $n auf dem Zahlenstrahl',
                          selected: position == n,
                          onTap: () => _change(
                            () => _linePosition = n,
                            'focusNumber',
                            'number-$n',
                          ),
                          child: Text('$n', style: _numberStyle),
                        ),
                        Container(width: 2, height: 9, color: _cyan),
                        Container(height: 2, color: _cyan),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _action(
                key: 'number-line-back',
                icon: Icons.arrow_back_rounded,
                label: 'Einen zurück',
                onPressed: position != null && position > minimum
                    ? () => _change(
                          () => _linePosition = position - 1,
                          'stepBack',
                          'number-${position - 1}',
                        )
                    : null,
              ),
              _action(
                key: 'number-line-forward',
                icon: Icons.arrow_forward_rounded,
                label: 'Einen weiter',
                onPressed: position != null && position < maximum
                    ? () => _change(
                          () => _linePosition = position + 1,
                          'stepForward',
                          'number-${position + 1}',
                        )
                    : null,
              ),
            ],
          ),
          if (position != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Deine Markierung: $position', style: _labelStyle),
            ),
        ],
      ),
    );
  }

  Widget _comparison() => _surface(
        title: 'Vergleichen und begründen',
        icon: Icons.compare_arrows_rounded,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_model.left}',
                    textAlign: TextAlign.center,
                    style: _numberStyle,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.help_outline, color: _muted),
                ),
                Expanded(
                  child: Text(
                    '${_model.right}',
                    textAlign: TextAlign.center,
                    style: _numberStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Lege probeweise ein Zeichen dazwischen.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final item in const {
                  '<': 'kleiner als',
                  '=': 'gleich',
                  '>': 'größer als',
                }.entries)
                  _tile(
                    key: 'comparison-${item.key}',
                    label: item.value,
                    selected: _relation == item.key,
                    onTap: () => _change(
                      () => _relation = item.key,
                      'compareNumbers',
                      'relation-${item.key}',
                    ),
                    child: Text(item.key, style: _numberStyle),
                  ),
              ],
            ),
            if (_relation != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Dein Vorschlag: ${_model.left} $_relation ${_model.right}',
                  style: _labelStyle,
                ),
              ),
          ],
        ),
      );

  Widget _syllables() {
    final visible = _unfolded || widget.helpLevel > 1;
    final active = _activeSyllable;
    return _surface(
      title: 'Ein Wort zum Entdecken',
      icon: Icons.record_voice_over_rounded,
      accent: _violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (LumoTaskObjectArt.assetForName(_model.word) != null)
            Center(
              child: LumoTaskObjectArt(
                name: _model.word,
                size: 104,
                semanticLabel: 'Bild zum Wort ${_model.word}',
              ),
            ),
          Text(
            _model.word,
            key: const ValueKey('workspace-word'),
            textAlign: TextAlign.center,
            style: _numberStyle.copyWith(fontSize: 31),
          ),
          const SizedBox(height: 10),
          if (!visible)
            _action(
              key: 'workspace-reveal-syllables',
              icon: Icons.touch_app_rounded,
              label: 'Hilf mir mit den Silben',
              onPressed: () => _change(
                () => _unfolded = true,
                'revealSyllables',
                'word',
                isHelp: true,
              ),
            )
          else ...[
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _model.tokens.length; i++)
                  _tile(
                    key: 'syllable-$i',
                    label: 'Silbe ${i + 1}: ${_model.tokens[i]}',
                    selected: active == i,
                    accent: _violet,
                    onTap: () => _change(
                      () => _focus = i,
                      'focusSyllable',
                      'syllable-$i',
                    ),
                    child: Text(_model.tokens[i], style: _numberStyle),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Tippe eine Silbe an. Die Markierung zeigt die Sprecheinheit.',
              textAlign: TextAlign.center,
              style: _bodyStyle,
            ),
            const SizedBox(height: 10),
            _action(
              key: 'workspace-arrange-syllables',
              icon: Icons.view_week_rounded,
              label: _arranging ? 'Zur Wortansicht' : 'Silben selbst ordnen',
              onPressed: () => _change(
                () => _arranging = !_arranging,
                'arrangeMode',
                'word',
                isHelp: true,
              ),
            ),
            if (_arranging) ...[
              const SizedBox(height: 10),
              LearningTokenWorkbench(
                tokens: _model.shuffledTokens,
                selected: _tokenOrder,
                enabled: widget.enabled,
                reduceMotion: _quiet,
                onChanged: (value) => _change(
                  () => _tokenOrder = value,
                  'arrangeTokens',
                  'syllable-workbench',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _pattern() {
    final showGroup = _groupVisible || widget.helpLevel > 1;
    return _surface(
      title: 'Die Musterwerkstatt',
      icon: Icons.category_outlined,
      accent: _violet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (var i = 0; i < _model.tokens.length; i++)
                _tile(
                  key: 'pattern-$i',
                  label: 'Platz ${i + 1}: ${_model.tokens[i]}'
                      '${showGroup ? ', Stelle ${i % _model.period + 1} der Gruppe' : ''}',
                  selected: _focus == i,
                  accent: showGroup && i < _model.period ? _gold : _violet,
                  onTap: () => _change(
                    () => _focus = i,
                    'focusPatternElement',
                    'pattern-$i',
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _shapeGlyph(_model.tokens[i]),
                      if (showGroup) ...[
                        const SizedBox(height: 4),
                        Text('${i % _model.period + 1}', style: _bodyStyle),
                      ],
                    ],
                  ),
                ),
              const SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    color: _ink,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showGroup)
            Text(
              'Die ersten ${_model.period} Formen bilden eine Gruppe. '
              'Die Zahlen darunter zeigen die Stellen der Wiederholung.',
              key: const ValueKey('pattern-group-hint'),
              style: _bodyStyle,
            )
          else
            _action(
              key: 'workspace-show-pattern-group',
              icon: Icons.view_week_rounded,
              label: 'Zeig mir die wiederkehrende Gruppe',
              onPressed: () => _change(
                () => _groupVisible = true,
                'showRepeatingGroup',
                'pattern-group',
                isHelp: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tokens() => LearningTokenWorkbench(
        tokens: _model.tokens,
        selected: _tokenOrder,
        enabled: widget.enabled,
        reduceMotion: _quiet,
        onChanged: (value) => _change(
            () => _tokenOrder = value, 'arrangeTokens', 'token-workbench'),
      );

  Widget _numberPattern() => _surface(
        title: 'Zahlenschritte entdecken',
        icon: Icons.trending_up_rounded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _model.tokens.length; i++)
                _tile(
                  key: 'number-pattern-$i',
                  label: 'Zahl ${_model.tokens[i]} an Stelle ${i + 1}',
                  selected: _focus == i,
                  onTap: () => _change(() => _focus = i, 'focusSequenceNumber',
                      'number-pattern-$i'),
                  child: Text(_model.tokens[i], style: _numberStyle),
                ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.help_outline_rounded, color: _ink),
              ),
            ]),
            const SizedBox(height: 10),
            if (_groupVisible || widget.helpLevel > 0)
              Text(
                  'Immer ${_model.period >= 0 ? '+' : '−'} ${_model.period.abs()}',
                  key: const ValueKey('number-pattern-step'),
                  style: _labelStyle)
            else
              _action(
                key: 'workspace-show-number-step',
                icon: Icons.linear_scale,
                label: 'Hilf mir mit dem Abstand',
                onPressed: () => _change(() => _groupVisible = true,
                    'showSequenceStep', 'number-pattern',
                    isHelp: true),
              ),
          ],
        ),
      );

  Widget _shapes() => _surface(
        title: 'Formen mit den Augen vergleichen',
        icon: Icons.category_outlined,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (var i = 0; i < _model.tokens.length; i++)
              _tile(
                key: 'shape-explore-$i',
                label: '${_model.tokens[i]}, Form untersuchen',
                selected: _focus == i,
                onTap: () =>
                    _change(() => _focus = i, 'focusShape', 'shape-$i'),
                child: _shapeGlyph(_model.tokens[i], size: 52),
              ),
          ],
        ),
      );

  Widget _plant() => _surface(
        title: 'Eine Pflanze untersuchen',
        icon: Icons.local_florist_outlined,
        accent: const Color(0xFF70D9A5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              label:
                  'Eine Pflanze mit Wurzeln im Boden, Stängel, Blättern und Blüte.',
              child: SizedBox(
                height: 204,
                child: CustomPaint(painter: _PlantPainter(_focus)),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < _plantParts.length; i++)
                _tile(
                  key: 'plant-${_plantParts[i].id}',
                  label: '${_plantParts[i].label}, untersuchen',
                  selected: _focus == i,
                  accent: const Color(0xFF70D9A5),
                  onTap: () => _change(() => _focus = i, 'inspectPlantPart',
                      'plant-${_plantParts[i].id}',
                      isHelp: true),
                  child: Text(_plantParts[i].label, style: _labelStyle),
                ),
            ]),
          ],
        ),
      );

  Widget _evidence() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.fallback != null) widget.fallback!,
          const SizedBox(height: 8),
          if (!_unfolded)
            _action(
              key: 'workspace-inspect-evidence',
              icon: Icons.manage_search_rounded,
              label: 'Wichtige Angaben markieren',
              onPressed: () => _change(
                  () => _unfolded = true, 'inspectEvidence', 'task-text'),
            )
          else
            _surface(
              title: 'Deine Fundstellen',
              icon: Icons.bookmark_border_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Tippe die Wörter oder Sätze an, die dir helfen.',
                    style: _bodyStyle,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _model.tokens.length; i++)
                        _tile(
                          key: 'evidence-$i',
                          label: _model.tokens[i],
                          selected: _marked.contains(i),
                          onTap: () => _change(
                            () {
                              if (!_marked.add(i)) _marked.remove(i);
                            },
                            'markEvidence',
                            'evidence-$i',
                          ),
                          child: Text(_model.tokens[i], style: _labelStyle),
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      );

  Widget _counter(
    String key,
    String label,
    Color color, {
    VoidCallback? onTap,
    bool removed = false,
  }) =>
      _tile(
        key: key,
        label: label,
        onTap: onTap,
        accent: color,
        child: SizedBox(
          width: 30,
          height: 30,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-.35, -.45),
                colors: [
                  Color.lerp(color, Colors.white, .38)!,
                  color,
                  Color.lerp(color, Colors.black, .38)!,
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  offset: Offset(0, 3),
                  blurRadius: 3,
                ),
              ],
            ),
            child: removed
                ? const Icon(Icons.remove, color: Color(0xFF061A33), size: 24)
                : null,
          ),
        ),
      );

  Widget _counterTray({required String key, required List<Widget> children}) =>
      Container(
        key: ValueKey(key),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minHeight: 66),
        decoration: BoxDecoration(
          color: const Color(0xFF071A32),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF33536E)),
        ),
        child: children.isEmpty
            ? const Center(
                child: Text('Hier liegen keine Steine.', style: _bodyStyle),
              )
            : Wrap(spacing: 4, runSpacing: 4, children: children),
      );

  Widget _tile({
    required String key,
    required String label,
    required Widget child,
    VoidCallback? onTap,
    bool selected = false,
    Color accent = _cyan,
  }) =>
      Semantics(
        key: ValueKey(key),
        button: onTap != null,
        selected: selected,
        label: label,
        enabled: onTap != null && widget.enabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.enabled ? onTap : null,
            child: AnimatedContainer(
              duration: _duration,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: .18)
                    : const Color(0xFF102D4C),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? accent : const Color(0xFF41617C),
                  width: selected ? 2 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ExcludeSemantics(child: child),
                  if (selected)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: _ink,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _action({
    required String key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool selected = false,
  }) =>
      OutlinedButton.icon(
        key: ValueKey(key),
        onPressed: widget.enabled ? onPressed : null,
        icon: Icon(icon, size: 20),
        label: Text(label, softWrap: true),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: _ink,
          disabledForegroundColor: _muted.withValues(alpha: .7),
          backgroundColor:
              selected ? _cyan.withValues(alpha: .18) : const Color(0xFF102D4C),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          side: BorderSide(color: selected ? _cyan : const Color(0xFF54708C)),
          textStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
      );

  Widget _surface({
    required String title,
    required IconData icon,
    required Widget child,
    Color accent = _cyan,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14395B), Color(0xFF092440)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: .55), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 23),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: _labelStyle)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );

  Widget _shapeGlyph(String shape, {double size = 34}) {
    final known = _shapeName(shape);
    if (known == null) return Text(shape, style: _labelStyle);
    return CustomPaint(
      size: Size.square(size),
      painter: _LearningShapePainter(known),
    );
  }
}

class _WorkspaceModel {
  const _WorkspaceModel(
    this.kind, {
    this.left,
    this.right,
    this.operation = '',
    this.tokens = const [],
    this.word = '',
    this.period = 0,
    this.lineMin = 0,
    this.lineMax = 20,
  });

  List<String> get _visibleObjectIds {
    final ids = <String>['task-workspace'];
    if (_model.kind == _WorkspaceKind.bridge && !_useLine) {
      ids.addAll(['ten-frame', 'supply',
        if (_model.left! + _moved > 10) 'overflow',
        for (var i = 0; i < _model.left!; i++) 'initial-$i',
        for (var i = 0; i < _model.right!; i++) 'addend-$i']);
    }
    if (_model.kind == _WorkspaceKind.subtraction) {
      ids.addAll(['remaining-tray', 'removed-tray',
        for (var i = 0; i < _model.left!; i++) 'counter-$i']);
    }
    if (_model.kind == _WorkspaceKind.groups) {
      final supply = _model.total - _allocations.fold(0, (a, b) => a + b);
      ids.addAll(['group-supply',
        for (var i = 0; i < supply; i++) 'group-bank-$i',
        for (var i = 0; i < _model.groupCount; i++) ...[
          'group-$i',
          for (var j = 0; j < _allocations[i]; j++) 'group-$i-counter-$j',
        ]]);
    }
    if (_model.kind == _WorkspaceKind.numberLine || _useLine) {
      ids.addAll(['number-line',
        for (var i = _model.lineMin; i <= _model.lineMax; i++) 'number-$i']);
    }
    if (_model.kind == _WorkspaceKind.comparison) {
      ids.addAll(['comparison-left', 'comparison-right',
        'relation-<', 'relation-=', 'relation->']);
    }
    if (_model.kind == _WorkspaceKind.syllables) {
      ids.add('word');
      if (_unfolded || widget.helpLevel > 1) {
        ids.addAll([for (var i = 0; i < _model.tokens.length; i++) 'syllable-$i']);
        if (_arranging) ids.add('syllable-workbench');
      }
    }
    if (_model.kind == _WorkspaceKind.pattern) {
      ids.addAll([for (var i = 0; i < _model.tokens.length; i++) 'pattern-$i']);
      if (_groupVisible || widget.helpLevel > 1) ids.add('pattern-group');
    }
    if (_model.kind == _WorkspaceKind.numberPattern) {
      ids.addAll(['number-pattern',
        for (var i = 0; i < _model.tokens.length; i++) 'number-pattern-$i']);
    }
    if (_model.kind == _WorkspaceKind.tokens) ids.add('token-workbench');
    if (_model.kind == _WorkspaceKind.shapes) {
      ids.addAll([for (var i = 0; i < _model.tokens.length; i++) 'shape-$i']);
    }
    if (_model.kind == _WorkspaceKind.plant) {
      ids.addAll([for (final part in _plantParts) 'plant-${part.id}']);
    }
    if (_model.kind == _WorkspaceKind.evidence) {
      ids.add('task-text');
      if (_unfolded) {
        ids.addAll([for (var i = 0; i < _model.tokens.length; i++) 'evidence-$i']);
      }
    }
    return ids;
  }

  final _WorkspaceKind kind;
  final int? left, right;
  final String operation, word;
  final List<String> tokens;
  final int period, lineMin, lineMax;
  int get groupCount => kind != _WorkspaceKind.groups
      ? 0
      : operation == 'division'
          ? right!
          : left!;
  int get total => kind != _WorkspaceKind.groups
      ? 0
      : operation == 'division'
          ? left!
          : left! * right!;
  List<String> get shuffledTokens => tokens.length < 2
      ? tokens
      : [tokens.last, ...tokens.take(tokens.length - 1)];

  factory _WorkspaceModel.from(TaskInstance task) {
    final data = task.visualPayload.data;
    final left = _integer(data['left']) ?? _integer(data['start']);
    final right = _integer(data['right']) ?? _integer(data['takeAway']);
    final result = _integer(task.correctAnswer);
    final operation = data['operation'];
    if (task.subject == LearningSubject.mathematik &&
        left != null &&
        right != null &&
        left >= 0 &&
        right >= 0) {
      if (operation == 'addition' &&
          left <= 10 &&
          right <= 10 &&
          result == left + right) {
        return _WorkspaceModel(_WorkspaceKind.bridge, left: left, right: right);
      }
      if (operation == 'subtraction' &&
          left <= 20 &&
          right <= left &&
          result == left - right) {
        return _WorkspaceModel(
          _WorkspaceKind.subtraction,
          left: left,
          right: right,
        );
      }
      if (operation == 'multiplication' &&
          left > 0 &&
          left <= 6 &&
          right <= 10 &&
          left * right <= 36 &&
          result == left * right) {
        return _WorkspaceModel(
          _WorkspaceKind.groups,
          left: left,
          right: right,
          operation: 'multiplication',
        );
      }
      if (operation == 'division' &&
          left <= 36 &&
          right > 0 &&
          right <= 6 &&
          left % right == 0 &&
          result == left ~/ right) {
        return _WorkspaceModel(
          _WorkspaceKind.groups,
          left: left,
          right: right,
          operation: 'division',
        );
      }
      if (task.visualPayload.type == VisualType.quantityCompare ||
          task.visualPayload.type == VisualType.numberCompare) {
        return _WorkspaceModel(
          _WorkspaceKind.comparison,
          left: left,
          right: right,
        );
      }
    }
    final rawSyllables = _strings(data['syllables']);
    final word = data['word'] is String ? data['word'] as String : '';
    if ((task.visualPayload.type == VisualType.syllables ||
            task.visualPayload.type == VisualType.syllableClap) &&
        rawSyllables.isNotEmpty &&
        rawSyllables.length <= 10 &&
        rawSyllables.join().toLowerCase() == word.toLowerCase()) {
      return _WorkspaceModel(
        _WorkspaceKind.syllables,
        tokens: rawSyllables,
        word: word,
      );
    }
    final sequence = _strings(data['sequence']);
    final period = _integer(data['period']);
    if (task.visualPayload.type == VisualType.sequence &&
        sequence.isNotEmpty &&
        sequence.length <= 16 &&
        period != null &&
        period > 0 &&
        period < sequence.length &&
        List.generate(
          sequence.length,
          (i) => sequence[i] == sequence[i % period],
        ).every((v) => v) &&
        sequence[sequence.length % period].toLowerCase() ==
            '${task.correctAnswer}'.toLowerCase()) {
      return _WorkspaceModel(
        _WorkspaceKind.pattern,
        tokens: sequence,
        period: period,
      );
    }
    final numberSequence = data['sequence'];
    final step = _integer(data['step']);
    if (numberSequence is List &&
        numberSequence.length >= 2 &&
        numberSequence.length <= 16 &&
        numberSequence.every((n) => n is int) &&
        step != null &&
        step != 0 &&
        List.generate(
            numberSequence.length - 1,
            (i) =>
                (numberSequence[i + 1] as int) - (numberSequence[i] as int) ==
                step).every((same) => same) &&
        result == (numberSequence.last as int) + step) {
      return _WorkspaceModel(_WorkspaceKind.numberPattern,
          tokens: numberSequence.map((n) => '$n').toList(growable: false),
          period: step);
    }
    final tokens = _strings(data['tokens']);
    if (tokens.length >= 2 &&
        tokens.length <= 20 &&
        (task.taskType == TaskType.dragDrop ||
            task.visualPayload.type == VisualType.sentenceBlocks)) {
      return _WorkspaceModel(_WorkspaceKind.tokens, tokens: tokens);
    }
    if (task.visualPayload.type == VisualType.numberLine) {
      final numbers = task.options
          .map((o) => _integer(o.payload ?? o.label))
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
      if (numbers.length > 1 && numbers.last - numbers.first <= 20) {
        return _WorkspaceModel(
          _WorkspaceKind.numberLine,
          lineMin: math.max(0, numbers.first - 1),
          lineMax: numbers.last + 1,
        );
      }
    }
    if (task.visualPayload.type == VisualType.shape) {
      final shapes = task.options
          .map((o) => o.label)
          .where((name) => _shapeName(name) != null)
          .toList();
      if (shapes.length > 1 && shapes.length == task.options.length) {
        return _WorkspaceModel(_WorkspaceKind.shapes, tokens: shapes);
      }
    }
    if (task.subject == LearningSubject.sachkunde &&
        data['sceneKind'] == 'plant_parts' &&
        _plantParts.any((part) => part.id == data['plantPart'])) {
      return const _WorkspaceModel(_WorkspaceKind.plant);
    }
    // Sentence fragments keep their real wording, punctuation and Unicode.
    // Short prompts use words; long passages use whole lines or sentences so
    // their 48dp controls do not become an endless wall of isolated words.
    final prompt = task.prompt.trim();
    final evidence = prompt.length > 150
        ? prompt.split(RegExp(r'(?<=[.!?])\s+|\n+'))
        : prompt.split(RegExp(r'\s+'));
    return _WorkspaceModel(
      _WorkspaceKind.evidence,
      tokens: evidence.where((s) => s.isNotEmpty).toList(),
    );
  }
}

int? _integer(Object? value) => value is int
    ? value
    : value is String && RegExp(r'^-?\d+$').hasMatch(value.trim())
        ? int.tryParse(value.trim())
        : null;

List<String> _strings(Object? value) => value is List &&
        value.every((item) => item is String && item.trim().isNotEmpty)
    ? List<String>.unmodifiable(value.cast<String>())
    : const [];

String? _shapeName(String value) => switch (value.trim().toLowerCase()) {
      'kreis' || 'circle' => 'circle',
      'dreieck' || 'triangle' => 'triangle',
      'quadrat' || 'square' => 'square',
      'rechteck' || 'rectangle' => 'rectangle',
      'oval' => 'oval',
      'stern' || 'star' => 'star',
      _ => null,
    };

const _plantParts = <({String id, String label, String description})>[
  (
    id: 'root',
    label: 'Wurzel',
    description:
        'Die Wurzeln halten die Pflanze im Boden. Sie nehmen Wasser und gelöste Nährstoffe auf.'
  ),
  (
    id: 'stem',
    label: 'Stängel / Stamm',
    description:
        'Stängel oder Stamm tragen Blätter und Blüten. In ihnen wird unter anderem Wasser weitergeleitet.'
  ),
  (
    id: 'leaf',
    label: 'Blatt',
    description:
        'Die Blätter sind bei vielen Pflanzen grün. Mit Licht kann die Pflanze in ihnen Zucker herstellen.'
  ),
  (
    id: 'flower',
    label: 'Blüte',
    description:
        'Die Blüten helfen vielen Pflanzen bei der Fortpflanzung. Viele Blüten locken Insekten an.'
  ),
];

class _PlantPainter extends CustomPainter {
  const _PlantPainter(this.focus);
  final int? focus;
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 270, size.height / 204);
    canvas.save();
    canvas.translate((size.width - 270 * scale) / 2, 0);
    canvas.scale(scale);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 144, 234, 55), const Radius.circular(12)),
        Paint()..color = const Color(0xFF594433));
    canvas.drawLine(
        const Offset(18, 144),
        const Offset(252, 144),
        Paint()
          ..color = const Color(0xFF85AD63)
          ..strokeWidth = 3);
    final roots = Path()
      ..moveTo(135, 142)
      ..lineTo(135, 187)
      ..moveTo(135, 157)
      ..lineTo(110, 177)
      ..lineTo(102, 188)
      ..moveTo(135, 166)
      ..lineTo(157, 181)
      ..lineTo(167, 188)
      ..moveTo(128, 170)
      ..lineTo(119, 193)
      ..moveTo(135, 179)
      ..lineTo(145, 195);
    canvas.drawPath(
        roots,
        Paint()
          ..color = const Color(0xFFE3C69B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
    canvas.drawLine(
        const Offset(135, 142),
        const Offset(135, 48),
        Paint()
          ..color = const Color(0xFF58BA70)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round);
    final leaf = Path()
      ..moveTo(135, 110)
      ..quadraticBezierTo(90, 117, 77, 80)
      ..quadraticBezierTo(121, 76, 135, 110)
      ..moveTo(135, 91)
      ..quadraticBezierTo(176, 96, 193, 65)
      ..quadraticBezierTo(149, 61, 135, 91);
    canvas.drawPath(
        leaf,
        Paint()
          ..shader = const LinearGradient(
                  colors: [Color(0xFF82D775), Color(0xFF2B8C55)])
              .createShader(const Rect.fromLTWH(75, 60, 120, 60)));
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final center =
          const Offset(135, 37) + Offset(math.cos(angle), math.sin(angle)) * 17;
      canvas.drawOval(Rect.fromCenter(center: center, width: 23, height: 23),
          Paint()..color = const Color(0xFFFFCC80));
    }
    canvas.drawCircle(
        const Offset(135, 37), 12, Paint()..color = const Color(0xFFEFA73A));
    if (focus != null) {
      final area = const [
        Rect.fromLTWH(96, 151, 78, 47),
        Rect.fromLTWH(123, 60, 24, 84),
        Rect.fromLTWH(74, 64, 125, 58),
        Rect.fromLTWH(101, 3, 68, 68),
      ][focus!];
      canvas.drawRRect(
          RRect.fromRectAndRadius(area, const Radius.circular(9)),
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      final tip = Offset(area.left - 3, area.center.dy);
      canvas.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - 12, tip.dy - 7)
            ..lineTo(tip.dx - 12, tip.dy + 7)
            ..close(),
          Paint()..color = Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.focus != focus;
}

class _LearningShapePainter extends CustomPainter {
  const _LearningShapePainter(this.shape);
  final String shape;
  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final path = Path();
    switch (shape) {
      case 'circle':
        path.addOval(box);
      case 'oval':
        path.addOval(
          Rect.fromCenter(
            center: box.center,
            width: box.width,
            height: box.height * .65,
          ),
        );
      case 'square':
        path.addRect(box);
      case 'rectangle':
        path.addRect(
          Rect.fromCenter(
            center: box.center,
            width: box.width,
            height: box.height * .64,
          ),
        );
      case 'triangle':
        path.moveTo(box.center.dx, box.top);
        path.lineTo(box.right, box.bottom);
        path.lineTo(box.left, box.bottom);
        path.close();
      case 'star':
        for (var i = 0; i < 10; i++) {
          final angle = -math.pi / 2 + i * math.pi / 5;
          final radius = box.width / 2 * (i.isEven ? 1 : .46);
          final point =
              box.center + Offset(math.cos(angle), math.sin(angle)) * radius;
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        path.close();
    }
    canvas.drawShadow(path, Colors.black.withValues(alpha: .6), 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFADE8B), Color(0xFFE9AE42)],
        ).createShader(box),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFE9AF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(covariant _LearningShapePainter oldDelegate) =>
      oldDelegate.shape != shape;
}

const _ink = LumoVisualTokens.white;
const _muted = LumoVisualTokens.muted;
const _cyan = LumoVisualTokens.cyanBright;
const _gold = LumoVisualTokens.gold;
const _violet = Color(0xFFC1AEFF);
const _labelStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: _ink,
  height: 1.3,
);
const _bodyStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 13,
  fontWeight: FontWeight.w700,
  color: _muted,
  height: 1.4,
);
const _numberStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 25,
  fontWeight: FontWeight.w900,
  color: _ink,
  height: 1.15,
);
