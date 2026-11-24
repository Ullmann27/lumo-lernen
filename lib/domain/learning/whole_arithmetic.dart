/// Verified whole-number arithmetic shared by live tutoring and analytics.
library;

enum WholeOperation { addition, subtraction, multiplication, division }

class WholeArithmetic {
  const WholeArithmetic._(this.left, this.right, this.operation, this.result);

  final int left;
  final int right;
  final WholeOperation operation;
  final int result;

  static final _expression = RegExp(
    r'^\s*(?:(?:Schriftlich|Blitzlicht):\s*|Rechne\s+)?(\d{1,7})\s*([+\-−–×x·*:÷])\s*(\d{1,7})\s*(?:=\s*\?)?\s*[.!?]?\s*$',
    caseSensitive: false,
  );
  static final _integer = RegExp(r'^-?\d{1,13}$');

  /// Never remove punctuation, units or words from numeric answers.
  static int? integerAnswer(String? raw) {
    final text = (raw ?? '').trim().replaceAll('−', '-');
    if (!_integer.hasMatch(text)) return null;
    return int.tryParse(text);
  }

  /// Require the entire prompt, not a substring of a fraction, decimal,
  /// missing-operand task or story. Check the supplied solution independently.
  static WholeArithmetic? parse(String prompt, {String? expected}) {
    final match = _expression.firstMatch(prompt);
    if (match == null) return null;
    final a = int.tryParse(match[1]!);
    final b = int.tryParse(match[3]!);
    if (a == null || b == null || a > 1000000 || b > 1000000) return null;
    final op = switch (match[2]!.toLowerCase()) {
      '+' => WholeOperation.addition,
      '-' || '−' || '–' => WholeOperation.subtraction,
      '×' || 'x' || '·' || '*' => WholeOperation.multiplication,
      _ => WholeOperation.division,
    };
    if (op == WholeOperation.division && (b == 0 || a % b != 0)) {
      return null;
    }
    final value = switch (op) {
      WholeOperation.addition => a + b,
      WholeOperation.subtraction => a - b,
      WholeOperation.multiplication => a * b,
      WholeOperation.division => a ~/ b,
    };
    if (expected != null && integerAnswer(expected) != value) return null;
    return WholeArithmetic._(a, b, op, value);
  }

  bool get isAddOrSubtract =>
      operation == WholeOperation.addition ||
      operation == WholeOperation.subtraction;

  bool get inPrimaryHundred =>
      left <= 100 && right <= 100 && result >= 0 && result <= 100;

  bool get carriesOnes =>
      operation == WholeOperation.addition &&
      inPrimaryHundred &&
      left % 10 + right % 10 >= 10;

  bool get borrowsOnes =>
      operation == WholeOperation.subtraction &&
      inPrimaryHundred &&
      left % 10 < right % 10;

  bool matchesMissingCarry(int given) => carriesOnes && given == result - 10;
  bool matchesMissingBorrow(int given) => borrowsOnes && given == result + 10;

  bool matchesReversedOnes(int given) =>
      borrowsOnes &&
      left < 100 &&
      right >= 10 &&
      right < 100 &&
      given == (left ~/ 10 - right ~/ 10) * 10 + right % 10 - left % 10;
}
