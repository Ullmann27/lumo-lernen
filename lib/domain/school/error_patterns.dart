import 'attempt.dart';

/// Erkennt typische, wiederkehrende Fehler aus Aufgabe, Antwort und
/// Lösung. Liefert einen kurzen deutschen Namen des Musters oder null.
///
/// Beispiele: `8 + 5` mit Antwort `3` → „Zehner beim Übergang vergessen“,
/// `52 − 27` mit Antwort `35` → „kleinere Einerziffer von der größeren
/// abgezogen“. Beim Lesen ist das schwierige Wort selbst das Muster.
class ErrorPatternDetector {
  const ErrorPatternDetector();

  static final RegExp _calc = RegExp(r'(\d+)\s*([+\-−–×x·*:÷])\s*(\d+)');

  String? detect(Attempt attempt) {
    if (attempt.correct) return null;
    if (attempt.subject == 'Lesen') {
      final word = attempt.given.trim();
      return word.isEmpty ? null : 'schwieriges Wort „$word“';
    }
    final m = _calc.firstMatch(attempt.prompt);
    final given = int.tryParse(attempt.given.trim());
    final expected = int.tryParse(attempt.expected.trim());
    if (m == null || given == null || expected == null) return null;
    final a = int.parse(m.group(1)!);
    final b = int.parse(m.group(3)!);
    switch (m.group(2)!) {
      case '+':
        if (given == expected - 10) return 'Zehner beim Übergang vergessen';
        if (given == (a - b).abs()) return 'Minus statt Plus gerechnet';
        if (_swapped(given, expected)) return 'Ziffern vertauscht';
        if ((given - expected).abs() == 1) return 'um eins verzählt';
      case '-':
      case '−':
      case '–':
        if (given == a + b) return 'Plus statt Minus gerechnet';
        if (a >= 10 &&
            b >= 10 &&
            a % 10 < b % 10 &&
            given == ((a ~/ 10) - (b ~/ 10)) * 10 + (b % 10 - a % 10)) {
          return 'kleinere Einerziffer von der größeren abgezogen';
        }
        if (given == expected + 10) return 'Zehner beim Übergang nicht abgezogen';
        if (_swapped(given, expected)) return 'Ziffern vertauscht';
        if ((given - expected).abs() == 1) return 'um eins verzählt';
      case '×':
      case 'x':
      case '·':
      case '*':
        if (given == a + b) return 'Plus statt Mal gerechnet';
        if (given == expected + a ||
            given == expected - a ||
            given == expected + b ||
            given == expected - b) {
          return 'in der Malreihe um einen Schritt verrutscht';
        }
      case ':':
      case '÷':
        if (given == a * b) return 'Mal statt Geteilt gerechnet';
        if ((given - expected).abs() == 1) return 'um eins verzählt';
    }
    return null;
  }

  static bool _swapped(int given, int expected) {
    final g = '$given', e = '$expected';
    return g.length == 2 && e.length == 2 && g[0] == e[1] && g[1] == e[0] && g != e;
  }
}
