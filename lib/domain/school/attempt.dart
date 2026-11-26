import 'competency.dart';

/// Eine einzelne beantwortete Aufgabe. Grundlage für Lernbericht,
/// Schwächenanalyse und später den Lehrerbereich.
///
/// Datensparsam: nur was für die Lernanalyse nötig ist (keine Namen, keine
/// Freitexte außer Aufgabe und gegebene Antwort).
class Attempt {
  const Attempt({
    required this.id,
    required this.studentId,
    required this.subject,
    required this.unit,
    required this.competency,
    required this.correct,
    required this.at,
    this.hintUsed = false,
    this.prompt = '',
    this.given = '',
    this.expected = '',
    this.durationMs,
    this.score,
    this.check,
    this.reference = '',
    this.method,
  });

  /// [check]: eigenständige Vergleichsaufgabe, die Lumo nach einer
  /// Hilfestellung angeboten hat. Nur sie kann ein späteres Indiz für
  /// Verständnis sein (wenn sie ohne Hilfe richtig gelöst wurde).
  static const String vergleichNachHilfe = 'vergleich';

  final String id;
  final String studentId;
  final String subject;
  final String unit;

  /// Feine Kompetenz, z. B. „Addition mit Zehnerübergang“ (siehe
  /// [CompetencyClassifier]).
  final String competency;
  final bool correct;
  final DateTime at;
  final bool hintUsed;
  final String prompt;
  final String given;
  final String expected;
  final int? durationMs;

  /// Teilbewertung 0..1, z. B. Lese-Genauigkeit eines vorgelesenen Satzes.
  final double? score;

  /// Art des Lernnachweises, z. B. [vergleichNachHilfe]; sonst null.
  /// Ältere Einträge haben keinen und bleiben gewöhnliche Antworten.
  final String? check;

  /// Aufgabe, bei der Lumo vorher geholfen hat (nur bei [check]), damit
  /// nachvollziehbar bleibt, worauf sich der Nachweis bezieht.
  final String reference;

  /// Erklärweise der gezeigten Hilfe (z. B. „zahlenstrahl“, „bild“), falls
  /// eine gezeigt wurde. Lumo wählt beim nächsten Mal eine andere, wenn
  /// diese nicht zum Ziel geführt hat.
  final String? method;

  /// Eine neue Aufgabe zur Kompetenz der dokumentierten Ausgangsaufgabe.
  bool get isComparableAfterHelp {
    if (check != vergleichNachHilfe) return false;
    final source = reference.trim();
    final target = prompt.trim();
    if (source.isEmpty || target.isEmpty || source == target) return false;
    const classifier = CompetencyClassifier();
    String classify(String text) =>
        classifier.classify(subject: subject, unit: unit, prompt: text);
    return classify(source) == classify(target);
  }

  /// Selbstständig richtig gelöste Vergleichsaufgabe nach einer Hilfe.
  bool get confirmsAfterHelp => isComparableAfterHelp && correct && !hintUsed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sid': studentId,
        'sub': subject,
        'unit': unit,
        'comp': competency,
        'ok': correct,
        'at': at.toIso8601String(),
        if (hintUsed) 'hint': true,
        if (prompt.isNotEmpty) 'q': prompt,
        if (given.isNotEmpty) 'a': given,
        if (expected.isNotEmpty) 'e': expected,
        if (durationMs != null) 'ms': durationMs,
        if (score != null) 'sc': double.parse(score!.toStringAsFixed(3)),
        if (check != null) 'chk': check,
        if (reference.isNotEmpty) 'ref': reference,
        if (method != null) 'm': method,
      };

  static Attempt? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final at = DateTime.tryParse('${raw['at']}');
    final id = raw['id'];
    if (at == null || id is! String) return null;
    return Attempt(
      id: id,
      studentId: '${raw['sid'] ?? 'self'}',
      subject: '${raw['sub'] ?? ''}',
      unit: '${raw['unit'] ?? ''}',
      competency: '${raw['comp'] ?? raw['unit'] ?? ''}',
      correct: raw['ok'] == true,
      at: at,
      hintUsed: raw['hint'] == true,
      prompt: '${raw['q'] ?? ''}',
      given: '${raw['a'] ?? ''}',
      expected: '${raw['e'] ?? ''}',
      durationMs: (raw['ms'] as num?)?.toInt(),
      score: (raw['sc'] as num?)?.toDouble(),
      check: raw['chk'] is String ? raw['chk'] as String : null,
      reference: raw['ref'] is String ? raw['ref'] as String : '',
      method: raw['m'] is String ? raw['m'] as String : null,
    );
  }
}
