// ════════════════════════════════════════════════════════════════════════
//                  LUMO KART - SICHERER MINI-FRAGE-POOL
// ════════════════════════════════════════════════════════════════════════
//
// Vor der vollen Lernfrage-Engine: eine kleine Liste handgepruefter
// Mini-Fragen damit Frageblock nicht crashen kann. Alle Antworten sind
// fachlich korrekt. Es gibt genau eine richtige Antwort pro Frage.
//
// Spaeter koennen wir hier auf das echte LearningContent-System
// umstellen.

import 'dart:math' as math;

class KartMiniQuestion {
  const KartMiniQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    this.hint,
  });

  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String? hint;

  String get correctAnswer => options[correctIndex];
}

class KartQuestionPool {
  const KartQuestionPool._();

  static const List<KartMiniQuestion> _questions = <KartMiniQuestion>[
    KartMiniQuestion(
      prompt: '2 + 3 = ?',
      options: ['4', '5', '6'],
      correctIndex: 1,
      hint: 'Zaehle: 2, dann +3 dazu.',
    ),
    KartMiniQuestion(
      prompt: '7 - 2 = ?',
      options: ['4', '5', '6'],
      correctIndex: 1,
      hint: 'Vom 7 zwei wegnehmen.',
    ),
    KartMiniQuestion(
      prompt: 'Welche Zahl kommt nach 9?',
      options: ['8', '10', '11'],
      correctIndex: 1,
      hint: '9, dann eins mehr.',
    ),
    KartMiniQuestion(
      prompt: 'Welcher Buchstabe ist am Anfang von "Sonne"?',
      options: ['O', 'S', 'N'],
      correctIndex: 1,
      hint: 'Was hoerst du zuerst?',
    ),
    KartMiniQuestion(
      prompt: 'Welches Wort beginnt mit M?',
      options: ['Hund', 'Maus', 'Apfel'],
      correctIndex: 1,
      hint: 'M wie Mama.',
    ),
    KartMiniQuestion(
      prompt: '4 + 4 = ?',
      options: ['7', '8', '9'],
      correctIndex: 1,
    ),
    KartMiniQuestion(
      prompt: 'Welche Farbe hat die Sonne im Bild?',
      options: ['Blau', 'Gelb', 'Gruen'],
      correctIndex: 1,
    ),
    KartMiniQuestion(
      prompt: 'Wie viele Raeder hat ein Kart?',
      options: ['2', '4', '6'],
      correctIndex: 1,
      hint: 'Schau dein Kart an.',
    ),
  ];

  /// Liefert eine zufaellige Frage. Seed kann fuer Tests gesetzt werden.
  static KartMiniQuestion random({int? seed}) {
    final rng = seed == null ? math.Random() : math.Random(seed);
    return _questions[rng.nextInt(_questions.length)];
  }

  static int get length => _questions.length;

  static KartMiniQuestion at(int index) =>
      _questions[index.clamp(0, _questions.length - 1)];
}
