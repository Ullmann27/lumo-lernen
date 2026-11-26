/// A named observation. A missing observation has no numeric value.
typedef BarChartEntry = ({String label, int? value});

class DataChartExercise {
  const DataChartExercise({
    required this.rows,
    required this.requestedRow,
    required this.pictogram,
    required this.horizontal,
  });

  static const maxCount = 5;
  final List<BarChartEntry> rows;
  final int requestedRow;
  final bool pictogram;
  final bool horizontal;

  BarChartEntry get requested => rows[requestedRow];
  String get sourceName => pictogram ? 'Bilddiagramm' : 'Tabelle';
  String get targetName => horizontal ? 'Balken' : 'Säule';
}
