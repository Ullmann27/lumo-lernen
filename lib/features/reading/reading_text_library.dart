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
        'Im Garten blühen die Blumen.',
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
        'Mein Kater heißt Felix.',
        'Er schläft gerne auf dem Sofa.',
        'Manchmal jagt er Mäuse.',
      ],
      emoji: '🐱',
    ),
    ReadingText(
      id: 'g1_ball',
      grade: 1,
      title: 'Der rote Ball',
      lines: [
        'Ben hat einen roten Ball.',
        'Der Ball rollt in die Pfütze.',
        'Ben lacht und holt ihn.',
      ],
      emoji: '⚽',
    ),
    ReadingText(
      id: 'g1_regen',
      grade: 1,
      title: 'Es regnet',
      lines: [
        'Es regnet am Morgen.',
        'Ida nimmt den Schirm mit.',
        'Ihre Stiefel sind gelb.',
      ],
      emoji: '☔',
    ),

    // ── KLASSE 2 ───────────────────────────────────────────
    ReadingText(
      id: 'g2_winter',
      grade: 2,
      title: 'Im Winter',
      lines: [
        'Es schneit seit dem Morgen.',
        'Die Kinder bauen einen großen Schneemann.',
        'Sie geben ihm eine Karotte als Nase.',
        'Am Abend leuchten die Sterne hell.',
      ],
      emoji: '⛄',
    ),
    ReadingText(
      id: 'g2_baeckerei',
      grade: 2,
      title: 'In der Bäckerei',
      lines: [
        'Die Bäckerin steht früh auf.',
        'Sie backt Brot, Semmeln und Kipferl.',
        'Der Duft zieht durch die ganze Straße.',
      ],
      emoji: '🥨',
    ),
    ReadingText(
      id: 'g2_zoo',
      grade: 2,
      title: 'Im Tiergarten',
      lines: [
        'Heute gehen wir in den Tiergarten.',
        'Wir sehen Elefanten, Affen und Zebras.',
        'Die Pinguine watscheln über das Eis.',
        'Das war ein wunderbarer Tag.',
      ],
      emoji: '🐘',
    ),
    ReadingText(
      id: 'g2_geburtstag',
      grade: 2,
      title: 'Lenas Geburtstag',
      lines: [
        'Lena wird heute acht Jahre alt.',
        'Ihre Freunde kommen am Nachmittag.',
        'Auf dem Tisch steht eine Torte mit Kerzen.',
        'Alle singen ein lustiges Lied.',
      ],
      emoji: '🎂',
    ),
    ReadingText(
      id: 'g2_herbst',
      grade: 2,
      title: 'Herbst im Park',
      lines: [
        'Im Herbst werden die Blätter bunt.',
        'Der Wind bläst sie von den Bäumen.',
        'Jonas sammelt Kastanien in seiner Tasche.',
        'Zu Hause bastelt er daraus kleine Tiere.',
      ],
      emoji: '🍂',
    ),
    ReadingText(
      id: 'g2_schulweg',
      grade: 2,
      title: 'Mein Schulweg',
      lines: [
        'Am Morgen gehe ich mit Paul zur Schule.',
        'An der Ampel warten wir auf Grün.',
        'Der Schülerlotse hilft uns über die Straße.',
        'Dann sind wir pünktlich in der Klasse.',
      ],
      emoji: '🚸',
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
      title: 'Bergwanderung',
      lines: [
        'Familie Berger wandert auf den Schneeberg.',
        'Der Weg geht steil bergauf, durch den Wald und über Felsen.',
        'Oben sehen sie weit über das Land.',
        'Auf der Hütte essen sie eine Jause und trinken Saft.',
      ],
      emoji: '🏔️',
    ),
    ReadingText(
      id: 'g3_bienen',
      grade: 3,
      title: 'Fleißige Bienen',
      lines: [
        'Bienen leben in einem Bienenstock.',
        'Sie fliegen von Blüte zu Blüte und sammeln Nektar.',
        'Daraus machen sie im Stock süßen Honig.',
        'Ohne Bienen würden viele Obstbäume keine Früchte tragen.',
      ],
      emoji: '🐝',
    ),
    ReadingText(
      id: 'g3_bibliothek',
      grade: 3,
      title: 'In der Bücherei',
      lines: [
        'Jeden Freitag geht die Klasse in die Bücherei.',
        'Tim sucht ein Buch über Dinosaurier.',
        'Die Bibliothekarin zeigt ihm das richtige Regal.',
        'Zu Hause liest er gleich drei Kapitel hintereinander.',
      ],
      emoji: '📚',
    ),
    ReadingText(
      id: 'g3_igel',
      grade: 3,
      title: 'Der Igel im Herbst',
      lines: [
        'Im Herbst frisst der Igel besonders viel.',
        'Er sucht Käfer, Würmer und Schnecken.',
        'Wenn es kalt wird, baut er sich ein Nest aus Laub.',
        'Dort hält er seinen Winterschlaf bis zum Frühling.',
      ],
      emoji: '🦔',
    ),
    ReadingText(
      id: 'g3_flohmarkt',
      grade: 3,
      title: 'Der Flohmarkt',
      lines: [
        'Am Samstag ist auf dem Schulhof ein Flohmarkt.',
        'Sara verkauft ihre alten Bilderbücher und ein Puzzle.',
        'Für das Geld kauft sie sich ein gebrauchtes Fahrrad.',
        'Am Abend zählt sie stolz ihre restlichen Münzen.',
      ],
      emoji: '🧸',
    ),

    // ── KLASSE 4 ───────────────────────────────────────────
    ReadingText(
      id: 'g4_lumo_und_alina',
      grade: 4,
      title: 'Lumo und Alina',
      lines: [
        'An einem Sonntag entdeckt Alina einen kleinen Fuchs in ihrem Garten.',
        'Sie nennt ihn Lumo, weil seine Augen golden leuchten.',
        'Gemeinsam erkunden sie den Wald und sammeln glitzernde Steine.',
        'Am Abend zeigt Lumo ihr die hellsten Sterne am Himmel.',
      ],
      emoji: '🦊',
    ),
    ReadingText(
      id: 'g4_donau',
      grade: 4,
      title: 'Die Donau',
      lines: [
        'Die Donau fließt durch viele Länder Europas.',
        'Sie entspringt im Schwarzwald und mündet ins Schwarze Meer.',
        'In Österreich fließt sie durch Linz und Wien.',
        'In den Auwäldern an ihrem Ufer leben Biber, Reiher und Frösche.',
      ],
      emoji: '🌊',
    ),
    ReadingText(
      id: 'g4_wasserkreislauf',
      grade: 4,
      title: 'Der Weg des Wassers',
      lines: [
        'Die Sonne erwärmt das Wasser in Seen und Meeren.',
        'Ein Teil davon verdunstet und steigt als Wasserdampf auf.',
        'In der kalten Luft bilden sich daraus Wolken.',
        'Wenn die Tropfen schwer genug sind, fällt das Wasser als Regen zurück.',
      ],
      emoji: '💧',
    ),
    ReadingText(
      id: 'g4_erfinder',
      grade: 4,
      title: 'Eine kluge Idee',
      lines: [
        'Leo ärgert sich, weil sein Fahrradlicht immer ausgeht.',
        'Er baut mit seinem Opa einen kleinen Dynamo an das Rad.',
        'Beim Treten erzeugt das Rad jetzt selbst den Strom.',
        'Stolz fährt Leo am Abend mit hellem Licht nach Hause.',
      ],
      emoji: '💡',
    ),
    ReadingText(
      id: 'g4_wien',
      grade: 4,
      title: 'Ausflug nach Wien',
      lines: [
        'Die vierte Klasse fährt mit dem Zug nach Wien.',
        'Zuerst besuchen sie den Stephansdom mitten in der Stadt.',
        'Danach staunen sie im Naturhistorischen Museum über die Dinosaurier.',
        'Am Nachmittag fahren sie mit dem Riesenrad im Prater.',
      ],
      emoji: '🏰',
    ),
    ReadingText(
      id: 'g4_streit',
      grade: 4,
      title: 'Streit und Versöhnung',
      lines: [
        'In der Pause streiten Mia und Elif um den Ball.',
        'Beide sind wütend und reden den ganzen Vormittag nicht miteinander.',
        'Nach der Schule entschuldigt sich Mia, weil ihr der Streit leidtut.',
        'Am nächsten Tag spielen die beiden wieder gemeinsam Fußball.',
      ],
      emoji: '🤝',
    ),
  ];

  static List<ReadingText> forGrade(int grade) {
    return all.where((t) => t.grade == grade).toList(growable: false);
  }
}
