// ════════════════════════════════════════════════════════════════════════
// LUMO STORY — KI-generierte Lerngeschichten mit Bildern + Mini-Übungen
// ════════════════════════════════════════════════════════════════════════
// Vorschlag 2 aus Heinz' Auswahl: 'Bilderbuch das mitlernt'.
//
// Kind waehlt 3 Woerter (Helden + Ort + Thema) -> LumoStory generiert
// eine 8-Seiten-Geschichte mit:
//   - Live-Pollinations-Bild pro Seite
//   - Vorlese-Text fuer TTS
//   - Lern-Stop dazwischen (Mathe / Schreibcoach)
//   - Speichern als persoenliches Lese-Heft
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

class LumoStoryPage {
  const LumoStoryPage({
    required this.pageNum,
    required this.text,
    required this.imagePrompt,
    this.exercise,
    this.newWord,
  });

  final int pageNum;
  /// Vorlese-Text fuer diese Seite (3-5 Saetze).
  final String text;
  /// Was Pollinations zeichnen soll.
  final String imagePrompt;
  /// Optionale Mini-Uebung nach dieser Seite.
  final StoryExercise? exercise;
  /// Neues Wort das auf dieser Seite vorgestellt wird (fuer Schreibcoach).
  final String? newWord;
}

enum StoryExerciseType { mathPlus, mathMinus, wordWrite, wordChoice }

class StoryExercise {
  const StoryExercise({
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    this.options,
  });
  final StoryExerciseType type;
  final String prompt;
  final String correctAnswer;
  /// Bei wordChoice/MultiChoice: Liste mit 4 Optionen.
  final List<String>? options;
}

class LumoStory {
  const LumoStory({
    required this.title,
    required this.heroName,
    required this.location,
    required this.theme,
    required this.pages,
    required this.newWords,
    required this.gradeLevel,
  });

  final String title;
  final String heroName;
  final String location;
  final String theme;
  final List<LumoStoryPage> pages;
  /// Neue Wörter die in der Story vorkommen (fuer Schreibcoach-Integration).
  final List<String> newWords;
  /// Klassenstufe 1-4.
  final int gradeLevel;
}

/// Generator fuer personalisierte Lern-Geschichten.
/// Erstellt 8-Seiten-Story basierend auf Kind-Wahl + Klassenstufe.
class LumoStoryGenerator {
  LumoStoryGenerator._();
  static final LumoStoryGenerator instance = LumoStoryGenerator._();

  final _rng = math.Random();

  // ────────────────────────────────────────────────────────────────
  // STORY-VORLAGEN (100+ Kombinationen moeglich durch Mix)
  // ────────────────────────────────────────────────────────────────

  static const List<String> _heroOptions = [
    // Klassische Heldenfiguren
    'Drache', 'Prinzessin', 'Pirat', 'Ritter', 'Astronaut',
    'Fee', 'Einhorn', 'Roboter', 'Zauberer', 'Detektiv',
    'Forscher', 'Pilot', 'Tierfreund', 'Meerjungfrau', 'Cowboy',
    // Erweiterung: Tier-Helden (besonders kinder-nah)
    'Fuchs', 'Hund', 'Katze', 'Hase', 'Pinguin', 'Pony',
    'Eichhoernchen', 'Schmetterling', 'Eule', 'Wal',
    // Erweiterung: Alltagsheld + Erfinder-Berufe
    'Feuerwehrmann', 'Tierarzt', 'Baeckerin', 'Lehrerin',
    'Gaertner', 'Lokfuehrerin',
  ];

  static const List<String> _locationOptions = [
    // Fantasie-Welten
    'Zauberwald', 'Schloss', 'Weltraum', 'Unterwasser-Stadt',
    'Dschungel', 'Berg', 'Wueste', 'Eis-Welt', 'Bauernhof',
    'Drachen-Hoehle', 'Piratenschiff', 'Magisches Dorf',
    'Wolken-Reich', 'Vulkan', 'Schatzinsel',
    // Erweiterung: Vertraute Welten fuer Kinder
    'Schule', 'Spielplatz', 'Garten', 'Park', 'Stadt am See',
    'Wiese', 'Bibliothek', 'Bauernhof am Bach',
    // Erweiterung: Magische Orte
    'Regenbogen-Insel', 'Sterne-Stadt', 'Mond-Palast',
    'Suessigkeiten-Land', 'Musik-Wald',
  ];

  static const List<String> _themeOptions = [
    // Abenteuer-Themen
    'Freundschaft', 'Abenteuer', 'Schatzsuche', 'Wettrennen',
    'Geheimnis', 'Rettungsaktion', 'Mutprobe', 'Helfen',
    'Erfinden', 'Reisen', 'Zauber lernen', 'Tiere retten',
    // Erweiterung: Kinder-Alltag
    'Geburtstag', 'Schul-Tag', 'Sport-Fest', 'Picknick',
    'Ferien', 'Backen', 'Pflanzen',
    // Erweiterung: Soziale Themen
    'Anders sein', 'Neuer Freund', 'Mut machen', 'Verzeihen',
    'Teilen', 'Etwas Neues lernen',
  ];

