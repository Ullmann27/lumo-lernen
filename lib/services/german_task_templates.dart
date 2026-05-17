import 'dart:math';
import 'class_settings.dart';
import 'quiz_question.dart';

/// Hand-crafted German (Deutsch) question pool for the quiz show.
///
/// Grade-1 questions cover: phonics, syllables, simple vocabulary, opposites.
/// Grade-2 questions cover: plurals, word classes, compound words, grammar.
class GermanTaskTemplates {
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
  // Grade-1 – simple phonics, syllables, vocab (20 questions)
  // ---------------------------------------------------------------------------
  static const List<QuizQuestion> _grade1 = [
    QuizQuestion(
      id: 'de_g1_01',
      subject: 'Deutsch',
      question: 'Welcher Buchstabe fehlt? "Ap_el"',
      options: ['f', 't', 'r', 's'],
      correctIndex: 0,
      explanation: 'Das Wort heißt "Apfel" – A-p-f-e-l.',
    ),
    QuizQuestion(
      id: 'de_g1_02',
      subject: 'Deutsch',
      question: 'Wie viele Silben hat "Blume"?',
      options: ['2', '1', '3', '4'],
      correctIndex: 0,
      explanation: 'Blu-me – das sind 2 Silben.',
    ),
    QuizQuestion(
      id: 'de_g1_03',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "groß"?',
      options: ['klein', 'hoch', 'weit', 'laut'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "groß" ist "klein".',
    ),
    QuizQuestion(
      id: 'de_g1_04',
      subject: 'Deutsch',
      question: 'Welches Tier sagt "Miau"?',
      options: ['Katze', 'Hund', 'Kuh', 'Pferd'],
      correctIndex: 0,
      explanation: 'Die Katze sagt "Miau".',
    ),
    QuizQuestion(
      id: 'de_g1_05',
      subject: 'Deutsch',
      question: 'Welches Wort beginnt mit "Sch"?',
      options: ['Schule', 'Apfel', 'Buch', 'Tisch'],
      correctIndex: 0,
      explanation: '"Schule" beginnt mit dem Laut "Sch".',
    ),
    QuizQuestion(
      id: 'de_g1_06',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "alt"?',
      options: ['neu', 'groß', 'kalt', 'lang'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "alt" ist "neu".',
    ),
    QuizQuestion(
      id: 'de_g1_07',
      subject: 'Deutsch',
      question: 'Welches Tier kann fliegen?',
      options: ['Vogel', 'Hund', 'Fisch', 'Kuh'],
      correctIndex: 0,
      explanation: 'Der Vogel kann fliegen.',
    ),
    QuizQuestion(
      id: 'de_g1_08',
      subject: 'Deutsch',
      question: 'Wie viele Buchstaben hat "Hund"?',
      options: ['4', '3', '5', '6'],
      correctIndex: 0,
      explanation: 'H-u-n-d – das sind 4 Buchstaben.',
    ),
    QuizQuestion(
      id: 'de_g1_09',
      subject: 'Deutsch',
      question: 'Welches Wort reimt sich auf "Haus"?',
      options: ['Maus', 'Hund', 'Baum', 'Mond'],
      correctIndex: 0,
      explanation: 'Haus – Maus: beide enden auf "-aus".',
    ),
    QuizQuestion(
      id: 'de_g1_10',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "hell"?',
      options: ['dunkel', 'laut', 'kalt', 'schnell'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "hell" ist "dunkel".',
    ),
    QuizQuestion(
      id: 'de_g1_11',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Katze"?',
      options: ['Katzen', 'Katze', 'Kätzin', 'Kätze'],
      correctIndex: 0,
      explanation: 'Mehr als eine Katze → die Katzen.',
    ),
    QuizQuestion(
      id: 'de_g1_12',
      subject: 'Deutsch',
      question: 'Welches Wort ist ein Körperteil?',
      options: ['Nase', 'Stuhl', 'Baum', 'Brot'],
      correctIndex: 0,
      explanation: 'Die Nase ist ein Körperteil im Gesicht.',
    ),
    QuizQuestion(
      id: 'de_g1_13',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "warm"?',
      options: ['kalt', 'nass', 'müde', 'dunkel'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "warm" ist "kalt".',
    ),
    QuizQuestion(
      id: 'de_g1_14',
      subject: 'Deutsch',
      question: 'Welches Wort ist eine Farbe?',
      options: ['grün', 'Hund', 'Schule', 'laufen'],
      correctIndex: 0,
      explanation: '"Grün" ist eine Farbe – wie Gras.',
    ),
    QuizQuestion(
      id: 'de_g1_15',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "viel"?',
      options: ['wenig', 'laut', 'lang', 'schwer'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "viel" ist "wenig".',
    ),
    QuizQuestion(
      id: 'de_g1_16',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "laut"?',
      options: ['leise', 'kalt', 'klein', 'langsam'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "laut" ist "leise".',
    ),
    QuizQuestion(
      id: 'de_g1_17',
      subject: 'Deutsch',
      question: 'Welches Tier ist für seine Wolle bekannt?',
      options: ['Schaf', 'Hund', 'Katze', 'Pferd'],
      correctIndex: 0,
      explanation: 'Das Schaf wird wegen seiner Wolle gehalten.',
    ),
    QuizQuestion(
      id: 'de_g1_18',
      subject: 'Deutsch',
      question: 'Welcher Buchstabe kommt nach "D" im Alphabet?',
      options: ['E', 'F', 'C', 'G'],
      correctIndex: 0,
      explanation: 'A-B-C-D-E – nach D kommt E.',
    ),
    QuizQuestion(
      id: 'de_g1_19',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "schnell"?',
      options: ['langsam', 'leise', 'kalt', 'klein'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "schnell" ist "langsam".',
    ),
    QuizQuestion(
      id: 'de_g1_20',
      subject: 'Deutsch',
      question: 'Welches Tier lebt im Wasser?',
      options: ['Fisch', 'Hund', 'Katze', 'Hase'],
      correctIndex: 0,
      explanation: 'Der Fisch lebt im Wasser.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Grade-2 – plurals, word classes, grammar (20 questions)
  // ---------------------------------------------------------------------------
  static const List<QuizQuestion> _grade2 = [
    QuizQuestion(
      id: 'de_g2_01',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Haus"?',
      options: ['Häuser', 'Hauses', 'Hausen', 'Haus'],
      correctIndex: 0,
      explanation: 'Mehr als ein Haus → die Häuser.',
    ),
    QuizQuestion(
      id: 'de_g2_02',
      subject: 'Deutsch',
      question: 'Welches Wort ist ein Verb?',
      options: ['springen', 'Baum', 'klein', 'der'],
      correctIndex: 0,
      explanation: '"Springen" ist ein Verb – es beschreibt eine Tätigkeit.',
    ),
    QuizQuestion(
      id: 'de_g2_03',
      subject: 'Deutsch',
      question: 'Welches Wort ist ein Nomen?',
      options: ['Freude', 'laufen', 'schön', 'schnell'],
      correctIndex: 0,
      explanation: '"Freude" ist ein Nomen – es wird großgeschrieben.',
    ),
    QuizQuestion(
      id: 'de_g2_04',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Kind"?',
      options: ['Kinder', 'Kindes', 'Kinds', 'Kinden'],
      correctIndex: 0,
      explanation: 'Mehr als ein Kind → die Kinder.',
    ),
    QuizQuestion(
      id: 'de_g2_05',
      subject: 'Deutsch',
      question: 'Welches Wort ist ein Adjektiv?',
      options: ['mutig', 'laufen', 'Hund', 'ich'],
      correctIndex: 0,
      explanation: '"Mutig" ist ein Adjektiv – es beschreibt eine Eigenschaft.',
    ),
    QuizQuestion(
      id: 'de_g2_06',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Maus"?',
      options: ['Mäuse', 'Mausen', 'Mäuser', 'Mause'],
      correctIndex: 0,
      explanation: 'Mehr als eine Maus → die Mäuse.',
    ),
    QuizQuestion(
      id: 'de_g2_07',
      subject: 'Deutsch',
      question: 'Welches Wort ist zusammengesetzt?',
      options: ['Schulbus', 'Schule', 'Bus', 'groß'],
      correctIndex: 0,
      explanation: '"Schulbus" = Schule + Bus – ein zusammengesetztes Nomen.',
    ),
    QuizQuestion(
      id: 'de_g2_08',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Baum"?',
      options: ['Bäume', 'Baumes', 'Baums', 'Baume'],
      correctIndex: 0,
      explanation: 'Mehr als ein Baum → die Bäume.',
    ),
    QuizQuestion(
      id: 'de_g2_09',
      subject: 'Deutsch',
      question: 'Was bedeutet "fröhlich"?',
      options: ['glücklich', 'traurig', 'müde', 'böse'],
      correctIndex: 0,
      explanation: '"Fröhlich" bedeutet glücklich und guter Stimmung.',
    ),
    QuizQuestion(
      id: 'de_g2_10',
      subject: 'Deutsch',
      question: 'Welche Form passt? "Der Hund _____ im Garten."',
      options: ['läuft', 'laufen', 'lief', 'lauft'],
      correctIndex: 0,
      explanation: 'Er/sie/es → läuft. Die 3. Person Singular lautet "läuft".',
    ),
    QuizQuestion(
      id: 'de_g2_11',
      subject: 'Deutsch',
      question: 'Was ist ein Synonym für "schön"?',
      options: ['hübsch', 'hässlich', 'schnell', 'laut'],
      correctIndex: 0,
      explanation: '"Hübsch" und "schön" bedeuten dasselbe.',
    ),
    QuizQuestion(
      id: 'de_g2_12',
      subject: 'Deutsch',
      question: 'Welches Wort muss großgeschrieben werden?',
      options: ['Tisch', 'groß', 'schnell', 'laufen'],
      correctIndex: 0,
      explanation: '"Tisch" ist ein Nomen – Nomen werden immer großgeschrieben.',
    ),
    QuizQuestion(
      id: 'de_g2_13',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Auto"?',
      options: ['Autos', 'Autoes', 'Aute', 'Autoen'],
      correctIndex: 0,
      explanation: 'Mehr als ein Auto → die Autos.',
    ),
    QuizQuestion(
      id: 'de_g2_14',
      subject: 'Deutsch',
      question: 'Welches Wort enthält einen Umlaut?',
      options: ['Mädchen', 'Schule', 'Ball', 'Hund'],
      correctIndex: 0,
      explanation: '"Mädchen" hat das ä – das ist ein Umlaut.',
    ),
    QuizQuestion(
      id: 'de_g2_15',
      subject: 'Deutsch',
      question: 'Was bedeutet "fleißig"?',
      options: ['arbeitsam', 'faul', 'müde', 'langsam'],
      correctIndex: 0,
      explanation: '"Fleißig" bedeutet, dass jemand viel und gerne arbeitet.',
    ),
    QuizQuestion(
      id: 'de_g2_16',
      subject: 'Deutsch',
      question: 'Wie viele Silben hat "Frühling"?',
      options: ['2', '1', '3', '4'],
      correctIndex: 0,
      explanation: 'Früh-ling – das sind 2 Silben.',
    ),
    QuizQuestion(
      id: 'de_g2_17',
      subject: 'Deutsch',
      question: 'Welches Wort beschreibt eine Eigenschaft?',
      options: ['tapfer', 'Katze', 'laufen', 'über'],
      correctIndex: 0,
      explanation: '"Tapfer" ist ein Adjektiv – es beschreibt eine Eigenschaft.',
    ),
    QuizQuestion(
      id: 'de_g2_18',
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "traurig"?',
      options: ['fröhlich', 'müde', 'böse', 'laut'],
      correctIndex: 0,
      explanation: 'Das Gegenteil von "traurig" ist "fröhlich".',
    ),
    QuizQuestion(
      id: 'de_g2_19',
      subject: 'Deutsch',
      question: 'Wie heißt die Mehrzahl von "Vogel"?',
      options: ['Vögel', 'Vogels', 'Vogelen', 'Vögeln'],
      correctIndex: 0,
      explanation: 'Mehr als ein Vogel → die Vögel.',
    ),
    QuizQuestion(
      id: 'de_g2_20',
      subject: 'Deutsch',
      question: 'Welcher Satz ist grammatikalisch richtig?',
      options: [
        'Die Katze schläft.',
        'Den Katze schläft.',
        'Die Katze schlafen.',
        'Das Katze schläft.',
      ],
      correctIndex: 0,
      explanation:
          '"Die Katze" (Nominativ, weiblich) + "schläft" (3. Person Sg.).',
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
