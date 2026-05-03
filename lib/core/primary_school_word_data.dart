/// Pädagogisch geprüfte Wortdaten für Volksschul-Aufgaben.
///
/// Diese Datei enthält bewusst statische, lokale Daten:
/// - keine Cloud
/// - keine Zufallslogik
/// - keine Schülerdaten
///
/// Zweck:
/// Generator, Adapter, Workbook-Visuals und später die KI-Aufgaben sollen aus
/// breiten, geprüften Wortlisten ziehen. Dadurch verschwinden die sichtbaren
/// Wiederholungen wie ständig Auto/Sonne/Haus als Antwortmöglichkeit.
class PrimarySchoolWordData {
  const PrimarySchoolWordData._();

  static const Map<String, List<String>> syllables = <String, List<String>>{
    // Klasse 1: einfache, häufige Wörter
    'Mama': <String>['Ma', 'ma'],
    'Papa': <String>['Pa', 'pa'],
    'Oma': <String>['O', 'ma'],
    'Opa': <String>['O', 'pa'],
    'Hund': <String>['Hund'],
    'Ball': <String>['Ball'],
    'Haus': <String>['Haus'],
    'Maus': <String>['Maus'],
    'Buch': <String>['Buch'],
    'Fuchs': <String>['Fuchs'],
    'Igel': <String>['I', 'gel'],
    'Rose': <String>['Ro', 'se'],
    'Sonne': <String>['Son', 'ne'],
    'Schule': <String>['Schu', 'le'],
    'Apfel': <String>['Ap', 'fel'],
    'Auto': <String>['Au', 'to'],
    'Biene': <String>['Bie', 'ne'],
    'Kerze': <String>['Ker', 'ze'],
    'Wolke': <String>['Wol', 'ke'],
    'Tasche': <String>['Ta', 'sche'],
    'Tafel': <String>['Ta', 'fel'],
    'Feder': <String>['Fe', 'der'],
    'Vogel': <String>['Vo', 'gel'],
    'Hase': <String>['Ha', 'se'],
    'Nase': <String>['Na', 'se'],
    'Dose': <String>['Do', 'se'],
    'Brot': <String>['Brot'],
    'Hut': <String>['Hut'],
    'Rad': <String>['Rad'],
    'Blatt': <String>['Blatt'],
    'Stift': <String>['Stift'],

    // Klasse 2: zwei bis drei Silben
    'Banane': <String>['Ba', 'na', 'ne'],
    'Tomate': <String>['To', 'ma', 'te'],
    'Rakete': <String>['Ra', 'ke', 'te'],
    'Kinder': <String>['Kin', 'der'],
    'Blume': <String>['Blu', 'me'],
    'Lampe': <String>['Lam', 'pe'],
    'Katze': <String>['Kat', 'ze'],
    'Tasse': <String>['Tas', 'se'],
    'Garten': <String>['Gar', 'ten'],
    'Fenster': <String>['Fens', 'ter'],
    'Elefant': <String>['E', 'le', 'fant'],
    'Kamel': <String>['Ka', 'mel'],
    'Ente': <String>['En', 'te'],
    'Schnecke': <String>['Schne', 'cke'],
    'Kaninchen': <String>['Ka', 'nin', 'chen'],
    'Pinsel': <String>['Pin', 'sel'],
    'Koffer': <String>['Kof', 'fer'],
    'Wasser': <String>['Was', 'ser'],
    'Wiese': <String>['Wie', 'se'],
    'Küche': <String>['Kü', 'che'],
    'Semmel': <String>['Sem', 'mel'],
    'Sackerl': <String>['Sa', 'ckerl'],
    'Jause': <String>['Jau', 'se'],
    'Marille': <String>['Ma', 'ril', 'le'],

    // Klasse 3 und 4: längere Wörter, aber noch kindgerecht
    'Schokolade': <String>['Scho', 'ko', 'la', 'de'],
    'Schmetterling': <String>['Schmet', 'ter', 'ling'],
    'Sonnenblume': <String>['Son', 'nen', 'blu', 'me'],
    'Krokodil': <String>['Kro', 'ko', 'dil'],
    'Kartoffel': <String>['Kar', 'tof', 'fel'],
    'Erdbeere': <String>['Erd', 'bee', 're'],
    'Polizist': <String>['Po', 'li', 'zist'],
    'Feuerwehr': <String>['Feu', 'er', 'wehr'],
    'Schulranzen': <String>['Schul', 'ran', 'zen'],
    'Zauberer': <String>['Zau', 'be', 'rer'],
    'Abenteuer': <String>['A', 'ben', 'teu', 'er'],
    'Bibliothek': <String>['Bi', 'blio', 'thek'],
    'Schatzkarte': <String>['Schatz', 'kar', 'te'],
    'Regenbogen': <String>['Re', 'gen', 'bo', 'gen'],
    'Sternwarte': <String>['Stern', 'war', 'te'],
    'Werkzeug': <String>['Werk', 'zeug'],
    'Schildkröte': <String>['Schild', 'krö', 'te'],
    'Papagei': <String>['Pa', 'pa', 'gei'],
  };

