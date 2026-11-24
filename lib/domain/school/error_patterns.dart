import 'attempt.dart';
import '../learning/whole_arithmetic.dart';

/// Erkennt typische, wiederkehrende Fehler aus Aufgabe, Antwort und
/// Lösung. Liefert einen kurzen deutschen Namen des Musters oder null.
///
/// Beispiele: `8 + 5` mit Antwort `3` → „Zehner beim Übergang vergessen“,
/// `52 − 27` mit Antwort `35` → „kleinere Einerziffer von der größeren
/// abgezogen“. Beim Lesen ist das schwierige Wort selbst das Muster.
class ErrorPatternDetector {
  const ErrorPatternDetector();

  String? detect(Attempt attempt) {
    if (attempt.correct) return null;
    if (attempt.subject == 'Lesen') {
      final word = attempt.given.trim();
      return word.isEmpty ? null : 'schwieriges Wort „$word“';
    }
    if (attempt.subject != 'Mathematik') return null;
    final calculation =
        WholeArithmetic.parse(attempt.prompt, expected: attempt.expected);
    final given = WholeArithmetic.integerAnswer(attempt.given);
    if (calculation == null || given == null || given == calculation.result) {
      return null;
    }
    final a = calculation.left;
    final b = calculation.right;
    final expected = calculation.result;
    switch (calculation.operation) {
      case WholeOperation.addition:
        if (calculation.matchesMissingCarry(given)) return 'Zehner beim Übergang vergessen';
        if (given == (a - b).abs()) return 'Minus statt Plus gerechnet';
        if (_swapped(given, expected)) return 'Ziffern vertauscht';
        if ((given - expected).abs() == 1) return 'um eins verzählt';
      case WholeOperation.subtraction:
        if (given == a + b) return 'Plus statt Minus gerechnet';
        if (calculation.matchesReversedOnes(given)) {
          return 'kleinere Einerziffer von der größeren abgezogen';
        }
        if (calculation.matchesMissingBorrow(given)) return 'Zehner beim Übergang nicht abgezogen';
        if (_swapped(given, expected)) return 'Ziffern vertauscht';
        if ((given - expected).abs() == 1) return 'um eins verzählt';
      case WholeOperation.multiplication:
        if (given == a + b) return 'Plus statt Mal gerechnet';
        if (given == expected + a ||
            given == expected - a ||
            given == expected + b ||
            given == expected - b) {
          return 'in der Malreihe um einen Schritt verrutscht';
        }
      case WholeOperation.division:
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
