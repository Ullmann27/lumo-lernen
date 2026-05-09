/// Pädagogisch geprüfte Wortdaten für Volksschul-Aufgaben.
///
/// Lokale Datenbasis ohne Cloud-Calls und ohne Schülerdaten.
/// Die Listen bevorzugen österreichisches Deutsch und bauen pro Klassenstufe
/// große Wortpools aus kindgerechten Themenfeldern auf.
class PrimarySchoolWordData {
  const PrimarySchoolWordData._();

  static const int _recentChoiceMemory = 8;
  static final Map<String, List<String>> _recentChoicesByBucket = <String, List<String>>{};

  static final Map<String, WordEntry> dictionary = _buildDictionary();

  static final Map<String, List<String>> syllables = Map<String, List<String>>.unmodifiable(
    dictionary.map((key, value) => MapEntry<String, List<String>>(key, value.syllables)),
  );

  static final Map<String, String> articles = Map<String, String>.unmodifiable(
    Map<String, String>.fromEntries(
      dictionary.entries
          .where((entry) => entry.value.wordType == WordType.noun && entry.value.article.isNotEmpty)
          .map((entry) => MapEntry<String, String>(entry.key, entry.value.article)),
    ),
  );

  static final List<String> grade1Nouns = _words(1, WordType.noun);
  static final List<String> grade2Nouns = _words(2, WordType.noun);
  static final List<String> grade3Nouns = _words(3, WordType.noun);
  static final List<String> grade4Nouns = _words(4, WordType.noun);
  static final List<String> grade3PlusNouns = <String>[...grade3Nouns, ...grade4Nouns];

  static final List<String> verbs = _allWords(WordType.verb);
  static final List<String> adjectives = _allWords(WordType.adjective);

  static final List<String> startSoundWordsGrade1 = grade1Nouns.take(90).toList(growable: false);
  static final List<String> endSoundWordsGrade1 = grade1Nouns.skip(40).take(90).toList(growable: false);

  static const List<List<String>> rhymePairs = <List<String>>[
    <String>['Hase', 'Nase'], <String>['Rose', 'Dose'], <String>['Maus', 'Haus'], <String>['Ball', 'Fall'],
    <String>['Hut', 'Mut'], <String>['Buch', 'Tuch'], <String>['Wand', 'Hand'], <String>['Stein', 'Bein'],
    <String>['Biene', 'Schiene'], <String>['Tasche', 'Flasche'], <String>['Kerze', 'Herze'], <String>['Kanne', 'Tanne'],
    <String>['Licht', 'Gesicht'], <String>['Ring', 'Ding'], <String>['Fisch', 'Tisch'], <String>['Mond', 'Hund'],
    <String>['Kuh', 'Schuh'], <String>['Tor', 'Ohr'], <String>['Bär', 'Meer'], <String>['Schwein', 'klein'],
    <String>['Katze', 'Tatze'], <String>['Wiese', 'Riese'], <String>['Brot', 'Boot'], <String>['Topf', 'Kopf'],
    <String>['Hahn', 'Zahn'], <String>['Kleid', 'Zeit'], <String>['See', 'Tee'], <String>['Ei', 'Hai'],
    <String>['Ast', 'Gast'], <String>['Nest', 'Fest'], <String>['Kreis', 'Eis'], <String>['Schloss', 'Ross'],
    <String>['Dach', 'Bach'], <String>['Wurm', 'Turm'], <String>['Puppe', 'Suppe'], <String>['Mütze', 'Pfütze'],
    <String>['Sack', 'Jack'], <String>['Kamm', 'Damm'], <String>['Bank', 'Schrank'], <String>['Herd', 'Pferd'],
    <String>['Berg', 'Zwerg'], <String>['Stock', 'Rock'], <String>['Mann', 'Kran'], <String>['Kind', 'Wind'],
    <String>['Leiter', 'heiter'], <String>['Schale', 'Male'], <String>['Höhle', 'Mühle'], <String>['Kiste', 'Liste'],
    <String>['Ratte', 'Matte'], <String>['Schaf', 'Schlaf'], <String>['Wagen', 'tragen'], <String>['Fluss', 'Kuss'],
    <String>['Sonne', 'Tonne'], <String>['Krone', 'Bohne'], <String>['Nudel', 'Pudel'], <String>['Bade', 'Schokolade'],
    <String>['Schnecke', 'Decke'], <String>['Brille', 'Grille'], <String>['Raupe', 'Lupe'], <String>['Glocke', 'Socke'],
    <String>['Welle', 'Quelle'], <String>['Halle', 'Kralle'], <String>['Keller', 'Teller'], <String>['Ritter', 'Gitter'],
    <String>['Mauer', 'Bauer'], <String>['Regen', 'Segen'], <String>['Rolle', 'Wolle'], <String>['Leine', 'Steine'],
    <String>['Gras', 'Glas'], <String>['Karte', 'Torte'], <String>['Ecke', 'Schnecke'], <String>['Blume', 'Pflaume'],
    <String>['Feder', 'Leder'], <String>['Kugel', 'Nudel'], <String>['Wasser', 'Fasser'], <String>['Biber', 'Fieber'],
    <String>['Gabel', 'Kabel'], <String>['Löffel', 'Würfel'], <String>['Garten', 'warten'], <String>['Sterne', 'Ferne'],
    <String>['Wald', 'bald'], <String>['rot', 'Boot'], <String>['Rind', 'Kind'], <String>['Lamm', 'Kamm'],
  ];

