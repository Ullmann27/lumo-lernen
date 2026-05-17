import 'dart:math';
import 'class_settings.dart';

class Exercise {
  final String subject;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;

  const Exercise({
    required this.subject,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });
}

class ExerciseFactory {
  static int _index = 0;

  // ── Easy (Klasse 1: Rechnen bis 20, Buchstaben, Mengen zählen) ────────────
  static const List<Exercise> _easyExercises = [
    Exercise(
      subject: 'Mathematik',
      question: '12 + 7 = ?',
      options: ['17', '18', '19', '20'],
      correctAnswer: '19',
      explanation: 'Zähle von 12 aus 7 weiter: 13, 14, 15, 16, 17, 18, 19.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '18 - 5 = ?',
      options: ['11', '12', '13', '14'],
      correctAnswer: '13',
      explanation: 'Zähle von 18 aus 5 zurück: 17, 16, 15, 14, 13.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '9 + 6 = ?',
      options: ['13', '14', '15', '16'],
      correctAnswer: '15',
      explanation: '9 + 6 = 15. Zähle von 9 aus 6 weiter.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '16 - 8 = ?',
      options: ['6', '7', '8', '9'],
      correctAnswer: '8',
      explanation: '16 - 8 = 8. Du kannst auch überlegen: 8 + 8 = 16.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '3 + 3 + 3 = ?',
      options: ['6', '7', '8', '9'],
      correctAnswer: '9',
      explanation: '3 + 3 + 3 = 9. Das ist dasselbe wie 3 × 3.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '7 + 5 = ?',
      options: ['10', '11', '12', '13'],
      correctAnswer: '12',
      explanation: '7 + 5 = 12. Zähle von 7 aus 5 weiter.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '5 + 8 = ?',
      options: ['11', '12', '13', '14'],
      correctAnswer: '13',
      explanation: '5 + 8 = 13. Zähle von 8 aus 5 weiter: 9,10,11,12,13.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was kommt nach der 9?',
      options: ['7', '8', '10', '11'],
      correctAnswer: '10',
      explanation: 'Nach 9 kommt 10 – die erste zweistellige Zahl!',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist die größte Zahl: 3, 7, 5, 9?',
      options: ['3', '5', '7', '9'],
      correctAnswer: '9',
      explanation: '9 ist die größte der vier Zahlen.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Wie viele Finger hat eine Hand?',
      options: ['4', '5', '6', '7'],
      correctAnswer: '5',
      explanation: 'Eine Hand hat 5 Finger.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist der Anfangsbuchstabe von "Mama"?',
      options: ['A', 'M', 'P', 'N'],
      correctAnswer: 'M',
      explanation: 'Das Wort "Mama" beginnt mit dem Buchstaben M.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was reimt sich auf "Haus"?',
      options: ['Baum', 'Maus', 'Ball', 'Tisch'],
      correctAnswer: 'Maus',
      explanation: 'Haus und Maus reimen sich – beide enden auf "-aus".',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Welches Wort fängt mit "S" an?',
      options: ['Tisch', 'Banane', 'Sonne', 'Hund'],
      correctAnswer: 'Sonne',
      explanation: '"Sonne" beginnt mit dem Buchstaben S.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist der Anfangsbuchstabe von "Esel"?',
      options: ['A', 'E', 'I', 'O'],
      correctAnswer: 'E',
      explanation: 'Das Wort "Esel" beginnt mit dem Buchstaben E.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Was ist kein Tier?',
      options: ['Hund', 'Katze', 'Tisch', 'Vogel'],
      correctAnswer: 'Tisch',
      explanation: 'Ein Tisch ist ein Möbelstück, kein Tier.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Beine hat ein Hund?',
      options: ['2', '3', '4', '6'],
      correctAnswer: '4',
      explanation: 'Ein Hund hat 4 Beine – er ist ein Vierbeiner.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Was ist keine Farbe?',
      options: ['Rot', 'Blau', 'Grün', 'Hund'],
      correctAnswer: 'Hund',
      explanation: 'Rot, Blau und Grün sind Farben. Ein Hund ist ein Tier.',
    ),
    // Mengen-Zähl-Aufgaben (emoji-visual)
    Exercise(
      subject: 'Mengen',
      question: 'Wie viele Sterne siehst du?\n⭐⭐⭐⭐⭐',
      options: ['3', '4', '5', '6'],
      correctAnswer: '5',
      explanation: 'Zähle die Sterne: 1, 2, 3, 4, 5 – es sind 5 Sterne.',
    ),
    Exercise(
      subject: 'Mengen',
      question: 'Wie viele Äpfel sind das?\n🍎🍎🍎',
      options: ['2', '3', '4', '5'],
      correctAnswer: '3',
      explanation: 'Zähle die Äpfel: 1, 2, 3 – es sind 3 Äpfel.',
    ),
    Exercise(
      subject: 'Mengen',
      question: 'Wie viele Herzen siehst du?\n❤️❤️❤️❤️',
      options: ['3', '4', '5', '6'],
      correctAnswer: '4',
      explanation: 'Zähle die Herzen: 1, 2, 3, 4 – es sind 4 Herzen.',
    ),
  ];

