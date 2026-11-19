/// Aufgabenkatalog der Holo-Lernräume (Godot-Route `learning` → Szene `holo`).
///
/// Jede Holo-Darstellung gehört zu genau einer geprüften Aufgabe des
/// regulären Generators: Die Textaufgabe „Im Korb liegen … Äpfel“, die
/// Satzaufgaben (Tunwort, Namenwort und Wiewort im Satz, Satz bauen), Silben
/// klatschen und Lesen (Satz → passendes Bild). Der Katalog liefert die
/// Aufgabe, die Zwillingsaufgabe mit gleicher Struktur und alle Daten, die der
/// Holo-Raum braucht. Antworten, Sterne und Lernprotokoll bleiben in der App.
library;

/// Ein geprüfter Satz für Tunwort- und Satzbau-Aufgaben (Klasse 1/2).
class HoloSentence {
  const HoloSentence({
    required this.words,
    required this.types,
    required this.verbIndex,
    required this.question,
    this.demo = 'none',
    this.nounIndex = -1,
    this.picture = '',
    this.adjIndex = -1,
    this.contrast = '',
    this.look = '',
  });

  /// Wörter ohne Satzzeichen; der Satz endet mit einem Punkt.
  final List<String> words;

  /// Wortart je Wort: artikel, nomen, adjektiv, verb, andere.
  final List<String> types;
  final int verbIndex;

  /// Die Frage, mit der Lumo zum Tunwort führt („Was tut der Fuchs?“).
  final String question;

  /// Was Lumo vormachen kann: jump, wave, nod oder none.
  final String demo;

  /// Nur für „Namenwort finden“: Stelle des einen Namenworts und das Bild,
  /// das der Holo-Raum nach der richtigen Wahl zeigt (fuchs, katze, hase, ente,
  /// hund, vogel, sonne, apfel).
  final int nounIndex;
  final String picture;

  /// Nur für „Wiewort finden“: Stelle des einen Wiewortes, die Art des
  /// Unterschieds für die Hilfe mit zwei Figuren (size oder color) und wie die
  /// Figur aussieht (klein/groß bzw. ein Farbwort).
  final int adjIndex;
  final String contrast;
  final String look;

  String get sentence => '${words.join(' ')}.';
  String get verb => words[verbIndex];
  String get noun => words[nounIndex];
  String get adjective => words[adjIndex];

  Map<String, Object> toPayload() => <String, Object>{
        'sentence': sentence,
        'words': List<String>.unmodifiable(words),
        'types': List<String>.unmodifiable(types),
        'verbIndex': verbIndex,
        'question': question,
        'demo': demo,
        if (nounIndex >= 0) 'nounIndex': nounIndex,
        if (picture.isNotEmpty) 'picture': picture,
        if (adjIndex >= 0) 'adjIndex': adjIndex,
        if (contrast.isNotEmpty) 'contrast': contrast,
        if (look.isNotEmpty) 'look': look,
      };
}

/// Ein Wort für „Silben klatschen“ mit seinen Sprechsilben (Grundschul-
/// Silbenlehre) und – wo der Holo-Raum es kennt – einem Bild.
class HoloSyllableWord {
  const HoloSyllableWord(this.spelling, [this.picture = '']);

  /// Silben mit Bindestrich, z. B. „Ba-na-ne“.
  final String spelling;
  final String picture;

  List<String> get syllables => spelling.split('-');
  String get word => syllables.join();

  Map<String, Object> toPayload() => <String, Object>{
        'word': word,
        'syllables': List<String>.unmodifiable(syllables),
        'picture': picture,
        'prompt': HoloLessonCatalog.syllablePrompt(word),
      };
}

/// Ein Satz für „Lesen“: Wo ist etwas? Drei Holo-Szenen mit demselben Ding und
/// Möbel; nur die Lage unterscheidet sich.
class HoloReadingSentence {
  const HoloReadingSentence({
    required this.words,
    required this.object,
    required this.place,
    required this.answer,
    required this.question,
  });

