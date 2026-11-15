/// A repeated shape group proved from the visible sequence itself.
///
/// At least two complete repetitions must be visible. Shape names, not colour,
/// determine the rule. Renderers receive these same facts after validation.
class CheckedShapePattern {
  CheckedShapePattern._(List<String> values, this.period)
      : sequence = List<String>.unmodifiable(values);

  final List<String> sequence;
  final int period;
  List<String> get group => sequence.take(period).toList(growable: false);
  String get next => sequence[sequence.length % period];

  static CheckedShapePattern? fromPrompt(String prompt) {
    final match = RegExp(
      r'^Das Muster wiederholt sich immer gleich:\s*(.+?)\s*[–—-]\s*\?\s*Welche Form folgt\?$',
    ).firstMatch(prompt.trim());
    if (match == null) return null;
    final values = match[1]!
        .split(RegExp(r'\s*[–—-]\s*'))
        .map((part) => part.trim())
        .toList(growable: false);
    const shapes = {'Kreis', 'Dreieck', 'Stern', 'Quadrat', 'Rechteck', 'Oval'};
    if (values.length < 4 || values.any((value) => !shapes.contains(value))) {
      return null;
    }
    for (var period = 1; period <= values.length ~/ 2; period++) {
      if (List.generate(values.length,
              (index) => values[index] == values[index % period])
          .every((same) => same)) {
        return CheckedShapePattern._(values, period);
      }
    }
    return null;
  }
}

/// The explicitly stated equal-step rule is checked at every visible gap.
class CheckedNumberPattern {
  CheckedNumberPattern._(List<int> values, this.step)
      : sequence = List<int>.unmodifiable(values);

  final List<int> sequence;
  final int step;
  int get next => sequence.last + step;

  static CheckedNumberPattern? fromPrompt(String prompt) {
    final match = RegExp(
      r'^Gehe jedes Mal gleich viele Schritte weiter:\s*(.+?)\s*[–—]\s*\?\s*Welche Zahl folgt\?$',
    ).firstMatch(prompt.trim());
    if (match == null) return null;
    final values = match[1]!
        .split(RegExp(r'\s*[–—]\s*'))
        .map(int.tryParse)
        .toList(growable: false);
    if (values.length < 3 || values.any((value) => value == null)) return null;
    final sequence = values.cast<int>();
    final step = sequence[1] - sequence.first;
    if (step == 0) return null;
    for (var index = 2; index < sequence.length; index++) {
      if (sequence[index] - sequence[index - 1] != step) return null;
    }
    return CheckedNumberPattern._(sequence, step);
  }
}
