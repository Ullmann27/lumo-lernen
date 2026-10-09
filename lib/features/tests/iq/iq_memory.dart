import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import 'iq_boards.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

enum IqMemoryPhase { showing, input }

/// Die drei Teile des Merk-Blitzes, damit die Seite sie je nach Platz
/// untereinander oder nebeneinander anordnen kann.
class IqMemoryParts {
  const IqMemoryParts({
    required this.status,
    required this.grid,
    required this.controls,
  });

  /// „Schau genau hin!“ / „Jetzt du!“ mit Punkten.
  final Widget status;

  /// Das quadratische Raster; füllt die Fläche, die es bekommt.
  final Widget grid;

  /// „Nochmal zeigen“ und „Rückgängig“.
  final Widget controls;
}

/// Merk-Blitz zum Spielen: Die Felder leuchten nacheinander auf, danach tippt
/// das Kind sie in derselben Reihenfolge an. „Nochmal zeigen“ spielt alles
/// einmal erneut ab; die Zeit zählt erst ab dem Ende der letzten Vorführung.
class IqMemoryPlay extends StatefulWidget {
  const IqMemoryPlay({
    super.key,
    required this.puzzle,
    required this.onChanged,
    this.onInputStart,
    this.maxSide = 360,
    this.leadIn = const Duration(milliseconds: 650),
    this.layout,
  });

  final IqMemoryPuzzle puzzle;

  /// Wird bei jedem Tippen (und beim Zurücknehmen) mit allen angetippten
  /// Feldern aufgerufen.
  final ValueChanged<List<int>> onChanged;

  /// Die Vorführung ist zu Ende, das Kind darf tippen.
  final VoidCallback? onInputStart;
  final double maxSide;
  final Duration leadIn;

  /// Eigene Anordnung der Teile (Standard: untereinander).
  final Widget Function(BuildContext context, IqMemoryParts parts)? layout;

  @override
  State<IqMemoryPlay> createState() => _IqMemoryPlayState();
}

class _IqMemoryPlayState extends State<IqMemoryPlay> {
  final List<Timer> _timers = [];
  IqMemoryPhase _phase = IqMemoryPhase.showing;
  List<int> _taps = const [];
  int? _lit;
  int _litStep = -1;
  int? _flash;

  /// „Nochmal zeigen“ gibt es genau einmal je Rätsel: Ein Kind, das die Reihenfolge beliebig oft
  /// ansehen darf, schreibt sie nur ab, und der Merk-Blitz würde kein Arbeitsgedächtnis messen.
  static const int _maxReplays = 1;
  int _replays = 0;

  IqMemoryPuzzle get _puzzle => widget.puzzle;

