/// Lumo Fehlerdetektiv.
///
/// Erkennt aus Aufgabe + falscher Antwort die wahrscheinlichste Fehlerart
/// und liefert kindgerechtes Feedback.
///
/// Fehlerarten (Heinz' Liste):
///   - countingError       (Zaehlfehler)
///   - plusMinusSwap       (Plus/Minus verwechselt)
///   - placeValueError     (Stellenwertproblem)
///   - rhymeError          (Reimproblem)
///   - syllableError       (Silbenproblem)
///   - articleError        (Artikelproblem)
///   - wordTypeError       (Wortartproblem)
///   - sentenceStructureError (Satzbauproblem)
///   - offByOne            (knapp daneben)
///   - unknown             (kein Muster erkannt)
///
/// Verwendung: `ErrorDetective().analyze(prompt, correctAnswer, givenAnswer, subject)`
/// liefert ein ErrorDetection-Objekt mit kindgerechter Message.

import 'package:flutter/foundation.dart';

enum ErrorPattern {
  countingError,
  plusMinusSwap,
  placeValueError,
  rhymeError,
  syllableError,
  articleError,
  wordTypeError,
  sentenceStructureError,
  offByOne,
  digitInversion, // 23 statt 32
  unknown,
}

extension ErrorPatternMeta on ErrorPattern {
  /// Kurzer Label fuer DNA-ErrorBreakdown (deutsch, alltagstauglich).
  String get germanShortLabel {
    switch (this) {
      case ErrorPattern.countingError: return 'Zaehlfehler';
      case ErrorPattern.plusMinusSwap: return 'Plus/Minus verwechselt';
      case ErrorPattern.placeValueError: return 'Stellenwert';
      case ErrorPattern.rhymeError: return 'Reim';
      case ErrorPattern.syllableError: return 'Silben';
      case ErrorPattern.articleError: return 'Artikel';
      case ErrorPattern.wordTypeError: return 'Wortart';
      case ErrorPattern.sentenceStructureError: return 'Satzbau';
      case ErrorPattern.offByOne: return 'Knapp daneben';
      case ErrorPattern.digitInversion: return 'Zahlen vertauscht';
      case ErrorPattern.unknown: return 'Unklarer Fehler';
    }
  }

  String get emoji {
    switch (this) {
      case ErrorPattern.countingError: return '🧮';
      case ErrorPattern.plusMinusSwap: return '➕';
      case ErrorPattern.placeValueError: return '🔢';
      case ErrorPattern.rhymeError: return '🎵';
      case ErrorPattern.syllableError: return '👏';
      case ErrorPattern.articleError: return '🏷️';
      case ErrorPattern.wordTypeError: return '📚';
      case ErrorPattern.sentenceStructureError: return '📝';
      case ErrorPattern.offByOne: return '🔍';
      case ErrorPattern.digitInversion: return '🔁';
      case ErrorPattern.unknown: return '❓';
    }
  }
}

@immutable
class ErrorDetection {
  const ErrorDetection({
    required this.pattern,
    required this.childFriendlyMessage,
    required this.confidence,
    this.delta,
  });

  final ErrorPattern pattern;

  /// Direkte Lumo-Botschaft an das Kind.
  /// z.B. "Ich glaube, du hast Plus und Minus verwechselt."
  final String childFriendlyMessage;

  /// 0.0 (Vermutung) bis 1.0 (sicher).
  final double confidence;

  /// Bei numerischen Fehlern: Differenz zur richtigen Antwort.
  final int? delta;
}

class ErrorDetective {
  const ErrorDetective();