  static const List<String> grade1Nouns = <String>[
    'Biene', 'Blume', 'Kerze', 'Rose', 'Igel', 'Maus', 'Brot', 'Hut',
    'Stift', 'Rad', 'Blatt', 'Tasche', 'Tafel', 'Feder', 'Vogel', 'Hase',
    'Nase', 'Dose', 'Lampe', 'Tasse', 'Wolke', 'Baum', 'Katze', 'Apfel',
  ];

  static const List<String> grade2Nouns = <String>[
    'Garten', 'Fenster', 'Banane', 'Tomate', 'Rakete', 'Kinder', 'Kamel',
    'Ente', 'Schnecke', 'Kaninchen', 'Pinsel', 'Koffer', 'Wasser', 'Wiese',
    'Küche', 'Semmel', 'Jause', 'Marille', 'Trommel', 'Brücke', 'Würfel',
    'Muschel', 'Schlüssel', 'Paket',
  ];

  static const List<String> grade3PlusNouns = <String>[
    'Schokolade', 'Krokodil', 'Kartoffel', 'Erdbeere', 'Feuerwehr',
    'Schulranzen', 'Zauberer', 'Regenbogen', 'Sternwarte', 'Werkzeug',
    'Schildkröte', 'Papagei', 'Abenteuer', 'Schatzkarte', 'Bibliothek',
  ];

  static const List<String> verbs = <String>[
    'laufen', 'malen', 'lesen', 'springen', 'singen', 'lachen', 'spielen',
    'tanzen', 'schreiben', 'rechnen', 'trinken', 'backen', 'bauen', 'fragen',
    'suchen', 'finden', 'tragen', 'rollen', 'klatschen', 'zählen', 'zeichnen',
    'turnen', 'wandern', 'helfen',
  ];

  static const List<String> adjectives = <String>[
    'groß', 'klein', 'warm', 'kalt', 'hell', 'dunkel', 'rund', 'eckig',
    'weich', 'hart', 'schnell', 'langsam', 'leise', 'laut', 'leicht',
    'schwer', 'fröhlich', 'müde', 'mutig', 'freundlich', 'sauber', 'bunt',
    'glatt', 'rau',
  ];

  static const List<List<String>> rhymePairs = <List<String>>[
    <String>['Hase', 'Nase'],
    <String>['Dose', 'Rose'],
    <String>['Ball', 'Fall'],
    <String>['Haus', 'Maus'],
    <String>['Stein', 'Bein'],
    <String>['Hut', 'Mut'],
    <String>['Kanne', 'Tanne'],
    <String>['Buch', 'Tuch'],
    <String>['Tasche', 'Flasche'],
    <String>['Biene', 'Schiene'],
    <String>['Wand', 'Hand'],
    <String>['Brot', 'Boot'],
    <String>['Licht', 'Gesicht'],
    <String>['Garten', 'Warten'],
    <String>['Kerze', 'Herze'],
    <String>['Kamel', 'Pinsel'],
  ];

