class LearningDecision {
  const LearningDecision({
    required this.subject,
    required this.unit,
    required this.reason,
    required this.shouldRepeat,
  });

  final String subject;
  final String unit;
  final String reason;
  final bool shouldRepeat;
}

class LearningEngine {
  const LearningEngine();

  LearningDecision nextStep({
    required Map<String, int> weakSkills,
    String fallbackSubject = 'Mathematik',
    String fallbackUnit = 'Alle',
  }) {
    if (weakSkills.isEmpty) {
      return LearningDecision(
        subject: fallbackSubject,
        unit: fallbackUnit,
        reason: 'Noch kein Schwächenprofil vorhanden. Wir starten mit einer gemischten Mission.',
        shouldRepeat: false,
      );
    }

    final entries = weakSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final unit = entries.first.key;
    return LearningDecision(
      subject: _subjectForUnit(unit, fallbackSubject),
      unit: unit,
      reason: 'Lumo wiederholt $unit, weil dort zuletzt mehrere Hilfen gebraucht wurden.',
      shouldRepeat: entries.first.value >= 2,
    );
  }

  String _subjectForUnit(String unit, String fallback) {
    if (unit.contains('Plus') || unit.contains('Minus') || unit.contains('Zahlen') || unit.contains('Geld') || unit.contains('Uhr')) return 'Mathematik';
    if (unit.contains('Silben') || unit.contains('Reime') || unit.contains('Artikel') || unit.contains('Laut')) return 'Deutsch';
    if (unit.contains('Wort') || unit.contains('Satz')) return 'Deutsch';
    return fallback;
  }
}
