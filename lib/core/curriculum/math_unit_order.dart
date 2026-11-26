/// Fixed, teacher-recognisable order for the Mathematik register.
///
/// The generator lists units in template order, which put "Textaufgaben"
/// before "Plus bis 10". Children and teachers expect the school book order:
/// first numbers, then plus/minus in growing number ranges, then times
/// tables, sizes, shapes and finally puzzles and word problems. Every unit
/// keeps its exact generator name; only order and group headings change.
class MathUnitOrder {
  const MathUnitOrder._();

  static const String numbers = 'Zahlen verstehen';
  static const String plusMinus = 'Plus und Minus';
  static const String timesDivide = 'Mal und Geteilt';
  static const String written = 'Schriftlich rechnen';
  static const String fractions = 'Brüche';
  static const String sizes = 'Geld, Zeit und Größen';
  static const String shapes = 'Formen und Geometrie';
  static const String puzzles = 'Sachaufgaben und Daten';

  /// Group headings in display order.
  static const List<String> groups = <String>[
    numbers,
    plusMinus,
    timesDivide,
    written,
    fractions,
    sizes,
    shapes,
    puzzles,
  ];

  static const List<(String, String)> _ordered = <(String, String)>[
    ('Mengenvergleich', numbers),
    ('Zahl in Worten', numbers),
    ('Zahlenstrahl', numbers),
    ('Nachbarzahlen', numbers),
    ('Zahlenreihe', numbers),
    ('Zahlen zerlegen', numbers),
    ('Größer, kleiner, gleich', numbers),
    ('Vergleichen', numbers),
    ('Zehner und Einer', numbers),
    ('Gerade und ungerade', numbers),
    ('Zahlenraum bis 1 Million', numbers),
    ('Plus bis 10', plusMinus),
    ('Minus bis 10', plusMinus),
    ('Plus bis 20', plusMinus),
    ('Minus bis 20', plusMinus),
    ('Minus ueber 10', plusMinus),
    ('Plus bis 100', plusMinus),
    ('Minus bis 100', plusMinus),
    ('Plus bis 1000', plusMinus),
    ('Minus bis 1000', plusMinus),
    ('Plus bis 10000', plusMinus),
    ('Minus bis 10000', plusMinus),
    ('Verdoppeln und Halbieren', plusMinus),
    ('Rechenhaeuser', plusMinus),
    ('Zahlenmauer', plusMinus),
    ('Einmaleins Vorbereitung', timesDivide),
    ('Einmaleins', timesDivide),
    ('Division einstellig', timesDivide),
    ('Schriftliche Addition', written),
    ('Schriftliche Subtraktion', written),
    ('Schriftliche Multiplikation', written),
    ('Schriftliche Division', written),
    ('Brüche Vorbereitung', fractions),
    ('Bruchrechnen einfach', fractions),
    ('Brüche erweitern', fractions),
    ('Dezimalzahlen', fractions),
    ('Geld', sizes),
    ('Geld wechseln', sizes),
    ('Geld bis 100 Euro', sizes),
    ('Marktstand', sizes),
    ('Zeit', sizes),
    ('Uhrzeit', sizes),
    ('Uhr-Abenteuer', sizes),
    ('Zeit Minuten und Stunden', sizes),
    ('Längen', sizes),
    ('Massen Kilogramm und Gramm', sizes),
    ('Hohlmaße Liter und Milliliter', sizes),
    ('Geometrie Formen', shapes),
    ('Formen Nachzeichnen', shapes),
    ('Symmetrie', shapes),
    ('Symmetrieachsen', shapes),
    ('Umfang', shapes),
    ('Flächeninhalt', shapes),
    ('Textaufgaben', puzzles),
    ('Rechengeschichten', puzzles),
    ('Sachaufgaben zwei Schritte', puzzles),
    ('Sachaufgaben drei Schritte', puzzles),
    ('Platzhalter-Rätsel', puzzles),
    ('Zahlenrätsel', puzzles),
    ('Blitzlicht', puzzles),
    ('Datenwerkstatt', puzzles),
    ('Diagramme lesen', puzzles),
    ('Mittelwert', puzzles),
  ];

  static final Map<String, int> _rank = <String, int>{
    for (var i = 0; i < _ordered.length; i++) _ordered[i].$1: i,
  };
  static final Map<String, String> _group = <String, String>{
    for (final entry in _ordered) entry.$1: entry.$2,
  };

  static const Map<String, String> _examples = <String, String>{
    'Datenwerkstatt': 'Zählwerte als Säulen oder Balken darstellen',
    'Plus bis 10': 'z. B. 4 + 3',
    'Minus bis 10': 'z. B. 9 − 5',
    'Plus bis 20': 'z. B. 8 + 6 · Zehnerübergang',
    'Minus bis 20': 'z. B. 14 − 6 · Zehnerübergang',
    'Plus bis 100': 'z. B. 37 + 25',
    'Minus bis 100': 'z. B. 64 − 28',
    'Plus bis 1000': 'z. B. 345 + 230',
    'Minus bis 1000': 'z. B. 720 − 350',
    'Plus bis 10000': 'z. B. 2400 + 1300',
    'Minus bis 10000': 'z. B. 5600 − 2300',
    'Einmaleins Vorbereitung': 'z. B. 3 + 3 + 3 = 3 · 3',
    'Einmaleins': 'z. B. 6 · 7',
    'Division einstellig': 'z. B. 24 : 6',
    'Zehner und Einer': 'z. B. 47 = 4 Z + 7 E',
    'Verdoppeln und Halbieren': 'z. B. das Doppelte von 8',
  };

  /// Short example shown under the unit title, or null if the title says it.
  static String? exampleOf(String unit) => _examples[unit];

  /// Operation symbol of a calculation unit, used as the card's badge.
  static String? symbolOf(String unit) {
    if (unit.startsWith('Plus bis') || unit == 'Schriftliche Addition') {
      return '+';
    }
    if (unit.startsWith('Minus') || unit == 'Schriftliche Subtraktion') {
      return '−';
    }
    if (unit.startsWith('Einmaleins') ||
        unit == 'Schriftliche Multiplikation') {
      return '·';
    }
    if (unit == 'Division einstellig' || unit == 'Schriftliche Division') {
      return ':';
    }
    return null;
  }

  /// Group heading of [unit]; unknown units are listed under the puzzles.
  static String groupOf(String unit) => _group[unit] ?? puzzles;

  /// Returns [units] in school order. Unknown units keep their relative
  /// order at the end, so no generated unit can disappear from the menu.
  static List<String> sorted(Iterable<String> units) {
    final indexed = units.toList(growable: false);
    final positions = <String, int>{
      for (var i = 0; i < indexed.length; i++) indexed[i]: i,
    };
    final result = [...indexed]..sort((a, b) {
        final ra = _rank[a] ?? _ordered.length + positions[a]!;
        final rb = _rank[b] ?? _ordered.length + positions[b]!;
        return ra.compareTo(rb);
      });
    return result;
  }

  /// Units in school order, split under their group headings. Groups without
  /// a unit for this grade are left out.
  static List<(String, List<String>)> grouped(Iterable<String> units) {
    final ordered = sorted(units);
    return <(String, List<String>)>[
      for (final group in groups)
        if (ordered.any((unit) => groupOf(unit) == group))
          (group, ordered.where((unit) => groupOf(unit) == group).toList()),
    ];
  }
}
