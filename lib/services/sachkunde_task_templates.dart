import 'dart:math';
import 'class_settings.dart';
import 'quiz_question.dart';

/// Hand-crafted Sachkunde question pool for the quiz show.
///
/// Grade-1 questions: seasons, animals, community helpers, basic nature.
/// Grade-2 questions: Austrian geography, science, health, environment.
class SachkundeTaskTemplates {
  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the question pool for [level] with options shuffled per call.
  static List<QuizQuestion> forLevel(ClassLevel level, [Random? rng]) {
    rng ??= Random();
    final pool = level == ClassLevel.klasse1
        ? _grade1
        : [..._grade1, ..._grade2];
    return pool.map((q) => _shuffle(q, rng!)).toList();
  }

  // ---------------------------------------------------------------------------
  // Grade-1 – seasons, animals, community (20 questions)
  // ---------------------------------------------------------------------------
  static const List<QuizQuestion> _grade1 = [
    QuizQuestion(
      id: 'sk_g1_01',
      subject: 'Sachkunde',
      question: 'Wie viele Jahreszeiten gibt es?',
      options: ['4', '2', '3', '5'],
      correctIndex: 0,
      explanation: 'Es gibt 4 Jahreszeiten: Frühling, Sommer, Herbst, Winter.',
    ),
    QuizQuestion(
      id: 'sk_g1_02',
      subject: 'Sachkunde',
      question: 'Welche Farbe hat eine reife Tomate?',
      options: ['rot', 'blau', 'grün', 'lila'],
      correctIndex: 0,
      explanation: 'Eine reife Tomate ist rot.',
    ),
    QuizQuestion(
      id: 'sk_g1_03',
      subject: 'Sachkunde',
      question: 'Was macht ein Feuerwehrmann?',
      options: [
        'Brände löschen',
        'Kranke heilen',
        'Häuser bauen',
        'Unterricht geben',
      ],
      correctIndex: 0,
      explanation: 'Die Feuerwehr löscht Brände und hilft bei Unfällen.',
    ),
    QuizQuestion(
      id: 'sk_g1_04',
      subject: 'Sachkunde',
      question: 'Welches Tier legt Eier?',
      options: ['Huhn', 'Hund', 'Katze', 'Pferd'],
      correctIndex: 0,
      explanation: 'Das Huhn legt Eier.',
    ),
    QuizQuestion(
      id: 'sk_g1_05',
      subject: 'Sachkunde',
      question: 'Wie viele Tage hat eine Woche?',
      options: ['7', '5', '6', '8'],
      correctIndex: 0,
      explanation: 'Eine Woche hat 7 Tage: Mo, Di, Mi, Do, Fr, Sa, So.',
    ),
    QuizQuestion(
      id: 'sk_g1_06',
      subject: 'Sachkunde',
      question: 'Welche Jahreszeit kommt nach dem Winter?',
      options: ['Frühling', 'Sommer', 'Herbst', 'Schnee'],
      correctIndex: 0,
      explanation: 'Nach dem Winter kommt der Frühling.',
    ),
    QuizQuestion(
      id: 'sk_g1_07',
      subject: 'Sachkunde',
      question: 'Wie viele Beine hat ein Hund?',
      options: ['4', '2', '6', '8'],
      correctIndex: 0,
      explanation: 'Ein Hund hat 4 Beine – er ist ein Vierbeiner.',
    ),
    QuizQuestion(
      id: 'sk_g1_08',
      subject: 'Sachkunde',
      question: 'Was macht eine Lehrerin?',
      options: [
        'Unterricht geben',
        'Kranke heilen',
        'Feuer löschen',
        'Haare schneiden',
      ],
      correctIndex: 0,
      explanation: 'Die Lehrerin gibt den Schülerinnen und Schülern Unterricht.',
    ),
    QuizQuestion(
      id: 'sk_g1_09',
      subject: 'Sachkunde',
      question: 'Welche Farbe hat Schnee?',
      options: ['weiß', 'blau', 'schwarz', 'gelb'],
      correctIndex: 0,
      explanation: 'Schnee ist weiß.',
    ),
    QuizQuestion(
      id: 'sk_g1_10',
      subject: 'Sachkunde',
      question: 'Wie viele Monate hat ein Jahr?',
      options: ['12', '10', '11', '13'],
      correctIndex: 0,
      explanation: 'Ein Jahr hat 12 Monate.',
    ),
    QuizQuestion(
      id: 'sk_g1_11',
      subject: 'Sachkunde',
      question: 'Was trinken Pflanzen?',
      options: ['Wasser', 'Milch', 'Saft', 'Tee'],
      correctIndex: 0,
      explanation: 'Pflanzen nehmen Wasser durch ihre Wurzeln auf.',
    ),
    QuizQuestion(
      id: 'sk_g1_12',
      subject: 'Sachkunde',
      question: 'Welches Tier gibt uns Milch?',
      options: ['Kuh', 'Hund', 'Hase', 'Vogel'],
      correctIndex: 0,
      explanation: 'Die Kuh gibt uns Milch.',
    ),
    QuizQuestion(
      id: 'sk_g1_13',
      subject: 'Sachkunde',
      question: 'Was macht ein Arzt?',
      options: [
        'Kranke behandeln',
        'Haare schneiden',
        'Feuer löschen',
        'Häuser bauen',
      ],
      correctIndex: 0,
      explanation: 'Der Arzt untersucht und behandelt kranke Menschen.',
    ),
    QuizQuestion(
      id: 'sk_g1_14',
      subject: 'Sachkunde',
      question: 'Welche Jahreszeit ist am wärmsten?',
      options: ['Sommer', 'Winter', 'Frühling', 'Herbst'],
      correctIndex: 0,
      explanation: 'Im Sommer ist es am wärmsten.',
    ),
    QuizQuestion(
      id: 'sk_g1_15',
      subject: 'Sachkunde',
      question: 'Was ist ein Gemüse?',
      options: ['Karotte', 'Apfel', 'Banane', 'Erdbeere'],
      correctIndex: 0,
      explanation: 'Die Karotte ist ein Gemüse – sie wächst unter der Erde.',
    ),
    QuizQuestion(
      id: 'sk_g1_16',
      subject: 'Sachkunde',
      question: 'Wie viele Beine hat eine Spinne?',
      options: ['8', '4', '6', '10'],
      correctIndex: 0,
      explanation: 'Eine Spinne hat 8 Beine.',
    ),
    QuizQuestion(
      id: 'sk_g1_17',
      subject: 'Sachkunde',
      question: 'Was brauchen Pflanzen zum Wachsen?',
      options: [
        'Licht und Wasser',
        'Milch und Saft',
        'Eis und Schnee',
        'Öl und Mehl',
      ],
      correctIndex: 0,
      explanation: 'Pflanzen brauchen Licht (Sonne) und Wasser zum Wachsen.',
    ),
    QuizQuestion(
      id: 'sk_g1_18',
      subject: 'Sachkunde',
      question: 'Welches Tier lebt auf einem Bauernhof?',
      options: ['Schwein', 'Delfin', 'Tiger', 'Pinguin'],
      correctIndex: 0,
      explanation: 'Das Schwein ist ein typisches Bauernhoftier.',
    ),
    QuizQuestion(
      id: 'sk_g1_19',
      subject: 'Sachkunde',
      question: 'Was macht ein Briefträger?',
      options: [
        'Briefe zustellen',
        'Feuer löschen',
        'Haare schneiden',
        'Tiere pflegen',
      ],
      correctIndex: 0,
      explanation: 'Der Briefträger bringt Briefe und Pakete zu uns nach Hause.',
    ),
    QuizQuestion(
      id: 'sk_g1_20',
      subject: 'Sachkunde',
      question: 'Welche Frucht ist gelb und krumm?',
      options: ['Banane', 'Apfel', 'Kirsche', 'Traube'],
      correctIndex: 0,
      explanation: 'Die Banane ist gelb und krumm.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Grade-2 – geography, science, health, environment (20 questions)
  // ---------------------------------------------------------------------------
  static const List<QuizQuestion> _grade2 = [
    QuizQuestion(
      id: 'sk_g2_01',
      subject: 'Sachkunde',
      question: 'Was ist die Hauptstadt von Österreich?',
      options: ['Wien', 'Salzburg', 'Graz', 'Linz'],
      correctIndex: 0,
      explanation: 'Wien ist die Hauptstadt und größte Stadt Österreichs.',
    ),
    QuizQuestion(
      id: 'sk_g2_02',
      subject: 'Sachkunde',
      question: 'Wie viele Tage hat ein normales Jahr?',
      options: ['365', '360', '364', '366'],
      correctIndex: 0,
      explanation: 'Ein normales Jahr hat 365 Tage (Schaltjahre haben 366).',
    ),
    QuizQuestion(
      id: 'sk_g2_03',
      subject: 'Sachkunde',
      question: 'Welches Gas atmen wir ein?',
      options: ['Sauerstoff', 'Wasserstoff', 'Stickstoff', 'Kohlendioxid'],
      correctIndex: 0,
      explanation: 'Wir atmen Sauerstoff (O₂) ein und Kohlendioxid (CO₂) aus.',
    ),
    QuizQuestion(
      id: 'sk_g2_04',
      subject: 'Sachkunde',
      question: 'Was ist das größte Tier der Welt?',
      options: ['Blauwal', 'Elefant', 'Hai', 'Giraffe'],
      correctIndex: 0,
      explanation: 'Der Blauwal ist das größte Tier – er kann 30 m lang werden.',
    ),
    QuizQuestion(
      id: 'sk_g2_05',
      subject: 'Sachkunde',
      question: 'Wie viele Planeten hat unser Sonnensystem?',
      options: ['8', '7', '9', '10'],
      correctIndex: 0,
      explanation:
          'Es gibt 8 Planeten: Merkur, Venus, Erde, Mars, Jupiter, Saturn, Uranus, Neptun.',
    ),
    QuizQuestion(
      id: 'sk_g2_06',
      subject: 'Sachkunde',
      question: 'Welcher Fluss fließt durch Wien?',
      options: ['Donau', 'Rhein', 'Elbe', 'Inn'],
      correctIndex: 0,
      explanation: 'Die Donau fließt durch Wien.',
    ),
    QuizQuestion(
      id: 'sk_g2_07',
      subject: 'Sachkunde',
      question: 'Welches Bundesland liegt im Westen Österreichs?',
      options: ['Vorarlberg', 'Wien', 'Burgenland', 'Niederösterreich'],
      correctIndex: 0,
      explanation: 'Vorarlberg ist das westlichste Bundesland Österreichs.',
    ),
    QuizQuestion(
      id: 'sk_g2_08',
      subject: 'Sachkunde',
      question: 'Wie viele Sinne hat der Mensch?',
      options: ['5', '3', '4', '6'],
      correctIndex: 0,
      explanation:
          'Die 5 Sinne: Sehen, Hören, Riechen, Schmecken, Tasten.',
    ),
    QuizQuestion(
      id: 'sk_g2_09',
      subject: 'Sachkunde',
      question: 'Welches Tier ist das schnellste Landtier?',
      options: ['Gepard', 'Pferd', 'Delfin', 'Adler'],
      correctIndex: 0,
      explanation: 'Der Gepard läuft bis zu 120 km/h – er ist das schnellste Landtier.',
    ),
    QuizQuestion(
      id: 'sk_g2_10',
      subject: 'Sachkunde',
      question: 'Was ist Recycling?',
      options: [
        'Wiederverwertung von Materialien',
        'Müll verbrennen',
        'Bäume pflanzen',
        'Wasser sparen',
      ],
      correctIndex: 0,
      explanation: 'Beim Recycling werden Materialien wiederverwertet.',
    ),
    QuizQuestion(
      id: 'sk_g2_11',
      subject: 'Sachkunde',
      question: 'Wie nennt man einen Arzt für Zähne?',
      options: ['Zahnarzt', 'Tierarzt', 'Hautarzt', 'Augenarzt'],
      correctIndex: 0,
      explanation: 'Der Zahnarzt kümmert sich um unsere Zähne.',
    ),
    QuizQuestion(
      id: 'sk_g2_12',
      subject: 'Sachkunde',
      question: 'Was ist der höchste Berg in Österreich?',
      options: ['Großglockner', 'Zugspitze', 'Mont Blanc', 'Dachstein'],
      correctIndex: 0,
      explanation:
          'Der Großglockner (3 798 m) ist der höchste Berg Österreichs.',
    ),
    QuizQuestion(
      id: 'sk_g2_13',
      subject: 'Sachkunde',
      question: 'Wie viele Kontinente gibt es?',
      options: ['7', '5', '6', '8'],
      correctIndex: 0,
      explanation:
          'Es gibt 7 Kontinente: Europa, Asien, Afrika, Amerika (N+S), Australien, Antarktis.',
    ),
    QuizQuestion(
      id: 'sk_g2_14',
      subject: 'Sachkunde',
      question: 'Welches Organ pumpt das Blut durch den Körper?',
      options: ['Herz', 'Lunge', 'Leber', 'Niere'],
      correctIndex: 0,
      explanation: 'Das Herz pumpt das Blut durch den Körper.',
    ),
    QuizQuestion(
      id: 'sk_g2_15',
      subject: 'Sachkunde',
      question: 'Was schützt uns vor schädlichen UV-Strahlen der Sonne?',
      options: ['Ozonschicht', 'Regenwolken', 'Magnetfeld', 'Atmosphäre'],
      correctIndex: 0,
      explanation: 'Die Ozonschicht in der Stratosphäre filtert UV-Strahlen.',
    ),
    QuizQuestion(
      id: 'sk_g2_16',
      subject: 'Sachkunde',
      question: 'Was ist eine erneuerbare Energiequelle?',
      options: ['Solarenergie', 'Kohle', 'Erdöl', 'Erdgas'],
      correctIndex: 0,
      explanation:
          'Solarenergie kommt von der Sonne und ist unerschöpflich.',
    ),
    QuizQuestion(
      id: 'sk_g2_17',
      subject: 'Sachkunde',
      question: 'Womit beginnt eine Nahrungskette?',
      options: ['Pflanzen', 'Raubtieren', 'Insekten', 'Pilzen'],
      correctIndex: 0,
      explanation:
          'Nahrungsketten beginnen immer mit Pflanzen (Produzenten).',
    ),
    QuizQuestion(
      id: 'sk_g2_18',
      subject: 'Sachkunde',
      question: 'Wo lebt ein Pinguin?',
      options: ['Antarktis', 'Nordpol', 'Sahara', 'Amazonas'],
      correctIndex: 0,
      explanation: 'Die meisten Pinguinarten leben in der Antarktis.',
    ),
    QuizQuestion(
      id: 'sk_g2_19',
      subject: 'Sachkunde',
      question: 'Was bedeutet "Nachhaltigkeit"?',
      options: [
        'Schonender Umgang mit der Natur',
        'Schnelle Entwicklung',
        'Viel Konsum',
        'Große Stärke',
      ],
      correctIndex: 0,
      explanation:
          'Nachhaltigkeit bedeutet, natürliche Ressourcen schonend zu nutzen.',
    ),
    QuizQuestion(
      id: 'sk_g2_20',
      subject: 'Sachkunde',
      question: 'Wie viele Bundesländer hat Österreich?',
      options: ['9', '7', '8', '10'],
      correctIndex: 0,
      explanation: 'Österreich hat 9 Bundesländer.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Helper: shuffle options while tracking correct answer
  // ---------------------------------------------------------------------------
  static QuizQuestion _shuffle(QuizQuestion q, Random rng) {
    final correct = q.options[q.correctIndex];
    final opts = List<String>.from(q.options)..shuffle(rng);
    return QuizQuestion(
      id: q.id,
      subject: q.subject,
      question: q.question,
      options: opts,
      correctIndex: opts.indexOf(correct),
      explanation: q.explanation,
    );
  }
}
