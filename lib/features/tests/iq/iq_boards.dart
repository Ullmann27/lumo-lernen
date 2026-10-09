import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import 'iq_figure_painter.dart';
import 'iq_style.dart';
import 'iq_widgets.dart';

/// Wie viele Blöcke das größte Bauteil des Rätsels breit oder hoch ist.
/// Damit sind die Blöcke bei allen Bauteilen eines Rätsels gleich groß.
int iqPieceSpan(IqRotationPuzzle puzzle) {
  var span = math.max(puzzle.target.width, puzzle.target.height);
  for (final option in puzzle.options) {
    span = math.max(span, math.max(option.width, option.height));
  }
  return span;
}

/// Text für die Antwortkarte (Screenreader). Beim Drehrätsel nennt
/// [IqChoicePuzzle.describeOption] schon „gedreht“ oder „umgeklappt“ – das
/// wäre die Lösung, also bleibt dort nur die Nummer des Bauteils.
String iqOptionLabel(IqChoicePuzzle puzzle, int index) {
  final text = puzzle is IqRotationPuzzle
      ? puzzle.describeOption(index).split(' (').first
      : puzzle.describeOption(index);
  return 'Antwort ${index + 1} von ${puzzle.optionCount}: $text';
}

// ---------------------------------------------------------------------------
// Antwortkarten
// ---------------------------------------------------------------------------

/// Antwortkarte aus Glas. Markiert leuchtet sie auf und zeigt ein Häkchen –
/// ob die Antwort stimmt, zeigt sie nie.
class IqOptionCard extends StatelessWidget {
  const IqOptionCard({
    super.key,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
    required this.child,
    this.number,
  });

  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  /// Kleine Ziffer in der Ecke (Bauteil 1, 2, 3 …).
  final int? number;

  @override
  Widget build(BuildContext context) {
    final reduced = LumoMotion.reduced(context);
    final duration = reduced ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: LumoPressable(
        radius: 22,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedScale(
            scale: selected ? 1.035 : 1,
            duration: duration,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: selected
                      ? const [Color(0xF5236FB4), Color(0xF510427F)]
                      : const [Color(0xF51B4B7E), Color(0xF70B2B55)],
                ),
                border: Border.all(
                  color: selected
                      ? LumoVisualTokens.cyanBright
                      : LumoVisualTokens.cyan.withValues(alpha: .3),
                  width: selected ? 2.6 : 1.2,
                ),
                boxShadow: [
                  if (selected)
                    ...iqGlow(LumoVisualTokens.cyanBright, alpha: .6, blur: 26),
                  const BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: child),
                  if (number != null)
                    Positioned(
                      left: 10,
                      top: 6,
                      child: Text(
                        '$number',
                        style: iqText(12,
                            weight: FontWeight.w900,
                            color: LumoVisualTokens.muted.withValues(alpha: .85)),
                      ),
                    ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: duration,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: LumoVisualTokens.cyanBright,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 16, color: LumoVisualTokens.night),
                      ),
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
}

/// Wie viele Spalten für [count] Antwortkarten in [width] passen, ohne dass
/// eine Karte schmaler als [minItem] wird. Bevorzugt wird eine volle Reihe,
/// sonst 2×2, 3+2 oder 3+3.
int iqOptionColumns(
  int count,
  double width, {
  required double gap,
  required double minItem,
}) {
  final choices = switch (count) {
    <= 2 => [count],
    3 => [3, 2],
    4 => [4, 2],
    5 => [5, 3, 2],
    6 => [6, 3, 2],
    _ => [count, 4, 3, 2],
  };
  for (final columns in choices) {
    if ((width - (columns - 1) * gap) / columns >= minItem) return columns;
  }
  return choices.last;
}

/// Ordnet Antwortkarten gleich groß und mittig an (2×2, 3+2, 3+3 …).
class IqOptionGrid extends StatelessWidget {
  const IqOptionGrid({
    super.key,
    required this.count,
    required this.itemBuilder,
    this.aspectRatio = 1,
    this.maxItemWidth = 156,
    this.minItemWidth = 110,
    this.gap = 12,
  });