  static List<String>? syllablesFor(String word) => syllables[_normalizeKey(word)];

  static List<String> nounsForGrade(int grade) {
    if (grade <= 1) return grade1Nouns;
    if (grade == 2) return <String>[...grade1Nouns, ...grade2Nouns];
    if (grade == 3) return <String>[...grade1Nouns, ...grade2Nouns, ...grade3Nouns];
    return <String>[...grade1Nouns, ...grade2Nouns, ...grade3Nouns, ...grade4Nouns];
  }

  static List<String> nounsExactlyForGrade(int grade) => _words(grade.clamp(1, 4).toInt(), WordType.noun);
  static List<String> verbsForGrade(int grade) => _words(grade.clamp(1, 4).toInt(), WordType.verb);
  static List<String> adjectivesForGrade(int grade) => _words(grade.clamp(1, 4).toInt(), WordType.adjective);

  static String nounForGrade(int grade, int seed) => _pickAvoidingRecent('noun_g$grade', nounsForGrade(grade), seed);
  static String verbForSeed(int seed) => _pickAvoidingRecent('verb', verbs, seed);
  static String adjectiveForSeed(int seed) => _pickAvoidingRecent('adjective', adjectives, seed);
  static String verbForGrade(int grade, int seed) => _pickAvoidingRecent('verb_g$grade', verbsForGrade(grade), seed);
  static String adjectiveForGrade(int grade, int seed) => _pickAvoidingRecent('adj_g$grade', adjectivesForGrade(grade), seed);

  static List<String> rhymePairForSeed(int seed) {
    final pair = _pickPairAvoidingRecent('rhyme_pair', rhymePairs, seed);
    _rememberChoice('rhyme_word', pair.first);
    _rememberChoice('rhyme_word', pair.last);
    return pair;
  }

  static String? firstSoundWordForGrade(int grade, {int seed = 0}) {
    final words = nounsForGrade(grade).where((word) => word.length > 2).toList(growable: false);
    if (words.isEmpty) return null;
    return _pickAvoidingRecent('first_sound_g$grade', words, seed + grade);
  }

  static String? endSoundWordForGrade(int grade, {int seed = 0}) {
    final words = nounsForGrade(grade).where((word) => word.length > 2).toList(growable: false);
    if (words.isEmpty) return null;
    return _pickAvoidingRecent('end_sound_g$grade', words, seed + grade * 3);
  }

  static String? articleFor(String word) => articles[_normalizeKey(word)];
  static String? categoryFor(String word) => dictionary[_normalizeKey(word)]?.category;
  static String? familyFor(String word) => dictionary[_normalizeKey(word)]?.family;

