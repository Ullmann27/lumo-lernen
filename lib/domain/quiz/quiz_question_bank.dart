/// Fragenbank fuer den Quiz-Modus.
///
/// CODEX TODO:
/// Implementiere generateGameQuestions() das 15 Fragen mit der richtigen
/// Verteilung produziert:
///   - 4 easy (Frage 1-4)
///   - 5 medium (Frage 5-9)
///   - 6 hard (Frage 10-15)
///
/// Themen-Mix pro Spiel:
///   - 5 Mathe + 5 Deutsch + 5 Sachunterricht (zufaellig durchmischt)
///
/// Anti-Wiederholung: seenIds aus Repository nutzen.
///
/// Quellen:
///   - lib/core/math_task_templates.dart (33 Templates, NICHT MODIFIZIEREN)
///   - lib/core/german_task_templates.dart (40 Templates, NICHT MODIFIZIEREN)
///   - lib/core/primary_school_word_data.dart (800+ Woerter, NICHT MODIFIZIEREN)

import 'dart:math' as math;

import 'quiz_show.dart';

class QuizQuestionBank {
  const QuizQuestionBank();

  /// CODEX TODO: Generiere 15 Fragen fuer ein Spiel.
  ///
  /// Parameter:
  ///   - grade: Schulklasse (1-4) - beeinflusst Schwierigkeit der hard-Fragen
  ///   - seenIds: bereits verwendete Frage-IDs zum Filtern
  ///   - random: optionaler Seed fuer reproduzierbare Tests
  List<QuizQuestion> generateGameQuestions({
    required int grade,
    Set<String> seenIds = const <String>{},
    math.Random? random,
  }) {
    final rng = random ?? math.Random();
    final allQuestions = _buildStaticPool(grade);

    // Filtere bereits gesehene Fragen
    final available = allQuestions.where((q) => !seenIds.contains(q.id)).toList();
    // Wenn weniger als 15 verfuegbar: Reset
    final pool = available.length >= 15 ? available : allQuestions;

    final easyPool = pool.where((q) => q.difficulty == QuizDifficulty.easy).toList()..shuffle(rng);
    final mediumPool = pool.where((q) => q.difficulty == QuizDifficulty.medium).toList()..shuffle(rng);
    final hardPool = pool.where((q) => q.difficulty == QuizDifficulty.hard).toList()..shuffle(rng);

    return <QuizQuestion>[
      ...easyPool.take(4),
      ...mediumPool.take(5),
      ...hardPool.take(6),
    ];
  }