  final int count;
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// Breite durch Höhe einer Karte.
  final double aspectRatio;
  final double maxItemWidth;
  final double minItemWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final width = c.maxWidth.isFinite ? c.maxWidth : 360.0;
        final columns =
            iqOptionColumns(count, width, gap: gap, minItem: minItemWidth);
        final item = math.min(maxItemWidth, (width - (columns - 1) * gap) / columns);
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < count; i++)
                SizedBox(
                  key: ValueKey('iq-option-$i'),
                  width: item,
                  height: item / aspectRatio,
                  child: itemBuilder(context, i),
                ),
            ],
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Rätselbilder
// ---------------------------------------------------------------------------

/// Eine Figur in einer Glas-Kachel.
class IqFigureTile extends StatelessWidget {
  const IqFigureTile(
    this.figure, {
    super.key,
    this.highlighted = false,
    this.accent = LumoVisualTokens.cyan,
    this.semanticLabel,
  });

  final IqFigure figure;
  final bool highlighted;
  final Color accent;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel ?? figure.describe(),
        image: true,
        excludeSemantics: true,
        child: IqTile(
          accent: accent,
          highlighted: highlighted,
          padding: const EdgeInsets.all(5),
          child: IqFigureView(figure),
        ),
      );
}

/// Muster-Matrix: 2×2 oder 3×3 Felder, ein Feld ist gesucht.
class IqMatrixBoard extends StatelessWidget {
  const IqMatrixBoard({
    super.key,
    required this.puzzle,
    this.preview,
    this.previewId,
    this.maxTile = 104,
  });

  final IqMatrixPuzzle puzzle;

  /// Antwort, die im gesuchten Feld gezeigt wird (markierte oder richtige).
  final IqFigure? preview;
  final Object? previewId;
  final double maxTile;

  @override
  Widget build(BuildContext context) {
    final n = puzzle.columns;
    const gap = 8.0;
    return LayoutBuilder(builder: (context, c) {
      var tile = (c.maxWidth - gap * (n - 1)) / n;
      tile = math.min(tile, n == 2 ? maxTile * 1.2 : maxTile);
      if (c.hasBoundedHeight) {
        tile = math.min(tile, (c.maxHeight - gap * (n - 1)) / n);
      }
      tile = math.max(tile, 28);
      final cells = <Widget>[];
      for (var r = 0; r < n; r++) {
        cells.add(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var col = 0; col < n; col++) ...[
              if (col > 0) const SizedBox(width: gap),
              SizedBox.square(
                dimension: tile,
                child: _cell(puzzle.cells[r * n + col], r, col),
              ),
            ],
          ],
        ));
        if (r < n - 1) cells.add(const SizedBox(height: gap));
      }
      return Semantics(
        container: true,
        label: 'Raster mit $n mal $n Feldern',
        child: Center(
          heightFactor: 1,
          child: Column(mainAxisSize: MainAxisSize.min, children: cells),
        ),
      );
    });
  }

  Widget _cell(IqFigure? figure, int row, int col) {
    final place = 'Reihe ${row + 1}, Spalte ${col + 1}';
    if (figure != null) {
      return IqFigureTile(figure, semanticLabel: '$place: ${figure.describe()}');
    }
    final shown = preview;
    return Semantics(
      label: shown == null ? '$place: gesuchtes Feld' : '$place: ${shown.describe()}',
      excludeSemantics: true,
      child: IqQuestionTile(
        preview: shown == null ? null : IqFigureView(shown),
        previewId: previewId,
      ),
    );
  }
}

/// Teilt [count] Felder so auf Reihen auf, dass sie nicht zu klein werden.
({int perRow, double tile}) iqRowLayout({
  required int count,
  required double width,
  required double connector,
  required double minTile,
  required double maxTile,
}) {
  final oneRow = (width - (count - 1) * connector) / count;
  final perRow = oneRow >= minTile ? count : (count + 1) ~/ 2;
  final tile = math.min(maxTile, (width - (perRow - 1) * connector) / perRow);
  return (perRow: perRow, tile: tile);
}

Widget _connector(double width) => SizedBox(
      width: width,
      child: Icon(Icons.chevron_right_rounded,
          size: 18, color: LumoVisualTokens.cyan.withValues(alpha: .65)),
    );

/// Zeichnet [items] in Reihen mit kleinen Pfeilen dazwischen.
Widget _flowRows(List<Widget> items, int perRow, double connector, double rowGap) {
  final rows = <Widget>[];
  for (var start = 0; start < items.length; start += perRow) {
    final end = math.min(start + perRow, items.length);
    rows.add(Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = start; i < end; i++) ...[
          if (i > start) _connector(connector),
          items[i],
        ],
      ],
    ));
    if (end < items.length) rows.add(SizedBox(height: rowGap));
  }
  return Column(mainAxisSize: MainAxisSize.min, children: rows);
}

