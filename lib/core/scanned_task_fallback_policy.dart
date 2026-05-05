enum RecognizedTaskRoute {
  multipleChoice,
  freeText,
  parentReview,
}

class RecognizedTaskFallback {
  const RecognizedTaskFallback({
    required this.route,
    required this.rawText,
    required this.prompt,
    required this.subject,
    required this.unit,
    required this.confidence,
    this.correctAnswer,
    this.choices = const <String>[],
    this.reason,
  });

  final RecognizedTaskRoute route;
  final String rawText;
  final String prompt;
  final String subject;
  final String unit;
  final double confidence;
  final String? correctAnswer;
  final List<String> choices;
  final String? reason;

  bool get isSolvable => route == RecognizedTaskRoute.multipleChoice || route == RecognizedTaskRoute.freeText;
  bool get requiresParentReview => route == RecognizedTaskRoute.parentReview;
  bool get hasChoices => choices.isNotEmpty;
}

class MathParseResult {
  const MathParseResult({
    required this.expression,
    required this.answer,
    required this.operation,
  });

  final String expression;
  final int answer;
  final String operation;
}

class ScannedTaskFallbackPolicy {
  const ScannedTaskFallbackPolicy();

  RecognizedTaskFallback analyze({
    required String rawText,
    required String subject,
    required String unit,
    int grade = 1,
    double? ocrConfidence,
  }) {
    final text = rawText.trim();
    final confidence = (ocrConfidence ?? _heuristicConfidence(text)).clamp(0.0, 1.0).toDouble();
    final safeSubject = subject == 'Unklar' ? _guessSubject(text) : subject;
    final safeUnit = unit.trim().isEmpty || unit == 'Alle Themen' ? _guessUnit(text, safeSubject, grade) : unit;

    if (text.isEmpty) {
      return _parentReview(text, safeSubject, safeUnit, confidence, 'empty_ocr');
    }
    if (confidence < .55 || _looksCorrupt(text)) {
      return _parentReview(text, safeSubject, safeUnit, confidence, 'low_ocr_confidence');
    }

    final math = parseSimpleMath(text);
    if (math != null) {
      final choices = generateMathChoices(
        answer: math.answer,
        expression: math.expression,
        grade: grade,
      );
      return RecognizedTaskFallback(
        route: RecognizedTaskRoute.multipleChoice,
        rawText: text,
        prompt: _promptForMath(text, math),
        subject: 'Mathematik',
        unit: _unitForMath(math, grade),
        confidence: confidence,
        correctAnswer: '${math.answer}',
        choices: choices,
        reason: 'math_parsed',
      );
    }

    if (_isOpenButReadable(text)) {
      return RecognizedTaskFallback(
        route: RecognizedTaskRoute.freeText,
        rawText: text,
        prompt: _cleanPrompt(text),
        subject: safeSubject,
        unit: safeUnit,
        confidence: confidence,
        reason: 'clear_open_task',
      );
    }

    return _parentReview(text, safeSubject, safeUnit, confidence, 'unknown_task_shape');
  }

  MathParseResult? parseSimpleMath(String rawText) {
    final normalized = _normalizeMath(rawText);
    final match = RegExp(r'(-?\d+)\s*([+\-*/:])\s*(-?\d+)').firstMatch(normalized);
    if (match == null) return null;

    final left = int.tryParse(match.group(1) ?? '');
    final op = match.group(2);
    final right = int.tryParse(match.group(3) ?? '');
    if (left == null || op == null || right == null) return null;

    int answer;
    String operation;
    switch (op) {
      case '+':
        answer = left + right;
        operation = 'addition';
        break;
      case '-':
        answer = left - right;
        operation = 'subtraction';
        break;
      case '*':
        answer = left * right;
        operation = 'multiplication';
        break;
      case '/':
      case ':':
        if (right == 0 || left % right != 0) return null;
        answer = left ~/ right;
        operation = 'division';
        break;
      default:
        return null;
    }

    final expression = '${match.group(1)} $op ${match.group(3)}';
    return MathParseResult(expression: expression, answer: answer, operation: operation);
  }

  List<String> generateMathChoices({
    required int answer,
    required String expression,
    int grade = 1,
    int targetCount = 4,
  }) {
    final candidates = <int>{answer};
    final nonNegative = grade <= 2;
    final normalized = _normalizeMath(expression);
    final operands = RegExp(r'-?\d+').allMatches(normalized).map((m) => int.tryParse(m.group(0) ?? '')).whereType<int>().toList(growable: false);

    void add(int value) {
      if (nonNegative && value < 0) return;
      candidates.add(value);
    }

    add(answer + 1);
    add(answer - 1);
    add(answer + 2);
    add(answer - 2);
    if (operands.length >= 2) {
      add(operands.first + operands.last + 1);
      add((operands.first - operands.last).abs());
      add(operands.first);
      add(operands.last);
    }

    var spread = 3;
    while (candidates.length < targetCount && spread < 20) {
      add(answer + spread);
      add(answer - spread);
      spread++;
    }

    final sorted = candidates.toList()..sort();
    final rotated = _rotate(sorted.map((v) => '$v').toList(growable: false), expression);
    if (!rotated.contains('$answer')) {
      return <String>['$answer', ...rotated].take(targetCount).toList(growable: false);
    }
    return rotated.take(targetCount).toList(growable: false);
  }