  // ── Medium (Klasse 2: Rechnen bis 100, kleine Einmaleins, Sachkunde) ───────
  static const List<Exercise> _mediumExercises = [
    Exercise(
      subject: 'Mathematik',
      question: '25 + 13 = ?',
      options: ['36', '37', '38', '39'],
      correctAnswer: '38',
      explanation: '25 + 13: Zuerst 25 + 10 = 35, dann 35 + 3 = 38.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '47 - 22 = ?',
      options: ['23', '24', '25', '26'],
      correctAnswer: '25',
      explanation: '47 - 22 = 25. Zuerst 47 - 20 = 27, dann 27 - 2 = 25.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '30 + 45 = ?',
      options: ['70', '73', '75', '80'],
      correctAnswer: '75',
      explanation: '30 + 45 = 75. Zähle die Zehner (3+4=7) und Einer (0+5=5).',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '56 - 19 = ?',
      options: ['35', '36', '37', '38'],
      correctAnswer: '37',
      explanation: '56 - 19 = 37. Du kannst 56 - 20 = 36, dann + 1 = 37 rechnen.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '7 × 3 = ?',
      options: ['18', '20', '21', '24'],
      correctAnswer: '21',
      explanation: '7 × 3 = 21. Zähle: 7, 14, 21.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '5 × 5 = ?',
      options: ['20', '24', '25', '30'],
      correctAnswer: '25',
      explanation: '5 × 5 = 25. Fünfer-Reihe: 5, 10, 15, 20, 25.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '8 × 3 = ?',
      options: ['21', '22', '23', '24'],
      correctAnswer: '24',
      explanation: '8 × 3 = 24. Zähle: 8, 16, 24.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist die Hälfte von 20?',
      options: ['8', '10', '12', '15'],
      correctAnswer: '10',
      explanation: 'Die Hälfte von 20 ist 10. 10 + 10 = 20.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist doppelt so viel wie 15?',
      options: ['25', '28', '30', '35'],
      correctAnswer: '30',
      explanation: 'Doppelt so viel wie 15 = 15 + 15 = 30.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '2, 4, 6, ?',
      options: ['7', '8', '9', '10'],
      correctAnswer: '8',
      explanation: 'Die Zahlen werden immer um 2 größer: 6 + 2 = 8.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '5, 10, 15, ?',
      options: ['18', '19', '20', '25'],
      correctAnswer: '20',
      explanation: 'Die Zahlen werden immer um 5 größer: 15 + 5 = 20.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist 100 - 40?',
      options: ['50', '55', '60', '65'],
      correctAnswer: '60',
      explanation: '100 - 40 = 60.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Tage hat eine Woche?',
      options: ['5', '6', '7', '8'],
      correctAnswer: '7',
      explanation: 'Eine Woche hat 7 Tage: Mo, Di, Mi, Do, Fr, Sa, So.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Monate hat ein Jahr?',
      options: ['10', '11', '12', '13'],
      correctAnswer: '12',
      explanation: 'Ein Jahr hat 12 Monate – von Januar bis Dezember.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Welche Jahreszeit folgt auf den Winter?',
      options: ['Sommer', 'Herbst', 'Frühling', 'Noch ein Winter'],
      correctAnswer: 'Frühling',
      explanation: 'Nach dem Winter kommt der Frühling – die Blumen blühen wieder.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Welches Tier legt Eier?',
      options: ['Hund', 'Katze', 'Huhn', 'Pferd'],
      correctAnswer: 'Huhn',
      explanation: 'Das Huhn legt Eier. Hunde, Katzen und Pferde bekommen lebende Jungtiere.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie heißt die Hauptstadt von Österreich?',
      options: ['Graz', 'Salzburg', 'Wien', 'Linz'],
      correctAnswer: 'Wien',
      explanation: 'Wien ist die Hauptstadt von Österreich.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist das Gegenteil von "groß"?',
      options: ['alt', 'klein', 'schwer', 'langsam'],
      correctAnswer: 'klein',
      explanation: 'Das Gegenteil (Antonym) von groß ist klein.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist ein Nomen (Hauptwort)?',
      options: ['laufen', 'Tisch', 'schön', 'schnell'],
      correctAnswer: 'Tisch',
      explanation: 'Ein Nomen (Hauptwort) schreibt man groß und bezeichnet ein Ding oder Lebewesen.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Welcher Monat kommt nach März?',
      options: ['Februar', 'April', 'Mai', 'Juni'],
      correctAnswer: 'April',
      explanation: 'Die Reihenfolge: Januar, Februar, März, April, …',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Stunden hat ein Tag?',
      options: ['12', '20', '24', '30'],
      correctAnswer: '24',
      explanation: 'Ein Tag hat 24 Stunden – 12 Stunden am Tag und 12 in der Nacht.',
    ),
    Exercise(
      subject: 'Mengen',
      question: 'Wie viele Fische siehst du?\n🐟🐟🐟🐟🐟🐟🐟🐟',
      options: ['6', '7', '8', '9'],
      correctAnswer: '8',
      explanation: 'Zähle die Fische genau: es sind 8 Fische.',
    ),
  ];

