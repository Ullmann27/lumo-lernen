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
  });

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
    );
  }
}