/// Figurenfolge: die gezeigten Figuren und ein gesuchtes Feld am Ende.
class IqSeriesBoard extends StatelessWidget {
  const IqSeriesBoard({
    super.key,
    required this.puzzle,
    this.preview,
    this.previewId,
    this.maxTile = 92,
  });

  final IqSeriesPuzzle puzzle;
  final IqFigure? preview;
  final Object? previewId;
  final double maxTile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const connector = 18.0;
        final count = puzzle.shown.length + 1;
        final layout = iqRowLayout(
          count: count,
          width: c.maxWidth,
          connector: connector,
          minTile: 62,
          maxTile: maxTile,
        );
        Widget tile(Widget child) =>
            SizedBox.square(dimension: layout.tile, child: child);
        final shown = preview;
        final items = <Widget>[
          for (var i = 0; i < puzzle.shown.length; i++)
            tile(IqFigureTile(puzzle.shown[i],
                semanticLabel: 'Schritt ${i + 1}: ${puzzle.shown[i].describe()}')),
          tile(Semantics(
            label: shown == null
                ? 'Schritt $count: gesucht'
                : 'Schritt $count: ${shown.describe()}',
            excludeSemantics: true,
            child: IqQuestionTile(
              preview: shown == null ? null : IqFigureView(shown),
              previewId: previewId,
            ),
          )),
        ];
        return Semantics(
          container: true,
          label: 'Folge aus ${puzzle.shown.length} Figuren',
          child: Center(
            heightFactor: 1,
            child: _flowRows(items, layout.perRow, connector, 10),
          ),
        );
      });
}

/// Zahlenrätsel: leuchtende Blasen, eine Zahl fehlt.
class IqNumberBoard extends StatelessWidget {
  const IqNumberBoard({
    super.key,
    required this.puzzle,
    this.fill,
    this.maxBubble = 66,
  });

  final IqNumberPuzzle puzzle;

  /// Zahl, die in die Lücke kommt (markierte oder richtige Antwort).
  final int? fill;
  final double maxBubble;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const connector = 16.0;
        final layout = iqRowLayout(
          count: puzzle.numbers.length,
          width: c.maxWidth,
          connector: connector,
          minTile: 52,
          maxTile: maxBubble,
        );
        final items = <Widget>[
          for (final number in puzzle.numbers)
            if (number != null)
              IqNumberBubble(number: number, size: layout.tile)
            else if (fill != null)
              IqNumberBubble(
                number: fill,
                size: layout.tile,
                highlighted: true,
              )
            else
              IqNumberBubble(size: layout.tile),
        ];
        final spoken = puzzle.numbers.map((n) => n == null ? 'gesucht' : '$n').join(', ');
        return Semantics(
          container: true,
          label: 'Zahlenfolge: $spoken',
          excludeSemantics: true,
          child: Center(
            heightFactor: 1,
            child: _flowRows(items, layout.perRow, connector, 12),
          ),
        );
      });
}

/// Drehrätsel: das Bauteil, das im Kopf gedreht werden soll.
class IqRotationBoard extends StatelessWidget {
  const IqRotationBoard({super.key, required this.puzzle, this.maxSide = 220});

