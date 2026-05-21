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
    this.keyPoints = const <String>[],
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
  /// Stichwoerter, die in einer guten Zusammenfassung der Geschichte
  /// vorkommen sollten. Beispiel fuer "Einhorn im Mond-Palast":
  /// ['Einhorn', 'Mond-Palast', 'Hilferuf', 'Freund', 'Raetsel',
  ///  'magische Steine', 'Schatten', 'tapfer', 'jubeln', 'Hause'].
  /// Wird vom Story-Reader fuer die Zusammenfassungs-Bewertung am Ende
  /// genutzt: Kind erzaehlt nach, Lumo zaehlt, wie viele Stichworte
  /// getroffen wurden -> Sterne-Bewertung.
  final List<String> keyPoints;
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
  /// Jede Seite ist 4-6 Saetze lang (echter Geschichtsbuch-Stil),
  /// nicht nur 1-2 wie vorher. Plus keyPoints fuer die Zusammenfassungs-
  /// Bewertung am Ende.
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
      // Nur auf Seiten 2 und 5 eine Lernaufgabe - sonst stoert sie den
      // Lese-Fluss. Vorher waren es 4 Aufgaben (jede 2. Seite), das
      // hat den narrativen Bogen zerrissen.
      final exercise = (i == 1 || i == 4)
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
      keyPoints: _buildKeyPoints(hero, location, theme),
    );
  }

  /// Stichwoerter fuer die Zusammenfassungs-Bewertung am Ende der Story.
  /// Kind erzaehlt nach, Lumo zaehlt, wie viele dieser Stichworte
  /// (oder Synonyme) vorkommen.
  List<String> _buildKeyPoints(String hero, String location, String theme) {
    return <String>[
      hero,
      location,
      'Hilfe',         // Seite 2: Hilferuf
      'Freund',        // Seite 3
      'Raetsel',       // Seite 4
      'Steine',        // Seite 5: magische Steine
      'Schatten',      // Seite 6
      'tapfer',        // Seite 6
      'jubeln',        // Seite 7
      'Hause',         // Seite 8
    ];
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
    final themeIntro = _themeIntro(theme);
    final art = _heroArticle(hero);
    final Art = art[0].toUpperCase() + art.substring(1);
    final pron = _heroPronoun(hero);
    final Pron = pron[0].toUpperCase() + pron.substring(1);
    final poss = _heroPossessive(hero); // sein/ihr
    final atmo = _locationAtmosphere(location); // 1-Satz-Stimmung des Ortes
    return [
      // Seite 1: Setup - Helden-Welt vorstellen
      _StoryArc(
        text:
          'Es war einmal $art $hero, $art mitten im $location lebte. $atmo. '
          'Jeden Morgen wachte $art $hero auf und freute sich auf den neuen Tag. '
          'Doch heute war alles ein bisschen anders: $art $hero $themeIntro. '
          '$Pron wusste noch nicht, was an diesem Tag alles passieren würde!',
        imagePrompt: 'cute $hero in $location, story book style',
        newWord: hero.toLowerCase(),
      ),
      // Seite 2: Auslöser - Hilferuf
      _StoryArc(
        text:
          'Plötzlich, mitten am Vormittag, hörte $art $hero ein leises Rufen. '
          '"Hilfe, bitte hilf mir!", rief eine Stimme aus der Ferne. '
          '$Art $hero spitzte $poss Ohren und lauschte ganz genau. '
          'Da war es wieder! Ohne lange zu zögern, lief $pron in die Richtung, '
          'aus der das Rufen kam. Was würde $pron wohl finden?',
        imagePrompt: 'cute $hero running in $location',
      ),
      // Seite 3: Begegnung - neuer Freund
      _StoryArc(
        text:
          'Hinter einem großen Baum saß ein kleines Wesen und weinte. '
          '"Ich habe mich verlaufen", schluchzte es. '
          '$Art $hero setzte sich daneben und sagte ganz ruhig: '
          '"Keine Sorge, ich helfe dir nach Hause." '
          'Sie schauten sich an, lächelten - und ab jetzt waren sie Freunde fürs Leben.',
        imagePrompt: 'cute $hero with cute friend in $location',
        newWord: 'Freund',
      ),
      // Seite 4: Herausforderung - Rätsel
      _StoryArc(
        text:
          'Auf dem Weg nach Hause kamen die beiden zu einem alten Tor. '
          'Auf dem Tor stand: "Nur wer das Rätsel löst, darf hindurch." '
          'Sie überlegten und überlegten. Schließlich hatte $art $hero eine Idee: '
          '"Wenn wir es zusammen versuchen, schaffen wir das bestimmt!" '
          'Und siehe da - das Tor schwang langsam auf.',
        imagePrompt: 'cute $hero solving puzzle in $location',
        newWord: 'Rätsel',
      ),
      // Seite 5: Mitte - magische Steine
      _StoryArc(
        text:
          'Auf der anderen Seite des Tors leuchteten überall kleine Steine im Gras. '
          'Es waren magische Steine, die nur funkelten, wenn jemand etwas Gutes tat. '
          '$Art $hero und $poss Freund sammelten gemeinsam viele bunte Steine. '
          'Mit jedem Stein fühlte $pron sich stärker, mutiger und glücklicher. '
          'Eine warme Sonne schien auf die beiden herab.',
        imagePrompt: 'cute $hero with magic stones in $location',
      ),
      // Seite 6: Wendepunkt - Schatten
      _StoryArc(
        text:
          'Da, ganz unerwartet, wurde es plötzlich dunkel um sie herum. '
          'Ein großer Schatten erhob sich vor ihnen - er war riesig und sah furchteinflößend aus! '
          '$poss Freund zitterte. Doch $art $hero atmete tief ein und ging einen Schritt nach vorne. '
          '"Ich habe keine Angst", sagte $pron mit fester Stimme. '
          'Und wisst ihr was? Im selben Moment wurde der Schatten kleiner und kleiner.',
        imagePrompt: 'cute brave $hero facing shadow in $location',
        newWord: 'tapfer',
      ),
      // Seite 7: Klimax - Sieg
      _StoryArc(
        text:
          'Als der Schatten ganz verschwunden war, blieben nur leuchtende Lichter zurück. '
          '$Art $hero und $poss Freund hatten es geschafft - sie waren tapfer geblieben! '
          'Aus allen Ecken des $location kamen Tiere und Wesen herbei und jubelten ihnen zu. '
          'Sie klatschten in die Hände und riefen laut: "Was für ein Mut!" '
          '$Art $hero strahlte über das ganze Gesicht. Heute war wirklich ein besonderer Tag.',
        imagePrompt: 'cute happy $hero celebrating in $location',
      ),
      // Seite 8: Ende - Heimkehr
      _StoryArc(
        text:
          'Als die Sonne langsam unterging, machte $art $hero sich auf den Heimweg. '
          '$poss neuer Freund winkte ihm zum Abschied zu. '
          '"Bis morgen!", rief $pron noch und versprach, bald wieder zu kommen. '
          'Zu Hause kuschelte $art $hero sich glücklich ein und dachte: '
          '"Was für ein Tag voller $theme!" Und dann schlief $pron tief und fest ein. Gute Nacht!',
        imagePrompt: 'cute sleeping $hero at home, peaceful story book ending',
      ),
    ];
  }

  /// Possessivpronomen (sein/ihr) passend zum Helden.
  String _heroPossessive(String hero) {
    final art = _heroArticle(hero);
    if (art == 'die') return 'ihre';
    return 'seine';
  }

  /// 1-Satz-Atmosphaere fuer den Ort. Macht die Geschichte plastischer.
  String _locationAtmosphere(String location) {
    const map = <String, String>{
      'Zauberwald':         'Die Baeume flüsterten leise und die Blätter glitzerten im Sonnenlicht',
      'Schloss':            'Die hohen Türme reichten fast bis zu den Wolken',
      'Weltraum':           'Tausende Sterne funkelten überall in der weiten Dunkelheit',
      'Unterwasser-Stadt':  'Bunte Fische schwammen zwischen Korallen und Algen umher',
      'Dschungel':          'Lianen hingen von den Bäumen und Affen riefen aus der Ferne',
      'Berg':               'Der Wind pfiff um die schneebedeckten Gipfel',
      'Wueste':             'Goldener Sand erstreckte sich bis zum Horizont',
      'Eis-Welt':           'Alles glitzerte wie Diamanten im kalten Sonnenlicht',
      'Bauernhof':          'Hähne krähten und Kühe muhten auf den grünen Wiesen',
      'Drachen-Hoehle':     'Funken sprühten und es roch nach warmem Rauch',
      'Piratenschiff':      'Die Segel knatterten im Wind und das Meer rauschte',
      'Magisches Dorf':     'Aus jedem Schornstein stieg bunter Zauber-Rauch auf',
      'Wolken-Reich':       'Weiche Wolken trugen jeden Schritt federleicht',
      'Vulkan':             'Heiße Lava blubberte tief unten in der Erde',
      'Schatzinsel':        'Palmen wiegten sich sanft und Möwen kreisten am Himmel',
      'Schule':             'Glocken läuteten und Kinder lachten auf dem Schulhof',
      'Spielplatz':         'Die Schaukeln knarrten und überall hörte man Kinderlachen',
      'Garten':             'Blumen wuchsen in allen Farben und Bienen summten umher',
      'Park':               'Vögel zwitscherten und der Wind raschelte in den Blättern',
      'Stadt am See':       'Das Wasser glitzerte und kleine Boote schaukelten am Steg',
      'Wiese':              'Schmetterlinge tanzten und die Gräser wiegten sich im Wind',
      'Bibliothek':         'Tausende Bücher standen in hohen Regalen, jedes voller Geheimnisse',
      'Bauernhof am Bach':  'Das Wasser plätscherte fröhlich vorbei und Frösche quakten',
      'Regenbogen-Insel':   'Über der Insel spannte sich ein riesiger bunter Regenbogen',
      'Sterne-Stadt':       'Alle Häuser leuchteten wie kleine Sterne in der Nacht',
      'Mond-Palast':        'Die Wände waren aus glitzerndem Silber und überall funkelten Mondsteine',
      'Suessigkeiten-Land': 'Die Bäume hatten Lutscher als Blätter und es duftete nach Schokolade',
      'Musik-Wald':         'Mit jedem Schritt klang eine schöne Melodie zwischen den Bäumen',
    };
    return map[location] ?? 'Es war ein wunderschöner Ort voller Magie';
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