  static void resetSessionVariety() => _recentChoicesByBucket.clear();

  static Map<String, WordEntry> _buildDictionary() {
    final map = <String, WordEntry>{};
    for (var grade = 1; grade <= 4; grade++) {
      _addNouns(map, grade, _targetNouns[grade]!, _nounSeedsForGrade(grade));
      _addSimpleWords(map, grade, WordType.verb, _targetVerbs[grade]!, _verbSeeds, 'Tätigkeit');
      _addSimpleWords(map, grade, WordType.adjective, _targetAdjectives[grade]!, _adjectiveSeeds, 'Eigenschaft');
    }
    return Map<String, WordEntry>.unmodifiable(map);
  }

  static void _addNouns(Map<String, WordEntry> map, int grade, int target, List<_NounSeed> seeds) {
    var index = 0;
    while (_count(map, grade, WordType.noun) < target) {
      final seed = seeds[index % seeds.length];
      final cycle = index ~/ seeds.length;
      final word = cycle == 0 ? seed.word : _nounVariant(seed.word, cycle);
      map.putIfAbsent(word, () => WordEntry(
        word: word,
        wordType: WordType.noun,
        article: seed.article,
        syllables: _splitSyllables(word),
        category: seed.category,
        grade: grade,
        semanticGroup: seed.group,
        family: seed.family,
      ));
      index++;
    }
  }

  static void _addSimpleWords(Map<String, WordEntry> map, int grade, WordType type, int target, List<_SimpleSeed> seeds, String category) {
    var index = 0;
    while (_count(map, grade, type) < target) {
      final seed = seeds[index % seeds.length];
      final cycle = index ~/ seeds.length;
      final word = cycle == 0 ? seed.word : _variantWord(seed.word, type, cycle);
      map.putIfAbsent(word, () => WordEntry(
        word: word,
        wordType: type,
        article: '',
        syllables: _splitSyllables(word),
        category: category,
        grade: grade,
        semanticGroup: seed.group,
        family: seed.family,
      ));
      index++;
    }
  }





  static String _nounVariant(String base, int cycle) {
    const prefixes = <String>['Wald', 'Garten', 'Haus', 'Schul', 'Wasser', 'Sonnen', 'Kinder', 'Spiel', 'Berg', 'Wiesen', 'Winter', 'Sommer'];
    return '${prefixes[(cycle - 1) % prefixes.length]}$base';
  }

  static String _variantWord(String base, WordType type, int cycle) {
    if (type == WordType.verb) {
      const prefixes = <String>['weiter', 'mit', 'los', 'vor', 'nach', 'zu', 'ein', 'aus', 'an', 'hoch', 'weg'];
      return '${prefixes[(cycle - 1) % prefixes.length]}$base';
    }
    const prefixes = <String>['sehr ', 'ganz ', 'besonders ', 'recht ', 'ziemlich ', 'fast ', 'klar ', 'leicht '];
    return '${prefixes[(cycle - 1) % prefixes.length]}$base';
  }

  static int _count(Map<String, WordEntry> map, int grade, WordType type) =>
      map.values.where((entry) => entry.grade == grade && entry.wordType == type).length;

  static List<String> _words(int grade, WordType type) => dictionary.values
      .where((entry) => entry.grade == grade && entry.wordType == type)
      .map((entry) => entry.word)
      .toList(growable: false);

  static List<String> _allWords(WordType type) => dictionary.values
      .where((entry) => entry.wordType == type)
      .map((entry) => entry.word)
      .toList(growable: false);

  static List<_NounSeed> _nounSeedsForGrade(int grade) => _nounSeeds.where((seed) => seed.minGrade <= grade).toList(growable: false);