  // ── Hard (Klasse 2+: Textaufgaben, Muster, Allgemeinwissen) ──────────────
  static const List<Exercise> _hardExercises = [
    Exercise(
      subject: 'Textaufgabe',
      question: 'Luisa liest täglich 5 Seiten. Nach 4 Tagen wie viele Seiten?',
      options: ['15 Seiten', '18 Seiten', '20 Seiten', '25 Seiten'],
      correctAnswer: '20 Seiten',
      explanation: '5 Seiten × 4 Tage = 20 Seiten.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '9 × 8 = ?',
      options: ['63', '70', '72', '81'],
      correctAnswer: '72',
      explanation: '9 × 8 = 72. Neuner-Reihe: 9, 18, 27, 36, 45, 54, 63, 72.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '7 × 7 = ?',
      options: ['42', '47', '49', '56'],
      correctAnswer: '49',
      explanation: '7 × 7 = 49. Merke: 7 × 7 ist 49 – wie im Lied "Sieben mal sieben".',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '6 × 9 = ?',
      options: ['48', '52', '54', '56'],
      correctAnswer: '54',
      explanation: '6 × 9 = 54. Sechser-Reihe: 6, 12, 18, 24, 30, 36, 42, 48, 54.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '100 - 37 = ?',
      options: ['60', '62', '63', '67'],
      correctAnswer: '63',
      explanation: '100 - 37 = 63. Du kannst 100 - 40 = 60 rechnen, dann + 3 = 63.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '3, 6, 9, 12, ?',
      options: ['13', '14', '15', '16'],
      correctAnswer: '15',
      explanation: 'Die Zahlen werden immer um 3 größer (Dreier-Reihe): 12 + 3 = 15.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '100, 90, 80, 70, ?',
      options: ['55', '60', '65', '70'],
      correctAnswer: '60',
      explanation: 'Die Zahlen werden immer um 10 kleiner: 70 - 10 = 60.',
    ),
    Exercise(
      subject: 'Zahlenreihe',
      question: '2, 4, 8, 16, ?',
      options: ['24', '28', '32', '36'],
      correctAnswer: '32',
      explanation: 'Jede Zahl wird verdoppelt: 16 × 2 = 32.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist 4 × 6 + 3?',
      options: ['24', '25', '27', '30'],
      correctAnswer: '27',
      explanation: 'Zuerst die Multiplikation: 4 × 6 = 24, dann + 3 = 27.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wenn heute Montag ist, welcher Tag ist in 3 Tagen?',
      options: ['Mittwoch', 'Donnerstag', 'Freitag', 'Samstag'],
      correctAnswer: 'Donnerstag',
      explanation: 'Montag + 1 = Dienstag, + 2 = Mittwoch, + 3 = Donnerstag.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Tage hat ein normales Jahr?',
      options: ['360', '364', '365', '366'],
      correctAnswer: '365',
      explanation: 'Ein normales Jahr hat 365 Tage. Ein Schaltjahr hat 366 Tage.',
    ),
    Exercise(
      subject: 'Textaufgabe',
      question: 'Ein Apfel: 50 Cent, eine Birne: 30 Cent. Zusammen?',
      options: ['70 Cent', '75 Cent', '80 Cent', '90 Cent'],
      correctAnswer: '80 Cent',
      explanation: '50 Cent + 30 Cent = 80 Cent.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Was ist ein Synonym für "froh"?',
      options: ['traurig', 'müde', 'glücklich', 'böse'],
      correctAnswer: 'glücklich',
      explanation: '"Froh" und "glücklich" bedeuten dasselbe – sie sind Synonyme.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Welcher Planet ist am nächsten zur Sonne?',
      options: ['Venus', 'Erde', 'Mars', 'Merkur'],
      correctAnswer: 'Merkur',
      explanation: 'Merkur ist der sonnennächste Planet in unserem Sonnensystem.',
    ),
    Exercise(
      subject: 'Textaufgabe',
      question: 'Tom hat 24 Kekse. Er gibt 3 Freunden je 4 Kekse. Wie viele hat er noch?',
      options: ['8', '10', '12', '14'],
      correctAnswer: '12',
      explanation: '3 × 4 = 12 verschenkte Kekse. 24 - 12 = 12 Kekse übrig.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: '9 × 7 = ?',
      options: ['54', '60', '63', '72'],
      correctAnswer: '63',
      explanation: '9 × 7 = 63. Neuner-Reihe: 9, 18, 27, 36, 45, 54, 63.',
    ),
    Exercise(
      subject: 'Deutsch',
      question: 'Welches Wort ist ein Adjektiv (Eigenschaftswort)?',
      options: ['Haus', 'laufen', 'groß', 'Baum'],
      correctAnswer: 'groß',
      explanation: '"Groß" ist ein Adjektiv – es beschreibt eine Eigenschaft.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist 1 + 2 + 3 + 4 + 5?',
      options: ['12', '13', '14', '15'],
      correctAnswer: '15',
      explanation: '1+2=3, 3+3=6, 6+4=10, 10+5=15.',
    ),
    Exercise(
      subject: 'Sachkunde',
      question: 'Wie viele Beine hat ein Insekt?',
      options: ['4', '6', '8', '10'],
      correctAnswer: '6',
      explanation: 'Alle Insekten haben genau 6 Beine – das ist ihr Erkennungsmerkmal.',
    ),
    Exercise(
      subject: 'Mathematik',
      question: 'Was ist 10 × 10?',
      options: ['10', '50', '100', '1000'],
      correctAnswer: '100',
      explanation: '10 × 10 = 100 – das ist eine Hundert.',
    ),
  ];