  final IqRotationPuzzle puzzle;
  final double maxSide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final side = math.min(maxSide, c.maxWidth);
        final span = iqPieceSpan(puzzle);
        return Center(
          child: SizedBox(
            width: side,
            height: side * .82,
            child: Semantics(
              label: 'Bauteil aus ${puzzle.target.cells.length} Blöcken, '
                  'das du drehen sollst',
              excludeSemantics: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IqTile(
                    radius: 24,
                    accent: iqTintColors(puzzle.tint).base,
                    padding: EdgeInsets.all(side * .06),
                    child: IqPolyominoView(puzzle.target, puzzle.tint, span: span),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xCC0B2B58),
                        border: Border.all(
                            color: LumoVisualTokens.cyanBright.withValues(alpha: .8)),
                      ),
                      child: const Icon(Icons.rotate_right_rounded,
                          size: 20, color: LumoVisualTokens.cyanBright),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Antworten je Rätselart
// ---------------------------------------------------------------------------

/// Inhalt einer Antwortkarte.
Widget iqOptionContent(IqChoicePuzzle puzzle, int index) {
  switch (puzzle) {
    case IqMatrixPuzzle p:
      return IqFigureView(p.options[index]);
    case IqSeriesPuzzle p:
      return IqFigureView(p.options[index]);
    case IqOddOnePuzzle p:
      return IqFigureView(p.figures[index]);
    case IqRotationPuzzle p:
      return IqPolyominoView(p.options[index], p.tint, span: iqPieceSpan(p));
    case IqNumberPuzzle p:
      return LayoutBuilder(
        builder: (context, c) => Center(
          child: IqNumberBubble(
            number: p.options[index],
            size: math.min(c.maxWidth, c.maxHeight) * .86,
          ),
        ),
      );
  }
}

/// Seitenverhältnis der Antwortkarten: Zahlen liegen breiter.
double iqOptionAspect(IqChoicePuzzle puzzle) => puzzle is IqNumberPuzzle ? 1.45 : 1;

/// Vorschau der markierten Antwort als Figur (für Matrix und Folge).
IqFigure? iqSelectedFigure(IqChoicePuzzle puzzle, int? selected) {
  if (selected == null) return null;
  return switch (puzzle) {
    IqMatrixPuzzle p => p.options[selected],
    IqSeriesPuzzle p => p.options[selected],
    _ => null,
  };
}

// ---------------------------------------------------------------------------
// Lösungen (Rückblick)
// ---------------------------------------------------------------------------

/// Die richtige Lösung eines Rätsels, klein gezeichnet. Auf breiten
/// Bildschirmen (Fold, Tablet) etwas größer.
class IqSolutionView extends StatelessWidget {
  const IqSolutionView(this.puzzle, {super.key, this.scale});

  final IqPuzzle puzzle;
  final double? scale;

  @override
  Widget build(BuildContext context) {
    final k = scale ?? (MediaQuery.sizeOf(context).width >= 600 ? 1.35 : 1.0);
    switch (puzzle) {
      case IqMatrixPuzzle p:
        return IqMatrixBoard(puzzle: p, preview: p.options[p.answer], maxTile: 62 * k);
      case IqSeriesPuzzle p:
        return IqSeriesBoard(puzzle: p, preview: p.options[p.answer], maxTile: 62 * k);
      case IqNumberPuzzle p:
        return IqNumberBoard(
            puzzle: p, fill: p.options[p.answer], maxBubble: 50 * k);
      case IqOddOnePuzzle p:
        return _OddSolution(puzzle: p, maxTile: 70 * k);
      case IqRotationPuzzle p:
        return _RotationSolution(puzzle: p, maxTile: 104 * k);
      case IqMemoryPuzzle p:
        return IqMemoryOrder(puzzle: p, maxSide: 220 * k);
    }
  }
}

class _OddSolution extends StatelessWidget {
  const _OddSolution({required this.puzzle, required this.maxTile});

  final IqOddOnePuzzle puzzle;
  final double maxTile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 8.0;
        final n = puzzle.figures.length;
        final tile = math.min(maxTile, (c.maxWidth - gap * (n - 1)) / n);
        return Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            runSpacing: gap,
            children: [
              for (var i = 0; i < n; i++)
                SizedBox.square(
                  dimension: tile,
                  child: Semantics(
                    label: i == puzzle.answer
                        ? '${puzzle.figures[i].describe()}: passt nicht dazu'
                        : puzzle.figures[i].describe(),
                    excludeSemantics: true,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        IqTile(
                          radius: 14,
                          accent: i == puzzle.answer
                              ? LumoVisualTokens.gold
                              : LumoVisualTokens.cyan,
                          highlighted: i == puzzle.answer,
                          padding: const EdgeInsets.all(4),
                          child: IqFigureView(puzzle.figures[i]),
                        ),
                        if (i == puzzle.answer)
                          const Positioned(
                            right: -4,
                            top: -4,
                            child: _Flag(),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      });
}

class _Flag extends StatelessWidget {
  const _Flag();

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: LumoVisualTokens.gold,
        ),
        child: const Icon(Icons.priority_high_rounded,
            size: 16, color: Color(0xFF3A2A00)),
      );
}

class _RotationSolution extends StatelessWidget {
  const _RotationSolution({required this.puzzle, required this.maxTile});

  final IqRotationPuzzle puzzle;
  final double maxTile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final span = iqPieceSpan(puzzle);
        final tile = math.min(maxTile, (c.maxWidth - 56) / 2);
        Widget piece(IqPolyomino p, {bool highlighted = false}) => SizedBox.square(
              dimension: tile,
              child: IqTile(
                radius: 18,
                accent: highlighted
                    ? LumoVisualTokens.gold
                    : iqTintColors(puzzle.tint).base,
                highlighted: highlighted,
                padding: const EdgeInsets.all(6),
                child: IqPolyominoView(p, puzzle.tint, span: span),
              ),
            );
        return Semantics(
          label: 'Das gesuchte Bauteil ist das Bauteil '
              '${puzzle.answer + 1}, nur gedreht',
          excludeSemantics: true,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                piece(puzzle.target),
                SizedBox(
                  width: 56,
                  child: Icon(Icons.rotate_right_rounded,
                      size: 28,
                      color: LumoVisualTokens.cyanBright.withValues(alpha: .9)),
                ),
                piece(puzzle.options[puzzle.answer], highlighted: true),
              ],
            ),
          ),
        );
      });
}