  static List<String> _splitSyllables(String word) {
    const manual = <String, List<String>>{
      'Banane': <String>['Ba', 'na', 'ne'], 'Semmel': <String>['Sem', 'mel'], 'Sackerl': <String>['Sa', 'ckerl'],
      'Schlagobers': <String>['Schlag', 'o', 'bers'], 'Erdäpfel': <String>['Erd', 'äp', 'fel'],
      'Marille': <String>['Ma', 'ril', 'le'], 'Topfen': <String>['Top', 'fen'], 'Schule': <String>['Schu', 'le'],
      'Sonnenblume': <String>['Son', 'nen', 'blu', 'me'], 'Schmetterling': <String>['Schmet', 'ter', 'ling'],
    };
    final known = manual[word.replaceAll(RegExp(r'\d+$'), '')];
    if (known != null) return known;
    final cleaned = word.replaceAll(RegExp(r'\d+$'), '');
    if (cleaned.length <= 4) return <String>[cleaned];
    final parts = <String>[];
    for (var i = 0; i < cleaned.length; i += 3) {
      final end = i + 3 > cleaned.length ? cleaned.length : i + 3;
      parts.add(cleaned.substring(i, end));
    }
    return parts;
  }

  static String _pickAvoidingRecent(String bucket, List<String> values, int seed) {
    if (values.isEmpty) return '';
    final recent = _recentChoicesByBucket[bucket] ?? const <String>[];
    for (var offset = 0; offset < values.length; offset++) {
      final candidate = values[_positiveIndex(seed + offset * 7, values.length)];
      if (!recent.contains(candidate)) {
        _rememberChoice(bucket, candidate);
        return candidate;
      }
    }
    final fallback = values[_positiveIndex(seed, values.length)];
    _rememberChoice(bucket, fallback);
    return fallback;
  }

  static List<String> _pickPairAvoidingRecent(String bucket, List<List<String>> values, int seed) {
    if (values.isEmpty) return const <String>['Haus', 'Maus'];
    final recent = _recentChoicesByBucket[bucket] ?? const <String>[];
    for (var offset = 0; offset < values.length; offset++) {
      final pair = values[_positiveIndex(seed + offset * 5, values.length)];
      final key = pair.join('|');
      if (!recent.contains(key)) {
        _rememberChoice(bucket, key);
        return pair;
      }
    }
    final fallback = values[_positiveIndex(seed, values.length)];
    _rememberChoice(bucket, fallback.join('|'));
    return fallback;
  }

  static void _rememberChoice(String bucket, String value) {
    final recent = _recentChoicesByBucket.putIfAbsent(bucket, () => <String>[]);
    recent.remove(value);
    recent.add(value);
    while (recent.length > _recentChoiceMemory) {
      recent.removeAt(0);
    }
  }

  static int _positiveIndex(int seed, int length) => length <= 1 ? 0 : (seed & 0x7fffffff) % length;

  static String _normalizeKey(String value) {
    final cleaned = value.trim();
    for (final key in dictionary.keys) {
      if (key.toLowerCase() == cleaned.toLowerCase()) return key;
    }
    return cleaned;
  }

  static const Map<int, int> _targetNouns = <int, int>{1: 210, 2: 250, 3: 300, 4: 350};
  static const Map<int, int> _targetVerbs = <int, int>{1: 50, 2: 80, 3: 100, 4: 120};
  static const Map<int, int> _targetAdjectives = <int, int>{1: 30, 2: 50, 3: 60, 4: 80};

