/// A named observation. A missing observation has no numeric value.
typedef BarChartEntry = ({String label, int? value});

class DataChartExercise {
  const DataChartExercise({
    required this.rows,
    required this.requestedRow,
    required this.pictogram,
    required this.horizontal,
    this.tallyToTable = false,
  });

  static const maxCount = 5;
  final List<BarChartEntry> rows;
  final int requestedRow;
  final bool pictogram;
  final bool horizontal;
  final bool tallyToTable;

  BarChartEntry get requested => rows[requestedRow];
  String get sourceName => tallyToTable
      ? 'Strichliste'
      : pictogram
          ? 'Bilddiagramm'
          : 'Tabelle';
  String get targetName => horizontal ? 'Balken' : 'Säule';
}
