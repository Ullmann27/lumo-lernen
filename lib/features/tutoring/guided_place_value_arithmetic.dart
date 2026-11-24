import 'package:flutter/material.dart';

/// Voluntary, offline intermediate steps; the original task owns its final
/// answer, rewards and score. No new profile or persistence is introduced.
class GuidedPlaceValueArithmetic extends StatefulWidget {
  const GuidedPlaceValueArithmetic({
    super.key,
    required this.left,
    required this.right,
    required this.subtract,
  }) : assert(left >= 0 && left <= 100),
       assert(right > 0 && right <= 100),
       assert(subtract ? left >= right : left + right <= 100);

  final int left;
  final int right;
  final bool subtract;

  @override
  State<GuidedPlaceValueArithmetic> createState() =>
      _GuidedPlaceValueArithmeticState();
}

class _GuidedPlaceValueArithmeticState
    extends State<GuidedPlaceValueArithmetic> {
  int _phase = 0;
  bool _retry = false;

  int get _direction => widget.subtract ? -1 : 1;
  int get _end => widget.left + _direction * widget.right;

  /// Whole tens first, then the next ten if needed. The result is never
  /// offered as an intermediate choice.
  List<int> get _stops {
    final stops = <int>[widget.left];
    final tens = widget.right ~/ 10 * 10;
    final afterTens = widget.left + _direction * tens;
    if (afterTens != widget.left && afterTens != _end) {
      stops.add(afterTens);
    }
    final current = stops.last;
    final anchor = widget.subtract
        ? (current - 1) ~/ 10 * 10
        : (current ~/ 10 + 1) * 10;
    if (widget.subtract
        ? anchor < current && anchor > _end
        : anchor > current && anchor < _end) {
      stops.add(anchor);
    }
    return stops;
  }

  List<int> _choices(int target) {
    final values = <int>{target};
    for (final offset in [-10, 10, -1, 1, -2, 2]) {
      final value = target + offset;
      if (value >= 0 && value <= 100 && value != _end) values.add(value);
      if (values.length == 3) break;
    }
    return values.toList()..sort();
  }

  @override
  void didUpdateWidget(covariant GuidedPlaceValueArithmetic oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.left != widget.left || oldWidget.right != widget.right ||
        oldWidget.subtract != widget.subtract) {
      _phase = 0;
      _retry = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;
    final current = stops[_phase];
    final finalStep = _phase == stops.length - 1;
    final target = finalStep ? _end : stops[_phase + 1];
    final change = (target - current).abs();
    final op = widget.subtract ? '−' : '+';
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('guided-place-value-arithmetic'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Lumo · Zehnerwerkstatt', textAlign: TextAlign.center),
        Text(
          'Zerlege ${widget.right} in ${widget.right ~/ 10 * 10} und ${widget.right % 10}.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Semantics(
          label: '${current ~/ 10} Zehner und ${current % 10} Einer',
          child: ExcludeSemantics(
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                for (var i = 0; i < current ~/ 10; i++)
                  Container(
                    width: 16,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.onPrimaryContainer),
                      borderRadius: BorderRadius.circular(4),
                      color: scheme.primaryContainer,
                    ),
                    child: Column(children: [
                      for (var j = 0; j < 10; j++)
                        Expanded(child: Container(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(
                              color: scheme.onPrimaryContainer,
                              width: 0.5,
                            )),
                          ),
                        )),
                    ]),
                  ),
                for (var i = 0; i < current % 10; i++)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      border: Border.all(color: scheme.onTertiaryContainer),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$current $op $change = ?',
          key: const ValueKey('place-value-intermediate'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (finalStep)
          const Text(
            'Den letzten Schritt rechnest du selbst. Trage die Lösung bei deiner Aufgabe ein.',
            textAlign: TextAlign.center,
          )
        else
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final choice in _choices(target))
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  key: ValueKey('place-value-choice-$choice'),
                  onPressed: () => setState(() {
                    if (choice == target) {
                      _phase++;
                      _retry = false;
                    } else {
                      _retry = true;
                    }
                  }),
                  child: Text('$choice'),
                ),
            ],
          ),
        if (_retry)
          const Text(
            'Zähle die Zehner und Einer noch einmal getrennt.',
            textAlign: TextAlign.center,
          ),
        if (_phase > 0)
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => setState(() {
              _phase = 0;
              _retry = false;
            }),
            child: const Text('Noch einmal erklären'),
          ),
      ],
    );
  }
}