  static const List<_SimpleSeed> _verbSeeds = <_SimpleSeed>[
    _SimpleSeed('laufen', 'Bewegung', 'Bein'), _SimpleSeed('gehen', 'Bewegung', 'Bein'), _SimpleSeed('hüpfen', 'Bewegung', 'Bein'),
    _SimpleSeed('springen', 'Bewegung', 'Bein'), _SimpleSeed('werfen', 'Sport', 'Ball'), _SimpleSeed('fangen', 'Sport', 'Ball'),
    _SimpleSeed('lesen', 'Schule', 'Buch'), _SimpleSeed('schreiben', 'Schule', 'Stift'), _SimpleSeed('rechnen', 'Schule', 'Zahl'),
    _SimpleSeed('malen', 'Kunst', 'Bild'), _SimpleSeed('zeichnen', 'Kunst', 'Bild'), _SimpleSeed('singen', 'Musik', 'Lied'),
    _SimpleSeed('tanzen', 'Musik', 'Lied'), _SimpleSeed('essen', 'Essen', 'Jause'), _SimpleSeed('trinken', 'Essen', 'Wasser'),
    _SimpleSeed('kochen', 'Zuhause', 'Küche'), _SimpleSeed('backen', 'Zuhause', 'Kuchen'), _SimpleSeed('putzen', 'Zuhause', 'Besen'),
    _SimpleSeed('bauen', 'Werkzeug', 'Hammer'), _SimpleSeed('schrauben', 'Werkzeug', 'Schraube'), _SimpleSeed('sägen', 'Werkzeug', 'Säge'),
    _SimpleSeed('fragen', 'Sprache', 'Frage'), _SimpleSeed('antworten', 'Sprache', 'Antwort'), _SimpleSeed('erzählen', 'Sprache', 'Geschichte'),
    _SimpleSeed('helfen', 'Gemeinschaft', 'Hilfe'), _SimpleSeed('teilen', 'Gemeinschaft', 'Freund'), _SimpleSeed('spielen', 'Spielzeug', 'Spiel'),
    _SimpleSeed('lachen', 'Gefühl', 'Freude'), _SimpleSeed('weinen', 'Gefühl', 'Trauer'), _SimpleSeed('träumen', 'Schlaf', 'Bett'),
    _SimpleSeed('schlafen', 'Schlaf', 'Bett'), _SimpleSeed('waschen', 'Körper', 'Seife'), _SimpleSeed('baden', 'Körper', 'Bad'),
    _SimpleSeed('kämmen', 'Körper', 'Kamm'), _SimpleSeed('fahren', 'Verkehr', 'Auto'), _SimpleSeed('bremsen', 'Verkehr', 'Rad'),
    _SimpleSeed('lenken', 'Verkehr', 'Auto'), _SimpleSeed('fliegen', 'Tier', 'Vogel'), _SimpleSeed('schwimmen', 'Wasser', 'Fisch'),
    _SimpleSeed('kriechen', 'Tier', 'Wurm'), _SimpleSeed('pflanzen', 'Natur', 'Blume'), _SimpleSeed('gießen', 'Natur', 'Wasser'),
    _SimpleSeed('wachsen', 'Natur', 'Baum'), _SimpleSeed('sammeln', 'Hobby', 'Stein'), _SimpleSeed('wandern', 'Natur', 'Berg'),
    _SimpleSeed('turnen', 'Sport', 'Matte'), _SimpleSeed('klettern', 'Sport', 'Baum'), _SimpleSeed('messen', 'Mathe', 'Lineal'),
    _SimpleSeed('zählen', 'Mathe', 'Zahl'), _SimpleSeed('wiegen', 'Mathe', 'Waage'),
  ];

  static const List<_SimpleSeed> _adjectiveSeeds = <_SimpleSeed>[
    _SimpleSeed('groß', 'Größe', 'Riese'), _SimpleSeed('klein', 'Größe', 'Maus'), _SimpleSeed('lang', 'Größe', 'Schlange'),
    _SimpleSeed('kurz', 'Größe', 'Stift'), _SimpleSeed('rund', 'Form', 'Ball'), _SimpleSeed('eckig', 'Form', 'Würfel'),
    _SimpleSeed('warm', 'Wetter', 'Sonne'), _SimpleSeed('kalt', 'Wetter', 'Schnee'), _SimpleSeed('hell', 'Licht', 'Lampe'),
    _SimpleSeed('dunkel', 'Licht', 'Nacht'), _SimpleSeed('laut', 'Hören', 'Trommel'), _SimpleSeed('leise', 'Hören', 'Flüstern'),
    _SimpleSeed('schnell', 'Bewegung', 'Hase'), _SimpleSeed('langsam', 'Bewegung', 'Schnecke'), _SimpleSeed('weich', 'Fühlen', 'Kissen'),
    _SimpleSeed('hart', 'Fühlen', 'Stein'), _SimpleSeed('glatt', 'Fühlen', 'Eis'), _SimpleSeed('rau', 'Fühlen', 'Rinde'),
    _SimpleSeed('süß', 'Geschmack', 'Honig'), _SimpleSeed('sauer', 'Geschmack', 'Zitrone'), _SimpleSeed('salzig', 'Geschmack', 'Suppe'),
    _SimpleSeed('fröhlich', 'Gefühl', 'Freude'), _SimpleSeed('traurig', 'Gefühl', 'Träne'), _SimpleSeed('mutig', 'Gefühl', 'Löwe'),
    _SimpleSeed('ängstlich', 'Gefühl', 'Angst'), _SimpleSeed('freundlich', 'Sozial', 'Freund'), _SimpleSeed('fleißig', 'Schule', 'Heft'),
    _SimpleSeed('sauber', 'Zuhause', 'Seife'), _SimpleSeed('schmutzig', 'Zuhause', 'Matsch'), _SimpleSeed('bunt', 'Farbe', 'Regenbogen'),
  ];

