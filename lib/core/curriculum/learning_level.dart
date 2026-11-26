/// Drei pädagogische Ebenen für jede Lerneinheit (Entscheidung Heinz,
/// 26.11.2026):
///
/// * [schulwissen]: Stoff der jeweiligen Schulstufe laut Lehrplan der
///   Volksschule (BGBl. II Nr. 1/2023, Anlage A).
/// * [vertiefung]: anspruchsvollere Anwendung des Gelernten, weiterhin im
///   Lehrplan verankert (Umkehraufgaben, Zahlenmauern, mehrschrittige
///   Sachaufgaben).
/// * [expertenwelt]: „Lumo Expertenwelt“ – freiwillige Herausforderungen
///   über den Lehrplan hinaus. Sie erscheinen nur, wenn das Kind sie
///   ausdrücklich auswählt, und nie von selbst in Tests, Schularbeiten oder
///   gemischten Runden.
///
/// Die Einheitsnamen bleiben unverändert: Gespeicherte Fortschritte
/// (Fach + Einheit) und Akademie-Kennungen gelten weiter.
enum LumoLearningLevel { schulwissen, vertiefung, expertenwelt }

extension LumoLearningLevelText on LumoLearningLevel {
  String get title => switch (this) {
        LumoLearningLevel.schulwissen => 'Schulwissen',
        LumoLearningLevel.vertiefung => 'Vertiefung',
        LumoLearningLevel.expertenwelt => 'Lumo Expertenwelt',
      };

  String get description => switch (this) {
        LumoLearningLevel.schulwissen => 'Der Stoff deiner Schulstufe.',
        LumoLearningLevel.vertiefung =>
          'Gelerntes anspruchsvoller anwenden: knobeln und in mehreren Schritten rechnen.',
        LumoLearningLevel.expertenwelt =>
          'Freiwillige Herausforderungen über den Lehrplan hinaus. '
              'Sie kommen in keinem Test und keiner Schularbeit vor.',
      };
}

class LearningLevels {
  const LearningLevels._();

  /// Mathematik, die angewandt und kombiniert wird: Umkehraufgaben
  /// (Platzhalter), Zahlenrätsel, Zahlenmauern und Sachaufgaben mit zwei
  /// oder drei Rechenschritten („vielfältige Sachsituationen modellieren“).
  static const Set<String> _mathDeepening = <String>{
    'Zahlenmauer',
    'Platzhalter-Rätsel',
    'Zahlenrätsel',
    'Sachaufgaben zwei Schritte',
    'Sachaufgaben drei Schritte',
  };

  /// Kommt im Volksschul-Lehrplan nicht vor: Rechnen mit Dezimalzahlen
  /// (Kommaschreibweise nur bei Geldbeträgen, ab der 3. Schulstufe),
  /// Mittelwert und formales Erweitern von Brüchen.
  static const Set<String> _mathBeyondCurriculum = <String>{
    'Dezimalzahlen',
    'Mittelwert',
    'Brüche erweitern',
  };

  /// Brüche stehen im Lehrplan erst in der 4. Schulstufe („Brüche mit
  /// kleinen Nennern … Bruchteile ermitteln“). Vorher sind sie ein Blick
  /// voraus, ab der 4. Schulstufe Schulwissen.
  static const Map<String, int> _mathCurriculumFromGrade = <String, int>{
    'Brüche Vorbereitung': 4,
  };

  /// Ebene der Einheit [unit] im Fach [subject] für die Schulstufe [grade].
  static LumoLearningLevel levelOf(String subject, String unit, int grade) {
    if (subject != 'Mathematik') return LumoLearningLevel.schulwissen;
    if (_mathBeyondCurriculum.contains(unit)) {
      return LumoLearningLevel.expertenwelt;
    }
    final from = _mathCurriculumFromGrade[unit];
    if (from != null && grade < from) return LumoLearningLevel.expertenwelt;
    if (_mathDeepening.contains(unit)) return LumoLearningLevel.vertiefung;
    return LumoLearningLevel.schulwissen;
  }

  /// Eine Expertenwelt-Einheit erscheint nur nach ausdrücklicher Auswahl.
  static bool isExpert(String subject, String unit, int grade) =>
      levelOf(subject, unit, grade) == LumoLearningLevel.expertenwelt;

  /// Lehrplanstoff (Schulwissen und Vertiefung) aus [units], in derselben
  /// Reihenfolge. Grundlage aller automatisch gemischten Runden.
  static List<String> withoutExpert(
          String subject, Iterable<String> units, int grade) =>
      [
        for (final unit in units)
          if (!isExpert(subject, unit, grade)) unit,
      ];

  /// [units] nach Ebenen getrennt, leere Ebenen fehlen.
  static List<(LumoLearningLevel, List<String>)> grouped(
      String subject, Iterable<String> units, int grade) {
    final list = units.toList(growable: false);
    return <(LumoLearningLevel, List<String>)>[
      for (final level in LumoLearningLevel.values)
        if (list.any((unit) => levelOf(subject, unit, grade) == level))
          (
            level,
            [
              for (final unit in list)
                if (levelOf(subject, unit, grade) == level) unit,
            ]
          ),
    ];
  }
}