  final List<String> words;

  /// ball, apfel, katze, hund
  final String object;

  /// tisch, stuhl, kiste
  final String place;

  /// darauf, darunter, daneben, darin oder davor
  final String answer;
  final String question;

  String get sentence => '${words.join(' ')}.';
  int get keyIndex => words.indexOf(HoloLessonCatalog.relationWords[answer]!);
  List<String> get relations => HoloLessonCatalog.placeRelations[place]!;
}

class HoloLessonCatalog {
  const HoloLessonCatalog._();

  static const String korbStory = 'korb_aepfel';

  /// Silben klatschen (Deutsch Klasse 1, Einheit „Silben“). Jede Trennung ist
  /// einzeln geprüft (Sprechsilben). Keine Wörter mit einzelnem Anfangsvokal
  /// (I-gel, A-bend, O-ma) und keine strittigen Trennungen.
  static const List<HoloSyllableWord> syllableWords = <HoloSyllableWord>[
    HoloSyllableWord('Ball', 'ball'),
    HoloSyllableWord('Hund', 'hund'),
    HoloSyllableWord('Fuchs', 'fuchs'),
    HoloSyllableWord('Baum', 'baum'),
    HoloSyllableWord('Haus', 'haus'),
    HoloSyllableWord('Son-ne', 'sonne'),
    HoloSyllableWord('Ap-fel', 'apfel'),
    HoloSyllableWord('Kat-ze', 'katze'),
    HoloSyllableWord('Blu-me', 'blume'),
    HoloSyllableWord('Ha-se', 'hase'),
    HoloSyllableWord('En-te', 'ente'),
    HoloSyllableWord('Vo-gel', 'vogel'),
    HoloSyllableWord('Ba-na-ne', 'banane'),
    HoloSyllableWord('To-ma-te', 'tomate'),
    HoloSyllableWord('Te-le-fon'),
    HoloSyllableWord('Ma-ril-le'),
    HoloSyllableWord('Schmet-ter-ling'),
    HoloSyllableWord('Re-gen-bo-gen', 'regenbogen'),
    HoloSyllableWord('Scho-ko-la-de'),
    HoloSyllableWord('Mar-me-la-de'),
  ];

  static String syllablePrompt(String word) => 'Wie viele Silben hat $word?';

  static final RegExp _syllablePattern =
      RegExp(r'^Wie viele Silben hat (\S+)\?$');

  /// Holo-Daten für eine Silbenaufgabe des Generators, sonst null. Das
  /// ähnliche Wort hat eine andere Silbenzahl, damit das Kind nicht einfach
  /// die alte Zahl wiederholt.
  static Map<String, Object>? syllablePayload({
    required String prompt,
    required Object? correctAnswer,
    required String taskId,
  }) {
    final match = _syllablePattern.firstMatch(prompt);
    if (match == null) return null;
    final index = syllableWords.indexWhere((item) => item.word == match[1]);
    if (index < 0) return null;
    final item = syllableWords[index];
    if ('$correctAnswer' != '${item.syllables.length}') return null;
    final others = <HoloSyllableWord>[
      for (final other in syllableWords)
        if (other.syllables.length != item.syllables.length &&
            (other.syllables.length - item.syllables.length).abs() <= 2)
          other,
    ];
    final twin = others[taskId.hashCode.abs() % others.length];
    return <String, Object>{
      'kind': 'holo_sentence',
      'mode': 'syllables',
      ...item.toPayload(),
      'twin': twin.toPayload(),
    };
  }

  /// Lesen: Lagewörter und welche Lagen zu welchem Möbel passen (unter einer
  /// Kiste liegt nichts, auf einer offenen Kiste bleibt nichts liegen).
  static const Map<String, String> relationWords = <String, String>{
    'darauf': 'auf',
    'darunter': 'unter',
    'daneben': 'neben',
    'darin': 'in',
    'davor': 'vor',
  };
  static const Map<String, List<String>> placeRelations =
      <String, List<String>>{
    'tisch': <String>['darauf', 'darunter', 'daneben'],
    'stuhl': <String>['darauf', 'darunter', 'daneben'],
    'kiste': <String>['darin', 'daneben', 'davor'],
  };

