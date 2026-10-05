/// Lückensätze für den Deutsch-Bereich (Bild 04): ein Wort fehlt, das Kind
/// wählt es aus vier Wörtern. Österreichische Volksschule, Klasse 1–2 und 3–4.
class GapSentence {
  const GapSentence({
    required this.before,
    required this.after,
    required this.answer,
    required this.options,
    required this.emoji,
    required this.minGrade,
    required this.maxGrade,
    this.image,
  });

  final String before;
  final String after;
  final String answer;
  final List<String> options;
  final String emoji;
  final int minGrade;
  final int maxGrade;

  /// Optionales Bild statt des Emojis.
  final String? image;

  String get spoken => '$before … $after';
  String get solved => '$before $answer$after';
}

class DeutschGapSentences {
  const DeutschGapSentences._();

  static const all = <GapSentence>[
    GapSentence(
        before: 'Der Hund spielt im',
        after: '.',
        answer: 'Garten',
        options: ['Haus', 'Garten', 'Ball', 'Baum'],
        emoji: '🐶',
        image: 'assets/lumo_design/cards/deutsch_hund.png',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Die Katze trinkt',
        after: '.',
        answer: 'Milch',
        options: ['Brot', 'Sand', 'Milch', 'Holz'],
        emoji: '🐱',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Im Winter fällt',
        after: '.',
        answer: 'Schnee',
        options: ['Schnee', 'Sonne', 'Laub', 'Gras'],
        emoji: '❄️',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Ich putze mir die',
        after: '.',
        answer: 'Zähne',
        options: ['Schuhe', 'Bücher', 'Wolken', 'Zähne'],
        emoji: '🪥',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Der Vogel sitzt auf dem',
        after: '.',
        answer: 'Ast',
        options: ['Tisch', 'Ast', 'Fisch', 'Teller'],
        emoji: '🐦',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Mama liest ein',
        after: '.',
        answer: 'Buch',
        options: ['Brot', 'Bett', 'Buch', 'Bad'],
        emoji: '📖',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Die Sonne',
        after: ' am Himmel.',
        answer: 'scheint',
        options: ['schläft', 'scheint', 'schwimmt', 'singt'],
        emoji: '☀️',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Wir gehen in die',
        after: '.',
        answer: 'Schule',
        options: ['Schaukel', 'Schere', 'Schachtel', 'Schule'],
        emoji: '🏫',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Der Apfel ist',
        after: '.',
        answer: 'rot',
        options: ['rot', 'laut', 'schnell', 'müde'],
        emoji: '🍎',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Der Fisch schwimmt im',
        after: '.',
        answer: 'Wasser',
        options: ['Wald', 'Wind', 'Wasser', 'Wagen'],
        emoji: '🐟',
        minGrade: 1,
        maxGrade: 2),
    GapSentence(
        before: 'Weil es regnet, nehme ich einen',
        after: ' mit.',
        answer: 'Regenschirm',
        options: ['Sonnenhut', 'Regenschirm', 'Schlitten', 'Eimer'],
        emoji: '☔',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Im Herbst fallen die',
        after: ' von den Bäumen.',
        answer: 'Blätter',
        options: ['Steine', 'Wolken', 'Blätter', 'Fenster'],
        emoji: '🍂',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Der Bäcker backt frisches',
        after: '.',
        answer: 'Brot',
        options: ['Brot', 'Gras', 'Eis', 'Papier'],
        emoji: '🥖',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Die Kinder',
        after: ' im Park Fußball.',
        answer: 'spielen',
        options: ['schlafen', 'kochen', 'rechnen', 'spielen'],
        emoji: '⚽',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Nach dem Essen wasche ich das',
        after: ' ab.',
        answer: 'Geschirr',
        options: ['Fahrrad', 'Geschirr', 'Auto', 'Fenster'],
        emoji: '🍽️',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Eine Woche hat sieben',
        after: '.',
        answer: 'Tage',
        options: ['Monate', 'Jahre', 'Tage', 'Stunden'],
        emoji: '📅',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Im Frühling',
        after: ' die Blumen.',
        answer: 'blühen',
        options: ['blühen', 'frieren', 'schmelzen', 'schlafen'],
        emoji: '🌷',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Der Zug fährt pünktlich vom',
        after: ' ab.',
        answer: 'Bahnhof',
        options: ['Bauernhof', 'Spielplatz', 'Bahnhof', 'Garten'],
        emoji: '🚆',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Die Eule ist ein Tier, das in der',
        after: ' wach ist.',
        answer: 'Nacht',
        options: ['Schule', 'Nacht', 'Küche', 'Pause'],
        emoji: '🦉',
        minGrade: 3,
        maxGrade: 4),
    GapSentence(
        before: 'Ich schreibe einen Brief an meine',
        after: '.',
        answer: 'Oma',
        options: ['Tasche', 'Lampe', 'Gabel', 'Oma'],
        emoji: '✉️',
        minGrade: 3,
        maxGrade: 4),
  ];

  static List<GapSentence> forGrade(int grade) => [
        for (final sentence in all)
          if (grade >= sentence.minGrade && grade <= sentence.maxGrade)
            sentence,
      ];
}
