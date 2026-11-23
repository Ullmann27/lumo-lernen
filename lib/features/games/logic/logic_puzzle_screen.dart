import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_state.dart';
import '../../../core/lumo_sound.dart';
import '../../../domain/logic/logic_games.dart';
import '../../../domain/logic/logic_learning_profile.dart';
import '../../tests/iq/iq_style.dart';
import 'logic_progress_store.dart';
import 'logic_widgets.dart';

class LogicPuzzleScreen extends StatefulWidget {
  const LogicPuzzleScreen({
    super.key,
    required this.appState,
    required this.owner,
    required this.puzzle,
    required this.session,
    this.store = const LogicProgressStore(),
  });
  final LumoAppState appState;
  final LearningProfileLease owner;
  final LogicPuzzle puzzle;
  final LogicPuzzleSession session;
  final LogicProgressStore store;

  @override
  State<LogicPuzzleScreen> createState() => _LogicPuzzleScreenState();
}

class _LogicPuzzleScreenState extends State<LogicPuzzleScreen> {
  late LogicPuzzleSession _session;
  late int _selected;
  final _boardScroll = ScrollController();
  final _wordScroll = ScrollController();
  final _pageScroll = ScrollController();
  final _boardKey = GlobalKey();
  final Set<int> _checked = {};
  String? _clue;
  String _feedback = 'Tippe auf ein freies Feld.';
  String? _saveError;
  bool _success = false;
  bool _finishing = false;
  bool _allowExit = false;
  int _writes = 0;
  double _boardCellStride = 52;
  double _boardInset = 7;

