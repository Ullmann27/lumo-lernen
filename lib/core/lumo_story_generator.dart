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

/// Whole-book understanding, separate from clues used to solve riddles.
class StoryBookQuestion {
  const StoryBookQuestion(this.prompt, this.correctAnswer, this.options,
      this.evidencePage);
  final String prompt, correctAnswer;
  final List<String> options;
  final int evidencePage;
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
    this.bookQuestions = const <StoryBookQuestion>[],
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
  final List<StoryBookQuestion> bookQuestions;
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
    String companion = 'Lumo',
    String magicItem = 'Sternenkompass',
    int variationSeed = 0,
  }) {
    final pages = <LumoStoryPage>[];
    final newWords = <String>[];

    // Story-Arc: Setup -> Aufgabe -> Mitte -> Klimax -> Aufloesung
    final arcs = _generateArc(hero, location, theme, gradeLevel,
        companion: companion, magicItem: magicItem, variationSeed: variationSeed);

    for (int i = 0; i < arcs.length; i++) {
      final arc = arcs[i];
      // Nur auf Seiten 2 und 5 eine Lernaufgabe - sonst stoert sie den
      // Lese-Fluss. Vorher waren es 4 Aufgaben (jede 2. Seite), das
      // hat den narrativen Bogen zerrissen.
      final exercise =
          (i == 1 || i == 4) ? _generateExercise(gradeLevel, i) : null;
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
      'Hilfe', // Seite 2: Hilferuf
      'Freund', // Seite 3
      'Raetsel', // Seite 4
      'Steine', // Seite 5: magische Steine
      'Schatten', // Seite 6
      'tapfer', // Seite 6
      'jubeln', // Seite 7
      'Hause', // Seite 8
    ];
  }

  /// Full 12-page reading adventure for the new story-selection flow.
  /// Older generated and stored eight-page stories stay backward-compatible.
  LumoStory generateReadingAdventure({
    required String hero,
    required String location,
    required String theme,
    required int gradeLevel,
    String companion = 'Lumo',
    String magicItem = 'Sternenkompass',
    int variationSeed = 0,
  }) {
    final lead = hero.replaceAll('Eichhoernchen', 'Eichhörnchen')
        .replaceAll('Baeckerin', 'Bäckerin')
        .replaceAll('Gaertner', 'Gärtner')
        .replaceAll('Lokfuehrerin', 'Lokführerin');
    final place = location.replaceAll('Wueste', 'Wüste')
        .replaceAll('Suessigkeiten', 'Süßigkeiten')
        .replaceAll('Drachen-Hoehle', 'Drachenhöhle');
    final friend = '${_heroArticle(hero)} $lead';
    final team = companion == 'Lumo'
        ? 'Lumo und $friend' : 'Lumo, $friend und $companion';
    const mysteries = <String>[
      'Sternenkarte', 'Geschichtenbuch', 'Mondlaterne',
      'Wolkenbild', 'Musikschlüssel', 'Schatzzeichnung',
    ];
    final missing = mysteries[variationSeed % mysteries.length];
    final pages = <LumoStoryPage>[];
    void add(String text, String image, {String? word, StoryExercise? puzzle}) {
      pages.add(LumoStoryPage(
        pageNum: pages.length + 1,
        text: text,
        imagePrompt: 'Lumo illustrated book: $image, $place',
        newWord: word,
        exercise: puzzle,
      ));
    }

    add(
      'Der Ort hieß $place. Lumo liebte diesen Ort und besonders '
      'Geschichten über $theme. Heute fand Lumo in der Bücherei ein Buch '
      'mit einem leeren Umschlag. Auf der ersten Seite stand: '
      '„Eine gute Geschichte beginnt mit genauem Hinsehen.“ '
      'Lumo schrieb den Namen des Ortes in ein rotes Notizbuch. '
      'Vor der Tür wartete $friend. Ein neues Abenteuer konnte beginnen.',
      'red notebook and library', word: 'Notizbuch',
    );
    add(
      'Am nächsten Morgen klopfte eine Botin an die Tür. '
      'Sie übergab Lumo einen Brief. Darin stand, dass der Gegenstand '
      'namens $missing verschwunden war. '
      'Ohne diesen Gegenstand fehlte der Bücherei ein wichtiger Schatz. '
      '„Findet ihn, aber achtet auf die Hinweise“, bat die Botin. '
      'Lumo schrieb drei Wörter auf: Suchen, Verstehen, Helfen.',
      'messenger with letter',
    );
    add(
      '$team gingen zum alten Brunnen. '
      'Dort lagen eine rote Feder, ein grauer Stein und ein blaues Band. '
      'Die Feder bewegte sich im Wind. Der Stein lag still im Gras. '
      'Das Band war an einem Zweig festgeknotet. '
      'Auf dem Brief stand: „Folge der Farbe des klaren Himmels.“ '
      'Lumo betrachtete die drei Fundstücke ganz genau.',
      'fountain with blue ribbon red feather and stone',
    );
    add(
      'Hinter dem Brunnen begann eine steinerne Treppe. '
      'An ihrer ersten Stufe waren die drei Fundstücke abgebildet. '
      'Nur das blaue Band war frisch angemalt. '
      'Lumo verglich die Bilder mit dem Brief. '
      '„Der Himmel ist blau“, bemerkte Lumo. '
      'Jetzt mussten alle überlegen, welchem Zeichen sie folgen sollten.',
      'stone stairs with three clues',
    );
    add(
      'Die Suche wurde spannend. Lumo wollte nicht einfach raten. '
      'Der Brief und die Zeichnung an der Treppe passten zusammen. '
      'Eine Spur führte nach oben, die anderen endeten am Brunnen. '
      'Wer aufmerksam gelesen hatte, konnte die richtige Spur finden.',
      'first puzzle at blue ribbon', word: 'Spur',
      puzzle: const StoryExercise(
        type: StoryExerciseType.wordChoice,
        prompt: 'Erstes Rätsel: Welchem Fundstück sollen alle folgen?',
        correctAnswer: 'dem blauen Band',
        options: ['der roten Feder', 'dem blauen Band', 'dem grauen Stein'],
      ),
    );
    add(
      'Die Treppe führte zu einem ruhigen Garten. '
      'Hier machten alle eine Pause. Lumo setzte sich auf eine Holzbank '
      'neben einem kleinen Brunnen und aß einen Apfel. '
      'Der Wind raschelte in den Blättern. '
      'Plötzlich hörte Lumo ein leises Klopfen hinter der Mauer. '
      'Das nächste Geheimnis war ganz in der Nähe.',
      'wooden bench in garden', word: 'Garten',
    );
    add(
      'Hinter der Mauer hing eine alte Karte. '
      'Auf ihr waren ein Kreis, ein Dreieck und ein Stern gezeichnet. '
      'Der Kreis führte zum Markt. Das Dreieck zeigte zurück. '
      'Beim Stern stand: „Hier beginnt der letzte Weg.“ '
      'Lumo zeichnete alle drei Zeichen in das rote Notizbuch. '
      'So konnten die Hinweise nicht verloren gehen.',
      'map with three symbols',
    );
    add(
      'Am Ende des Gartens entdeckte Lumo eine Tür ohne Griff. '
      'Darüber leuchteten die gleichen Zeichen wie auf der Karte. '
      'Lumo nahm den Gegenstand namens $magicItem aus der Tasche. '
      'Er passte in eine Vertiefung, doch die Tür blieb verschlossen. '
      'Ein einziges Zeichen musste zuerst berührt werden. '
      'Zum Glück war der Hinweis aus der Karte noch bekannt.',
      'secret door with symbols',
    );
    add(
      'Vor der Tür dachte Lumo lange nach. '
      'Der Kreis führte zum Markt. Das Dreieck zeigte zurück. '
      'Doch ein Zeichen versprach den letzten Weg. '
      'Lumo wusste: Die Lösung stand bereits auf der Karte.',
      'second puzzle door', word: 'Zeichen',
      puzzle: const StoryExercise(
        type: StoryExerciseType.wordChoice,
        prompt: 'Zweites Rätsel: Welches Zeichen öffnet den letzten Weg?',
        correctAnswer: 'der Stern',
        options: ['der Kreis', 'das Dreieck', 'der Stern'],
      ),
    );
    add(
      'Hinter der Tür lag ein heller Raum mit hohen Bücherregalen. '
      'Auf einem Tisch entdeckte Lumo den vermissten Gegenstand: $missing. '
      'Daneben lag eine Nachricht: „Danke für eure Geduld.“ '
      'Der Gegenstand war hier sicher aufbewahrt worden. '
      'Alle waren erleichtert. Nur durch gutes Lesen und Nachdenken '
      'hatten sie den richtigen Weg gefunden.',
      'hidden book chamber discovery',
    );
    add(
      'Die Botin kam zurück und bedankte sich bei allen. '
      'Lumo erzählte vom Brunnen, vom Garten und von der Tür. '
      'Danach zeichnete Lumo die Holzbank und die geheimnisvolle Tür '
      'in das rote Notizbuch. Diese Zeichnung sollte später '
      'an die lange Suche erinnern. '
      'Auch $friend wollte das Abenteuer eines Tages nachlesen.',
      'friends and red sketchbook',
    );
    add(
      'Am Abend lag das Notizbuch auf Lumos Tisch. '
      'Darin standen der Name des Ortes und die Nachricht der Botin. '
      'Daneben war die Zeichnung aus dem Garten zu sehen. '
      'Lumo dachte noch einmal über die beiden Rätsel nach. '
      'Am schönsten war aber, dass alle zusammengeholfen hatten. '
      '„Morgen lese ich wieder ein Buch“, sagte Lumo.',
      'storybook reading lamp and notebook', word: 'Erinnerung',
    );

    return LumoStory(
      title: 'Lumo und das Geheimnis der $missing',
      heroName: hero,
      location: location,
      theme: theme,
      gradeLevel: gradeLevel,
      pages: pages,
      newWords: const ['Notizbuch', 'Spur', 'Garten', 'Zeichen', 'Erinnerung'],
      keyPoints: const ['Notizbuch', 'Botin', 'Brunnen', 'Band',
          'Garten', 'Stern', 'Buch'],
      bookQuestions: const [
        StoryBookQuestion(
          'Was schrieb Lumo ganz am Anfang in das rote Notizbuch?',
          'den Namen des Ortes',
          ['den Namen des Ortes', 'eine Einkaufsliste', 'ein Lied'],
          1,
        ),
        StoryBookQuestion(
          'Wer brachte am Morgen die Nachricht?',
          'eine Botin', ['ein Koch', 'eine Botin', 'ein Musiker'], 2,
        ),
        StoryBookQuestion(
          'Wo machte Lumo eine Pause und aß einen Apfel?',
          'auf einer Holzbank',
          ['in einem Zug', 'auf einer Holzbank', 'in einem Boot'], 6,
        ),
        StoryBookQuestion(
          'Was zeichnete Lumo am Ende als Erinnerung?',
          'die Holzbank und die Tür',
          ['einen Drachen', 'die Holzbank und die Tür', 'eine Rakete'], 11,
        ),
      ],
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

  List<_StoryArc> _generateArc(String hero, String location, String theme,
      int gradeLevel, {required String companion,
      required String magicItem, required int variationSeed}) {
    final themeIntro = _themeIntro(theme);
    final art = _heroArticle(hero);
    final capitalArticle = art[0].toUpperCase() + art.substring(1);
    final pron = _heroPronoun(hero);
    final capitalPronoun = pron[0].toUpperCase() + pron.substring(1);
    final poss = _heroPossessive(hero); // sein/ihr
    final atmo = _locationAtmosphere(location); // 1-Satz-Stimmung des Ortes
    final beats = _variantBeats(variationSeed);
    final beatIntro = beats[0], beatChallenge = beats[1];
    final beatTurn = beats[2], beatVictory = beats[3];
    final beatImage = beats[4];
    return [
      // Seite 1: Setup - Helden-Welt vorstellen
      _StoryArc(
        text:
            'Es war einmal $art $hero, $art mitten im $location lebte. $atmo. '
            'Jeden Morgen wachte $art $hero auf und freute sich auf den neuen Tag. '
            'Doch heute war alles ein bisschen anders: $art $hero $themeIntro. '
            '$capitalPronoun wusste noch nicht, was an diesem Tag alles passieren würde!',
        imagePrompt: 'cute $hero in $location, story book style',
        newWord: hero.toLowerCase(),
      ),
      // Seite 2: Neuer Anlass für jede wiederholte Setup-Kombination.
      _StoryArc(
        text: 'Am nächsten Morgen kam $companion zu $art $hero. '
            '"Wir müssen helfen!", rief $companion. '
            '$beatIntro '
            '$capitalArticle $hero packte den Zaubergegenstand $magicItem ein. '
            'Gemeinsam machten sie sich auf den Weg.',
        imagePrompt: 'storybook $hero with $companion, $magicItem in $location',
      ),
      _StoryArc(
        text: 'Schon bald trafen $art $hero und $companion ein kleines Wesen. '
            'Es brauchte dringend Hilfe. '
            '"Wir schaffen das gemeinsam", versprach $companion. '
            '$capitalArticle $hero zeigte den Zaubergegenstand $magicItem. '
            'Jetzt waren alle ein Team.',
        imagePrompt: 'cute $hero, $companion and friend in $location',
        newWord: 'Freund',
      ),
      _StoryArc(
        text: '$beatChallenge '
            '$capitalArticle $hero und $companion überlegten ganz genau. '
            '"Wir lösen das Rätsel gemeinsam!", rief $companion. '
            'Mit dem Zaubergegenstand $magicItem fanden sie eine Spur.',
        imagePrompt: 'storybook puzzle, $hero, $companion in $location',
        newWord: 'Rätsel',
      ),
      _StoryArc(
        text: 'Die Spur führte sie immer tiefer durch $location. '
            '$companion fand drei leuchtende Zeichen. '
            '$capitalArticle $hero schaute auf den Zaubergegenstand $magicItem. '
            'Ein Zeichen passte zum nächsten. '
            'Endlich wussten beide, was zu tun war.',
        imagePrompt: 'glowing clues, $hero, $companion in $location',
      ),
      _StoryArc(
        text: '$beatTurn '
            '$companion war erst unsicher. Doch $art $hero blieb ruhig. '
            '"Wir geben nicht auf!", sagte $pron. '
            'Mit dem Zaubergegenstand $magicItem gingen beide mutig weiter.',
        imagePrompt: 'brave $hero and $companion, $beatImage in $location',
        newWord: 'tapfer',
      ),
      _StoryArc(
        text: '$beatVictory '
            '$capitalArticle $hero und $companion jubelten. '
            'Der kleine Freund bedankte sich. '
            'Alle freuten sich über ihre gute Zusammenarbeit.',
        imagePrompt: 'celebrating $hero and $companion in $location',
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

  List<String> _variantBeats(int seed) {
    const scenarios = <List<String>>[
      ['Ein kleines Tier ist verschwunden.',
       'Vor ihnen stand ein Tor mit drei Zeichen.',
       'Dichter Nebel verdeckte plötzlich das Tor.',
       'Das Tor öffnete sich und das Tier war wieder frei.',
       'glowing gate'],
      ['Das Sternenfest braucht Licht.',
       'Alle bunten Laternen waren erloschen.',
       'Der Wind trug die letzte Laterne davon.',
       'Alle Laternen leuchteten und das Fest begann.',
       'festival lanterns'],
      ['Eine Schatzkarte wurde gefunden.',
       'Auf der Schatzkarte fehlte ein Wegzeichen.',
       'Die Brücke über dem Bach wackelte.',
       'In der Schatzkiste lagen funkelnde Wissenssterne.',
       'treasure map'],
      ['Eine Erfindung funktioniert nicht mehr.',
       'Der Sternenmaschine fehlte ein Zahnrad.',
       'Das große Uhrwerk blieb stehen.',
       'Die Maschine funktionierte wieder.',
       'clockwork machine'],
      ['Ein wichtiges Buch ist verschwunden.',
       'In der Bibliothek lag nur eine leere Buchhülle.',
       'Der Wind verstreute alle Hinweise.',
       'Das Buch wurde gefunden und vorgelesen.',
       'flying pages'],
      ['Eine Wolkenbahn hat sich verfahren.',
       'Die Wegweiser zeigten in falsche Richtungen.',
       'Dunkle Wolken verdeckten die Schienen.',
       'Die Bahn fuhr wieder sicher ans Ziel.',
       'rainbow train'],
    ];
    return scenarios[seed % scenarios.length];
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
      'Zauberwald':
          'Die Baeume flüsterten leise und die Blätter glitzerten im Sonnenlicht',
      'Schloss': 'Die hohen Türme reichten fast bis zu den Wolken',
      'Weltraum': 'Tausende Sterne funkelten überall in der weiten Dunkelheit',
      'Unterwasser-Stadt':
          'Bunte Fische schwammen zwischen Korallen und Algen umher',
      'Dschungel':
          'Lianen hingen von den Bäumen und Affen riefen aus der Ferne',
      'Berg': 'Der Wind pfiff um die schneebedeckten Gipfel',
      'Wueste': 'Goldener Sand erstreckte sich bis zum Horizont',
      'Eis-Welt': 'Alles glitzerte wie Diamanten im kalten Sonnenlicht',
      'Bauernhof': 'Hähne krähten und Kühe muhten auf den grünen Wiesen',
      'Drachen-Hoehle': 'Funken sprühten und es roch nach warmem Rauch',
      'Piratenschiff': 'Die Segel knatterten im Wind und das Meer rauschte',
      'Magisches Dorf': 'Aus jedem Schornstein stieg bunter Zauber-Rauch auf',
      'Wolken-Reich': 'Weiche Wolken trugen jeden Schritt federleicht',
      'Vulkan': 'Heiße Lava blubberte tief unten in der Erde',
      'Schatzinsel': 'Palmen wiegten sich sanft und Möwen kreisten am Himmel',
      'Schule': 'Glocken läuteten und Kinder lachten auf dem Schulhof',
      'Spielplatz': 'Die Schaukeln knarrten und überall hörte man Kinderlachen',
      'Garten': 'Blumen wuchsen in allen Farben und Bienen summten umher',
      'Park': 'Vögel zwitscherten und der Wind raschelte in den Blättern',
      'Stadt am See':
          'Das Wasser glitzerte und kleine Boote schaukelten am Steg',
      'Wiese': 'Schmetterlinge tanzten und die Gräser wiegten sich im Wind',
      'Bibliothek':
          'Tausende Bücher standen in hohen Regalen, jedes voller Geheimnisse',
      'Bauernhof am Bach':
          'Das Wasser plätscherte fröhlich vorbei und Frösche quakten',
      'Regenbogen-Insel':
          'Über der Insel spannte sich ein riesiger bunter Regenbogen',
      'Sterne-Stadt': 'Alle Häuser leuchteten wie kleine Sterne in der Nacht',
      'Mond-Palast':
          'Die Wände waren aus glitzerndem Silber und überall funkelten Mondsteine',
      'Suessigkeiten-Land':
          'Die Bäume hatten Lutscher als Blätter und es duftete nach Schokolade',
      'Musik-Wald':
          'Mit jedem Schritt klang eine schöne Melodie zwischen den Bäumen',
    };
    return map[location] ?? 'Es war ein wunderschöner Ort voller Magie';
  }

  /// Artikel kleingeschrieben (fuer mitten im Satz).
  String _heroArticle(String hero) {
    const die = <String>[
      'Prinzessin',
      'Fee',
      'Meerjungfrau',
      'Baeckerin',
      'Lehrerin',
      'Lokfuehrerin',
      'Katze',
      'Eule',
      'Schildkroete',
      'Maus',
    ];
    const das = <String>[
      'Einhorn',
      'Pony',
      'Eichhoernchen',
      'Kind',
      'Reh',
      'Kueken',
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
        'Drache',
        'Burg',
        'Wald',
        'Stern',
        'Kind',
        'Held',
        'Schatz',
        'Magie',
        'Reise',
        'Freund',
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
