import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_sound.dart';
import '../../../domain/logic/trail_puzzle.dart';
import '../../tests/iq/iq_style.dart';
import 'logic_widgets.dart';
import 'trail_progress_store.dart';

IconData _trailDirectionIcon(TrailDirection direction) => switch (direction) {
      TrailDirection.up => Icons.arrow_upward_rounded,
      TrailDirection.right => Icons.arrow_forward_rounded,
      TrailDirection.down => Icons.arrow_downward_rounded,
      TrailDirection.left => Icons.arrow_back_rounded,
    };

/// Complete route-planning game: plan, watch the program, correct and retry.
class TrailPuzzleScreen extends StatefulWidget {
  const TrailPuzzleScreen({
    super.key,
    required this.appState,
    this.initialGrade,
    this.initialLevel,
    this.store = const TrailProgressStore(),
  });
  final LumoAppState appState;
  final int? initialGrade;
  final int? initialLevel;
  final TrailProgressStore store;

  @override
  State<TrailPuzzleScreen> createState() => _TrailPuzzleScreenState();
}

class _TrailPuzzleScreenState extends State<TrailPuzzleScreen> {
  LearningProfileLease? _owner;
  TrailProgress? _progress;
  TrailPuzzle? _puzzle;
  TrailState? _state;
  List<TrailDirection> _commands = [];
  bool _saving = false;
  bool _running = false;
  bool _won = false;
  int _executing = -1;
  int _runToken = 0;
  String? _loadError;
  String? _saveError;
  String _feedback =
      'Plane zuerst den Weg. Jeder Pfeil bewegt die Pfote ein Feld.';
  final _boardKey = GlobalKey();

  bool get _current =>
      _owner != null &&
      !widget.appState.backupBusy &&
      widget.appState.isCurrentLearningLease(_owner!);
  bool get _editable => _current && !_running && !_saving && _saveError == null;
  bool get _reduced => iqReduceMotion(context, widget.appState);

  @override
  void initState() {
    super.initState();
    widget.appState.addListener(_profileChanged);
    unawaited(_load());
  }

  @override
  void dispose() {
    _runToken++;
    widget.appState.removeListener(_profileChanged);
    super.dispose();
  }

  void _profileChanged() {
    if (mounted && _owner != null && !_current) {
      _runToken++;
      setState(() => _running = false);
    }
  }

  Future<void> _load() async {
    try {
      final owner = _owner ?? await widget.appState.captureLearningProfile();
      final progress = await widget.store.load(owner.studentId);
      if (!mounted ||
          widget.appState.backupBusy ||
          !widget.appState.isCurrentLearningLease(owner)) {
        return;
      }
      final grade = (widget.initialGrade ??
              (progress.plans.isEmpty
                  ? widget.appState.state.grade
                  : progress.lastGrade))
          .clamp(1, 4);
      final level = (widget.initialLevel ?? progress.lastLevel).clamp(1, 6);
      final puzzle = TrailCatalog.puzzle(grade, level);
      setState(() {
        _owner = owner;
        _progress = progress;
        _puzzle = puzzle;
        _state = TrailState.initial(puzzle);
        _commands = List.of(progress.plans[puzzle.id] ?? []);
        _loadError = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadError =
            'Dein Pfotenpfad konnte noch nicht geladen werden. Bitte versuche es erneut.');
      }
    }
  }

  void _sound(SoundEffect effect) {
    final settings = widget.appState.state.settings;
    if (settings.soundEnabled && !settings.calmMode) {
      unawaited(LumoSound.instance.play(effect));
    }
  }

