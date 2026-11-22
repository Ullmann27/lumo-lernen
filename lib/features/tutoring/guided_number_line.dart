import 'package:flutter/material.dart';

/// The child moves one marker from the starting number to ten and then beyond.
/// A swipe chooses a tick. The buttons offer the same steps without precise tapping.
class GuidedNumberLine extends StatefulWidget {
  const GuidedNumberLine(
      {super.key,
      required this.start,
      required this.change,
      required this.reduceMotion});
  final int start;
  final int change;
  final bool reduceMotion;

  @override
  State<GuidedNumberLine> createState() => _GuidedNumberLineState();
}

class _GuidedNumberLineState extends State<GuidedNumberLine> {
  int _phase = 0;
  String? _hint;
  int? _selection;

  int get _end => widget.start + widget.change;
  List<int> get _stops {
    final start = widget.start;
    final anchors = widget.change < 0 ? [10, 15, 5] : [10, 5, 15];
    for (final anchor in anchors) {
      if ((start < anchor && anchor < _end) ||
          (start > anchor && anchor > _end)) {
        return [start, anchor, _end];
      }
    }
    return [start, _end];
  }

  bool get _finished => _phase == _stops.length - 1;
  int get _current => _stops[_phase];
  int get _next => _finished ? _current : _stops[_phase + 1];
  void _choose(int value) {
    if (_finished) return;
    setState(() {
      if (value == _next) {
        _phase++;
        _hint = null;
        _selection = null;
      } else {
        _hint = _phase == 0 && _stops.length == 3
            ? 'Suche zuerst die $_next.'
            : 'Gehe von $_current noch ${(_next - _current).abs()} Schritte ${widget.change.isNegative ? "zurück" : "weiter"}.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const low = 0;
    const high = 20;
    final direction = widget.change.isNegative ? 'zurück' : 'vor';
    final count = (_next - _current).abs();
    return Column(children: [
      Text(
          !_finished
              ? 'Von $_current um $count $direction'
              : '${widget.start} ${widget.change.isNegative ? "−" : "+"} ${widget.change.abs()} = $_end',
          style: Theme.of(context).textTheme.titleMedium),
      LayoutBuilder(builder: (context, constraints) {
        const inset = 16.0;
        final spacing = (constraints.maxWidth - 2 * inset) / (high - low);
        int tick(double dx) =>
            (low + ((dx - inset) / spacing).round()).clamp(low, high);
        return Semantics(
            label: 'Zahlenstrahl von $low bis $high. Figur auf $_current.',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (event) => _choose(tick(event.localPosition.dx)),
              onHorizontalDragEnd: (event) =>
                  _choose(tick(event.localPosition.dx)),
              child: SizedBox(
                  height: 70,
                  child: Stack(children: [
                    Positioned(
                        left: inset,
                        right: inset,
                        top: 38,
                        child: Container(
                            height: 2, color: Colors.lightBlueAccent)),
                    for (int n = low; n <= high; n++)
                      Positioned(
                          left: (n - low) * spacing,
                          width: 2 * inset,
                          top: 33,
                          child: Column(children: [
                            Container(
                                width: 2,
                                height: 12,
                                color: n == 10
                                    ? Colors.amber
                                    : Colors.lightBlueAccent),
                            if (n == low ||
                                n == high ||
                                n == 10 ||
                                spacing >= 22)
                              Text('$n'),
                          ])),
                    AnimatedPositioned(
                        key: const ValueKey('number-line-marker'),
                        top: 5,
                        left: ((_selection ?? _current) - low) * spacing,
                        width: 2 * inset,
                        duration: widget.reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 550),
                        curve: Curves.easeInOut,
                        child:
                            const Icon(Icons.location_on, color: Colors.amber)),
                  ])),
            ));
      }),
      if (_finished)
        Text(
            'Probe: $_end ${widget.change.isNegative ? "+" : "−"} ${widget.change.abs()} = ${widget.start}'),
      if (_hint != null) Text(_hint!, textAlign: TextAlign.center),
      if (!_finished)
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              tooltip: 'Einen Schritt zurück',
              onPressed: (_selection ?? _current) <= low
                  ? null
                  : () => setState(() {
                        _selection = (_selection ?? _current) - 1;
                      }),
              icon: const Icon(Icons.remove)),
          TextButton(
              onPressed: () => _choose(_selection ?? _current),
              child: Text('${_selection ?? _current} prüfen')),
          IconButton(
              tooltip: 'Einen Schritt vor',
              onPressed: (_selection ?? _current) >= high
                  ? null
                  : () => setState(() {
                        _selection = (_selection ?? _current) + 1;
                      }),
              icon: const Icon(Icons.add)),
        ])
      else
        TextButton(
            onPressed: () => setState(() {
                  _phase = 0;
                  _hint = null;
                }),
            child: const Text('Noch einmal springen')),
    ]);
  }
}
