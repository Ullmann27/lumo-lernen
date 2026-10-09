import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import 'iq_boards.dart';
import 'iq_memory.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

/// Kopfzeile aller Testseiten: Zurück, Fortschritt und Bereich.
class IqProgressHeader extends StatelessWidget {
  const IqProgressHeader({
    super.key,
    required this.index,
    required this.total,
    required this.areaNumber,
    required this.itemsPerArea,
    required this.onBack,
    this.done,
  });

  final int index;
  final int total;
  final int areaNumber;
  final int itemsPerArea;
  final VoidCallback onBack;

  /// Schon beantwortete Rätsel (Standard: [index]).
  final int? done;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
        child: Row(
          children: [
            IqRoundButton(
              key: const ValueKey('iq-back'),
              icon: Icons.arrow_back_rounded,
              label: 'Zurück',
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Rätsel ${index + 1} von $total',
                            maxLines: 1,
                            style: iqText(16, weight: FontWeight.w900, shadows: iqScrim),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Bereich $areaNumber von ${IqArea.values.length}',
                            maxLines: 1,
                            style: iqText(12.5,
                                color: const Color(0xFFDCE8F8), shadows: iqScrim),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  IqSegmentedProgress(done: done ?? index, perArea: itemsPerArea),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Eine Rätselseite: Frage, gezeichnetes Rätsel, Antwortkarten und „Weiter“.
///
/// Nach „Weiter“ zeigt sie nie, ob die Antwort stimmt.
class IqPuzzleView extends StatefulWidget {
  const IqPuzzleView({
    super.key,
    required this.puzzle,
    required this.index,
    required this.total,
    required this.areaNumber,
    required this.itemsPerArea,
    required this.onSubmit,
    required this.onBack,
  });

  final IqPuzzle puzzle;
  final int index;
  final int total;
  final int areaNumber;
  final int itemsPerArea;

  /// Antwort (Index der Karte oder angetippte Felder) und Denkzeit.
  final void Function(List<int> response, int durationMs) onSubmit;
  final VoidCallback onBack;

  @override
  State<IqPuzzleView> createState() => _IqPuzzleViewState();
}

class _IqPuzzleViewState extends State<IqPuzzleView> {
  int? _choice;
  List<int> _taps = const [];
  final Stopwatch _clock = Stopwatch()..start();
  bool _submitted = false;

  IqPuzzle get _puzzle => widget.puzzle;

  bool get _ready => switch (_puzzle) {
        IqChoicePuzzle _ => _choice != null,
        IqMemoryPuzzle p => _taps.length == p.sequence.length,
      };

  bool get _isLast => widget.index + 1 >= widget.total;

  void _submit() {
    if (!_ready || _submitted) return;
    _submitted = true;
    final response = _puzzle is IqChoicePuzzle ? [_choice!] : _taps;
    widget.onSubmit(List<int>.unmodifiable(response), _clock.elapsedMilliseconds);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        // Ab 640 dp Breite (Fold innen, Querformat, Tablet) stehen Rätsel und
        // Antworten nebeneinander.
        final wide = c.maxWidth >= 640;
        return Column(
          children: [
            IqProgressHeader(
              index: widget.index,
              total: widget.total,
              areaNumber: widget.areaNumber,
              itemsPerArea: widget.itemsPerArea,
              onBack: widget.onBack,
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, body) =>
                    wide ? _wideBody(body) : _narrowBody(body),
              ),
            ),
            _bottomBar(),
          ],
        );
      });

  // ------------------------------------------------------------- Aufbau

  Widget _intro() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IqChip(
            label: _puzzle.area.title,
            icon: iqAreaStyle(_puzzle.area).icon,
            color: iqAreaStyle(_puzzle.area).color,
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(
              _puzzle.question,
              style: iqText(22,
                  weight: FontWeight.w900, height: 1.2, shadows: iqScrim),
            ),
          ),
        ],
      );

  /// Chip und Frage in einer Zeile (für niedrige Bildschirme im Querformat).
  Widget _inlineIntro() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
        child: Row(
          children: [
            IqChip(
              label: _puzzle.area.title,
              icon: iqAreaStyle(_puzzle.area).icon,
              color: iqAreaStyle(_puzzle.area).color,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  _puzzle.question,
                  style: iqText(20,
                      weight: FontWeight.w900, height: 1.15, shadows: iqScrim),
                ),
              ),
            ),
          ],
        ),
      );

  /// Querformat auf dem Telefon: Frage oben in einer Zeile, darunter Rätsel
  /// und Antworten nebeneinander – ohne Scrollen.
  Widget _shortBody() {
    final puzzle = _puzzle;
    const pad = EdgeInsets.fromLTRB(20, 0, 20, 6);
    final Widget content;
    if (puzzle is IqMemoryPuzzle) {
      content = IqMemoryPlay(
        puzzle: puzzle,
        onChanged: (taps) => setState(() => _taps = taps),
        onInputStart: () => _clock
          ..reset()
          ..start(),
        layout: (context, parts) => Row(
          children: [
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      parts.status,
                      const SizedBox(height: 10),
                      parts.controls,
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 5,
              child: Center(child: AspectRatio(aspectRatio: 1, child: parts.grid)),
            ),
          ],
        ),
      );
    } else {
      final choice = puzzle as IqChoicePuzzle;
      final hasBoard = _board(140, 200, wide: true) != null;
      content = hasBoard
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, c) => SingleChildScrollView(
                      child: _board(140, c.maxHeight, wide: true, snug: true),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(
                    child: _options(
                      choice,
                      190,
                      // Flache Karten, damit zwei Reihen ohne Scrollen passen.
                      aspect: choice is IqNumberPuzzle
                          ? null
                          : (choice.optionCount <= 4 ? 1.0 : 1.5),
                      minItem: 90,
                    ),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: _options(choice, 170, minItem: 90),
                ),
              ),
            );
    }
    return Column(
      children: [
        _inlineIntro(),
        Expanded(child: Padding(padding: pad, child: content)),
      ],
    );
  }

  Widget _narrowBody(BoxConstraints body) {
    final roomy = body.maxWidth >= 600;
    final puzzle = _puzzle;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: roomy ? 640 : 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _intro(),
              const SizedBox(height: 14),
              if (puzzle is IqMemoryPuzzle)
                _memory(puzzle, maxSide: roomy ? 420 : 360)
              else ...[
                if (_board(roomy ? 132 : 104, 260) case final board?) ...[
                  board,
                  const SizedBox(height: 16),
                ],
                _options(puzzle as IqChoicePuzzle, roomy ? 170 : 156),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _wideBody(BoxConstraints body) {
    final puzzle = _puzzle;
    final height = body.maxHeight;
    if (height < 330) return _shortBody();
    const pad = EdgeInsets.fromLTRB(20, 6, 20, 8);
    // Der Inhalt sitzt etwas über der Mitte, damit unten nicht alles leer ist.
    Widget placed(Widget child) => SingleChildScrollView(
          padding: pad,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(0, height - pad.vertical)),
            child: Align(alignment: const Alignment(0, -.2), child: child),
          ),
        );
    if (puzzle is IqMemoryPuzzle) {
      final room = math.max(150.0, height - pad.vertical - 8);
      return placed(
        IqMemoryPlay(
          puzzle: puzzle,
          onChanged: (taps) => setState(() => _taps = taps),
          onInputStart: () => _clock
            ..reset()
            ..start(),
          layout: (context, parts) => Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _intro(),
                    const SizedBox(height: 16),
                    Center(child: parts.status),
                    const SizedBox(height: 14),
                    Center(child: parts.controls),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 5,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: math.min(room, 440)),
                    child: AspectRatio(aspectRatio: 1, child: parts.grid),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final choice = puzzle as IqChoicePuzzle;
    final boardHeight = math.max(170.0, height - 112);
    final board = _board(140, boardHeight, wide: true);
    if (board == null) {
      return placed(
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _intro(),
                const SizedBox(height: 14),
                _options(choice, 170),
              ],
            ),
          ),
        ),
      );
    }
    return placed(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _intro(),
                const SizedBox(height: 12),
                board,
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _options(
              choice,
              190,
              aspect: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// Das gezeichnete Rätsel; beim „Was passt nicht?“ sind die Antwortkarten
  /// das Rätsel selbst.
  Widget? _board(
    double maxTile,
    double maxHeight, {
    bool wide = false,
    bool snug = false,
  }) {
    final puzzle = _puzzle;
    // Hoch genug zum Atmen, aber nie höher als der Platz neben der Frage.
    Widget fit(Widget child) => wide
        ? ConstrainedBox(constraints: BoxConstraints(maxHeight: maxHeight), child: child)
        : child;
    switch (puzzle) {
      case IqMatrixPuzzle p:
        return fit(IqPanel(
          strong: true,
          padding: EdgeInsets.all(snug ? 8 : 16),
          accent: iqAreaStyle(IqArea.matrix).color,
          child: IqMatrixBoard(
            puzzle: p,
            preview: iqSelectedFigure(p, _choice),
            previewId: _choice,
            maxTile: maxTile,
          ),
        ));
      case IqSeriesPuzzle p:
        return IqPanel(
          strong: true,
          padding: EdgeInsets.all(snug ? 8 : 16),
          accent: iqAreaStyle(IqArea.series).color,
          child: IqSeriesBoard(
            puzzle: p,
            preview: iqSelectedFigure(p, _choice),
            previewId: _choice,
            maxTile: snug ? 54 : maxTile * .9,
          ),
        );
      case IqNumberPuzzle p:
        return IqPanel(
          strong: true,
          padding: EdgeInsets.all(snug ? 8 : 16),
          accent: iqAreaStyle(IqArea.numbers).color,
          child: IqNumberBoard(
            puzzle: p,
            fill: _choice == null ? null : p.options[_choice!],
            maxBubble: snug ? 50 : 66,
          ),
        );
      case IqRotationPuzzle p:
        return IqRotationBoard(
          puzzle: p,
          maxSide: math.max(
              snug ? 110 : 120, math.min(wide ? 300 : 230, maxHeight / .82)),
        );
      case IqOddOnePuzzle _:
      case IqMemoryPuzzle _:
        return null;
    }
  }

  Widget _options(
    IqChoicePuzzle puzzle,
    double maxItem, {
    double? aspect,
    double minItem = 110,
  }) =>
      IqOptionGrid(
        count: puzzle.optionCount,
        aspectRatio: aspect ?? iqOptionAspect(puzzle),
        maxItemWidth: maxItem,
        minItemWidth: minItem,
        itemBuilder: (context, i) => IqOptionCard(
          semanticLabel: iqOptionLabel(puzzle, i),
          selected: _choice == i,
          number: puzzle is IqRotationPuzzle ? i + 1 : null,
          onTap: () => setState(() => _choice = i),
          child: iqOptionContent(puzzle, i),
        ),
      );

  Widget _memory(IqMemoryPuzzle puzzle, {required double maxSide}) => IqMemoryPlay(
        puzzle: puzzle,
        maxSide: maxSide,
        onChanged: (taps) => setState(() => _taps = taps),
        onInputStart: () => _clock
          ..reset()
          ..start(),
      );

  Widget _bottomBar() => IqBottomBar(
        child: IqPrimaryButton(
          key: const ValueKey('iq-next'),
          label: _isLast ? 'Ergebnis ansehen' : 'Weiter',
          icon: _isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded,
          onPressed: _ready ? _submit : null,
        ),
      );
}