  RecognizedTaskFallback _parentReview(String text, String subject, String unit, double confidence, String reason) {
    return RecognizedTaskFallback(
      route: RecognizedTaskRoute.parentReview,
      rawText: text,
      prompt: text.isEmpty ? 'Scan konnte nicht sicher gelesen werden.' : _cleanPrompt(text),
      subject: subject,
      unit: unit,
      confidence: confidence,
      reason: reason,
    );
  }

  String _normalizeMath(String value) {
    return value
        .toLowerCase()
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('×', '*')
        .replaceAll('x', '*')
        .replaceAll('mal', '*')
        .replaceAll('geteilt durch', ':')
        .replaceAll('geteilt', ':')
        .replaceAll('=', ' = ')
        .replaceAll('?', ' ? ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _promptForMath(String text, MathParseResult math) {
    final cleaned = _cleanPrompt(text);
    if (cleaned.contains('?') || cleaned.contains('=')) return cleaned;
    return '${math.expression} = ?';
  }

  String _cleanPrompt(String value) => value.trim().replaceAll(RegExp(r'\s+'), ' ');

  String _guessSubject(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\d+\s*[+\-×x*/:]\s*\d+').hasMatch(lower) || lower.contains('rechne')) return 'Mathematik';
    if (lower.contains('satz') || lower.contains('wort') || lower.contains('lies') || lower.contains('schreibe')) return 'Deutsch';
    return 'Unklar';
  }

  String _guessUnit(String text, String subject, int grade) {
    final lower = text.toLowerCase();
    if (subject == 'Mathematik') {
      if (lower.contains('+') || lower.contains('plus')) return grade <= 2 ? 'Plus bis 20' : 'Addition';
      if (lower.contains('-') || lower.contains('minus')) return grade <= 2 ? 'Minus bis 20' : 'Subtraktion';
      if (lower.contains('mal') || lower.contains('×') || lower.contains('*')) return 'Einmaleins';
      if (lower.contains('geteilt') || lower.contains(':')) return 'Division';
      return 'Gemischtes Rechnen';
    }
    if (subject == 'Deutsch') return 'Lesen und Schreiben';
    return 'Alle Themen';
  }

  String _unitForMath(MathParseResult math, int grade) {
    switch (math.operation) {
      case 'addition':
        return grade <= 2 ? 'Plus bis 20' : 'Addition';
      case 'subtraction':
        return grade <= 2 ? 'Minus bis 20' : 'Subtraktion';
      case 'multiplication':
        return 'Einmaleins';
      case 'division':
        return 'Division';
      default:
        return 'Gemischtes Rechnen';
    }
  }

  bool _isOpenButReadable(String text) {
    final lower = text.toLowerCase();
    final hasLetters = RegExp(r'[a-zäöüß]').hasMatch(lower);
    if (!hasLetters) return false;
    return lower.contains('schreibe') ||
        lower.contains('lies') ||
        lower.contains('nenne') ||
        lower.contains('ergänze') ||
        lower.contains('ergaenze') ||
        lower.contains('setze') ||
        lower.contains('antwort') ||
        lower.contains('verbinde') ||
        lower.contains('unterstreiche') ||
        lower.endsWith('?');
  }

  bool _looksCorrupt(String text) {
    if (text.contains('�')) return true;
    if (RegExp(r'[?]{3,}|[_]{3,}').hasMatch(text)) return true;
    final visible = text.replaceAll(RegExp(r'\s+'), '');
    if (visible.length < 3) return true;
    final odd = RegExp(r'[^a-zA-Z0-9äöüÄÖÜß+\-×x*/:=?.!,;\s]').allMatches(text).length;
    return visible.isNotEmpty && odd / visible.length > .30;
  }

  double _heuristicConfidence(String text) {
    if (text.trim().isEmpty) return .0;
    if (_looksCorrupt(text)) return .35;
    if (parseSimpleMath(text) != null) return .88;
    if (_isOpenButReadable(text)) return .72;
    return .50;
  }

  List<String> _rotate(List<String> values, String seed) {
    if (values.length <= 1) return values;
    final offset = (seed.hashCode & 0x7fffffff) % values.length;
    return <String>[...values.skip(offset), ...values.take(offset)];
  }
}