  /// Statischer Frage-Pool als Fallback.
  /// CODEX TODO: ERWEITERE diese Liste auf mindestens 60 Fragen
  /// (20 easy + 20 medium + 20 hard), damit Anti-Wiederholung greift.
  List<QuizQuestion> _buildStaticPool(int grade) {
    return <QuizQuestion>[
      // ─────────────────── EASY (Frage 1-4) ───────────────────
      const QuizQuestion(
        id: 'e_math_1',
        prompt: 'Wie viel ist 3 + 2?',
        options: ['4', '5', '6', '7'],
        correctIndex: 1,
        difficulty: QuizDifficulty.easy,
        subject: 'Mathe',
        hint: 'Zähle: 3 Finger, dann noch 2 dazu.',
      ),
      const QuizQuestion(
        id: 'e_math_2',
        prompt: 'Wie viel ist 4 + 1?',
        options: ['3', '4', '5', '6'],
        correctIndex: 2,
        difficulty: QuizDifficulty.easy,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'e_math_3',
        prompt: 'Wie viel ist 6 + 2?',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
        difficulty: QuizDifficulty.easy,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'e_math_4',
        prompt: 'Wie viel ist 5 + 5?',
        options: ['8', '9', '10', '11'],
        correctIndex: 2,
        difficulty: QuizDifficulty.easy,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'e_de_1',
        prompt: 'Welches Wort fängt mit "A" an?',
        options: ['Tisch', 'Apfel', 'Maus', 'Hund'],
        correctIndex: 1,
        difficulty: QuizDifficulty.easy,
        subject: 'Deutsch',
        hint: 'A wie Anfang!',
      ),
      const QuizQuestion(
        id: 'e_de_2',
        prompt: 'Wie viele Buchstaben hat "Haus"?',
        options: ['3', '4', '5', '6'],
        correctIndex: 1,
        difficulty: QuizDifficulty.easy,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'e_de_3',
        prompt: 'Was reimt sich auf "Maus"?',
        options: ['Baum', 'Haus', 'Fisch', 'Wasser'],
        correctIndex: 1,
        difficulty: QuizDifficulty.easy,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'e_sa_1',
        prompt: 'Welches Tier sagt "Wuff"?',
        options: ['Katze', 'Kuh', 'Hund', 'Schwein'],
        correctIndex: 2,
        difficulty: QuizDifficulty.easy,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'e_sa_2',
        prompt: 'Welche Farbe hat die Sonne?',
        options: ['Blau', 'Grün', 'Gelb', 'Rot'],
        correctIndex: 2,
        difficulty: QuizDifficulty.easy,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'e_sa_3',
        prompt: 'Wie viele Beine hat eine Spinne?',
        options: ['6', '7', '8', '10'],
        correctIndex: 2,
        difficulty: QuizDifficulty.easy,
        subject: 'Sachunterricht',
      ),

      // ─────────────────── MEDIUM (Frage 5-9) ───────────────────
      const QuizQuestion(
        id: 'm_math_1',
        prompt: 'Wie viel ist 12 + 7?',
        options: ['18', '19', '20', '21'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Mathe',
        hint: 'Denk an die Zehnerregel: 12 + 7 = 12 + 7.',
      ),
      const QuizQuestion(
        id: 'm_math_2',
        prompt: 'Wie viel ist 15 - 6?',
        options: ['8', '9', '10', '11'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'm_math_3',
        prompt: 'Was ist die Hälfte von 14?',
        options: ['6', '7', '8', '9'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'm_de_1',
        prompt: 'Welches Wort ist ein Verb?',
        options: ['Tisch', 'laufen', 'gross', 'rot'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Deutsch',
        hint: 'Verben sind Wörter für Tätigkeiten.',
      ),
      const QuizQuestion(
        id: 'm_de_2',
        prompt: 'Was ist der Artikel von "Haus"?',
        options: ['der', 'die', 'das', 'den'],
        correctIndex: 2,
        difficulty: QuizDifficulty.medium,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'm_de_3',
        prompt: 'Welches Wort wird mit "ie" geschrieben?',
        options: ['Bett', 'Liebe', 'Hund', 'Tisch'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'm_sa_1',
        prompt: 'Welche Jahreszeit kommt nach dem Winter?',
        options: ['Sommer', 'Herbst', 'Frühling', 'Winter'],
        correctIndex: 2,
        difficulty: QuizDifficulty.medium,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'm_sa_2',
        prompt: 'Wie heißt die Hauptstadt von Österreich?',
        options: ['Graz', 'Linz', 'Wien', 'Salzburg'],
        correctIndex: 2,
        difficulty: QuizDifficulty.medium,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'm_sa_3',
        prompt: 'Welches Tier legt Eier?',
        options: ['Hund', 'Henne', 'Kuh', 'Katze'],
        correctIndex: 1,
        difficulty: QuizDifficulty.medium,
        subject: 'Sachunterricht',
      ),

      // ─────────────────── HARD (Frage 10-15) ───────────────────
      const QuizQuestion(
        id: 'h_math_1',
        prompt: 'Wie viel ist 7 × 8?',
        options: ['54', '56', '58', '64'],
        correctIndex: 1,
        difficulty: QuizDifficulty.hard,
        subject: 'Mathe',
        hint: '7 mal 8 - denk an das Einmaleins.',
      ),
      const QuizQuestion(
        id: 'h_math_2',
        prompt: 'Wie viel ist 100 - 47?',
        options: ['53', '57', '63', '47'],
        correctIndex: 0,
        difficulty: QuizDifficulty.hard,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'h_math_3',
        prompt: 'Welche Zahl ist genau die Hälfte zwischen 20 und 30?',
        options: ['22', '24', '25', '27'],
        correctIndex: 2,
        difficulty: QuizDifficulty.hard,
        subject: 'Mathe',
      ),
      const QuizQuestion(
        id: 'h_de_1',
        prompt: 'Welcher Satz ist richtig?',
        options: [
          'Ich gehe in die Schule.',
          'Ich geht in die Schule.',
          'Ich gehst in die Schule.',
          'Ich gegangen Schule.',
        ],
        correctIndex: 0,
        difficulty: QuizDifficulty.hard,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'h_de_2',
        prompt: 'Was ist die Mehrzahl von "Maus"?',
        options: ['Maus', 'Mäuse', 'Mauses', 'Mäusen'],
        correctIndex: 1,
        difficulty: QuizDifficulty.hard,
        subject: 'Deutsch',
      ),
      const QuizQuestion(
        id: 'h_de_3',
        prompt: 'Welches Wort ist KEIN Nomen?',
        options: ['Apfel', 'Haus', 'schnell', 'Auto'],
        correctIndex: 2,
        difficulty: QuizDifficulty.hard,
        subject: 'Deutsch',
        hint: 'Nomen kann man anfassen oder zeigen.',
      ),
      const QuizQuestion(
        id: 'h_sa_1',
        prompt: 'Welcher Planet ist der Sonne am nächsten?',
        options: ['Erde', 'Mars', 'Merkur', 'Venus'],
        correctIndex: 2,
        difficulty: QuizDifficulty.hard,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'h_sa_2',
        prompt: 'Wie viele Bundesländer hat Österreich?',
        options: ['7', '8', '9', '10'],
        correctIndex: 2,
        difficulty: QuizDifficulty.hard,
        subject: 'Sachunterricht',
      ),
      const QuizQuestion(
        id: 'h_sa_3',
        prompt: 'Was atmen Pflanzen aus?',
        options: ['Stickstoff', 'Kohlendioxid', 'Sauerstoff', 'Wasser'],
        correctIndex: 2,
        difficulty: QuizDifficulty.hard,
        subject: 'Sachunterricht',
      ),
    ];
  }
}
