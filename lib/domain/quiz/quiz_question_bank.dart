/// Fragenbank fuer den Quiz-Modus.

import 'dart:math' as math;

import 'quiz_show.dart';

class QuizQuestionBank {
  const QuizQuestionBank();

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

  /// Statischer Frage-Pool — kategorisiert nach Schwierigkeit + Fach.
  ///
  /// 96 Fragen total:
  ///   EASY (32):   Klasse 1 - einfache Konzepte
  ///   MEDIUM (32): Klasse 2 - mittlere Schwierigkeit
  ///   HARD (32):   Klasse 3-4 - komplexere Aufgaben
  ///
  /// Pro Schwierigkeit: ~11 Mathe + ~11 Deutsch + ~10 Sachunterricht.
  /// Unterkategorien per ID-Prefix (e_math_add_1 = Easy/Math/Addition).
  /// Anti-Wiederholung via seenIds in generateGameQuestions().
  List<QuizQuestion> _buildStaticPool(int grade) {
    return <QuizQuestion>[
      // ════════════════════════════════════════════════════════════════
      // EASY (32 Fragen) — Schulstart, Klasse 1
      // ════════════════════════════════════════════════════════════════

      // ── EASY MATHE (11): Addition, Zaehlen, Mengen, Formen ─────────
      const QuizQuestion(id: 'e_math_add_1', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viel ist 3 + 2?', options: ['4', '5', '6', '7'], correctIndex: 1,
        hint: 'Zaehle: 3 Finger, dann noch 2 dazu.'),
      const QuizQuestion(id: 'e_math_add_2', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viel ist 4 + 1?', options: ['3', '4', '5', '6'], correctIndex: 2,
        hint: 'Eins mehr als 4.'),
      const QuizQuestion(id: 'e_math_add_3', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viel ist 1 + 1?', options: ['1', '2', '3', '4'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_add_4', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viel ist 5 + 3?', options: ['7', '8', '9', '10'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_add_5', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viel ist 6 + 4?', options: ['9', '10', '11', '12'], correctIndex: 1,
        hint: 'Das gibt eine schoene runde Zahl.'),
      const QuizQuestion(id: 'e_math_count_1', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Welche Zahl kommt nach 7?', options: ['6', '8', '9', '10'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_count_2', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Welche Zahl kommt vor 5?', options: ['3', '4', '6', '7'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_count_3', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viele Finger hat eine Hand?', options: ['4', '5', '6', '10'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_set_1', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Welche Zahl ist groesser: 7 oder 4?', options: ['4', '7', 'Beide gleich', 'Keine'], correctIndex: 1),
      const QuizQuestion(id: 'e_math_shape_1', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viele Ecken hat ein Dreieck?', options: ['2', '3', '4', '5'], correctIndex: 1,
        hint: 'Drei-eck, die Vorsilbe verraet es.'),
      const QuizQuestion(id: 'e_math_shape_2', subject: 'Mathe', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viele Ecken hat ein Quadrat?', options: ['3', '4', '5', '6'], correctIndex: 1),

      // ── EASY DEUTSCH (11): Buchstaben, Anlaute, Reime ──────────────
      const QuizQuestion(id: 'e_de_letter_1', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Mit welchem Buchstaben beginnt "Apfel"?', options: ['A', 'E', 'O', 'P'], correctIndex: 0),
      const QuizQuestion(id: 'e_de_letter_2', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Mit welchem Buchstaben beginnt "Buch"?', options: ['A', 'B', 'D', 'P'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_letter_3', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Mit welchem Buchstaben beginnt "Sonne"?', options: ['Z', 'S', 'N', 'O'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_letter_4', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viele Buchstaben hat das Wort "Maus"?', options: ['3', '4', '5', '6'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_rhyme_1', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Was reimt sich auf "Haus"?', options: ['Hund', 'Maus', 'Auto', 'Buch'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_rhyme_2', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Was reimt sich auf "Hose"?', options: ['Tasse', 'Hand', 'Rose', 'Baum'], correctIndex: 2),
      const QuizQuestion(id: 'e_de_rhyme_3', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Was reimt sich auf "Katze"?', options: ['Hund', 'Tatze', 'Maus', 'Auto'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_word_1', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Welches Wort beschreibt ein Tier?', options: ['Tisch', 'Hund', 'Auto', 'Buch'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_word_2', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Welches Wort beschreibt eine Farbe?', options: ['Hund', 'Rot', 'Tisch', 'Buch'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_word_3', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Was isst man zum Fruehstueck?', options: ['Auto', 'Brot', 'Stein', 'Stuhl'], correctIndex: 1),
      const QuizQuestion(id: 'e_de_word_4', subject: 'Deutsch', difficulty: QuizDifficulty.easy,
        prompt: 'Was zieht man an, wenn es regnet?', options: ['Hut', 'Regenjacke', 'Schwimmreifen', 'Sandalen'], correctIndex: 1),

      // ── EASY SACHKUNDE (10): Tiere, Farben, Wetter, Koerper ────────
      const QuizQuestion(id: 'e_sk_anim_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Welches Tier sagt "Wuff"?', options: ['Katze', 'Hund', 'Vogel', 'Fisch'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_anim_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Welches Tier sagt "Miau"?', options: ['Katze', 'Hund', 'Kuh', 'Schwein'], correctIndex: 0),
      const QuizQuestion(id: 'e_sk_anim_3', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Wo wohnen Fische?', options: ['Im Baum', 'Im Wasser', 'Im Haus', 'In der Luft'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_color_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Welche Farbe hat das Gras?', options: ['Rot', 'Gruen', 'Blau', 'Gelb'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_color_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Welche Farbe hat eine Banane?', options: ['Rot', 'Blau', 'Gelb', 'Gruen'], correctIndex: 2),
      const QuizQuestion(id: 'e_sk_weather_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Was faellt vom Himmel wenn es regnet?', options: ['Schnee', 'Wassertropfen', 'Blaetter', 'Steine'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_weather_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'In welcher Jahreszeit faellt Schnee?', options: ['Sommer', 'Fruehling', 'Winter', 'Herbst'], correctIndex: 2),
      const QuizQuestion(id: 'e_sk_body_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Wie viele Augen hat ein Mensch?', options: ['1', '2', '3', '4'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_body_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Womit hoeren wir?', options: ['Mit den Augen', 'Mit den Ohren', 'Mit dem Mund', 'Mit den Haenden'], correctIndex: 1),
      const QuizQuestion(id: 'e_sk_body_3', subject: 'Sachunterricht', difficulty: QuizDifficulty.easy,
        prompt: 'Womit riechen wir?', options: ['Mit den Ohren', 'Mit der Nase', 'Mit den Augen', 'Mit den Fuessen'], correctIndex: 1),

      // ════════════════════════════════════════════════════════════════
      // MEDIUM (32 Fragen) — Klasse 2
      // ════════════════════════════════════════════════════════════════

      // ── MEDIUM MATHE (11): Subtraktion, Einmaleins-Start, Geld ─────
      const QuizQuestion(id: 'm_math_add_1', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 12 + 7?', options: ['18', '19', '20', '21'], correctIndex: 1),
      const QuizQuestion(id: 'm_math_add_2', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 15 + 5?', options: ['18', '19', '20', '25'], correctIndex: 2),
      const QuizQuestion(id: 'm_math_sub_1', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 10 - 4?', options: ['5', '6', '7', '8'], correctIndex: 1),
      const QuizQuestion(id: 'm_math_sub_2', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 18 - 9?', options: ['8', '9', '10', '11'], correctIndex: 1),
      const QuizQuestion(id: 'm_math_sub_3', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 20 - 7?', options: ['11', '12', '13', '14'], correctIndex: 2),
      const QuizQuestion(id: 'm_math_mul_1', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 2 mal 3?', options: ['4', '5', '6', '7'], correctIndex: 2),
      const QuizQuestion(id: 'm_math_mul_2', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 5 mal 2?', options: ['7', '10', '12', '15'], correctIndex: 1),
      const QuizQuestion(id: 'm_math_mul_3', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel ist 4 mal 4?', options: ['12', '14', '16', '18'], correctIndex: 2),
      const QuizQuestion(id: 'm_math_money_1', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viel sind 2 Euro plus 50 Cent?', options: ['2 Euro', '2,50 Euro', '3 Euro', '5 Euro'], correctIndex: 1),
      const QuizQuestion(id: 'm_math_time_1', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viele Minuten hat eine Stunde?', options: ['30', '45', '60', '100'], correctIndex: 2),
      const QuizQuestion(id: 'm_math_time_2', subject: 'Mathe', difficulty: QuizDifficulty.medium,
        prompt: 'Wie viele Tage hat eine Woche?', options: ['5', '6', '7', '8'], correctIndex: 2),

      // ── MEDIUM DEUTSCH (11): Lesen, Plural, Wortarten ──────────────
      const QuizQuestion(id: 'm_de_plural_1', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist der Plural von "Kind"?', options: ['Kinden', 'Kinds', 'Kinder', 'Kindern'], correctIndex: 2),
      const QuizQuestion(id: 'm_de_plural_2', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist der Plural von "Hund"?', options: ['Hunde', 'Hunden', 'Hunds', 'Hundi'], correctIndex: 0),
      const QuizQuestion(id: 'm_de_plural_3', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist der Plural von "Apfel"?', options: ['Apfels', 'Aepfel', 'Apfeln', 'Apfler'], correctIndex: 1),
      const QuizQuestion(id: 'm_de_article_1', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Welcher Artikel passt zu "Sonne"?', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 1),
      const QuizQuestion(id: 'm_de_article_2', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Welcher Artikel passt zu "Buch"?', options: ['Der', 'Die', 'Das', 'Dem'], correctIndex: 2),
      const QuizQuestion(id: 'm_de_article_3', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Welcher Artikel passt zu "Tisch"?', options: ['Der', 'Die', 'Das', 'Den'], correctIndex: 0),
      const QuizQuestion(id: 'm_de_opp_1', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist das Gegenteil von "gross"?', options: ['Schnell', 'Klein', 'Langsam', 'Bunt'], correctIndex: 1),
      const QuizQuestion(id: 'm_de_opp_2', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist das Gegenteil von "hell"?', options: ['Bunt', 'Weiss', 'Dunkel', 'Warm'], correctIndex: 2),
      const QuizQuestion(id: 'm_de_opp_3', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was ist das Gegenteil von "alt"?', options: ['Jung', 'Klein', 'Schnell', 'Bunt'], correctIndex: 0),
      const QuizQuestion(id: 'm_de_verb_1', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was machen Voegel?', options: ['Schwimmen', 'Fliegen', 'Bellen', 'Grasen'], correctIndex: 1),
      const QuizQuestion(id: 'm_de_verb_2', subject: 'Deutsch', difficulty: QuizDifficulty.medium,
        prompt: 'Was machen Fische?', options: ['Fliegen', 'Klettern', 'Schwimmen', 'Bellen'], correctIndex: 2),

      // ── MEDIUM SACHKUNDE (10): Pflanzen, Jahreszeiten, Berufe ──────
      const QuizQuestion(id: 'm_sk_plant_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Was brauchen Pflanzen zum Wachsen?', options: ['Nur Wasser', 'Nur Sonne', 'Wasser und Sonne', 'Nichts'], correctIndex: 2),
      const QuizQuestion(id: 'm_sk_plant_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wo waechst ein Baum?', options: ['In der Erde', 'Im Wasser', 'In den Wolken', 'Im Schrank'], correctIndex: 0),
      const QuizQuestion(id: 'm_sk_season_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wann werden die Blaetter bunt?', options: ['Sommer', 'Herbst', 'Winter', 'Fruehling'], correctIndex: 1),
      const QuizQuestion(id: 'm_sk_season_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wann bluehen die meisten Blumen?', options: ['Winter', 'Fruehling', 'Herbst', 'Nachts'], correctIndex: 1),
      const QuizQuestion(id: 'm_sk_job_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wer behandelt kranke Menschen?', options: ['Lehrer', 'Arzt', 'Baecker', 'Friseur'], correctIndex: 1),
      const QuizQuestion(id: 'm_sk_job_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wer backt Brot?', options: ['Arzt', 'Lehrer', 'Baecker', 'Polizist'], correctIndex: 2),
      const QuizQuestion(id: 'm_sk_job_3', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Wer loescht Feuer?', options: ['Baecker', 'Feuerwehrmann', 'Arzt', 'Briefträger'], correctIndex: 1),
      const QuizQuestion(id: 'm_sk_anim_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Welches Tier legt Eier?', options: ['Kuh', 'Schaf', 'Huhn', 'Pferd'], correctIndex: 2),
      const QuizQuestion(id: 'm_sk_anim_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Welches Tier gibt Milch?', options: ['Huhn', 'Kuh', 'Schmetterling', 'Schlange'], correctIndex: 1),
      const QuizQuestion(id: 'm_sk_traffic_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.medium,
        prompt: 'Bei welcher Ampelfarbe darfst du gehen?', options: ['Rot', 'Gelb', 'Gruen', 'Blau'], correctIndex: 2),

      // ════════════════════════════════════════════════════════════════
      // HARD (32 Fragen) — Klasse 3-4
      // ════════════════════════════════════════════════════════════════

      // ── HARD MATHE (11): Einmaleins, Division, Brueche, Geometrie ──
      const QuizQuestion(id: 'h_math_mul_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 7 mal 8?', options: ['54', '56', '63', '64'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_mul_2', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 9 mal 9?', options: ['72', '81', '90', '99'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_mul_3', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 6 mal 7?', options: ['36', '42', '48', '49'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_div_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 24 geteilt durch 4?', options: ['4', '5', '6', '8'], correctIndex: 2),
      const QuizQuestion(id: 'h_math_div_2', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 45 geteilt durch 9?', options: ['4', '5', '6', '9'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_add_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 47 + 38?', options: ['75', '85', '95', '105'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_sub_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viel ist 100 - 47?', options: ['43', '53', '57', '63'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_frac_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Was ist die Haelfte von 16?', options: ['6', '7', '8', '10'], correctIndex: 2),
      const QuizQuestion(id: 'h_math_frac_2', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Was ist ein Viertel von 20?', options: ['4', '5', '6', '10'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_geo_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie heisst eine Form mit 5 Ecken?', options: ['Quadrat', 'Fuenfeck', 'Sechseck', 'Kreis'], correctIndex: 1),
      const QuizQuestion(id: 'h_math_time_1', subject: 'Mathe', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viele Sekunden hat eine Minute?', options: ['30', '50', '60', '100'], correctIndex: 2),

      // ── HARD DEUTSCH (11): Grammatik, Rechtschreibung, Wortarten ───
      const QuizQuestion(id: 'h_de_wort_1', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Was ist ein "Verb"?', options: ['Ein Tier', 'Ein Tu-Wort', 'Eine Farbe', 'Ein Name'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_wort_2', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Was ist ein "Nomen"?', options: ['Ein Tu-Wort', 'Ein Name-Wort', 'Eine Farbe', 'Ein Zeichen'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_wort_3', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Welches Wort ist ein Verb?', options: ['Haus', 'Laufen', 'Schoen', 'Schnell'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_wort_4', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Welches Wort ist ein Adjektiv (Wie-Wort)?', options: ['Laufen', 'Hund', 'Schnell', 'Tisch'], correctIndex: 2),
      const QuizQuestion(id: 'h_de_spell_1', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Wie schreibt man "schtoa..."?', options: ['Schtohr', 'Stohr', 'Stoa', 'Stör'], correctIndex: 3),
      const QuizQuestion(id: 'h_de_spell_2', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Welches Wort hat ein "ie"?', options: ['Hund', 'Liebe', 'Tasse', 'Stuhl'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_spell_3', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Wie schreibt man die Zahl 12?', options: ['Zwoelf', 'Zwoolf', 'Zoelf', 'Zwlf'], correctIndex: 0),
      const QuizQuestion(id: 'h_de_sentence_1', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Womit endet ein normaler Satz?', options: ['Komma', 'Punkt', 'Fragezeichen', 'Strich'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_sentence_2', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Wie endet eine Frage?', options: ['Punkt', 'Komma', 'Fragezeichen', 'Klammer'], correctIndex: 2),
      const QuizQuestion(id: 'h_de_meaning_1', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Was bedeutet "fluestern"?', options: ['Laut sprechen', 'Leise sprechen', 'Schreien', 'Singen'], correctIndex: 1),
      const QuizQuestion(id: 'h_de_meaning_2', subject: 'Deutsch', difficulty: QuizDifficulty.hard,
        prompt: 'Was bedeutet "trauern"?', options: ['Sich freuen', 'Traurig sein', 'Lachen', 'Singen'], correctIndex: 1),

      // ── HARD SACHKUNDE (10): Geografie, Geschichte, Wissenschaft ───
      const QuizQuestion(id: 'h_sk_geo_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Wie heisst die Hauptstadt von Oesterreich?', options: ['Salzburg', 'Linz', 'Wien', 'Graz'], correctIndex: 2),
      const QuizQuestion(id: 'h_sk_geo_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Wie heisst die Hauptstadt von Deutschland?', options: ['Muenchen', 'Berlin', 'Hamburg', 'Koeln'], correctIndex: 1),
      const QuizQuestion(id: 'h_sk_geo_3', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Welches ist das groesste Tier der Erde?', options: ['Elefant', 'Giraffe', 'Blauwal', 'Baer'], correctIndex: 2),
      const QuizQuestion(id: 'h_sk_geo_4', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'In welchem Kontinent leben Loewen wild?', options: ['Europa', 'Afrika', 'Amerika', 'Asien'], correctIndex: 1),
      const QuizQuestion(id: 'h_sk_sci_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viele Planeten hat unser Sonnensystem?', options: ['7', '8', '9', '12'], correctIndex: 1),
      const QuizQuestion(id: 'h_sk_sci_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Was ist die Sonne?', options: ['Ein Planet', 'Ein Stern', 'Ein Mond', 'Ein Komet'], correctIndex: 1),
      const QuizQuestion(id: 'h_sk_sci_3', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Was atmen wir ein?', options: ['Wasser', 'Stickstoff', 'Sauerstoff', 'Kohlendioxid'], correctIndex: 2),
      const QuizQuestion(id: 'h_sk_body_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Wie viele Knochen hat ein Erwachsener etwa?', options: ['100', '150', '200', '250'], correctIndex: 2),
      const QuizQuestion(id: 'h_sk_body_2', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Welches Organ pumpt das Blut?', options: ['Lunge', 'Magen', 'Herz', 'Leber'], correctIndex: 2),
      const QuizQuestion(id: 'h_sk_nature_1', subject: 'Sachunterricht', difficulty: QuizDifficulty.hard,
        prompt: 'Wie heisst der laengste Fluss in Oesterreich?', options: ['Donau', 'Inn', 'Mur', 'Drau'], correctIndex: 0),
    ];
  }
}