  /// Lesen (Deutsch Klasse 1, Einheit „Erste Sätze“): genau ein Lagewort je
  /// Satz, Dativ nach auf/unter/neben/in/vor.
  static const List<HoloReadingSentence> readingSentences =
      <HoloReadingSentence>[
    HoloReadingSentence(
        words: <String>['Der', 'Ball', 'liegt', 'unter', 'dem', 'Tisch'],
        object: 'ball',
        place: 'tisch',
        answer: 'darunter',
        question: 'Wo liegt der Ball?'),
    HoloReadingSentence(
        words: <String>['Der', 'Ball', 'liegt', 'auf', 'dem', 'Tisch'],
        object: 'ball',
        place: 'tisch',
        answer: 'darauf',
        question: 'Wo liegt der Ball?'),
    HoloReadingSentence(
        words: <String>['Die', 'Katze', 'sitzt', 'auf', 'dem', 'Stuhl'],
        object: 'katze',
        place: 'stuhl',
        answer: 'darauf',
        question: 'Wo sitzt die Katze?'),
    HoloReadingSentence(
        words: <String>['Der', 'Hund', 'liegt', 'unter', 'dem', 'Stuhl'],
        object: 'hund',
        place: 'stuhl',
        answer: 'darunter',
        question: 'Wo liegt der Hund?'),
    HoloReadingSentence(
        words: <String>['Der', 'Apfel', 'liegt', 'in', 'der', 'Kiste'],
        object: 'apfel',
        place: 'kiste',
        answer: 'darin',
        question: 'Wo liegt der Apfel?'),
    HoloReadingSentence(
        words: <String>['Der', 'Apfel', 'liegt', 'neben', 'der', 'Kiste'],
        object: 'apfel',
        place: 'kiste',
        answer: 'daneben',
        question: 'Wo liegt der Apfel?'),
    HoloReadingSentence(
        words: <String>['Die', 'Katze', 'sitzt', 'in', 'der', 'Kiste'],
        object: 'katze',
        place: 'kiste',
        answer: 'darin',
        question: 'Wo sitzt die Katze?'),
    HoloReadingSentence(
        words: <String>['Der', 'Hund', 'sitzt', 'neben', 'dem', 'Tisch'],
        object: 'hund',
        place: 'tisch',
        answer: 'daneben',
        question: 'Wo sitzt der Hund?'),
    HoloReadingSentence(
        words: <String>['Der', 'Ball', 'liegt', 'vor', 'der', 'Kiste'],
        object: 'ball',
        place: 'kiste',
        answer: 'davor',
        question: 'Wo liegt der Ball?'),
  ];

  static String readingPrompt(HoloReadingSentence item) =>
      'Lies den Satz: „${item.sentence}“\n${item.question} Wähle das passende Wort.';

  static final RegExp _readingPattern = RegExp(
      r'^Lies den Satz: „(.+)“\nWo (?:liegt|sitzt) (?:der|die|das) \S+\? Wähle das passende Wort\.$');

  /// Reihenfolge der drei Szenen: je Aufgabe anders gedreht, damit die
  /// richtige Szene nicht immer an derselben Stelle steht.
  static List<String> readingScenes(HoloReadingSentence item, int seed) {
    final relations = item.relations;
    final shift =
        (seed.abs() + readingSentences.indexOf(item)) % relations.length;
    return <String>[
      ...relations.sublist(shift),
      ...relations.sublist(0, shift)
    ];
  }

  static Map<String, Object> _readingTask(HoloReadingSentence item, int seed) =>
      <String, Object>{
        'sentence': item.sentence,
        'words': List<String>.unmodifiable(item.words),
        'keyIndex': item.keyIndex,
        'object': item.object,
        'place': item.place,
        'scenes': readingScenes(item, seed),
        'answer': item.answer,
        'question': item.question,
      };