  Future<bool> _save({bool complete = false}) async {
    if (!_current || _puzzle == null) return false;
    setState(() => _saving = true);
    try {
      final progress = await widget.store.savePlan(
        profileId: _owner!.studentId,
        puzzle: _puzzle!,
        commands: _commands,
        complete: complete,
      );
      if (mounted && _current) {
        setState(() {
          _progress = progress;
          _saveError = null;
        });
        return true;
      }
      return false;
    } catch (_) {
      if (mounted) {
        setState(() => _saveError =
            'Dein Programm ist noch nicht gespeichert. Versuche es bitte erneut.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _select(int grade, int level) async {
    if (!_editable) return;
    final puzzle = TrailCatalog.puzzle(grade, level);
    setState(() {
      _puzzle = puzzle;
      _state = TrailState.initial(puzzle);
      _commands = List.of(_progress!.plans[puzzle.id] ?? []);
      _won = false;
      _executing = -1;
      _feedback = puzzle.instruction;
    });
    await _save();
  }

  Future<void> _add(TrailDirection direction) async {
    if (!_editable || _commands.length >= TrailCatalog.maxCommands) return;
    _sound(SoundEffect.click);
    setState(() {
      _commands = [..._commands, direction];
      _state = TrailState.initial(_puzzle!);
      _executing = -1;
      _won = false;
      _feedback =
          '${_commands.length}. Schritt: ${direction.label.toLowerCase()}. '
          'Mit „Los!“ läuft dein Programm vom Start.';
    });
    await _save();
  }

  Future<void> _remove({bool all = false}) async {
    if (!_editable || _commands.isEmpty) return;
    setState(() {
      _commands = all ? [] : _commands.take(_commands.length - 1).toList();
      _state = TrailState.initial(_puzzle!);
      _executing = -1;
      _won = false;
      _feedback = all
          ? 'Ein neuer Plan! Deine gelösten Pfade bleiben erhalten.'
          : 'Der letzte Pfeil ist weg. Jetzt kannst du deinen Plan ändern.';
    });
    await _save();
  }

  Future<void> _run() async {
    if (!_editable || _commands.isEmpty) return;
    final puzzle = _puzzle!;
    final commands = List<TrailDirection>.of(_commands);
    final token = ++_runToken;
    final reduced = _reduced;
    setState(() {
      _running = true;
      _won = false;
      _state = TrailState.initial(puzzle);
      _executing = -1;
      _feedback = 'Die Pfote folgt deinem Plan …';
    });
    if (_boardKey.currentContext != null) {
      await Scrollable.ensureVisible(_boardKey.currentContext!,
          duration:
              reduced ? Duration.zero : const Duration(milliseconds: 180));
    }
    for (var i = 0; i < commands.length; i++) {
      if (!mounted || !_current || token != _runToken) return;
      if (!reduced) {
        await Future<void>.delayed(const Duration(milliseconds: 330));
      }
      if (!mounted || !_current || token != _runToken) return;
      final result = _state!.step(commands[i]);
      setState(() {
        _executing = i;
        _state = result.state;
      });
      if (!result.accepted) {
        setState(() {
          _running = false;
          _feedback = result.status == TrailStepStatus.edge
              ? 'Schritt ${i + 1} führt über den Rand. Ändere diesen Pfeil und probiere deinen Plan noch einmal.'
              : 'Bei Schritt ${i + 1} liegt ein Felsen. Plane einen Weg daran vorbei.';
        });
        return;
      }
      if (result.collectedStation) _sound(SoundEffect.click);
      if (result.state.isComplete) {
        setState(() {
          _commands = commands.take(i + 1).toList();
          _won = true;
          _running = false;
          _feedback =
              'Picknick erreicht! Du hast alle Sterne in der richtigen Reihenfolge besucht.';
        });
        _sound(SoundEffect.win);
        await _save(complete: true);
        return;
      }
    }
    if (!mounted || !_current || token != _runToken) return;
    setState(() {
      _running = false;
      _feedback = _state!.nextStation < puzzle.stations.length
          ? 'Dein Programm ist zu Ende. Es fehlt noch Stern ${_state!.nextStation + 1}. Ergänze weitere Pfeile.'
          : 'Alle Sterne sind da! Ergänze jetzt den Weg zum Picknick.';
    });
  }

  void _hint() {
    if (!_editable) return;
    final puzzle = _puzzle!;
    final replay = TrailExecution.run(puzzle, _commands);
    if (replay.failure != null) {
      setState(() => _feedback = 'Prüfe Pfeil ${replay.consumed + 1}: '
          'Dort liegt ein Felsen oder der Rand. Jeder Pfeil gilt aus Sicht des Bildschirms.');
      return;
    }
    final state = replay.state;
    final station = state.nextStation;
    final target = station < puzzle.stations.length
        ? puzzle.stations[station]
        : puzzle.goal;
    final name = station < puzzle.stations.length
        ? 'Stern ${station + 1}'
        : 'das Picknick';
    setState(() => _feedback = state.isComplete
        ? 'Dein Plan erreicht schon das Picknick. Drücke „Los!“, um ihn auszuprobieren.'
        : 'Nach deinen Pfeilen steht die Pfote in Reihe ${state.position ~/ puzzle.columns + 1}, '
            'Spalte ${state.position % puzzle.columns + 1}. Suche $name '
            'in Reihe ${target ~/ puzzle.columns + 1}, Spalte ${target % puzzle.columns + 1}. '
            'Felsen darfst du umrunden.');
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = _puzzle;
    return Scaffold(
      backgroundColor: logicNavy,
      appBar: AppBar(
        backgroundColor: logicNavy,
        foregroundColor: Colors.white,
        title: Text('Pfotenpfad', style: iqText(23)),
      ),
      body: LogicBackdrop(
        child: SafeArea(
          top: false,
          child: puzzle == null
              ? Center(
                  child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _loadError == null
                      ? const CircularProgressIndicator(color: logicCyan)
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_loadError!,
                              style: iqText(17), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          LogicAction(label: 'Erneut laden', onPressed: _load),
                        ]),
                ))
              : !_current
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          'Das Lernprofil wurde gewechselt oder wird gerade gesichert. '
                          'Öffne den Pfotenpfad danach erneut.',
                          style: iqText(20),
                          textAlign: TextAlign.center),
                    ))
                  : LayoutBuilder(builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(16) / 16;
                      if (constraints.maxWidth < 850 &&
                          constraints.maxHeight >= 640 &&
                          textScale <= 1.3) {
                        return _compactPlanner(puzzle);
                      }
                      final wide = constraints.maxWidth >= 850;
                      final board = _boardPanel(puzzle);
                      final controls = _programPanel(puzzle);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                            child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _selection(puzzle),
                              const SizedBox(height: 16),
                              if (wide)
                                Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 6, child: board),
                                      const SizedBox(width: 18),
                                      Expanded(flex: 5, child: controls),
                                    ])
                              else ...[
                                board,
                                const SizedBox(height: 16),
                                controls
                              ],
                            ],
                          ),
                        )),
                      );
                    }),
        ),
      ),
    );
  }

  Future<T?> _showTrailSheet<T>(WidgetBuilder content) =>
      showModalBottomSheet<T>(
        context: context,
        backgroundColor: logicNavy,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) => SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ListenableBuilder(
                listenable: widget.appState,
                builder: (context, _) => !_current
                    ? Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          'Das Lernprofil wurde gewechselt oder wird gerade gesichert. '
                          'Öffne den Pfotenpfad danach erneut.',
                          style: iqText(18),
                        ),
                        const SizedBox(height: 16),
                        LogicAction(
                          label: 'Schließen',
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ])
                    : content(sheetContext),
              ),
            ),
          ),
        ),
      );

  Future<void> _choosePuzzle() async {
    if (!_editable) return;
    var grade = _puzzle!.grade;
    final chosen = await _showTrailSheet<TrailPuzzle>(
      (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Klasse und Pfad wählen', style: iqText(22)),
            const SizedBox(height: 8),
            Text('24 Pfade · 6 Wege pro Schulstufe',
                style: iqText(14, color: logicMuted)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var choice = 1; choice <= 4; choice++)
                _choice('Klasse $choice', grade == choice,
                    () => updateSheet(() => grade = choice),
                    key: ValueKey('trail-grade-$choice')),
            ]),
            const SizedBox(height: 16),
            Text('Tippe auf deinen Pfad.', style: iqText(16)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var level = 1; level <= 6; level++)
                _choice('Pfad $level',
                    _puzzle!.grade == grade && _puzzle!.level == level,
                    () => Navigator.of(sheetContext)
                        .pop(TrailCatalog.puzzle(grade, level)),
                    key: ValueKey('trail-level-$level'),
                    completed: _progress!.completed
                        .contains(TrailCatalog.puzzle(grade, level).id)),
            ]),
            const SizedBox(height: 20),
            LogicAction(
              label: 'Beim aktuellen Pfad bleiben',
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    );
    if (!mounted || chosen == null) return;
    await _select(chosen.grade, chosen.level);
  }

  Future<void> _showGuide() async {
    if (!_current || _puzzle == null) return;
    await _showTrailSheet<void>((sheetContext) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dein Pfotenpfad', style: iqText(22)),
            const SizedBox(height: 12),
            Text(_puzzle!.instruction, style: iqText(17)),
            const SizedBox(height: 12),
            Text(
              'Die Pfeile gelten so, wie du den Bildschirm siehst. '
              'Jeder Pfeil bewegt die Pfote ein Feld. '
              'Jeder Lauf beginnt wieder an der Startpfote. '
              'In der Pfeilleiste kannst du nach links und rechts wischen, '
              'um deinen ganzen Plan zu prüfen.',
              style: iqText(15, color: logicMuted),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 16, runSpacing: 8, children: [
              _legend(Icons.pets_rounded, const Color(0xFFFFB767), 'Deine Pfote'),
              _legend(Icons.star_rounded, const Color(0xFFFFDC81),
                  '${_state!.nextStation}/${_puzzle!.stations.length} Sterne'),
              _legend(Icons.park_rounded, logicGreen, 'Picknick'),
            ]),
            const SizedBox(height: 18),
            Text('Dein Hinweis', style: iqText(17, color: logicCyan)),
            const SizedBox(height: 6),
            Text(_feedback, style: iqText(16)),
            const SizedBox(height: 18),
            Text(
              '${_commands.length}/${TrailCatalog.maxCommands} Pfeile · '
              '${_progress!.completed.length}/24 Pfade entdeckt',
              style: iqText(14, color: logicMuted),
            ),
            if (_commands.length >= TrailCatalog.maxCommands) ...[
              const SizedBox(height: 8),
              Text(
                'Dein Programm hat 64 Pfeile. Entferne einen Pfeil, um es zu ändern.',
                style: iqText(14, color: logicMuted),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(spacing: 5, runSpacing: 6, children: [
              for (var i = 0; i < _commands.length; i++) _commandChip(i),
            ]),
            const SizedBox(height: 18),
            LogicAction(
              key: const ValueKey('trail-reset'),
              label: 'Neuer Plan',
              icon: Icons.restart_alt_rounded,
              onPressed: _editable && _commands.isNotEmpty
                  ? () {
                      Navigator.of(sheetContext).pop();
                      unawaited(_remove(all: true));
                    }
                  : null,
            ),
            const SizedBox(height: 10),
            LogicAction(
              key: const ValueKey('trail-guide-close'),
              label: 'Weiter planen',
              primary: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ));
  }

  Widget _compactPlanner(TrailPuzzle puzzle) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('trail-choose'),
                onPressed: _editable ? _choosePuzzle : null,
                style: _compactButtonStyle(),
                icon: const Icon(Icons.unfold_more_rounded, size: 20),
                label: Text('${puzzle.title} · Wählen', style: iqText(13)),
              ),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              key: const ValueKey('trail-guide'),
              onPressed: _showGuide,
              style: _compactButtonStyle(),
              icon: const Icon(Icons.help_outline_rounded, size: 20),
              label: Text('Hilfe', style: iqText(13)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(puzzle.instruction, style: iqText(14)),
          const SizedBox(height: 6),
          Expanded(
            key: _boardKey,
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _TrailBoard(
                  key: const ValueKey('trail-board'),
                  puzzle: puzzle,
                  state: _state!,
                  reduced: _reduced,
                  won: _won,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Row(
              key: const ValueKey('trail-feedback'),
              children: [
                Expanded(
                  child: Text(_feedback,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: iqText(13,
                          color: _won ? logicGreen : Colors.white)),
                ),
                IconButton(
                  tooltip: 'Den ganzen Hinweis lesen',
                  onPressed: _showGuide,
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  color: logicCyan,
                  icon: const Icon(Icons.read_more_rounded),
                ),
              ],
            ),
          ),
          Container(
            key: const ValueKey('trail-program'),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF081B32),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF39627C)),
            ),
            child: Row(children: [
              Text(_saving ? '…' : '${_commands.length}',
                  semanticsLabel: _saving
                      ? 'Dein Programm wird gespeichert.'
                      : '${_commands.length} Pfeile im Plan',
                  style: iqText(14, color: logicCyan)),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: _commands.isEmpty
                      ? Text('Tippe auf einen Pfeil.',
                          style: iqText(13, color: logicMuted))
                      : Row(children: [
                          for (var i = 0; i < _commands.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: _commandChip(i),
                            ),
                        ]),
                ),
              ),
              if (_commands.isNotEmpty) ...[
                const SizedBox(width: 4),
                const Icon(Icons.swipe_rounded, size: 18, color: logicMuted),
              ],
            ]),
          ),
          const SizedBox(height: 6),
          _directionControls(compact: true),
          const SizedBox(height: 6),
          Row(children: [
            FilledButton.icon(
              key: const ValueKey('trail-undo'),
              onPressed: _editable && _commands.isNotEmpty ? _remove : null,
              style: _compactButtonStyle(),
              icon: const Icon(Icons.backspace_outlined, size: 19),
              label: Text('Pfeil weg', style: iqText(13)),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              key: const ValueKey('trail-hint'),
              onPressed: _editable
                  ? () {
                      _hint();
                      unawaited(_showGuide());
                    }
                  : null,
              style: _compactButtonStyle(),
              icon: const Icon(Icons.lightbulb_outline_rounded, size: 19),
              label: Text('Tipp', style: iqText(13)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('trail-run'),
                onPressed: _running
                    ? () {
                        ++_runToken;
                        setState(() {
                          _running = false;
                          _feedback =
                              'Angehalten. Dein Programm bleibt erhalten.';
                        });
                      }
                    : _editable && _commands.isNotEmpty
                        ? _run
                        : null,
                style: _compactButtonStyle(primary: true),
                icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20),
                label: Text(_running ? 'Stopp' : 'Los!'),
              ),
            ),
          ]),
          if (_won) ...[
            const SizedBox(height: 6),
            LogicAction(
              key: const ValueKey('trail-next'),
              label: puzzle.level < 6 ? 'Nächster Pfad' : 'Noch einmal entdecken',
              icon: Icons.flag_rounded,
              onPressed: _editable
                  ? () => _select(
                      puzzle.grade, puzzle.level < 6 ? puzzle.level + 1 : 1)
                  : null,
            ),
          ],
          if (_saveError != null) ...[
            const SizedBox(height: 6),
            Text(_saveError!,
                style: iqText(13, color: const Color(0xFFFFD388))),
            LogicAction(
              label: 'Speichern erneut versuchen',
              onPressed:
                  _saving || !_current ? null : () => _save(complete: _won),
            ),
          ],
        ]),
      );

  ButtonStyle _compactButtonStyle({bool primary = false}) =>
      FilledButton.styleFrom(
        textStyle: iqText(14),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: primary ? logicGreen : const Color(0xFF254D70),
        foregroundColor: primary ? logicNavy : Colors.white,
        disabledBackgroundColor: const Color(0xFF263850),
        disabledForegroundColor: logicMuted,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _selection(TrailPuzzle puzzle) => LogicGlass(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Plane ein kleines Abenteuer', style: iqText(24)),
          const SizedBox(height: 5),
          Text('24 Pfade · Pfeile planen · Sterne besuchen · Picknick finden',
              style: iqText(14, color: logicMuted, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (var grade = 1; grade <= 4; grade++)
              _choice('Klasse $grade', puzzle.grade == grade,
                  () => _select(grade, 1),
                  key: ValueKey('trail-grade-$grade')),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (var level = 1; level <= 6; level++)
              _choice('$level', puzzle.level == level,
                  () => _select(puzzle.grade, level),
                  key: ValueKey('trail-level-$level'),
                  completed: _progress!.completed
                      .contains(TrailCatalog.puzzle(puzzle.grade, level).id)),
          ]),
        ]),
      );

  Widget _choice(String label, bool selected, VoidCallback onPressed,
          {required Key key, bool completed = false}) =>
      FilledButton(
        key: key,
        onPressed: _editable ? onPressed : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          backgroundColor: selected ? logicCyan : const Color(0xFF214C68),
          foregroundColor: selected ? logicNavy : Colors.white,
          disabledForegroundColor: logicMuted,
          textStyle: iqText(15),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label),
          if (completed) ...[
            const SizedBox(width: 4),
            Icon(Icons.check_circle_rounded,
                size: 17, color: selected ? logicNavy : logicGreen),
          ],
        ]),
      );

  Widget _boardPanel(TrailPuzzle puzzle) => LogicGlass(
        key: _boardKey,
        color: logicGreen,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.explore_rounded, color: logicGreen),
            const SizedBox(width: 10),
            Expanded(child: Text(puzzle.title, style: iqText(21))),
          ]),
          const SizedBox(height: 10),
          Text(puzzle.instruction,
              style: iqText(16, color: Colors.white, weight: FontWeight.w600)),
          const SizedBox(height: 16),
          Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AspectRatio(
              aspectRatio: 1,
              child: _TrailBoard(
                  key: const ValueKey('trail-board'),
                  puzzle: puzzle, state: _state!, reduced: _reduced, won: _won),
            ),
          )),
          const SizedBox(height: 12),
          Wrap(spacing: 16, runSpacing: 8, children: [
            _legend(Icons.pets_rounded, const Color(0xFFFFB767), 'Deine Pfote'),
            _legend(Icons.star_rounded, const Color(0xFFFFDC81),
                '${_state!.nextStation}/${puzzle.stations.length} Sterne'),
            _legend(Icons.park_rounded, logicGreen, 'Picknick'),
          ]),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Container(
              key: const ValueKey('trail-feedback'),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _won ? const Color(0xFF153E3C) : const Color(0xFF102D48),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _won ? logicGreen : const Color(0xFF376580)),
              ),
              child: Text(_feedback,
                  style: iqText(15,
                      color: _won ? logicGreen : Colors.white,
                      weight: FontWeight.w700)),
            ),
          ),
        ]),
      );

  Widget _legend(IconData icon, Color color, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 5),
        Text(label,
            style: iqText(13, color: logicMuted, weight: FontWeight.w700)),
      ]);

  Widget _commandChip(int index) => Semantics(
        label: 'Schritt ${index + 1}: ${_commands[index].label}',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: index == _executing ? logicGreen : const Color(0xFF2A5270),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('${index + 1}',
                style: iqText(17,
                    color: index == _executing ? logicNavy : Colors.white)),
            const SizedBox(width: 4),
            Icon(_trailDirectionIcon(_commands[index]),
                size: 21,
                color: index == _executing ? logicNavy : Colors.white),
          ]),
        ),
      );

  Widget _directionControls({bool compact = false}) => Row(children: [
        for (final direction in TrailDirection.values) ...[
          if (direction != TrailDirection.up) const SizedBox(width: 6),
          Expanded(
            child: FilledButton(
              key: ValueKey('trail-add-${direction.name}'),
              onPressed: _editable && _commands.length < TrailCatalog.maxCommands
                  ? () => _add(direction)
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: Size(48, compact ? 52 : 72),
                padding: EdgeInsets.symmetric(
                    horizontal: 2, vertical: compact ? 4 : 10),
                backgroundColor: const Color(0xFF2D5878),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(_trailDirectionIcon(direction), size: compact ? 24 : 28),
                Text(direction.label, style: iqText(12)),
              ]),
            ),
          ),
        ],
      ]);

  Widget _programPanel(TrailPuzzle puzzle) => LogicGlass(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Dein Pfeilprogramm', style: iqText(22)),
          const SizedBox(height: 5),
          Text(
              'Die Pfeile gelten so, wie du den Bildschirm siehst. '
              'Jeder Lauf beginnt wieder an der Startpfote.',
              style: iqText(14, color: logicMuted, weight: FontWeight.w600)),
          const SizedBox(height: 14),
          Container(
            key: const ValueKey('trail-program'),
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF081B32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF39627C))),
            child: _commands.isEmpty
                ? Center(
                    child: Text('Tippe unten auf einen Pfeil.',
                        style: iqText(15, color: logicMuted)))
                : Wrap(spacing: 5, runSpacing: 6, children: [
                    for (var i = 0; i < _commands.length; i++) _commandChip(i),
                  ]),
          ),
          const SizedBox(height: 12),
          _directionControls(),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            LogicAction(
                label: 'Letzter Pfeil weg',
                icon: Icons.backspace_outlined,
                onPressed: _editable && _commands.isNotEmpty ? _remove : null),
            LogicAction(
                label: 'Neuer Plan',
                icon: Icons.restart_alt_rounded,
                onPressed: _editable && _commands.isNotEmpty
                    ? () => _remove(all: true)
                    : null),
            LogicAction(
                label: 'Tipp',
                icon: Icons.lightbulb_outline_rounded,
                onPressed: _editable ? _hint : null),
          ]),
          const SizedBox(height: 16),
          LogicAction(
              key: const ValueKey('trail-run'),
              label: _running ? 'Die Pfote läuft …' : 'Los!',
              icon: Icons.play_arrow_rounded,
              primary: true,
              onPressed: _editable && _commands.isNotEmpty ? _run : null),
          if (_running) ...[
            const SizedBox(height: 10),
            LogicAction(
                label: 'Anhalten',
                icon: Icons.pause_rounded,
                onPressed: () {
                  ++_runToken;
                  setState(() {
                    _running = false;
                    _feedback = 'Angehalten. Dein Programm bleibt erhalten.';
                  });
                }),
          ],
          if (_won) ...[
            const SizedBox(height: 12),
            LogicAction(
                key: const ValueKey('trail-next'),
                label: puzzle.level < 6
                    ? 'Nächster Pfad'
                    : 'Noch einmal entdecken',
                icon: Icons.flag_rounded,
                onPressed: _editable
                    ? () => _select(
                        puzzle.grade, puzzle.level < 6 ? puzzle.level + 1 : 1)
                    : null),
          ],
          const SizedBox(height: 12),
          Text(
              _saving
                  ? 'Dein Programm wird gespeichert …'
                  : _commands.length >= TrailCatalog.maxCommands
                      ? 'Dein Programm hat 64 Pfeile. Entferne einen Pfeil, um es zu ändern.'
                      : '${_commands.length} Pfeile · ${_progress!.completed.length}/24 Pfade entdeckt',
              style: iqText(13, color: logicMuted, weight: FontWeight.w600)),
          if (_saveError != null) ...[
            const SizedBox(height: 12),
            Text(_saveError!,
                style: iqText(15, color: const Color(0xFFFFD388))),
            const SizedBox(height: 8),
            LogicAction(
                label: 'Speichern erneut versuchen',
                onPressed:
                    _saving || !_current ? null : () => _save(complete: _won)),
          ],
        ]),
      );
}