  static Exercise nextExercise() {
    final all = allExercises;
    final exercise = all[_index % all.length];
    _index++;
    return exercise;
  }

  /// Returns a random exercise for the given [level], excluding any exercise
  /// whose question text appears in [recentQuestions]. If all candidates have
  /// been recently shown, the exclusion is ignored.
  static Exercise randomForLevel(
    ClassLevel level, {
    Set<String> recentQuestions = const {},
  }) {
    final pool = exercisesForLevel(level);
    final candidates =
        pool.where((e) => !recentQuestions.contains(e.question)).toList();
    final source = candidates.isNotEmpty ? candidates : pool;
    return source[Random().nextInt(source.length)];
  }

  /// Returns the exercise pool for [level].
  static List<Exercise> exercisesForLevel(ClassLevel level) {
    switch (level) {
      case ClassLevel.klasse1:
        return List.unmodifiable(_easyExercises);
      case ClassLevel.klasse2:
        return List.unmodifiable([..._easyExercises, ..._mediumExercises]);
      case ClassLevel.fortgeschritten:
        return allExercises;
    }
  }

  static List<Exercise> get easyExercises => List.unmodifiable(_easyExercises);
  static List<Exercise> get mediumExercises =>
      List.unmodifiable(_mediumExercises);
  static List<Exercise> get hardExercises => List.unmodifiable(_hardExercises);

  static List<Exercise> get allExercises => [
        ..._easyExercises,
        ..._mediumExercises,
        ..._hardExercises,
      ];
}
