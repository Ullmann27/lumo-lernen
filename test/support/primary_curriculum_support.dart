enum CurriculumDelivery {
  interactiveExercise,
  practicalActivity,
  mixed,
  schoolManaged,
}

class CurriculumSupportEntry {
  const CurriculumSupportEntry({
    required this.subject,
    required this.delivery,
    required this.note,
  });

  final String subject;
  final CurriculumDelivery delivery;
  final String note;
}

/// Transparente Abdeckung des gesetzlichen Fächerrahmens.
///
/// "schoolManaged" ist absichtlich kein grünes Häkchen für App-Inhalte:
/// Religionsunterricht hängt von der jeweiligen Kirche/Religionsgesellschaft
/// und dem schulischen Angebot ab. Lumo erfindet dafür keinen neutralen
/// Einheitslehrplan.
class PrimaryCurriculumSupport {
  const PrimaryCurriculumSupport._();

  static List<CurriculumSupportEntry> forGrade(int grade) {
    final g = grade.clamp(1, 4);
    return <CurriculumSupportEntry>[
      const CurriculumSupportEntry(
        subject: 'Religion',
        delivery: CurriculumDelivery.schoolManaged,
        note:
            'Schul-/bekenntnisspezifisch. Keine generische automatische Inhaltsgenerierung.',
      ),
      const CurriculumSupportEntry(
        subject: 'Deutsch',
        delivery: CurriculumDelivery.mixed,
        note:
            'Interaktive Sprach-, Lese-, Schreib- und Rechtschreibaufgaben plus mündliche Aktivitäten.',
      ),
      const CurriculumSupportEntry(
        subject: 'Sachunterricht',
        delivery: CurriculumDelivery.mixed,
        note:
            'Interaktive Wissensaufgaben plus Beobachten, Forschen, Dokumentieren und Reflektieren.',
      ),
      const CurriculumSupportEntry(
        subject: 'Mathematik',
        delivery: CurriculumDelivery.interactiveExercise,
        note:
            'Zahlen und Daten, Operationen, Größen sowie Ebene und Raum.',
      ),
      const CurriculumSupportEntry(
        subject: 'Musik',
        delivery: CurriculumDelivery.practicalActivity,
        note:
            'Hören, Singen/Musizieren und Bewegen/Darstellen als praktische Aktivitäten.',
      ),
      const CurriculumSupportEntry(
        subject: 'Kunst und Gestaltung',
        delivery: CurriculumDelivery.practicalActivity,
        note:
            'Bildnerische Praxis, Wahrnehmen/Reflektieren und Kommunizieren.',
      ),
      const CurriculumSupportEntry(
        subject: 'Technik und Design',
        delivery: CurriculumDelivery.practicalActivity,
        note: 'Entwickeln, Herstellen und Reflektieren.',
      ),
      const CurriculumSupportEntry(
        subject: 'Bewegung und Sport',
        delivery: CurriculumDelivery.practicalActivity,
        note:
            'Sichere Bewegungsaufträge und Reflexion; reale Durchführung nicht durch Bildschirm ersetzen.',
      ),
      CurriculumSupportEntry(
        subject: g <= 2
            ? 'Lebende Fremdsprache (verbindliche Übung)'
            : 'Lebende Fremdsprache',
        delivery: CurriculumDelivery.mixed,
        note:
            'Englisch als Lumo-Ausprägung mit Wortschatz sowie Hören/Sprechen/Lesen/Schreiben; andere Schulsprachen bleiben möglich.',
      ),
      const CurriculumSupportEntry(
        subject: 'Verkehrs- und Mobilitätsbildung',
        delivery: CurriculumDelivery.practicalActivity,
        note:
            'Handlungskompetenz, Gefahrenabschätzung und Mobilitätsreflexion mit realweltlichem Üben.',
      ),
    ];
  }
}