  static const List<String> startSoundWordsGrade1 = <String>[
    'Biene', 'Blume', 'Kerze', 'Rose', 'Igel', 'Maus', 'Tasse', 'Lampe',
    'Katze', 'Nase', 'Oma', 'Papa', 'Tisch', 'Uhr', 'Fisch', 'Garten',
    'Vogel', 'Hase', 'Dose', 'Feder', 'Wolke', 'Baum', 'Rad', 'Stift',
  ];

  static const List<String> endSoundWordsGrade1 = <String>[
    'Brot', 'Rad', 'Glas', 'Rose', 'Apfel', 'Garten', 'Stift', 'Blatt',
    'Hut', 'Maus', 'Buch', 'Tisch', 'Lampe', 'Tasse', 'Igel', 'Pinsel',
    'Koffer', 'Feder', 'Wiese', 'Kamel', 'Ente', 'Kerze', 'Biene', 'Dose',
  ];

  static const Map<String, String> articles = <String, String>{
    'Biene': 'die',
    'Blume': 'die',
    'Kerze': 'die',
    'Rose': 'die',
    'Igel': 'der',
    'Maus': 'die',
    'Brot': 'das',
    'Hut': 'der',
    'Stift': 'der',
    'Rad': 'das',
    'Blatt': 'das',
    'Tasche': 'die',
    'Tafel': 'die',
    'Feder': 'die',
    'Vogel': 'der',
    'Hase': 'der',
    'Nase': 'die',
    'Dose': 'die',
    'Lampe': 'die',
    'Tasse': 'die',
    'Wolke': 'die',
    'Baum': 'der',
    'Katze': 'die',
    'Apfel': 'der',
    'Garten': 'der',
    'Fenster': 'das',
    'Banane': 'die',
    'Tomate': 'die',
    'Rakete': 'die',
    'Kamel': 'das',
    'Ente': 'die',
    'Schnecke': 'die',
    'Kaninchen': 'das',
    'Pinsel': 'der',
    'Koffer': 'der',
    'Wasser': 'das',
    'Wiese': 'die',
    'Küche': 'die',
    'Semmel': 'die',
    'Jause': 'die',
    'Marille': 'die',
  };

  static List<String>? syllablesFor(String word) => syllables[_normalizeKey(word)];

  static List<String> nounsForGrade(int grade) {
    if (grade <= 1) return grade1Nouns;
    if (grade == 2) return <String>[...grade1Nouns, ...grade2Nouns];
    return <String>[...grade1Nouns, ...grade2Nouns, ...grade3PlusNouns];
  }

  static String nounForGrade(int grade, int seed) {
    final words = nounsForGrade(grade);
    return words[_positiveIndex(seed, words.length)];
  }

  static String verbForSeed(int seed) => verbs[_positiveIndex(seed, verbs.length)];

  static String adjectiveForSeed(int seed) => adjectives[_positiveIndex(seed, adjectives.length)];

  static List<String> rhymePairForSeed(int seed) => rhymePairs[_positiveIndex(seed, rhymePairs.length)];

  static String? firstSoundWordForGrade(int grade, {int seed = 0}) {
    if (startSoundWordsGrade1.isEmpty) return null;
    return startSoundWordsGrade1[_positiveIndex(seed + grade, startSoundWordsGrade1.length)];
  }

  static String? endSoundWordForGrade(int grade, {int seed = 0}) {
    if (endSoundWordsGrade1.isEmpty) return null;
    return endSoundWordsGrade1[_positiveIndex(seed + grade, endSoundWordsGrade1.length)];
  }

  static String? articleFor(String word) => articles[_normalizeKey(word)];

  static int _positiveIndex(int seed, int length) {
    if (length <= 1) return 0;
    return (seed & 0x7fffffff) % length;
  }

  static String _normalizeKey(String value) {
    final cleaned = value.trim();
    for (final key in syllables.keys) {
      if (key.toLowerCase() == cleaned.toLowerCase()) return key;
    }
    for (final key in articles.keys) {
      if (key.toLowerCase() == cleaned.toLowerCase()) return key;
    }
    return cleaned;
  }
}