  List<String> get heroOptions => _heroOptions;
  List<String> get locationOptions => _locationOptions;
  List<String> get themeOptions => _themeOptions;

  /// Erstelle eine personalisierte 8-Seiten-Geschichte.
  LumoStory generate({
    required String hero,
    required String location,
    required String theme,
    required int gradeLevel,
  }) {
    final pages = <LumoStoryPage>[];
    final newWords = <String>[];

    // Story-Arc: Setup -> Aufgabe -> Mitte -> Klimax -> Aufloesung
    final arcs = _generateArc(hero, location, theme, gradeLevel);

    for (int i = 0; i < arcs.length; i++) {
      final arc = arcs[i];
      // Alle 2 Seiten kommt eine Lernaufgabe (Seiten 2, 4, 6, 8).
      final exercise = (i + 1) % 2 == 0
          ? _generateExercise(gradeLevel, i)
          : null;
      pages.add(LumoStoryPage(
        pageNum: i + 1,
        text: arc.text,
        imagePrompt: arc.imagePrompt,
        exercise: exercise,
        newWord: arc.newWord,
      ));
      if (arc.newWord != null) newWords.add(arc.newWord!);
    }

    return LumoStory(
      title: '$hero im $location',
      heroName: hero,
      location: location,
      theme: theme,
      pages: pages,
      newWords: newWords,
      gradeLevel: gradeLevel,
    );
  }

  /// Generiert eine zufaellige Story (alles random).
  LumoStory generateRandom({int gradeLevel = 1}) {
    return generate(
      hero: _heroOptions[_rng.nextInt(_heroOptions.length)],
      location: _locationOptions[_rng.nextInt(_locationOptions.length)],
      theme: _themeOptions[_rng.nextInt(_themeOptions.length)],
      gradeLevel: gradeLevel,
    );
  }

  // ────────────────────────────────────────────────────────────────
  // STORY-ARC-GENERIERUNG (8 Seiten)
  // ────────────────────────────────────────────────────────────────

  List<_StoryArc> _generateArc(
      String hero, String location, String theme, int gradeLevel) {
    // Grammar-Helper: aus dem 'theme' Wort einen sauberen Satz bauen.
    // Vorher: "wollte ein Ferien erleben" - grammatikalisch falsch.
    // Jetzt: "wollte $themeStart" mit themenspezifischem Auftakt.
    final themeIntro = _themeIntro(theme);
    final art = _heroArticle(hero); // kleingeschrieben (mitten im Satz)
    final Art = art[0].toUpperCase() + art.substring(1); // Satzanfang
    final pron = _heroPronoun(hero);
    return [
      // Seite 1: Setup
      _StoryArc(
        text: 'Es war einmal $art $hero. $Art $hero lebte im $location und $themeIntro.',
        imagePrompt: 'cute $hero in $location, story book style',
        newWord: hero.toLowerCase(),
      ),
      // Seite 2: Aufgabe
      _StoryArc(
        text: 'Eines Tages hörte $art $hero ein Rufen. "Hilfe, hilfe!" rief jemand aus der Ferne. Schnell lief $pron los!',
        imagePrompt: 'cute $hero running in $location',
      ),
      // Seite 3: Begegnung
      _StoryArc(
        text: 'Im $location traf $art $hero einen neuen Freund. Sie wurden ein tolles Team!',
        imagePrompt: 'cute $hero with cute friend in $location',
        newWord: 'Freund',
      ),
      // Seite 4: Erste Herausforderung
      _StoryArc(
        text: 'Zusammen mussten sie ein Rätsel lösen. Das war gar nicht so leicht!',
        imagePrompt: 'cute $hero solving puzzle in $location',
        newWord: 'Rätsel',
      ),
      // Seite 5: Mitte
      _StoryArc(
        text: 'Sie sammelten magische Steine. Mit jedem Stein wurde $art $hero stärker und mutiger.',
        imagePrompt: 'cute $hero with magic stones in $location',
      ),
      // Seite 6: Wendepunkt
      _StoryArc(
        text: 'Plötzlich tauchte ein großer Schatten auf. $Art $hero atmete tief ein und blieb tapfer!',
        imagePrompt: 'cute brave $hero facing shadow in $location',
        newWord: 'tapfer',
      ),
      // Seite 7: Klimax
      _StoryArc(
        text: 'Mit dem Mut von ${gradeLevel * 10} Löwen schaffte $art $hero das große Abenteuer! Alle jubelten!',
        imagePrompt: 'cute happy $hero celebrating in $location',
      ),
      // Seite 8: Ende
      _StoryArc(
        text: 'Am Abend kehrte $art $hero nach Hause zurück. Was für ein Tag voller $theme! Gute Nacht!',
        imagePrompt: 'cute sleeping $hero at home, peaceful story book ending',
      ),
    ];
  }