  /// Heinz' Textaufgabe als Generator-Geschichte (a + b mit Zehnerübergang).
  static String korbPrompt(int a, int b) =>
      'Im Korb liegen $a Äpfel. Lumo legt $b dazu. Wie viele sind es jetzt?';

  static final RegExp _korbPattern = RegExp(
      r'^Im Korb liegen (\d{1,2}) Äpfel\. Lumo legt (\d{1,2}) dazu\. Wie viele sind es jetzt\?$');

  /// Tunwort im Satz (Deutsch Klasse 2, Einheit „Tunwörter“).
  /// Das Tunwort steht an verschiedenen Stellen, damit die Lage nichts verrät.
  static const List<HoloSentence> verbSentences = <HoloSentence>[
    HoloSentence(
        words: <String>['Der', 'kleine', 'Fuchs', 'springt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        question: 'Was tut der Fuchs?',
        demo: 'jump'),
    HoloSentence(
        words: <String>['Die', 'Ente', 'schwimmt', 'im', 'Teich'],
        types: <String>['artikel', 'nomen', 'verb', 'andere', 'nomen'],
        verbIndex: 2,
        question: 'Was tut die Ente?'),
    HoloSentence(
        words: <String>['Lumo', 'winkt', 'den', 'Kindern'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Lumo?',
        demo: 'wave'),
    HoloSentence(
        words: <String>['Mia', 'malt', 'ein', 'buntes', 'Bild'],
        types: <String>['nomen', 'verb', 'artikel', 'adjektiv', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Mia?'),
    HoloSentence(
        words: <String>['Im', 'Garten', 'singt', 'ein', 'Vogel'],
        types: <String>['andere', 'nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Vogel?'),
    HoloSentence(
        words: <String>['Der', 'Hund', 'bellt', 'am', 'Zaun'],
        types: <String>['artikel', 'nomen', 'verb', 'andere', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Hund?'),
    HoloSentence(
        words: <String>['Opa', 'liest', 'die', 'Zeitung'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Opa?'),
    HoloSentence(words: <String>[
      'Die',
      'Katze',
      'schläft',
      'auf',
      'dem',
      'Sofa'
    ], types: <String>[
      'artikel',
      'nomen',
      'verb',
      'andere',
      'artikel',
      'nomen'
    ], verbIndex: 2, question: 'Was tut die Katze?'),
    HoloSentence(
        words: <String>['Am', 'Morgen', 'hüpft', 'der', 'Hase'],
        types: <String>['andere', 'nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 2,
        question: 'Was tut der Hase?',
        demo: 'jump'),
  ];

  /// Satz bauen (Deutsch Klasse 1, Einheit „Erste Sätze“): kurze Sätze
  /// mit lauter verschiedenen Wörtern, damit genau eine Reihenfolge stimmt.
  static const List<HoloSentence> orderSentences = <HoloSentence>[
    HoloSentence(
        words: <String>['Der', 'kleine', 'Fuchs', 'springt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        question: 'Was tut der Fuchs?',
        demo: 'jump'),
    HoloSentence(
        words: <String>['Mia', 'malt', 'ein', 'Bild'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Mia?'),
    HoloSentence(
        words: <String>['Die', 'Ente', 'schwimmt'],
        types: <String>['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        question: 'Was tut die Ente?'),
    HoloSentence(
        words: <String>['Lumo', 'winkt', 'den', 'Kindern'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Lumo?',
        demo: 'wave'),
    HoloSentence(
        words: <String>['Die', 'Katze', 'schläft'],
        types: <String>['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        question: 'Was tut die Katze?'),
    HoloSentence(
        words: <String>['Opa', 'liest', 'die', 'Zeitung'],
        types: <String>['nomen', 'verb', 'artikel', 'nomen'],
        verbIndex: 1,
        question: 'Was tut Opa?'),
    HoloSentence(
        words: <String>['Der', 'Hase', 'hüpft', 'weit'],
        types: <String>['artikel', 'nomen', 'verb', 'adjektiv'],
        verbIndex: 2,
        question: 'Was tut der Hase?',
        demo: 'jump'),
  ];

  /// Sätze für „Namenwort finden“: je genau ein Namenwort und ein Bild, das der
  /// Holo-Raum als Hologramm kennt. Die Frage führt zum Namenwort („Wer …?“).
  static const List<HoloSentence> nounSentences = <HoloSentence>[
    HoloSentence(
        words: ['Der', 'kleine', 'Fuchs', 'springt'],
        types: ['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        nounIndex: 2,
        picture: 'fuchs',
        question: 'Wer springt?'),
    HoloSentence(
        words: ['Die', 'Katze', 'schläft'],
        types: ['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'katze',
        question: 'Wer schläft?'),
    HoloSentence(
        words: ['Der', 'Hase', 'hüpft', 'weit'],
        types: ['artikel', 'nomen', 'verb', 'adjektiv'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'hase',
        question: 'Wer hüpft weit?'),
    HoloSentence(
        words: ['Die', 'Ente', 'schwimmt'],
        types: ['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'ente',
        question: 'Wer schwimmt?'),
    HoloSentence(
        words: ['Der', 'Hund', 'bellt', 'laut'],
        types: ['artikel', 'nomen', 'verb', 'adjektiv'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'hund',
        question: 'Wer bellt laut?'),
    HoloSentence(
        words: ['Ein', 'Vogel', 'singt'],
        types: ['artikel', 'nomen', 'verb'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'vogel',
        question: 'Wer singt?'),
    HoloSentence(
        words: ['Die', 'Sonne', 'scheint', 'hell'],
        types: ['artikel', 'nomen', 'verb', 'adjektiv'],
        verbIndex: 2,
        nounIndex: 1,
        picture: 'sonne',
        question: 'Was scheint hell?'),
    HoloSentence(
        words: ['Der', 'rote', 'Apfel', 'fällt'],
        types: ['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        nounIndex: 2,
        picture: 'apfel',
        question: 'Was fällt?'),
  ];

  /// Wiewort finden (Deutsch Klasse 2, Einheit „Wiewörter“): Begleiter,
  /// Wiewort, Namenwort, Tunwort – die Ablenker sind echte andere Wortarten.
  static const List<HoloSentence> adjectiveSentences = <HoloSentence>[
    HoloSentence(
        words: <String>['Der', 'kleine', 'Fuchs', 'springt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'fuchs',
        contrast: 'size',
        look: 'klein',
        question: 'Welches Wort sagt, wie der Fuchs ist?'),
    HoloSentence(
        words: <String>['Der', 'große', 'Hund', 'bellt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'hund',
        contrast: 'size',
        look: 'groß',
        question: 'Welches Wort sagt, wie der Hund ist?'),
    HoloSentence(
        words: <String>['Die', 'rote', 'Blume', 'blüht'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'blume',
        contrast: 'color',
        look: 'rot',
        question: 'Welches Wort sagt, wie die Blume ist?'),
    HoloSentence(
        words: <String>['Der', 'gelbe', 'Ball', 'rollt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'ball',
        contrast: 'color',
        look: 'gelb',
        question: 'Welches Wort sagt, wie der Ball ist?'),
    HoloSentence(
        words: <String>['Der', 'große', 'Baum', 'wächst'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'baum',
        contrast: 'size',
        look: 'groß',
        question: 'Welches Wort sagt, wie der Baum ist?'),
    HoloSentence(
        words: <String>['Die', 'kleine', 'Katze', 'schläft'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'katze',
        contrast: 'size',
        look: 'klein',
        question: 'Welches Wort sagt, wie die Katze ist?'),
    HoloSentence(
        words: <String>['Der', 'grüne', 'Apfel', 'fällt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'apfel',
        contrast: 'color',
        look: 'grün',
        question: 'Welches Wort sagt, wie der Apfel ist?'),
    HoloSentence(
        words: <String>['Die', 'gelbe', 'Ente', 'schwimmt'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'ente',
        contrast: 'color',
        look: 'gelb',
        question: 'Welches Wort sagt, wie die Ente ist?'),
    HoloSentence(
        words: <String>['Der', 'weiße', 'Hase', 'hüpft'],
        types: <String>['artikel', 'adjektiv', 'nomen', 'verb'],
        verbIndex: 3,
        adjIndex: 1,
        picture: 'hase',
        contrast: 'color',
        look: 'weiß',
        question: 'Welches Wort sagt, wie der Hase ist?'),
  ];

  /// Bilder, die der Holo-Raum als Hologramm zeigen kann.
  static const Set<String> nounPictures = <String>{
    'fuchs',
    'katze',
    'hase',
    'ente',
    'hund',
    'vogel',
    'sonne',
    'apfel',
    'ball',
    'baum',
    'haus',
    'blume',
    'banane',
    'tomate',
    'regenbogen',
  };

  /// Wie eine Figur in der Wiewort-Hilfe aussehen kann.
  static const Set<String> adjectiveLooks = <String>{
    'klein',
    'groß',
    'rot',
    'gelb',
    'grün',
    'blau',
    'weiß',
    'braun',
  };

  static String adjectivePrompt(HoloSentence item) =>
      'Lies den Satz: „${item.sentence}“\n${item.question}';

  static String verbPrompt(HoloSentence item) =>
      'Lies den Satz: „${item.sentence}“\nWelches Wort ist das Tunwort?';

  static String nounPrompt(HoloSentence item) =>
      'Lies den Satz: „${item.sentence}“\nWelches Wort ist das Namenwort?';

  static String orderPrompt(List<String> shuffledWords) =>
      'Bilde einen Satz aus diesen Wörtern: ${shuffledWords.join(' · ')}';

  static final RegExp _verbPattern =
      RegExp(r'^Lies den Satz: „(.+)“\nWelches Wort ist das Tunwort\?$');
  static final RegExp _nounPattern =
      RegExp(r'^Lies den Satz: „(.+)“\nWelches Wort ist das Namenwort\?$');
  static final RegExp _adjectivePattern =
      RegExp(r'^Lies den Satz: „(.+)“\nWelches Wort sagt, wie .+ ist\?$');
  static const String _orderPrefix = 'Bilde einen Satz aus diesen Wörtern: ';

  /// Vier Antwortkarten für die Textaufgabe: richtige Summe, je eins daneben
  /// und der typische Fehler „nur die Einer“ (a + b − 10).
  static List<int> mathChoices(int a, int b, int seed) {
    final sum = a + b;
    final values = <int>[sum - 1, sum, sum + 1, sum - 10];
    final shift = seed.abs() % values.length;
    return <int>[...values.sublist(shift), ...values.sublist(0, shift)];
  }

  /// Gleiche Struktur, andere Zahlen: wieder ein Zehnerübergang bis 20, aber
  /// eine andere Summe, damit die Lösung nicht abgeschrieben werden kann.
  static (int, int) twinNumbers(int a, int b, int seed) {
    final pairs = <(int, int)>[
      for (var x = 3; x <= 9; x++)
        for (var y = 3; y <= 9; y++)
          if (x + y > 10 && x + y <= 18 && x + y != a + b && x != a) (x, y),
    ];
    return pairs[seed.abs() % pairs.length];
  }

  static bool isBridgingAddition(int a, int b) =>
      a >= 2 && a <= 9 && b >= 2 && b <= 9 && a + b > 10 && a + b <= 20;

  /// Holo-Daten für eine Textaufgabe des Generators, sonst null.
  static Map<String, Object>? wordProblemPayload({
    required String prompt,
    required Object? correctAnswer,
    required List<String> choiceLabels,
    required String taskId,
  }) {
    final match = _korbPattern.firstMatch(prompt);
    if (match == null) return null;
    final a = int.parse(match[1]!);
    final b = int.parse(match[2]!);
    if (!isBridgingAddition(a, b)) return null;
    if ('$correctAnswer' != '${a + b}') return null;
    final choices = <int>[];
    for (final label in choiceLabels) {
      final value = int.tryParse(label.trim());
      if (value == null || value < 0 || value > 40 || choices.contains(value)) {
        return null;
      }
      choices.add(value);
    }
    if (choices.length < 3 || choices.length > 4 || !choices.contains(a + b)) {
      return null;
    }
    final seed = taskId.hashCode;
    final (twinA, twinB) = twinNumbers(a, b, seed);
    return <String, Object>{
      'kind': 'holo_word_problem',
      'story': korbStory,
      'a': a,
      'b': b,
      'prompt': prompt,
      'choices': List<int>.unmodifiable(choices),
      'twin': <String, Object>{
        'story': korbStory,
        'a': twinA,
        'b': twinB,
        'prompt': korbPrompt(twinA, twinB),
        'choices': mathChoices(twinA, twinB, seed ~/ 7),
      },
    };
  }

  /// Holo-Daten für eine Satzaufgabe des Generators, sonst null.
  static Map<String, Object>? sentencePayload({
    required String prompt,
    required Object? correctAnswer,
    required String taskId,
  }) {
    final seed = taskId.hashCode;
    final verb = _verbPattern.firstMatch(prompt);
    if (verb != null) {
      final index =
          verbSentences.indexWhere((item) => item.sentence == verb[1]);
      if (index < 0 || '$correctAnswer' != verbSentences[index].verb) {
        return null;
      }
      final twin = verbSentences[
          (index + 1 + seed.abs() % (verbSentences.length - 1)) %
              verbSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'verb',
        ...verbSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    final noun = _nounPattern.firstMatch(prompt);
    if (noun != null) {
      final index =
          nounSentences.indexWhere((item) => item.sentence == noun[1]);
      if (index < 0 || '$correctAnswer' != nounSentences[index].noun) {
        return null;
      }
      final twin = nounSentences[
          (index + 1 + seed.abs() % (nounSentences.length - 1)) %
              nounSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'noun',
        ...nounSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    final adjective = _adjectivePattern.firstMatch(prompt);
    if (adjective != null) {
      final index = adjectiveSentences
          .indexWhere((item) => item.sentence == adjective[1]);
      if (index < 0 ||
          '$correctAnswer' != adjectiveSentences[index].adjective ||
          prompt != adjectivePrompt(adjectiveSentences[index])) {
        return null;
      }
      final twin = adjectiveSentences[
          (index + 1 + seed.abs() % (adjectiveSentences.length - 1)) %
              adjectiveSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'adjective',
        ...adjectiveSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    final reading = _readingPattern.firstMatch(prompt);
    if (reading != null) {
      final index =
          readingSentences.indexWhere((item) => item.sentence == reading[1]);
      if (index < 0 ||
          '$correctAnswer' != readingSentences[index].answer ||
          prompt != readingPrompt(readingSentences[index])) {
        return null;
      }
      final item = readingSentences[index];
      // Ähnlicher Satz: anderes Möbel oder andere Lage, nie derselbe Satz.
      final candidates = <HoloReadingSentence>[
        for (final other in readingSentences)
          if (other.sentence != item.sentence && other.answer != item.answer)
            other,
      ];
      final twin = candidates[seed.abs() % candidates.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'reading',
        ..._readingTask(item, seed),
        'twin': _readingTask(twin, seed ~/ 3),
      };
    }
    if (prompt.startsWith(_orderPrefix)) {
      final index = orderSentences
          .indexWhere((item) => item.sentence == '$correctAnswer');
      if (index < 0) return null;
      final twin = orderSentences[
          (index + 1 + seed.abs() % (orderSentences.length - 1)) %
              orderSentences.length];
      return <String, Object>{
        'kind': 'holo_sentence',
        'mode': 'order',
        ...orderSentences[index].toPayload(),
        'twin': twin.toPayload(),
      };
    }
    return null;
  }
}
