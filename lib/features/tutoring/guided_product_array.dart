import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';
import '../../widgets/design/lumo_learning_module_frame.dart';
import '../../widgets/design/lumo_quantity_art.dart';

class GuidedProductArray extends StatefulWidget {
  const GuidedProductArray({
    super.key,
    required this.rows,
    required this.columns,
    this.example = false,
    this.practice = false,
    required this.reduceMotion,
  });

  final int rows;
  final int columns;
  final bool example;
  final bool practice;
  final bool reduceMotion;

  @override
  State<GuidedProductArray> createState() => _GuidedProductArrayState();
}

class _GuidedProductArrayState extends State<GuidedProductArray> {
  bool _turned = false;
  bool _fiveRows = false;
  double _drag = 0;

  void _turn() => setState(() => _turned = !_turned);

  @override
  Widget build(BuildContext context) {
    final example = widget.example;
    final canTurn = example || widget.practice;
    final a = _fiveRows ? 6 : widget.rows;
    final b = _fiveRows ? 7 : widget.columns;
    final anchor = a == 10
        ? 10
        : a >= 5
            ? 5
            : a >= 2
                ? 2
                : 1;
    final rows = _turned ? b : a;
    final columns = _turned ? a : b;
    final duration =
        widget.reduceMotion ? Duration.zero : const Duration(milliseconds: 560);
    const text = TextStyle(
        color: LumoVisualTokens.white,
        fontSize: 17,
        fontWeight: FontWeight.w700);
    return LumoLessonSurface(
      child: Column(children: [
        Text('$rows Reihen mit je $columns Äpfeln',
            style: text, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final extent = math.max(a, b);
          final cell = math.min(38.0, constraints.maxWidth / extent);
          return Semantics(
            image: true,
            label: '$rows Reihen mit je $columns Äpfeln',
            child: GestureDetector(
              onHorizontalDragStart: canTurn ? (_) => _drag = 0 : null,
              onHorizontalDragUpdate:
                  canTurn ? (event) => _drag += event.primaryDelta ?? 0 : null,
              onHorizontalDragEnd: canTurn
                  ? (_) {
                      if (_drag.abs() >= 28) _turn();
                    }
                  : null,
              child: SizedBox(
                width: extent * cell,
                height: (canTurn ? extent : rows) * cell,
                child: Stack(children: [
                  for (var row = 0; row < a; row++)
                    for (var col = 0; col < b; col++)
                      AnimatedPositioned(
                        key: ValueKey('guided-group-apple-$row-$col'),
                        duration: duration,
                        curve: Curves.easeInOut,
                        left: (_turned ? a - 1 - row : col) * cell,
                        top: (_turned ? col : row) * cell,
                        width: cell,
                        height: cell,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                (_fiveRows || widget.practice) && row >= anchor
                                    ? const Color(0xFF815120)
                                    : const Color(0xFF164E70),
                            borderRadius: BorderRadius.circular(cell / 4),
                          ),
                          child: ExcludeSemantics(
                              child: LumoQuantityArt.apple(size: cell - 4)),
                        ),
                      ),
                ]),
              ),
            ),
          );
        }),
        if (widget.practice) ...[
          Text(
              a == anchor
                  ? 'Das ist eine Kernaufgabe. Zähle in Schritten von $b.'
                  : 'Die blauen Reihen ergeben $anchor × $b. Wie viele Äpfel kommen mit den goldenen Reihen dazu?',
              style: text,
              textAlign: TextAlign.center),
          TextButton.icon(
              onPressed: _turn,
              icon: const Icon(Icons.rotate_right),
              label: const Text('Feld drehen')),
        ],
        if (example) ...[
          const SizedBox(height: 8),
          Text(
              _fiveRows
                  ? '5 × 7 + 7 = 35 + 7 = 42'
                  : '${List.filled(rows, "$columns").join(" + ")} = ${a * b}',
              style: text,
              textAlign: TextAlign.center),
          Text('$rows × $columns = ${a * b}', style: text),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            TextButton.icon(
                onPressed: _turn,
                icon: const Icon(Icons.rotate_right),
                label: const Text('Feld drehen')),
            TextButton(
              onPressed: () => setState(() {
                _fiveRows = !_fiveRows;
                _turned = false;
              }),
              child: Text(_fiveRows
                  ? 'Zur ersten Aufgabe'
                  : '6 × 7 mit der Fünferreihe'),
            ),
          ]),
        ],
      ]),
    );
  }
}