  /// Artikel kleingeschrieben (fuer mitten im Satz).
  String _heroArticle(String hero) {
    const die = <String>[
      'Prinzessin', 'Fee', 'Meerjungfrau', 'Baeckerin', 'Lehrerin',
      'Lokfuehrerin', 'Katze', 'Eule', 'Schildkroete', 'Maus',
    ];
    const das = <String>[
      'Einhorn', 'Pony', 'Eichhoernchen', 'Kind', 'Reh', 'Kueken',
    ];
    if (die.contains(hero)) return 'die';
    if (das.contains(hero)) return 'das';
    return 'der';
  }

  /// Personalpronomen (er/sie/es) passend zum Artikel.
  String _heroPronoun(String hero) {
    final art = _heroArticle(hero);
    if (art == 'die') return 'sie';
    if (art == 'das') return 'es';
    return 'er';
  }

  /// Bildet einen sauberen Satz-Auftakt aus dem Theme-Wort.
  /// Vorher: "wollte ein $theme erleben" - mit theme="Ferien" wurde das
  /// "wollte ein Ferien erleben" (falsch). Jetzt: pro Theme passender
  /// Satz, der grammatikalisch funktioniert.
  String _themeIntro(String theme) {
    const map = <String, String>{
      'Freundschaft': 'wollte echte Freundschaft erleben',
      'Abenteuer': 'wollte ein großes Abenteuer erleben',
      'Schatzsuche': 'wollte einen Schatz suchen',
      'Wettrennen': 'wollte ein Wettrennen gewinnen',
      'Geheimnis': 'wollte ein Geheimnis lüften',
      'Rettungsaktion': 'wollte jemanden retten',
      'Mutprobe': 'wollte seinen Mut beweisen',
      'Helfen': 'wollte anderen helfen',
      'Erfinden': 'wollte etwas Neues erfinden',
      'Reisen': 'wollte auf Reisen gehen',
      'Zauber lernen': 'wollte einen Zauber lernen',
      'Tiere retten': 'wollte Tiere retten',
      'Geburtstag': 'feierte gerade Geburtstag',
      'Schul-Tag': 'hatte einen aufregenden Schul-Tag',
      'Sport-Fest': 'freute sich auf das Sport-Fest',
      'Picknick': 'wollte ein Picknick im Grünen machen',
      'Ferien': 'freute sich auf die Ferien',
      'Backen': 'wollte etwas Leckeres backen',
      'Pflanzen': 'wollte einen Garten pflanzen',
      'Anders sein': 'war anders als alle anderen',
      'Neuer Freund': 'suchte einen neuen Freund',
      'Mut machen': 'wollte anderen Mut machen',
      'Verzeihen': 'lernte zu verzeihen',
      'Teilen': 'wollte mit anderen teilen',
      'Etwas Neues lernen': 'wollte etwas Neues lernen',
    };
    return map[theme] ?? 'erlebte etwas Spannendes';
  }

  // ────────────────────────────────────────────────────────────────
  // MINI-UEBUNGEN BASIEREND AUF KLASSENSTUFE
  // ────────────────────────────────────────────────────────────────

  StoryExercise _generateExercise(int gradeLevel, int pageIdx) {
    final maxNum = gradeLevel == 1
        ? 10
        : gradeLevel == 2
            ? 100
            : gradeLevel == 3
                ? 1000
                : 1000000;
    // Wechseln zwischen Mathe + Wort-Uebungen
    if (pageIdx % 4 == 1) {
      // Plus
      final a = 1 + _rng.nextInt(math.min(maxNum, 9));
      final b = 1 + _rng.nextInt(math.min(maxNum - a, 9));
      return StoryExercise(
        type: StoryExerciseType.mathPlus,
        prompt: 'In der Geschichte: $a + $b = ?',
        correctAnswer: '${a + b}',
        options: _buildNumOptions(a + b),
      );
    } else {
      // Wort-Aufgabe
      const words = [
        'Drache', 'Burg', 'Wald', 'Stern', 'Kind',
        'Held', 'Schatz', 'Magie', 'Reise', 'Freund',
      ];
      final word = words[_rng.nextInt(words.length)];
      return StoryExercise(
        type: StoryExerciseType.wordWrite,
        prompt: 'Schreib das Wort: $word',
        correctAnswer: word,
      );
    }
  }

  List<String> _buildNumOptions(int correct) {
    final options = <String>{correct.toString()};
    while (options.length < 4) {
      final delta = _rng.nextInt(5) - 2;
      if (delta == 0) continue;
      final wrong = (correct + delta).clamp(0, 9999);
      if (wrong != correct) options.add(wrong.toString());
    }
    final list = options.toList()..shuffle(_rng);
    return list;
  }
}

class _StoryArc {
  const _StoryArc({
    required this.text,
    required this.imagePrompt,
    this.newWord,
  });
  final String text;
  final String imagePrompt;
  final String? newWord;
}