  /// Analysiert einen Fehler basierend auf Subject, Prompt, korrekter Antwort
  /// und gegebener Antwort.
  ErrorDetection analyze({
    required String subject,
    required String prompt,
    required String correctAnswer,
    required String givenAnswer,
  }) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('math')) {
      return _analyzeMath(prompt, correctAnswer, givenAnswer);
    }
    if (subjectLower.contains('deutsch') || subjectLower.contains('lesen')) {
      return _analyzeGerman(prompt, correctAnswer, givenAnswer);
    }
    return ErrorDetection(
      pattern: ErrorPattern.unknown,
      childFriendlyMessage: 'Schau die Aufgabe noch einmal in Ruhe an, du schaffst das!',
      confidence: 0.2,
    );
  }

  // ─────────────────────────── MATHE ───────────────────────────

  ErrorDetection _analyzeMath(String prompt, String correctAnswer, String givenAnswer) {
    final correct = _tryParseInt(correctAnswer);
    final given = _tryParseInt(givenAnswer);

    // Beide Werte numerisch?
    if (correct != null && given != null) {
      final delta = (correct - given).abs();
      final p = _detectMathOperator(prompt);

      // 1) Off-by-one (klassischer Zaehlfehler).
      if (delta == 1) {
        return ErrorDetection(
          pattern: ErrorPattern.offByOne,
          childFriendlyMessage: 'Du warst nur um 1 daneben. Zaehle nochmal nach!',
          confidence: 0.85,
          delta: delta,
        );
      }

      // 2) Plus/Minus-Swap erkennen.
      if (p != null) {
        final operands = _extractOperands(prompt);
        if (operands != null && operands.length == 2) {
          final a = operands[0];
          final b = operands[1];
          if (p == _Op.plus) {
            final wrongIfMinus = a - b;
            if (given == wrongIfMinus) {
              return ErrorDetection(
                pattern: ErrorPattern.plusMinusSwap,
                childFriendlyMessage: 'Ich glaube, du hast Plus und Minus verwechselt. Plus heisst dazu!',
                confidence: 0.95,
                delta: delta,
              );
            }
          } else if (p == _Op.minus) {
            final wrongIfPlus = a + b;
            if (given == wrongIfPlus) {
              return ErrorDetection(
                pattern: ErrorPattern.plusMinusSwap,
                childFriendlyMessage: 'Ich glaube, du hast Plus und Minus verwechselt. Minus heisst weg!',
                confidence: 0.95,
                delta: delta,
              );
            }
          }
        }
      }

      // 3) Stellenwert-Fehler bei zweistelligen Zahlen.
      if (correct >= 10 && given >= 10) {
        final correctStr = correct.toString();
        final givenStr = given.toString();
        if (correctStr.length == givenStr.length &&
            correctStr.length == 2 &&
            correctStr[0] == givenStr[1] &&
            correctStr[1] == givenStr[0]) {
          return ErrorDetection(
            pattern: ErrorPattern.digitInversion,
            childFriendlyMessage: 'Du hast die Zahlen vertauscht. Schau dir die Reihenfolge an!',
            confidence: 0.92,
            delta: delta,
          );
        }
      }

      // 4) Stellenwert bei Zehner/Einer.
      if (correct >= 10 && (delta == 10 || delta == 20 || delta == 30)) {
        return ErrorDetection(
          pattern: ErrorPattern.placeValueError,
          childFriendlyMessage: 'Achte auf die Zehner. Manchmal hilft es, mit Zehnerstaeben zu rechnen.',
          confidence: 0.75,
          delta: delta,
        );
      }

      // 5) Allgemeiner Zaehlfehler (kleines Delta).
      if (delta <= 3) {
        return ErrorDetection(
          pattern: ErrorPattern.countingError,
          childFriendlyMessage: 'Zaehle nochmal genau mit den Fingern oder mit Punkten.',
          confidence: 0.65,
          delta: delta,
        );
      }

      // 6) Grosses Delta - unklar.
      return ErrorDetection(
        pattern: ErrorPattern.unknown,
        childFriendlyMessage: 'Schau dir die Aufgabe nochmal an. Welche Rechenart ist es?',
        confidence: 0.4,
        delta: delta,
      );
    }

    // Nicht-numerische Antwort bei Mathe-Aufgabe -> unklar.
    return const ErrorDetection(
      pattern: ErrorPattern.unknown,
      childFriendlyMessage: 'Probier es nochmal - du schaffst das!',
      confidence: 0.3,
    );
  }

  // ─────────────────────────── DEUTSCH ───────────────────────────

  ErrorDetection _analyzeGerman(String prompt, String correctAnswer, String givenAnswer) {
    final promptLower = prompt.toLowerCase();
    final correctLower = correctAnswer.toLowerCase().trim();
    final givenLower = givenAnswer.toLowerCase().trim();

    // 1) Artikel-Fehler (der/die/das).
    final articles = <String>{'der', 'die', 'das', 'den', 'dem'};
    if (articles.contains(correctLower) && articles.contains(givenLower)) {
      return const ErrorDetection(
        pattern: ErrorPattern.articleError,
        childFriendlyMessage: 'Achte auf den richtigen Artikel - der, die oder das?',
        confidence: 0.95,
      );
    }

    // 2) Reim-Aufgabe?
    if (promptLower.contains('reim') || promptLower.contains('endung')) {
      return const ErrorDetection(
        pattern: ErrorPattern.rhymeError,
        childFriendlyMessage: 'Hoer auf das Wortende. Was klingt gleich am Schluss?',
        confidence: 0.8,
      );
    }

    // 3) Silben-Aufgabe?
    if (promptLower.contains('silbe') || promptLower.contains('klatsch')) {
      return const ErrorDetection(
        pattern: ErrorPattern.syllableError,
        childFriendlyMessage: 'Klatsche das Wort langsam mit. Jede Silbe ist ein Klatscher.',
        confidence: 0.8,
      );
    }

    // 4) Wortart (Nomen/Verb/Adjektiv)?
    final wordTypes = <String>{'nomen', 'verb', 'adjektiv', 'tunwort', 'wiewort', 'namenwort'};
    if (promptLower.contains('wortart') ||
        wordTypes.any(promptLower.contains) ||
        wordTypes.contains(correctLower)) {
      return const ErrorDetection(
        pattern: ErrorPattern.wordTypeError,
        childFriendlyMessage: 'Frage dich: Ist es ein Ding (Nomen), eine Taetigkeit (Verb) oder eine Eigenschaft (Adjektiv)?',
        confidence: 0.85,
      );
    }

    // 5) Satzbau / Wortfolge?
    if (correctAnswer.split(' ').length >= 3) {
      return const ErrorDetection(
        pattern: ErrorPattern.sentenceStructureError,
        childFriendlyMessage: 'Schau dir die Reihenfolge der Woerter an. Wer macht was?',
        confidence: 0.7,
      );
    }

    // 6) Einzelner-Buchstaben-Fehler (Tippfehler-aehnlich).
    if (correctLower.length == givenLower.length && correctLower.length >= 2) {
      final diff = _charDiff(correctLower, givenLower);
      if (diff == 1) {
        return const ErrorDetection(
          pattern: ErrorPattern.syllableError,
          childFriendlyMessage: 'Lies langsam Buchstabe fuer Buchstabe. Du warst nah dran!',
          confidence: 0.65,
        );
      }
    }

    return const ErrorDetection(
      pattern: ErrorPattern.unknown,
      childFriendlyMessage: 'Lies die Aufgabe nochmal in Ruhe vor.',
      confidence: 0.35,
    );
  }

  // ─── Helper ───

  int? _tryParseInt(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9-]'), '');
    return int.tryParse(cleaned);
  }

  _Op? _detectMathOperator(String prompt) {
    if (prompt.contains('+') || prompt.toLowerCase().contains('plus')) return _Op.plus;
    if (prompt.contains('-') || prompt.contains('−') || prompt.toLowerCase().contains('minus')) return _Op.minus;
    return null;
  }

  List<int>? _extractOperands(String prompt) {
    final matches = RegExp(r'\d+').allMatches(prompt).toList();
    if (matches.length < 2) return null;
    final a = int.tryParse(matches[0].group(0)!);
    final b = int.tryParse(matches[1].group(0)!);
    if (a == null || b == null) return null;
    return <int>[a, b];
  }

  int _charDiff(String a, String b) {
    var c = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) c++;
    }
    return c;
  }
}

enum _Op { plus, minus }