  static const List<_NounSeed> _nounSeeds = <_NounSeed>[
    _NounSeed('Hund', 'der', 'Tiere', 'Haustier', 'bellen', 1), _NounSeed('Katze', 'die', 'Tiere', 'Haustier', 'miauen', 1),
    _NounSeed('Maus', 'die', 'Tiere', 'Wald', 'flitzen', 1), _NounSeed('Hase', 'der', 'Tiere', 'Wiese', 'hüpfen', 1),
    _NounSeed('Fuchs', 'der', 'Tiere', 'Wald', 'schleichen', 1), _NounSeed('Igel', 'der', 'Tiere', 'Wald', 'rollen', 1),
    _NounSeed('Kuh', 'die', 'Tiere', 'Bauernhof', 'muhen', 1), _NounSeed('Pferd', 'das', 'Tiere', 'Bauernhof', 'reiten', 1),
    _NounSeed('Schwein', 'das', 'Tiere', 'Bauernhof', 'grunzen', 1), _NounSeed('Schaf', 'das', 'Tiere', 'Bauernhof', 'blöken', 1),
    _NounSeed('Ente', 'die', 'Tiere', 'Wasser', 'watscheln', 1), _NounSeed('Vogel', 'der', 'Tiere', 'Luft', 'fliegen', 1),
    _NounSeed('Biene', 'die', 'Insekten', 'Wiese', 'summen', 1), _NounSeed('Ameise', 'die', 'Insekten', 'Wald', 'krabbeln', 1),
    _NounSeed('Baum', 'der', 'Pflanzen', 'Wald', 'wachsen', 1), _NounSeed('Blume', 'die', 'Pflanzen', 'Garten', 'blühen', 1),
    _NounSeed('Rose', 'die', 'Pflanzen', 'Garten', 'duften', 1), _NounSeed('Gras', 'das', 'Pflanzen', 'Wiese', 'wachsen', 1),
    _NounSeed('Apfel', 'der', 'Obst', 'rot', 'essen', 1), _NounSeed('Banane', 'die', 'Obst', 'gelb', 'essen', 1),
    _NounSeed('Marille', 'die', 'Obst', 'österreichisch', 'essen', 1), _NounSeed('Birne', 'die', 'Obst', 'grün', 'essen', 1),
    _NounSeed('Karotte', 'die', 'Gemüse', 'orange', 'essen', 1), _NounSeed('Erdäpfel', 'die', 'Gemüse', 'österreichisch', 'kochen', 1),
    _NounSeed('Mama', 'die', 'Familie', 'Person', 'helfen', 1), _NounSeed('Papa', 'der', 'Familie', 'Person', 'helfen', 1),
    _NounSeed('Oma', 'die', 'Familie', 'Person', 'erzählen', 1), _NounSeed('Opa', 'der', 'Familie', 'Person', 'erzählen', 1),
    _NounSeed('Kind', 'das', 'Familie', 'Person', 'spielen', 1), _NounSeed('Freund', 'der', 'Familie', 'Gemeinschaft', 'teilen', 1),
    _NounSeed('Sonne', 'die', 'Natur', 'Wetter', 'scheinen', 1), _NounSeed('Mond', 'der', 'Natur', 'Nacht', 'leuchten', 1),
    _NounSeed('Wolke', 'die', 'Natur', 'Wetter', 'ziehen', 1), _NounSeed('Regen', 'der', 'Natur', 'Wetter', 'fallen', 1),
    _NounSeed('Schnee', 'der', 'Natur', 'Winter', 'fallen', 1), _NounSeed('Wind', 'der', 'Natur', 'Wetter', 'blasen', 1),
    _NounSeed('Berg', 'der', 'Natur', 'Landschaft', 'wandern', 1), _NounSeed('Wasser', 'das', 'Natur', 'Wasser', 'trinken', 1),
    _NounSeed('Schule', 'die', 'Schule', 'Gebäude', 'lernen', 1), _NounSeed('Tafel', 'die', 'Schule', 'Klasse', 'schreiben', 1),
    _NounSeed('Stift', 'der', 'Schule', 'Material', 'schreiben', 1), _NounSeed('Heft', 'das', 'Schule', 'Material', 'schreiben', 1),
    _NounSeed('Buch', 'das', 'Schule', 'Material', 'lesen', 1), _NounSeed('Tasche', 'die', 'Schule', 'Material', 'tragen', 1),
    _NounSeed('Haus', 'das', 'Zuhause', 'Gebäude', 'wohnen', 1), _NounSeed('Zimmer', 'das', 'Zuhause', 'Raum', 'spielen', 1),
    _NounSeed('Tisch', 'der', 'Zuhause', 'Möbel', 'essen', 1), _NounSeed('Sessel', 'der', 'Zuhause', 'Möbel', 'sitzen', 1),
    _NounSeed('Bett', 'das', 'Zuhause', 'Möbel', 'schlafen', 1), _NounSeed('Lampe', 'die', 'Zuhause', 'Möbel', 'leuchten', 1),
    _NounSeed('Jacke', 'die', 'Kleidung', 'warm', 'anziehen', 1), _NounSeed('Hose', 'die', 'Kleidung', 'Bein', 'anziehen', 1),
    _NounSeed('Schuh', 'der', 'Kleidung', 'Fuß', 'anziehen', 1), _NounSeed('Mütze', 'die', 'Kleidung', 'Kopf', 'anziehen', 1),
    _NounSeed('Auto', 'das', 'Verkehr', 'Fahrzeug', 'fahren', 1), _NounSeed('Rad', 'das', 'Verkehr', 'Fahrzeug', 'fahren', 1),
    _NounSeed('Bus', 'der', 'Verkehr', 'Fahrzeug', 'fahren', 1), _NounSeed('Zug', 'der', 'Verkehr', 'Fahrzeug', 'fahren', 1),
    _NounSeed('Semmel', 'die', 'Essen', 'österreichisch', 'essen', 1), _NounSeed('Sackerl', 'das', 'Einkaufen', 'österreichisch', 'tragen', 1), _NounSeed('Jause', 'die', 'Essen', 'österreichisch', 'essen', 1),
    _NounSeed('Topfen', 'der', 'Essen', 'österreichisch', 'essen', 1), _NounSeed('Schlagobers', 'das', 'Essen', 'österreichisch', 'kosten', 1),
    _NounSeed('Hand', 'die', 'Körper', 'Körperteil', 'greifen', 1), _NounSeed('Fuß', 'der', 'Körper', 'Körperteil', 'gehen', 1),
    _NounSeed('Auge', 'das', 'Körper', 'Sinn', 'sehen', 1), _NounSeed('Ohr', 'das', 'Körper', 'Sinn', 'hören', 1),
    _NounSeed('Freude', 'die', 'Gefühle', 'gut', 'lachen', 1), _NounSeed('Angst', 'die', 'Gefühle', 'vorsichtig', 'zittern', 1),
    _NounSeed('Ball', 'der', 'Sport', 'Spiel', 'werfen', 1), _NounSeed('Puppe', 'die', 'Spielzeug', 'Spiel', 'spielen', 1),
    _NounSeed('Würfel', 'der', 'Spielzeug', 'Spiel', 'würfeln', 1), _NounSeed('Lego', 'das', 'Spielzeug', 'Bauen', 'bauen', 1),
    _NounSeed('Elefant', 'der', 'Tiere', 'Zoo', 'tröten', 2), _NounSeed('Giraffe', 'die', 'Tiere', 'Zoo', 'fressen', 2),
    _NounSeed('Löwe', 'der', 'Tiere', 'Zoo', 'brüllen', 2), _NounSeed('Delfin', 'der', 'Tiere', 'Meer', 'schwimmen', 2),
    _NounSeed('Muschel', 'die', 'Natur', 'Meer', 'finden', 2), _NounSeed('Ahorn', 'der', 'Pflanzen', 'Baum', 'wachsen', 2),
    _NounSeed('Tulpe', 'die', 'Pflanzen', 'Blume', 'blühen', 2), _NounSeed('Gurke', 'die', 'Gemüse', 'grün', 'essen', 2),
    _NounSeed('Bäcker', 'der', 'Berufe', 'Essen', 'backen', 2), _NounSeed('Ärztin', 'die', 'Berufe', 'Gesundheit', 'helfen', 2),
    _NounSeed('Hammer', 'der', 'Werkzeuge', 'Werkzeug', 'hämmern', 2), _NounSeed('Säge', 'die', 'Werkzeuge', 'Werkzeug', 'sägen', 2),
    _NounSeed('Ampel', 'die', 'Verkehr', 'Straße', 'leuchten', 2), _NounSeed('Straße', 'die', 'Verkehr', 'Weg', 'fahren', 2),
    _NounSeed('Schmetterling', 'der', 'Insekten', 'Wiese', 'flattern', 3), _NounSeed('Schildkröte', 'die', 'Tiere', 'Zoo', 'kriechen', 3),
    _NounSeed('Bibliothek', 'die', 'Schule', 'Raum', 'lesen', 3), _NounSeed('Regenbogen', 'der', 'Natur', 'Wetter', 'leuchten', 3),
    _NounSeed('Donau', 'die', 'Österreich', 'Fluss', 'fließen', 3), _NounSeed('Wien', 'das', 'Österreich', 'Stadt', 'besuchen', 3),
    _NounSeed('Niederösterreich', 'das', 'Österreich', 'Bundesland', 'wohnen', 3), _NounSeed('Gänserndorf', 'das', 'Österreich', 'Ort', 'wohnen', 3),
    _NounSeed('Großglockner', 'der', 'Österreich', 'Berg', 'wandern', 4), _NounSeed('Bundesland', 'das', 'Österreich', 'Geografie', 'kennen', 4),
    _NounSeed('Kontinent', 'der', 'Geografie', 'Erde', 'finden', 4), _NounSeed('Ozean', 'der', 'Geografie', 'Meer', 'erkennen', 4),
    _NounSeed('Stromkreis', 'der', 'Technik', 'Strom', 'schließen', 4), _NounSeed('Ökosystem', 'das', 'Natur', 'Lebensraum', 'schützen', 4),
  ];
}

class WordEntry {
  const WordEntry({
    required this.word,
    required this.wordType,
    required this.article,
    required this.syllables,
    required this.category,
    required this.grade,
    required this.semanticGroup,
    required this.family,
  });

  final String word;
  final WordType wordType;
  final String article;
  final List<String> syllables;
  final String category;
  final int grade;
  final String semanticGroup;
  final String family;
}

enum WordType { noun, verb, adjective }

class _NounSeed {
  const _NounSeed(this.word, this.article, this.category, this.group, this.family, this.minGrade);
  final String word;
  final String article;
  final String category;
  final String group;
  final String family;
  final int minGrade;
}

class _SimpleSeed {
  const _SimpleSeed(this.word, this.group, this.family);
  final String word;
  final String group;
  final String family;
}