// ---------------------------------------------------------------------------
// Merk-Blitz: gezeigte Reihenfolge (ruhend)
// ---------------------------------------------------------------------------

/// Farben, in denen die Felder aufleuchten (Lumos Farben).
const iqFlashColors = <Color>[
  LumoVisualTokens.cyanBright,
  Color(0xFFFF9A3D),
  LumoVisualTokens.gold,
];

/// Eine Merk-Kachel aus Glas. Leuchtet, wenn [lit] gesetzt ist.
class IqMemoryTile extends StatelessWidget {
  const IqMemoryTile({
    super.key,
    required this.lit,
    this.badge,
    this.marked = false,
    this.litColor = LumoVisualTokens.cyanBright,
    this.radius = 16,
  });

  final bool lit;

  /// Schon angetippt (ohne aufzuleuchten): hellerer Rand.
  final bool marked;

  /// Nummer des Tippens (1, 2, 3 …).
  final int? badge;
  final Color litColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final reduced = LumoMotion.reduced(context);
    return AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: lit
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(litColor, Colors.white, .5)!,
                  litColor,
                  Color.lerp(litColor, const Color(0xFF0B1D45), .3)!,
                ],
              )
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: marked
                    ? const [Color(0xF5236FB4), Color(0xF510427F)]
                    : const [Color(0xF51C4E83), Color(0xF70B2B55)],
              ),
        border: Border.all(
          color: lit
              ? Colors.white.withValues(alpha: .9)
              : marked
                  ? LumoVisualTokens.cyanBright
                  : LumoVisualTokens.cyan.withValues(alpha: .3),
          width: lit ? 1.8 : (marked ? 2 : 1.1),
        ),
        boxShadow: [
          if (lit) ...iqGlow(litColor, alpha: .75, blur: 30),
          if (marked && !lit) ...iqGlow(LumoVisualTokens.cyanBright, alpha: .35, blur: 16),
          const BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radius - 1),
            child: Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                heightFactor: .45,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: lit ? .5 : .10),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (badge != null)
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '$badge',
                    style: iqText(
                      26,
                      weight: FontWeight.w900,
                      color: lit ? const Color(0xFF0B2A52) : LumoVisualTokens.white,
                      shadows: lit
                          ? null
                          : const [Shadow(color: Color(0x88031230), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Raster aus Merk-Kacheln, in dem die richtige Reihenfolge nummeriert ist.
class IqMemoryOrder extends StatelessWidget {
  const IqMemoryOrder({super.key, required this.puzzle, this.maxSide = 220});

  final IqMemoryPuzzle puzzle;
  final double maxSide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final side = math.min(maxSide, c.maxWidth);
        final n = puzzle.gridSize;
        const gap = 6.0;
        final tile = (side - gap * (n - 1)) / n;
        return Semantics(
          label: 'Richtige Reihenfolge: ${puzzle.describeExpected()}',
          excludeSemantics: true,
          child: Center(
            child: SizedBox(
              width: side,
              height: side,
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
                              child: _orderTile(r * n + col),
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

  Widget _orderTile(int cell) {
    final step = puzzle.sequence.indexOf(cell);
    return IqMemoryTile(
      lit: step >= 0,
      litColor: iqFlashColors[math.max(step, 0) % iqFlashColors.length],
      badge: step >= 0 ? step + 1 : null,
      radius: 12,
    );
  }
}
