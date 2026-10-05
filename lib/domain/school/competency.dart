/// Ordnet eine Aufgabe einer feinen Kompetenz zu. Aus „Plus bis 20“ wird bei
/// der Aufgabe `8 + 5` die Kompetenz „Addition mit Zehnerübergang“.
/// Ohne erkennbare Rechnung bleibt es beim Themennamen.
class CompetencyClassifier {
  const CompetencyClassifier();

  static final RegExp _calc =
      RegExp(r'(\d+)\s*([+\-−–×x·*:÷])\s*(\d+)');

  String classify({
    required String subject,
    required String unit,
    String prompt = '',
  }) {
    if (subject == 'Mathematik') {
      final m = _calc.firstMatch(prompt);
      if (m != null) {
        final a = int.parse(m.group(1)!);
        final op = m.group(2)!;
        final b = int.parse(m.group(3)!);
        switch (op) {
          case '+':
            return (a % 10) + (b % 10) >= 10
                ? 'Addition mit Zehnerübergang'
                : 'Addition ohne Zehnerübergang';
          case '-':
          case '−':
          case '–':
            return (a % 10) < (b % 10)
                ? 'Subtraktion mit Zehnerübergang'
                : 'Subtraktion ohne Zehnerübergang';
          case '×':
          case 'x':
          case '·':
          case '*':
            return 'Einmaleins';
          case ':':
          case '÷':
            return 'Division';
        }
      }
    }
    final clean = unit.trim();
    return clean.isEmpty ? subject : clean;
  }
}