  @override
  void initState() {
    super.initState();
    _schedulePlayback();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _at(Duration after, VoidCallback action) {
    _timers.add(Timer(after, () {
      if (mounted) action();
    }));
  }

  /// Plant die Vorführung. Ändert keinen Zustand – das macht der Aufrufer.
  void _schedulePlayback() {
    var at = widget.leadIn;
    final sequence = _puzzle.sequence;
    for (var i = 0; i < sequence.length; i++) {
      final step = i;
      _at(at, () => setState(() {
            _lit = sequence[step];
            _litStep = step;
          }));
      at += Duration(milliseconds: _puzzle.showMs);
      _at(at, () => setState(() => _lit = null));
      at += Duration(milliseconds: _puzzle.gapMs);
    }
    _at(at, () {
      setState(() {
        _phase = IqMemoryPhase.input;
        _litStep = -1;
      });
      widget.onInputStart?.call();
    });
  }

  void _replay() {
    if (_replays >= _maxReplays) return;
    _replays++;
    _cancelTimers();
    setState(() {
      _phase = IqMemoryPhase.showing;
      _taps = const [];
      _lit = null;
      _litStep = -1;
      _flash = null;
    });
    widget.onChanged(const []);
    _schedulePlayback();
  }

  void _tap(int cell) {
    if (_phase != IqMemoryPhase.input) return;
    if (_taps.length >= _puzzle.sequence.length) return;
    setState(() {
      _taps = [..._taps, cell];
      _flash = cell;
    });
    widget.onChanged(List<int>.unmodifiable(_taps));
    _at(const Duration(milliseconds: 240), () {
      if (_flash == cell) setState(() => _flash = null);
    });
  }

  void _undo() {
    if (_phase != IqMemoryPhase.input || _taps.isEmpty) return;
    setState(() {
      _taps = _taps.sublist(0, _taps.length - 1);
      _flash = null;
    });
    widget.onChanged(List<int>.unmodifiable(_taps));
  }

  @override
  Widget build(BuildContext context) {
    final showing = _phase == IqMemoryPhase.showing;
    final total = _puzzle.sequence.length;
    final parts = IqMemoryParts(
      status: _status(showing, total),
      grid: _grid(),
      controls: _controls(),
    );
    final layout = widget.layout;
    if (layout != null) return layout(context, parts);
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(
        widget.maxSide,
        math.min(
          c.maxWidth,
          c.hasBoundedHeight ? math.max(c.maxHeight - 150, 160.0) : double.infinity,
        ),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          parts.status,
          const SizedBox(height: 12),
          SizedBox(width: side, height: side, child: parts.grid),
          const SizedBox(height: 14),
          parts.controls,
        ],
      );
    });
  }

  Widget _status(bool showing, int total) {
    final filled = showing ? (_litStep + 1).clamp(0, total) : _taps.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(showing ? Icons.visibility_rounded : Icons.touch_app_rounded,
                color: showing ? LumoVisualTokens.gold : LumoVisualTokens.cyanBright,
                size: 24),
            const SizedBox(width: 8),
            Text(
              showing ? 'Schau genau hin!' : 'Jetzt du!',
              style: iqText(18, weight: FontWeight.w900, shadows: iqScrim),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Semantics(
          label: showing
              ? 'Es leuchten $total Felder nacheinander auf'
              : '${_taps.length} von $total Feldern angetippt',
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < total; i++)
                AnimatedContainer(
                  duration: LumoMotion.reduced(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < filled
                        ? iqFlashColors[i % iqFlashColors.length]
                        : Colors.white.withValues(alpha: .22),
                    border: Border.all(color: Colors.white.withValues(alpha: .35)),
                    boxShadow: i < filled
                        ? iqGlow(iqFlashColors[i % iqFlashColors.length],
                            alpha: .6, blur: 8)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _grid() => LayoutBuilder(builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        final n = _puzzle.gridSize;
        const gap = 10.0;
        final tile = (side - gap * (n - 1)) / n;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Semantics(
              container: true,
              label: 'Raster mit $n mal $n Feldern',
              child: Column(
                children: [
                  for (var r = 0; r < n; r++) ...[
                    if (r > 0) const SizedBox(height: gap),
                    Expanded(
                      child: Row(
                        children: [
                          for (var col = 0; col < n; col++) ...[
                            if (col > 0) const SizedBox(width: gap),
                            SizedBox.square(
                              dimension: tile,
                              child: _tile(r * n + col, r, col),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      });

  Widget _tile(int cell, int row, int col) {
    final tapIndex = _taps.indexOf(cell);
    final lit = _lit == cell || _flash == cell;
    final litStep = _lit == cell
        ? _litStep
        : (tapIndex >= 0 ? tapIndex : _taps.length - 1);
    final input = _phase == IqMemoryPhase.input;
    final label = StringBuffer('Feld ${cell + 1}, Reihe ${row + 1}, Spalte ${col + 1}');
    if (tapIndex >= 0) label.write(', als ${tapIndex + 1}. angetippt');
    return Semantics(
      button: true,
      enabled: input,
      label: label.toString(),
      excludeSemantics: true,
      onTap: input ? () => _tap(cell) : null,
      child: GestureDetector(
        key: ValueKey('iq-memory-tile-$cell'),
        behavior: HitTestBehavior.opaque,
        onTap: input ? () => _tap(cell) : null,
        child: AnimatedScale(
          scale: lit ? 1.05 : 1,
          duration: LumoMotion.reduced(context)
              ? Duration.zero
              : const Duration(milliseconds: 120),
          child: IqMemoryTile(
            lit: lit,
            marked: tapIndex >= 0,
            badge: tapIndex >= 0 ? tapIndex + 1 : null,
            litColor: iqFlashColors[math.max(litStep, 0) % iqFlashColors.length],
          ),
        ),
      ),
    );
  }

  Widget _controls() => Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 188,
            child: IqPrimaryButton(
              key: const ValueKey('iq-replay'),
              label: 'Nochmal zeigen',
              icon: Icons.replay_rounded,
              outlined: true,
              height: 50,
              fontSize: 15,
              onPressed: _replays >= _maxReplays ? null : _replay,
            ),
          ),
          SizedBox(
            width: 188,
            child: IqPrimaryButton(
              key: const ValueKey('iq-undo'),
              label: 'Rückgängig',
              icon: Icons.undo_rounded,
              outlined: true,
              height: 50,
              fontSize: 15,
              onPressed: _phase == IqMemoryPhase.showing || _taps.isEmpty ? null : _undo,
            ),
          ),
        ],
      );
}