class _TrailBoard extends StatelessWidget {
  const _TrailBoard(
      {super.key,
      required this.puzzle,
      required this.state,
      required this.reduced,
      required this.won});
  final TrailPuzzle puzzle;
  final TrailState state;
  final bool reduced;
  final bool won;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A806F), Color(0xFF173C47)]),
          border: Border.all(
              color: won ? logicGreen : const Color(0xFF5CA78B), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x66010712), blurRadius: 15, offset: Offset(0, 9))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: LayoutBuilder(builder: (context, constraints) {
            final cellSide = constraints.maxWidth / puzzle.columns;
            return Stack(children: [
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: puzzle.rows * puzzle.columns,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: puzzle.columns),
                itemBuilder: (context, cell) {
                  final rock = puzzle.blocked.contains(cell);
                  final station = puzzle.stations.indexOf(cell);
                  final visited = state.visited.contains(cell);
                  final collected = station >= 0 && station < state.nextStation;
                  final goal = cell == puzzle.goal;
                  final start = cell == puzzle.start;
                  final label = 'Reihe ${cell ~/ puzzle.columns + 1}, '
                      'Spalte ${cell % puzzle.columns + 1}: '
                      '${rock ? 'Felsen' : goal ? 'Picknick' : station >= 0 ? 'Stern ${station + 1}${collected ? ', besucht' : ''}' : start ? 'Start' : 'Weg'}';
                  return Semantics(
                      label: label,
                      child: ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: AnimatedContainer(
                            duration: reduced
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: rock
                                  ? const Color(0xFF597383)
                                  : visited
                                      ? const Color(0xFF489982)
                                      : const Color(0xFF327663),
                              borderRadius: BorderRadius.circular(
                                  math.min(11, cellSide * .2)),
                              border: Border.all(
                                  color: rock
                                      ? const Color(0xFF91A9B4)
                                      : visited
                                          ? const Color(0xFF97EAC1)
                                          : const Color(0xFF52987B)),
                              boxShadow: [
                                BoxShadow(
                                    color: rock
                                        ? const Color(0xFF233F50)
                                        : const Color(0xFF204F45),
                                    offset: const Offset(0, 3))
                              ],
                            ),
                            child: Center(
                                child: rock
                                    ? Icon(Icons.terrain_rounded,
                                        size: cellSide * .62,
                                        color: const Color(0xFFC4D2D7))
                                    : goal
                                        ? Icon(Icons.park_rounded,
                                            size: cellSide * .66,
                                            color: const Color(0xFFD6FFA9))
                                        : station >= 0
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                    Icon(
                                                        collected
                                                            ? Icons
                                                                .check_circle_rounded
                                                            : Icons
                                                                .star_rounded,
                                                        size: cellSide * .82,
                                                        color: collected
                                                            ? logicGreen
                                                            : const Color(
                                                                0xFFFFDC81)),
                                                    if (!collected)
                                                      Text('${station + 1}',
                                                          style: iqText(
                                                              cellSide * .3,
                                                              color:
                                                                  logicNavy)),
                                                  ])
                                            : start && state.position != cell
                                                ? Icon(
                                                    Icons.outlined_flag_rounded,
                                                    size: cellSide * .5,
                                                    color:
                                                        const Color(0xFFB6E6D5))
                                                : null),
                          ),
                        ),
                      ));
                },
              ),
              AnimatedPositioned(
                duration:
                    reduced ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                left: (state.position % puzzle.columns) * cellSide +
                    cellSide * .12,
                top: (state.position ~/ puzzle.columns) * cellSide +
                    cellSide * .12,
                width: cellSide * .76,
                height: cellSide * .76,
                child: IgnorePointer(
                    child: Semantics(
                  label: 'Deine Pfote',
                  child: Container(
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFFD393), Color(0xFFF9974F)]),
                        border: Border.all(
                            color: const Color(0xFFFFF4DA), width: 2),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x550B1F25),
                              blurRadius: 5,
                              offset: Offset(0, 4))
                        ]),
                    child: Icon(Icons.pets_rounded,
                        size: cellSide * .46, color: const Color(0xFF6F3828)),
                  ),
                )),
              ),
            ]);
          }),
        ),
      );
}