  LogicPuzzle get _puzzle => widget.puzzle;
  bool get _current =>
      !widget.appState.backupBusy &&
      widget.appState.isCurrentLearningLease(widget.owner);
  bool get _reduced => iqReduceMotion(context, widget.appState);
  bool get _editable =>
      _current &&
      !_success &&
      !_finishing &&
      _writes == 0 &&
      _saveError == null;
  LogicCell get _cell => _puzzle.cells[_selected];
  String get _value => _session.answers[_selected] ?? '';
  LogicClue? get _activeClue =>
      _puzzle.clues.where((clue) => clue.id == _clue).firstOrNull;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _selected = _puzzle.suggestedHintIndex(_session.answers) ??
        _puzzle.editableCells.first.index;
    _clue = _puzzle.checksFor(_selected).firstOrNull?.id;
    for (final entry in _session.answers.entries) {
      if (_puzzle.isCorrectCell(entry.key, entry.value)) {
        _checked.add(entry.key);
      }
    }
    widget.appState.addListener(_ownerChanged);
    _revealSelectedCell();
    if (_puzzle.isComplete(_session.answers)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }
  }

  @override
  void dispose() {
    widget.appState.removeListener(_ownerChanged);
    _boardScroll.dispose();
    _wordScroll.dispose();
    _pageScroll.dispose();
    super.dispose();
  }

  void _ownerChanged() {
    if (mounted && !_current) setState(() {});
  }

  void _sound(SoundEffect effect) {
    final settings = widget.appState.state.settings;
    if (settings.soundEnabled && !settings.calmMode) {
      unawaited(LumoSound.instance.play(effect));
    }
  }

  Future<bool> _save(LogicPuzzleSession value) async {
    if (!_current) return false;
    setState(() => _writes++);
    try {
      await widget.store.saveSession(widget.owner.studentId, value);
      if (mounted && _current) setState(() => _saveError = null);
      return true;
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Dein Stand ist noch nicht gespeichert. Versuche es bitte noch einmal.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _writes--);
    }
  }

  void _select(int index, {bool revealBoard = false}) {
    if (!_editable || !_puzzle.cells[index].editable) return;
    _sound(SoundEffect.click);
    setState(() {
      _setSelected(index);
      _feedback =
          'Reihe ${index ~/ _puzzle.columns + 1}, Spalte ${index % _puzzle.columns + 1}';
    });
    if (revealBoard && _boardKey.currentContext != null) {
      Scrollable.ensureVisible(
        _boardKey.currentContext!,
        duration: _reduced ? Duration.zero : const Duration(milliseconds: 220),
      );
    }
    _revealSelectedCell();
  }

  void _setSelected(int index) {
    _selected = index;
    if (!(_activeClue?.cells.contains(index) ?? false)) {
      _clue = _puzzle.checksFor(index).firstOrNull?.id;
    }
  }

  void _revealSelectedCell() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void reveal(ScrollController controller, double center) {
        if (!controller.hasClients) return;
        final target = (center - controller.position.viewportDimension / 2)
            .clamp(0.0, controller.position.maxScrollExtent);
        if (_reduced) {
          controller.jumpTo(target);
        } else {
          unawaited(controller.animateTo(
            target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ));
        }
      }

      reveal(_boardScroll,
          _boardInset + (_selected % _puzzle.columns + .5) * _boardCellStride);
      final wordPosition = _activeClue?.cells.indexOf(_selected) ?? -1;
      if (wordPosition >= 0) reveal(_wordScroll, (wordPosition + .5) * 52);
    });
  }

  void _selectClue(LogicClue clue) {
    if (!_editable) return;
    final index = clue.cells
            .where((i) =>
                _puzzle.cells[i].editable &&
                !_puzzle.isCorrectCell(i, _session.answers[i] ?? ''))
            .firstOrNull ??
        clue.cells.where((i) => _puzzle.cells[i].editable).firstOrNull;
    if (index == null) return;
    setState(() => _clue = clue.id);
    _select(index);
  }

  Future<void> _enter(String input) async {
    if (!_editable) return;
    final index = _selected;
    final current = _session.answers[index] ?? '';
    final text = _puzzle.kind == LogicGameKind.maths
        ? (_checked.contains(index) || current.length >= _cell.maxLength
            ? input
            : current + input)
        : input;
    _sound(SoundEffect.click);
    setState(() {
      _checked.remove(index);
      _session = _session.copyWith(answers: {..._session.answers, index: text});
    });
    if (_puzzle.kind != LogicGameKind.maths) {
      await _check(index);
    } else {
      await _save(_session);
    }
  }

  Future<void> _erase() async {
    if (!_editable || _value.isEmpty) return;
    _sound(SoundEffect.click);
    final answers = {..._session.answers};
    final value = answers[_selected]!;
    if (_puzzle.kind == LogicGameKind.maths && value.length > 1) {
      answers[_selected] = value.substring(0, value.length - 1);
    } else {
      answers.remove(_selected);
    }
    setState(() {
      _checked.remove(_selected);
      _session = _session.copyWith(answers: answers);
      _feedback = 'Hier kannst du etwas Neues ausprobieren.';
    });
    await _save(_session);
  }

  Future<void> _check(int index) async {
    if (!_editable) return;
    final value = _session.answers[index] ?? '';
    if (value.isEmpty) return;
    final correct = _puzzle.isCorrectCell(index, value);
    setState(() {
      _checked.add(index);
      if (!correct) _session = _session.copyWith(errors: _session.errors + 1);
      _feedback = correct
          ? 'Das passt! Gut kombiniert.'
          : 'Prüfe dieses Feld noch einmal. Lumo hilft dir gern.';
    });
    if (correct) {
      _sound(SoundEffect.cardDraw);
      if (!widget.appState.state.settings.calmMode) {
        unawaited(HapticFeedback.selectionClick());
      }
    }
    final saved = await _save(_session);
    if (!mounted || !_current || !saved) return;
    if (_puzzle.isComplete(_session.answers)) {
      await _finish();
    } else if (correct && _selected == index) {
      final following = _activeClue?.cells
          .where(
            (i) =>
                _puzzle.cells[i].editable &&
                !_puzzle.isCorrectCell(i, _session.answers[i] ?? ''),
          )
          .firstOrNull;
      final nextWordCell = _puzzle.kind == LogicGameKind.words
          ? _puzzle.clues
              .expand((clue) => clue.cells)
              .where((i) =>
                  _puzzle.cells[i].editable &&
                  !_puzzle.isCorrectCell(i, _session.answers[i] ?? ''))
              .firstOrNull
          : null;
      final next = following ??
          nextWordCell ??
          _puzzle.editableCells
              .where(
                (c) =>
                    c.index > index &&
                    !_puzzle.isCorrectCell(
                      c.index,
                      _session.answers[c.index] ?? '',
                    ),
              )
              .firstOrNull
              ?.index ??
          _puzzle.suggestedHintIndex(_session.answers);
      if (next != null) {
        setState(() => _setSelected(next));
        _revealSelectedCell();
      }
    }
  }

  Future<void> _hint() async {
    if (!_editable) return;
    final index = _puzzle.isCorrectCell(_selected, _value)
        ? _puzzle.suggestedHintIndex(_session.answers) ?? _selected
        : _selected;
    final hint = _puzzle.hintFor(index, answers: _session.answers);
    final next = _session.copyWith(hints: _session.hints + 1);
    setState(() {
      _session = next;
      _setSelected(index);
    });
    // Record the assistance before revealing it; a restart cannot erase it.
    if (!await _save(next) || !mounted || !_current) return;
    _revealSelectedCell();
    setState(() => _feedback = hint);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: logicNavy,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Lumo denkt mit dir',
                      style: iqText(23, color: logicCyan)),
                  const SizedBox(height: 16),
                  Text(hint, style: iqText(18, weight: FontWeight.w600)),
                  const SizedBox(height: 22),
                  LogicAction(
                    label: 'Ich probiere es',
                    primary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    if (_finishing ||
        _success ||
        !_current ||
        !_puzzle.isComplete(_session.answers)) {
      return;
    }
    setState(() => _finishing = true);
    try {
      await widget.store.complete(
        widget.owner.studentId,
        _session,
        puzzle: _puzzle,
      );
      if (!mounted || !_current) return;
      setState(() {
        _success = true;
        _saveError = null;
        _feedback = 'Abenteuer geschafft! Dein Fortschritt ist gespeichert.';
      });
      _sound(SoundEffect.win);
      if (_pageScroll.hasClients) {
        if (_reduced) {
          _pageScroll.jumpTo(0);
        } else {
          unawaited(
            _pageScroll.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _saveError =
              'Rätsel gelöst! Wir müssen deinen Fortschritt noch speichern.',
        );
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  Future<void> _retrySave() async {
    if (!_current) return;
    if (_puzzle.isComplete(_session.answers)) {
      await _finish();
    } else {
      await _save(_session);
    }
  }

  Future<void> _leave() async {
    if (_finishing || _writes > 0) return;
    if (_current && !_success && !await _save(_session)) return;
    if (!mounted) return;
    setState(() => _allowExit = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final solved = _puzzle.editableCells
        .where(
          (c) =>
              _puzzle.isCorrectCell(c.index, _session.answers[c.index] ?? ''),
        )
        .length;
    return PopScope(
      canPop: _allowExit || (_writes == 0 && !_finishing && _saveError == null),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Dein Stand wird gespeichert. Bei einem Fehler tippe auf „Speichern wiederholen“.',
              ),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: logicNavy,
        body: LogicBackdrop(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Zu den Levels',
                        onPressed: _writes > 0 || _finishing ? null : _leave,
                        color: Colors.white,
                        icon: const Icon(Icons.arrow_back_rounded),
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_puzzle.kind.title, style: iqText(21)),
                            Text(
                              '${_puzzle.grade}. Klasse · Level ${_puzzle.level}',
                              style: iqText(13, color: logicMuted),
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        label:
                            '$solved von ${_puzzle.editableCells.length} Feldern gelöst',
                        child: Text(
                          '$solved / ${_puzzle.editableCells.length}',
                          style: iqText(16, color: logicGreen),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _pageScroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1080),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_current)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Text(
                                  'Das Profil wurde gewechselt. Dieser Rätselstand gehört weiterhin zum vorherigen Kind.',
                                  style: iqText(18),
                                ),
                              ),
                            if (_success) _successPanel(),
                            if (_saveError != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: LogicGlass(
                                  color: const Color(0xFFFFD388),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(_saveError!, style: iqText(17)),
                                      const SizedBox(height: 14),
                                      LogicAction(
                                        label: 'Speichern wiederholen',
                                        onPressed: _finishing || _writes > 0
                                            ? null
                                            : _retrySave,
                                        primary: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Text(_puzzle.title, style: iqText(25)),
                            const SizedBox(height: 7),
                            Text(
                              _puzzle.instruction,
                              style: iqText(
                                16,
                                color: logicMuted,
                                weight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 790;
                                final board = Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _grid(),
                                    const SizedBox(height: 12),
                                    Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        _feedback,
                                        key: const ValueKey('logic-feedback'),
                                        style: iqText(
                                          16,
                                          color: _success
                                              ? logicGreen
                                              : logicMuted,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    if (wide && _puzzle.clues.isNotEmpty)
                                      _clues(),
                                  ],
                                );
                                final controls = Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _keypad(),
                                    const SizedBox(height: 14),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        LogicAction(
                                          label: 'Lumo hilft',
                                          icon: Icons.lightbulb_outline_rounded,
                                          onPressed: _editable ? _hint : null,
                                        ),
                                        LogicAction(
                                          label: 'Feld löschen',
                                          icon: Icons.backspace_outlined,
                                          onPressed:
                                              _editable && _value.isNotEmpty
                                                  ? _erase
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                                return wide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(flex: 3, child: board),
                                          const SizedBox(width: 22),
                                          Expanded(flex: 2, child: controls),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          board,
                                          const SizedBox(height: 18),
                                          controls,
                                          if (_puzzle.clues.isNotEmpty) ...[
                                            const SizedBox(height: 18),
                                            _clues()
                                          ],
                                        ],
                                      );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _grid() => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final cellPadding = compact ? 1.0 : 2.0;
          final framePadding = compact ? 4.0 : 6.0;
          final frameInsets = (framePadding + 1) * 2;
          final cellSide = math.max(
            48.0,
            math.min(
                66.0,
                (constraints.maxWidth - frameInsets) / _puzzle.columns -
                    cellPadding * 2),
          );
          _boardCellStride = cellSide + cellPadding * 2;
          _boardInset = framePadding + 1;
          // Include both padding and border. Compact gaps fit six 48 dp cells
          // on a narrow fold cover without shrinking their touch targets.
          final boardWidth = _boardCellStride * _puzzle.columns + frameInsets;
          final scrolls = boardWidth > constraints.maxWidth + .5;
          return Column(
            key: _boardKey,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (scrolls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.swipe_rounded,
                          size: 20, color: logicCyan),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Das Raster lässt sich seitlich schieben.',
                          style: iqText(13, color: logicMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              Scrollbar(
                controller: _boardScroll,
                thumbVisibility: scrolls,
                child: SingleChildScrollView(
                  controller: _boardScroll,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: boardWidth,
                    padding: EdgeInsets.all(framePadding),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06182D),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: logicColor(_puzzle.kind).withValues(alpha: .5),
                      ),
                      boxShadow: iqGlow(logicColor(_puzzle.kind)),
                    ),
                    child: CustomPaint(
                      foregroundPainter: _puzzle.blockRows != null &&
                              _puzzle.blockColumns != null
                          ? _SudokuBlockPainter(
                              rows: _puzzle.rows,
                              columns: _puzzle.columns,
                              blockRows: _puzzle.blockRows!,
                              blockColumns: _puzzle.blockColumns!,
                              stride: _boardCellStride,
                            )
                          : null,
                      child: Column(
                        children: [
                          for (var row = 0; row < _puzzle.rows; row++)
                            Row(
                              children: [
                                for (var col = 0; col < _puzzle.columns; col++)
                                  _gridCell(
                                    _puzzle.cells[row * _puzzle.columns + col],
                                    cellSide,
                                    cellPadding: cellPadding,
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  Widget _gridCell(LogicCell cell, double side,
      {String keyPrefix = 'logic-cell',
      bool showClueNumber = true,
      double cellPadding = 2}) {
    if (cell.blocked) {
      return SizedBox(
          width: side + cellPadding * 2, height: side + cellPadding * 2);
    }
    final selected = cell.index == _selected;
    final value = cell.given || cell.isOperator
        ? cell.answer
        : _session.answers[cell.index] ?? '';
    final correct = cell.editable &&
        _checked.contains(cell.index) &&
        _puzzle.isCorrectCell(cell.index, value);
    final needsCheck =
        cell.editable && _checked.contains(cell.index) && !correct;
    final row = cell.index ~/ _puzzle.columns;
    final col = cell.index % _puzzle.columns;
    final blockRows = _puzzle.blockRows;
    final blockColumns = _puzzle.blockColumns;
    final edge = correct
        ? logicGreen
        : needsCheck
            ? const Color(0xFFFFCF79)
            : selected
                ? logicCyan
                : const Color(0xFF446B8B);
    return Padding(
      padding: EdgeInsets.all(cellPadding),
      child: Semantics(
        key: ValueKey('$keyPrefix-${cell.index}'),
        label:
            'Reihe ${row + 1}, Spalte ${col + 1}${cell.given ? ', vorgegeben' : ''}${value.isNotEmpty ? ', $value' : ', leer'}${correct ? ', richtig' : ''}',
        button: cell.editable,
        selected: selected && cell.editable,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap:
                _editable && cell.editable ? () => _select(cell.index) : null,
            child: AnimatedContainer(
              duration:
                  _reduced ? Duration.zero : const Duration(milliseconds: 180),
              width: side,
              height: side,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cell.given
                      ? [const Color(0xFFE8F4FF), const Color(0xFFB8CEE4)]
                      : correct
                          ? [const Color(0xFF214E43), const Color(0xFF0B302D)]
                          : selected
                              ? [
                                  const Color(0xFF32678C),
                                  const Color(0xFF153F62)
                                ]
                              : [
                                  const Color(0xFF284967),
                                  const Color(0xFF142E49)
                                ],
                ),
                border: Border(
                  top: BorderSide(
                    color: edge,
                    width: blockRows != null && row % blockRows == 0 ? 2 : 1,
                  ),
                  left: BorderSide(
                    color: edge,
                    width:
                        blockColumns != null && col % blockColumns == 0 ? 2 : 1,
                  ),
                  right: BorderSide(
                    color: edge,
                    width: selected || correct ? 2 : 1,
                  ),
                  bottom: BorderSide(
                    color: edge,
                    width: selected || correct ? 2 : 1,
                  ),
                ),
                boxShadow: correct
                    ? iqGlow(logicGreen, blur: 12)
                    : const [
                        BoxShadow(
                          color: Color(0x99030818),
                          offset: Offset(0, 3),
                          blurRadius: 2,
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  if (showClueNumber && cell.clueNumber != null)
                    Positioned(
                      left: 4,
                      top: 1,
                      child: Text(
                        cell.clueNumber!,
                        style: iqText(
                          9,
                          color: cell.given ? logicNavy : logicMuted,
                        ),
                      ),
                    ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          value,
                          style: iqText(
                            value.length > 2 ? 21 : 26,
                            color: cell.given
                                ? logicNavy
                                : correct
                                    ? logicGreen
                                    : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (correct)
                    const Positioned(
                      right: 2,
                      top: 1,
                      child: Icon(
                        Icons.check_rounded,
                        color: logicGreen,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keypad() => LogicGlass(
        color: logicColor(_puzzle.kind),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _puzzle.kind == LogicGameKind.words
                  ? 'Deine Buchstaben'
                  : 'Deine Zahlen',
              style: iqText(18),
            ),
            if (_puzzle.kind == LogicGameKind.words && _activeClue != null)
              _wordEntry(_activeClue!)
            else ...[
              const SizedBox(height: 4),
              Text(
                'Feld ${_selected ~/ _puzzle.columns + 1} · ${_selected % _puzzle.columns + 1}',
                style: iqText(13, color: logicMuted),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final input in _puzzle.inputChoices)
                  SizedBox(
                    width: 48,
                    height: 52,
                    child: FilledButton(
                      key: ValueKey('logic-input-$input'),
                      onPressed: _editable ? () => _enter(input) : null,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 52),
                        backgroundColor: const Color(0xFF315D80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: Text(input, style: iqText(23)),
                    ),
                  ),
              ],
            ),
            if (_puzzle.kind == LogicGameKind.maths) ...[
              const SizedBox(height: 16),
              LogicAction(
                key: const ValueKey('logic-check'),
                label: 'Zahl prüfen',
                icon: Icons.check_rounded,
                primary: true,
                onPressed: _editable && _value.isNotEmpty
                    ? () => _check(_selected)
                    : null,
              ),
            ],
          ],
        ),
      );

  Widget _wordEntry(LogicClue clue) => Column(
        key: const ValueKey('logic-word-entry'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in _puzzle.clues)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Semantics(
                      selected: option.id == clue.id,
                      label: 'Hinweis ${_clueDescription(option)}',
                      child: OutlinedButton(
                        key: ValueKey('logic-word-clue-${option.id}'),
                        onPressed: _editable ? () => _selectClue(option) : null,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor:
                              option.id == clue.id ? logicNavy : logicMuted,
                          backgroundColor: option.id == clue.id
                              ? logicCyan
                              : const Color(0xFF193751),
                          side: BorderSide(
                            color: option.id == clue.id
                                ? logicCyan
                                : const Color(0xFF446B8B),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _clueBadge(
                          option,
                          color: option.id == clue.id ? logicNavy : logicMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            clue.text,
            key: const ValueKey('logic-active-clue'),
            style: iqText(16, weight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Dein Wort mit ${clue.cells.length} Buchstaben',
            child: Scrollbar(
              controller: _wordScroll,
              child: SingleChildScrollView(
                controller: _wordScroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final index in clue.cells)
                      _gridCell(_puzzle.cells[index], 48,
                          keyPrefix: 'logic-word-cell', showClueNumber: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      );

  String _clueDescription(LogicClue clue) =>
      clue.label.replaceAll('→', 'waagrecht').replaceAll('↓', 'senkrecht');

  Widget _clueBadge(LogicClue clue, {required Color color}) {
    final across = clue.label.endsWith('→');
    final down = clue.label.endsWith('↓');
    return Semantics(
      label: _clueDescription(clue),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              across || down
                  ? clue.label.substring(0, clue.label.length - 1).trim()
                  : clue.label,
              style: iqText(15, color: color),
            ),
            if (across || down) ...[
              const SizedBox(width: 4),
              Icon(
                across
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_downward_rounded,
                size: 18,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _clues() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _puzzle.kind == LogicGameKind.words
                ? 'Deine Hinweise'
                : 'So hängen die Felder zusammen',
            style: iqText(17),
          ),
          const SizedBox(height: 8),
          for (final clue in _puzzle.clues)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: _clue == clue.id
                    ? const Color(0xFF2D5477)
                    : const Color(0xFF18344F),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: ValueKey('logic-clue-${clue.id}'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: _editable ? () => _selectClue(clue) : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _clueBadge(clue, color: logicColor(_puzzle.kind)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              clue.text,
                              style: iqText(15, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _successPanel() => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: LogicGlass(
          color: logicGreen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.verified_rounded, color: logicGreen, size: 52),
              const SizedBox(height: 12),
              Text(
                'Abenteuer geschafft!',
                textAlign: TextAlign.center,
                style: iqText(28, color: logicGreen),
              ),
              const SizedBox(height: 8),
              Text(
                _puzzle.level == 12
                    ? 'Du hast alle zwölf Level dieser Rätselwelt entdeckt!'
                    : 'Level ${_puzzle.level + 1} ist jetzt offen. Dein Fortschritt ist gespeichert.',
                textAlign: TextAlign.center,
                style: iqText(17),
              ),
              const SizedBox(height: 18),
              LogicAction(
                key: const ValueKey('logic-finished'),
                label: 'Zu meinen Levels',
                primary: true,
                onPressed: _leave,
              ),
            ],
          ),
        ),
      );
}

/// Strong block boundaries stay visible even when a narrow screen uses the
/// smallest cell gaps. This overlay never changes the 48 dp touch targets.
class _SudokuBlockPainter extends CustomPainter {
  const _SudokuBlockPainter({
    required this.rows,
    required this.columns,
    required this.blockRows,
    required this.blockColumns,
    required this.stride,
  });

  final int rows;
  final int columns;
  final int blockRows;
  final int blockColumns;
  final double stride;

  @override
  void paint(Canvas canvas, Size size) {
    final separation = Paint()
      ..color = logicNavy
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final boundary = Paint()
      ..color = const Color(0xFF98CEE9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    void line(Offset start, Offset end) {
      canvas.drawLine(start, end, separation);
      canvas.drawLine(start, end, boundary);
    }

    for (var col = blockColumns; col < columns; col += blockColumns) {
      final x = col * stride;
      line(Offset(x, 1), Offset(x, size.height - 1));
    }
    for (var row = blockRows; row < rows; row += blockRows) {
      final y = row * stride;
      line(Offset(1, y), Offset(size.width - 1, y));
    }
  }

  @override
  bool shouldRepaint(covariant _SudokuBlockPainter oldDelegate) =>
      rows != oldDelegate.rows ||
      columns != oldDelegate.columns ||
      blockRows != oldDelegate.blockRows ||
      blockColumns != oldDelegate.blockColumns ||
      stride != oldDelegate.stride;
}
