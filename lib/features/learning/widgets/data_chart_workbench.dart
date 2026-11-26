import 'package:flutter/material.dart';

import '../../../core/data_chart_exercise.dart';
import '../../../widgets/design/lumo_motion.dart';

const _ink = Color(0xFF123B52);
const _fill = Color(0xFF086C82);
const _active = Color(0xFFAB5A13);
const _strong = TextStyle(fontWeight: FontWeight.w900, color: _ink);
const _card = BoxDecoration(
  color: Color(0xFFF2FAFA),
  borderRadius: BorderRadius.all(Radius.circular(18)),
);

class DataChartObservations extends StatelessWidget {
  const DataChartObservations({super.key, required this.exercise});

  final DataChartExercise exercise;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
              header: true, child: Text(exercise.sourceName, style: _strong)),
          if (exercise.pictogram)
            const Text('1 Kästchen steht für 1 Stück.',
                style: TextStyle(color: _ink)),
          const SizedBox(height: 6),
          for (final row in exercise.rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(child: Text(row.label, style: _strong)),
                  if (exercise.pictogram && (row.value ?? 0) > 0)
                    Semantics(
                      label: '${row.value} Kästchen',
                      excludeSemantics: true,
                      child: Row(children: [
                        for (var i = 0; i < row.value!; i++)
                          const Padding(
                            padding: EdgeInsets.only(left: 3),
                            child: SizedBox(
                                width: 12,
                                height: 12,
                                child: ColoredBox(color: _fill)),
                          ),
                      ]),
                    )
                  else
                    Text(row.value?.toString() ?? 'Fehlt',
                        key: ValueKey('data-observation-${row.label}'),
                        style: _strong),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Draft chart values stay in this view. Only an explicit submission is an answer.
class DataChartAnswer extends StatefulWidget {
  const DataChartAnswer({
    super.key,
    required this.exercise,
    required this.enabled,
    required this.rejectedValues,
    required this.onSubmit,
  });

  final DataChartExercise exercise;
  final bool enabled;
  final Set<String> rejectedValues;
  final ValueChanged<int> onSubmit;

  @override
  State<DataChartAnswer> createState() => _DataChartAnswerState();
}

class _DataChartAnswerState extends State<DataChartAnswer> {
  int? _draft;

  void _setDraft(int value) => setState(() => _draft = value);

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final draft = _draft;
    final current = draft ?? 0;
    final quiet = LumoMotion.reduced(context);
    return Container(
      decoration: _card,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
                exercise.horizontal ? 'Balkendiagramm' : 'Säulendiagramm',
                style: _strong),
          ),
          const SizedBox(height: 8),
          if (exercise.horizontal)
            Column(children: [
              for (var i = 0; i < exercise.rows.length; i++) _series(i, quiet),
            ])
          else
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < exercise.rows.length; i++)
                Expanded(child: _series(i, quiet)),
            ]),
          const SizedBox(height: 10),
          Text(
              'Dein Eintrag für ${exercise.requested.label}: ${draft ?? 'offen'}',
              key: const ValueKey('data-chart-draft'),
              style: _strong),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            IconButton.outlined(
              key: const ValueKey('data-chart-remove'),
              tooltip: 'Ein Kästchen wegnehmen',
              onPressed: widget.enabled && current > 0
                  ? () => _setDraft(current - 1)
                  : null,
              style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _ink),
              icon: const Icon(Icons.remove),
            ),
            IconButton.outlined(
              key: const ValueKey('data-chart-add'),
              tooltip: 'Ein Kästchen hinzufügen',
              onPressed: widget.enabled && current < DataChartExercise.maxCount
                  ? () => _setDraft(current + 1)
                  : null,
              style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _ink),
              icon: const Icon(Icons.add),
            ),
            OutlinedButton(
              key: const ValueKey('data-chart-zero'),
              onPressed:
                  widget.enabled && draft != 0 ? () => _setDraft(0) : null,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48), foregroundColor: _ink),
              child: const Text('Null eintragen'),
            ),
          ]),
          const SizedBox(height: 6),
          FilledButton(
            key: const ValueKey('data-chart-submit'),
            onPressed: widget.enabled &&
                    draft != null &&
                    !widget.rejectedValues.contains('$draft')
                ? () => widget.onSubmit(draft)
                : null,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48), backgroundColor: _fill),
            child: const Text('Eintrag prüfen'),
          ),
        ],
      ),
    );
  }

  Widget _series(int index, bool quiet) {
    final exercise = widget.exercise;
    final row = exercise.rows[index];
    final active = index == exercise.requestedRow;
    final value = active ? _draft : row.value;
    final title = Text(row.label,
        style: _strong, textAlign: TextAlign.center, maxLines: 2);
    final amount =
        Text(value?.toString() ?? (active ? 'offen' : 'Fehlt'), style: _strong);
    final cells = <Widget>[
      for (var position = 0; position < DataChartExercise.maxCount; position++)
        AnimatedContainer(
          key: ValueKey(
              'data-chart-$index-$position-${(value ?? 0) > position}'),
          duration: quiet ? Duration.zero : const Duration(milliseconds: 130),
          width: exercise.horizontal ? 13 : 22,
          height: exercise.horizontal ? 22 : 13,
          color: (value ?? 0) > position
              ? (active ? _active : _fill)
              : const Color(0xFFE3ECEE),
        ),
    ];
    if (exercise.horizontal) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: title),
          const SizedBox(width: 8),
          const SizedBox(width: 2, height: 22, child: ColoredBox(color: _ink)),
          ...cells,
          const SizedBox(width: 6),
          Expanded(child: amount),
        ]),
      );
    }
    return Column(children: [
      amount,
      ...cells.reversed,
      const SizedBox(
          width: double.infinity, height: 2, child: ColoredBox(color: _ink)),
      const SizedBox(height: 3),
      SizedBox(
        height: MediaQuery.textScalerOf(context).scale(14) * 2.7,
        child: title,
      ),
    ]);
  }
}
