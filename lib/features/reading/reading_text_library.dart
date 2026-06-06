// ════════════════════════════════════════════════════════════════════════
// READING TEXT LIBRARY — Volksschul-Lesetexte K1-K4
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 34: Foundation fuer den Reading Buddy. Kurze Texte pro
// Klassenstufe, lehrplan-konform (AT 2023), kindgerecht und mit
// steigender Komplexitaet von kurzen 1-Satz-K1-Texten bis 4-Satz-K4-Texten.
// ════════════════════════════════════════════════════════════════════════

class ReadingText {
  const ReadingText({
    required this.id,
    required this.grade,
    required this.title,
    required this.lines,
    required this.emoji,
  });

  final String id;
  final int grade;
  final String title;
  final List<String> lines;
  final String emoji;

  /// Alle Woerter aus allen Zeilen flach.
  List<String> get words {
    final out = <String>[];
    for (final line in lines) {
      out.addAll(line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty));
    }
    return out;
  }
}

class ReadingTextLibrary {
  const ReadingTextLibrary._();

  static const List<ReadingText> all = <ReadingText>[
    // ── KLASSE 1 ───────────────────────────────────────────
    ReadingText(
      id: 'g1_mama_und_tom',
      grade: 1,
      title: 'Mama und Tom',
      lines: [
        'Mama backt einen Kuchen.',
        'Tom hilft ihr.',
        'Es duftet sehr gut.',
      ],
      emoji: '🍰',
    ),
    ReadingText(
      id: 'g1_der_garten',
      grade: 1,
      title: 'Im Garten',
      lines: [
        'Im Garten bluehen die Blumen.',
        'Eine Biene summt um die Rose.',
        'Lisa lacht und freut sich.',
      ],
      emoji: '🌸',
    ),
    ReadingText(
      id: 'g1_lumo_fox',
      grade: 1,
      title: 'Lumo der Fuchs',
      lines: [
        'Lumo ist ein kleiner Fuchs.',
        'Er lebt im Wald.',
        'Lumo spielt mit Sternen.',
      ],
      emoji: '🦊',
    ),
    ReadingText(
      id: 'g1_kater',
      grade: 1,
      title: 'Der Kater',
      lines: [
        'Mein Kater heisst Felix.',
        'Er schlaeft gerne auf dem Sofa.',
        'Manchmal jagt er Maeuse.',
      ],
      emoji: '🐱',
    ),

    // ── KLASSE 2 ───────────────────────────────────────────
    ReadingText(
      id: 'g2_winter',
      grade: 2,
      title: 'Im Winter',
      lines: [
        'Es schneit seit dem Morgen.',
        'Die Kinder bauen einen grossen Schneemann.',
        'Sie geben ihm eine alte Karotten-Nase.',
        'Am Abend leuchten die Sterne hell.',
      ],
      emoji: '⛄',
    ),
    ReadingText(
      id: 'g2_baeckerei',
      grade: 2,
      title: 'In der Baeckerei',
      lines: [
        'Die Baeckerin steht frueh auf.',
        'Sie backt Brot, Semmeln und Kipferl.',
        'Der Duft zieht durch die ganze Strasse.',
      ],
      emoji: '🥨',
    ),
    ReadingText(
      id: 'g2_zoo',
      grade: 2,
      title: 'Im Zoo',
      lines: [
        'Heute gehen wir in den Tiergarten.',
        'Wir sehen Elefanten, Affen und Zebras.',
        'Die Pinguine watscheln auf dem Eis.',
        'Das war ein wunderbarer Tag.',
      ],
      emoji: '🐘',
    ),

    // ── KLASSE 3 ───────────────────────────────────────────
    ReadingText(
      id: 'g3_schwimmbad',
      grade: 3,
      title: 'Im Schwimmbad',
      lines: [
        'Marie schwimmt zum ersten Mal ohne Schwimmreifen.',
        'Sie hat etwas Angst, aber Papa ist gleich neben ihr.',
        'Mit jedem Schwimmzug wird sie sicherer.',
        'Am Ende klatscht ihre Mama vom Beckenrand.',
      ],
      emoji: '🏊',
    ),
    ReadingText(
      id: 'g3_wanderung',
      grade: 3,
      title: 'Berg-Wanderung',
      lines: [
        'Familie Berger wandert auf den Schneeberg.',
        'Der Weg geht steil bergauf, durch Wald und ueber Felsen.',
        'Oben angekommen sehen sie die ganze Steiermark vor sich.',
        'Sie machen ein Foto und essen eine Jause.',
      ],
      emoji: '🏔️',
    ),

    // ── KLASSE 4 ───────────────────────────────────────────
    ReadingText(
      id: 'g4_lumo_und_alina',
      grade: 4,
      title: 'Lumo und Alina',
      lines: [
        'An einem Sonntag entdeckt Alina einen kleinen Fuchs in ihrem Garten.',
        'Sie nennt ihn Lumo, weil er goldene Augen hat wie Lampen.',
        'Gemeinsam erkunden sie den Wald und sammeln Sternen-Steine.',
        'Lumo bringt Alina bei, wie man im Mondlicht zaubert.',
      ],
      emoji: '🦊',
    ),
    ReadingText(
      id: 'g4_donau',
      grade: 4,
      title: 'Die Donau',
      lines: [
        'Die Donau fliesst durch viele Laender.',
        'Sie beginnt im Schwarzwald und mundet am Schwarzen Meer.',
        'In Oesterreich fliesst sie durch Linz, Wien und Hainburg.',
        'Viele Tiere, wie Biber und Reiher, leben am Donau-Auwald.',
      ],
      emoji: '🌊',
    ),
  ];

  static List<ReadingText> forGrade(int grade) {
    return all.where((t) => t.grade == grade).toList(growable: false);
  }
}
