// ════════════════════════════════════════════════════════════════════════
// LUMO IMAGE GENERATOR — Kindersicher mit positiver Allowlist
// ════════════════════════════════════════════════════════════════════════
// Prinzip:
//   1. Nur Themen aus der Allowlist werden gemalt.
//   2. Deutsche Begriffe werden zu englischen uebersetzt damit Pollinations
//      sauber rendert (vorher kam bei 'Hund' ein Kind weil 'kid-friendly'
//      Wrapper falsch interpretiert wurde).
//   3. Comic-Style-Wrapper mit prominentem Hauptmotiv.
//   4. Pollinations.ai safe=true als Zusatz-Sicherung.
// ════════════════════════════════════════════════════════════════════════

class LumoImageGenerator {
  LumoImageGenerator._();
  static final LumoImageGenerator instance = LumoImageGenerator._();

  // ── DEUTSCH -> ENGLISCH MAPPING ───────────────────────────────────
  // Wird VOR Pollinations geschickt damit das Modell den richtigen
  // Begriff versteht. 'Hund' -> 'dog' rendert sauber, 'Hund' allein
  // wird oft falsch interpretiert weil Englisch dominiert.
  static const Map<String, String> _translate = {
    // Tiere
    'hund': 'dog', 'katze': 'cat', 'hase': 'bunny', 'haeschen': 'bunny',
    'maus': 'mouse', 'fisch': 'fish', 'vogel': 'bird',
    'pferd': 'horse', 'kuh': 'cow', 'schaf': 'sheep', 'lamm': 'lamb',
    'ziege': 'goat', 'schwein': 'pig', 'huhn': 'chicken',
    'kueken': 'chick', 'küken': 'chick', 'ente': 'duck', 'gans': 'goose',
    'reh': 'deer', 'fuchs': 'fox', 'baer': 'bear', 'bär': 'bear',
    'wolf': 'wolf', 'eule': 'owl', 'frosch': 'frog',
    'loewe': 'lion', 'löwe': 'lion', 'tiger': 'tiger',
    'elefant': 'elephant', 'giraffe': 'giraffe', 'affe': 'monkey',
    'pinguin': 'penguin', 'eisbaer': 'polar bear', 'eisbär': 'polar bear',
    'panda': 'panda', 'koala': 'koala', 'krokodil': 'crocodile',
    'schlange': 'snake', 'delfin': 'dolphin', 'wal': 'whale',
    'schmetterling': 'butterfly', 'biene': 'bee',
    'marienkaefer': 'ladybug', 'marienkäfer': 'ladybug',
    'eichhoernchen': 'squirrel', 'eichhörnchen': 'squirrel',
    'igel': 'hedgehog', 'dinosaurier': 'dinosaur', 'dino': 'dinosaur',
    'einhorn': 'unicorn', 'drache': 'friendly dragon',
    // Erweiterung Mai 2026 - fehlende Safari-Tiere
    // Vorher rendert Pollinations ein 🎨 Palette-Fallback weil
    // 'zebra', 'nashorn', etc. NICHT in der Allowlist waren.
    'zebra': 'zebra', 'nashorn': 'rhinoceros', 'flusspferd': 'hippopotamus',
    'nilpferd': 'hippopotamus',
    'kaenguru': 'kangaroo', 'känguru': 'kangaroo',
    'faultier': 'sloth', 'hai': 'shark', 'robbe': 'seal',
    'rentier': 'reindeer', 'schildkroete': 'turtle', 'schildkröte': 'turtle',
    'pinguine': 'penguin', 'voegel': 'bird', 'vögel': 'bird',
    'fledermaus': 'bat', 'spinne': 'spider', 'ameise': 'ant',
    'libelle': 'dragonfly', 'wespe': 'wasp', 'hummel': 'bumblebee',
    'storch': 'stork', 'specht': 'woodpecker', 'rabe': 'raven',
    'taube': 'pigeon', 'papagei': 'parrot', 'flamingo': 'flamingo',
    'pfau': 'peacock', 'adler': 'eagle', 'falke': 'falcon',
    'krebs': 'crab', 'oktopus': 'octopus', 'seestern': 'starfish',
    'qualle': 'jellyfish', 'rochen': 'stingray', 'forelle': 'trout',
    'lachs': 'salmon', 'hering': 'herring', 'thunfisch': 'tuna',
    'echse': 'lizard', 'gecko': 'gecko', 'chamaeleon': 'chameleon',
    'chamäleon': 'chameleon',
    // Pflanzen
    'baum': 'tree', 'blume': 'flower', 'rose': 'rose', 'tulpe': 'tulip',
    'sonnenblume': 'sunflower', 'kaktus': 'cactus', 'pilz': 'mushroom',
    'tanne': 'pine tree', 'eiche': 'oak tree',
    // Obst + Gemuese
    'apfel': 'apple', 'birne': 'pear', 'banane': 'banana',
    'orange': 'orange', 'kirsche': 'cherry', 'erdbeere': 'strawberry',
    'wassermelone': 'watermelon', 'ananas': 'pineapple', 'traube': 'grapes',
    'karotte': 'carrot', 'tomate': 'tomato', 'gurke': 'cucumber',
    'kartoffel': 'potato',
    // Essen
    'pizza': 'pizza', 'spaghetti': 'spaghetti', 'kuchen': 'cake',
    'eis': 'ice cream', 'eiscreme': 'ice cream', 'brot': 'bread',
    'kekse': 'cookies', 'schokolade': 'chocolate', 'pommes': 'french fries',
    'milch': 'milk glass', 'saft': 'juice glass',
    // Spielzeug
    'ball': 'ball', 'puppe': 'doll', 'teddy': 'teddy bear',
    'teddybaer': 'teddy bear', 'teddybär': 'teddy bear',
    'roboter': 'cute robot', 'luftballon': 'balloon',
    // Fahrzeuge
    'auto': 'car', 'lastwagen': 'truck', 'lkw': 'truck',
    'traktor': 'tractor', 'bus': 'school bus',
    'feuerwehr': 'fire truck', 'krankenwagen': 'ambulance',
    'polizeiauto': 'police car', 'rakete': 'rocket',
    'flugzeug': 'airplane', 'helikopter': 'helicopter',
    'hubschrauber': 'helicopter', 'schiff': 'ship',
    'segelboot': 'sailboat', 'fahrrad': 'bicycle', 'zug': 'train',
    'eisenbahn': 'train', 'lokomotive': 'locomotive',
    // Natur + Himmel
    'wolke': 'cloud', 'sonne': 'sun', 'mond': 'moon', 'stern': 'star',
    'regenbogen': 'rainbow', 'regen': 'rain', 'schnee': 'snowflake',
    'schneemann': 'snowman', 'blatt': 'leaf', 'berg': 'mountain',
    'meer': 'ocean', 'see': 'lake', 'wald': 'forest', 'wiese': 'meadow',
    'feld': 'field', 'insel': 'island', 'strand': 'beach',
    'sandburg': 'sandcastle', 'wasserfall': 'waterfall',
    // Wetter
    'wetter': 'sunny weather scene', 'gewitter': 'thunderstorm clouds',
    'blitz': 'lightning bolt', 'donner': 'storm clouds',
    'nebel': 'foggy landscape', 'sturm': 'stormy weather',
    'sonnig': 'sunny day', 'wolkig': 'cloudy sky',
    // Koerper (Heinz-Wunsch: Koerper-Topic mit Bildern)
    'koerper': 'cute child showing body', 'körper': 'cute child showing body',
    'kopf': 'cartoon head', 'arm': 'cartoon arm',
    'bein': 'cartoon leg', 'bauch': 'cartoon belly',
    'fuss': 'cartoon foot', 'fuß': 'cartoon foot',
    'hand': 'cartoon hand', 'finger': 'cartoon hand with five fingers',
    'auge': 'cartoon eyes', 'augen': 'cartoon eyes',
    'ohr': 'cartoon ears', 'ohren': 'cartoon ears',
    'nase': 'cartoon nose', 'mund': 'cartoon smile',
    'zahn': 'cartoon tooth', 'zaehne': 'cartoon teeth',
    'zähne': 'cartoon teeth', 'herz': 'cute heart shape',
    'haare': 'cartoon hair', 'haar': 'cartoon hair',
    // Maerchenfiguren
    'pirat': 'cute pirate', 'piratenschiff': 'pirate ship',
    'ritter': 'cute knight', 'prinzessin': 'cute princess',
    'prinz': 'cute prince', 'koenig': 'cute king', 'könig': 'cute king',
    'koenigin': 'cute queen', 'königin': 'cute queen',
    'fee': 'cute fairy', 'meerjungfrau': 'cute mermaid',
    'engel': 'cute angel',
    // Berufe
    'feuerwehrmann': 'cute firefighter', 'polizist': 'cute policeman',
    'arzt': 'cute doctor', 'baecker': 'cute baker', 'bäcker': 'cute baker',
    'koch': 'cute chef', 'astronaut': 'cute astronaut',
    'pilot': 'cute pilot',
    // Familie + Alltag
    'mama': 'cute happy mom', 'papa': 'cute happy dad',
    'oma': 'cute happy grandmother', 'opa': 'cute happy grandfather',
    'baby': 'cute baby', 'kind': 'cute happy child',
    'haus': 'cute house', 'garten': 'cute garden',
    'spielplatz': 'cute playground',
    // Geometrie + Lernthemen
    'buchstabe': 'large letter on background', 'zahl': 'large number',
    'farbe': 'rainbow colors palette',
    'kreis': 'circle shape', 'quadrat': 'square shape',
    'dreieck': 'triangle shape', 'uhr': 'cute analog clock',
    'buch': 'open book', 'schultasche': 'school backpack',
    // Verkehr (Klasse 2)
    'ampel': 'traffic light', 'zebrastreifen': 'zebra crossing',
    'strasse': 'street with cars', 'straße': 'street with cars',
    'kreuzung': 'street intersection',
    // Jahreszeiten + Feste
    'fruehling': 'spring meadow', 'frühling': 'spring meadow',
    'sommer': 'sunny summer beach', 'herbst': 'autumn forest',
    'winter': 'snowy winter scene', 'weihnachten': 'christmas tree',
    'ostern': 'easter eggs', 'geburtstag': 'birthday cake',
    // Geografie / Klasse 3+4 Sachkunde
    'europa': 'map of Europe', 'oesterreich': 'map of Austria',
    'österreich': 'map of Austria', 'deutschland': 'map of Germany',
    'italien': 'map of Italy', 'frankreich': 'map of France',
    'wien': 'Vienna city skyline', 'berlin': 'Berlin skyline',
    'rom': 'Rome with Colosseum', 'paris': 'Paris Eiffel Tower',
    'london': 'London Big Ben', 'madrid': 'Madrid skyline',
    'alpen': 'Alps mountains', 'salzburg': 'Salzburg city',
    'graz': 'Graz city', 'donau': 'Danube river',
    'bundesland': 'map region',
    // Sport
    'klettern': 'kid climbing', 'rennen': 'kid running',
    'schwimmen': 'kid swimming', 'tanzen': 'kid dancing',
    // Musik
    'gitarre': 'guitar', 'klavier': 'piano',
    'trommel': 'drum', 'fluete': 'flute', 'flöte': 'flute',
  };

  // ── ALLOWLIST = KEYS DES TRANSLATE-MAPS ───────────────────────────
  // Wenn ein Begriff im Map ist, ist er erlaubt. Konsolidiert beide
  // Datenstrukturen zu einer einzigen Quelle.
  static Set<String> get _allowedTopics => _translate.keys.toSet();

  // ── COMIC-STYLE WRAPPER ───────────────────────────────────────────
  // Wichtige Aenderung: das Motiv kommt ZUERST, dann der Style-Hinweis.
  // Sonst dominiert 'kid-friendly child' das Bild.
  static String _buildPrompt(String englishTopic) {
    return '$englishTopic, cute kid-friendly cartoon style, '
        'soft pastel colors, simple shapes, illustration for children';
  }

  /// Prueft ob ein Prompt mindestens EIN erlaubtes Thema enthaelt.
  static ImageRequestResult check(String prompt) {
    final trimmed = prompt.trim();
    if (trimmed.length < 2) {
      return ImageRequestResult(
        allowed: false,
        hint: 'Sag mir was ich malen soll - zum Beispiel ein Tier oder eine Blume!',
      );
    }
    final lower = trimmed.toLowerCase();
    for (final topic in _allowedTopics) {
      final regex = RegExp(r'\b' + RegExp.escape(topic) + r'\b');
      if (regex.hasMatch(lower)) {
        return const ImageRequestResult(allowed: true);
      }
    }
    return const ImageRequestResult(
      allowed: false,
      hint: 'Ich male am liebsten Tiere, Pflanzen, Essen, Spielzeug, '
          'Fahrzeuge, Wetter, Maerchenfiguren oder die Natur. '
          'Was magst du sehen?',
    );
  }

  /// Baut die URL zum Bildgenerator. Translatet deutsche Begriffe zu
  /// englischen damit Pollinations das Motiv sauber rendert.
  ///
  /// WICHTIG: Bei Prompts mit Farb-Modifikator (z.B. "red Apfel",
  /// "orange Auto") wurde die Farbinformation frueher weggeworfen,
  /// weil nur das Haupt-Motiv ueber `_translate` gemappt wurde. Heinz
  /// sah dann im Farben-Quiz 4 visuell identische Bilder (alle in der
  /// Pollinations-Default-Farbe), egal welche Farbe gefragt war.
  ///
  /// Fix: Bekannte Farb-Praefixe werden separat extrahiert und VOR das
  /// uebersetzte Motiv geschrieben. Beispiel: "orange Apfel" -> Color
  /// "orange-colored", Topic "apple" -> Prompt "orange-colored apple,
  /// cute kid-friendly cartoon..." -> Pollinations rendert einen
  /// orangefarbenen Apfel statt einer Orange-Frucht oder roten Apfel.
  String? buildSafeImageUrl(String childPrompt,
      {int width = 512, int height = 512}) {
    final result = check(childPrompt);
    if (!result.allowed) return null;

    final lower = childPrompt.toLowerCase().trim();

    // Farb-Modifikator extrahieren. "orange-colored" statt "orange",
    // damit Pollinations nicht die Orange-Frucht ausspielt wenn das
    // Motiv ein Apfel oder Auto sein soll.
    const colorModifiers = <String, String>{
      'red': 'red-colored',
      'rot': 'red-colored',
      'blue': 'blue-colored',
      'blau': 'blue-colored',
      'yellow': 'yellow-colored',
      'gelb': 'yellow-colored',
      'green': 'green-colored',
      'gruen': 'green-colored',
      'grün': 'green-colored',
      'orange': 'orange-colored',
      'pink': 'pink-colored',
      'rosa': 'pink-colored',
      'purple': 'purple-colored',
      'lila': 'purple-colored',
      'brown': 'brown-colored',
      'braun': 'brown-colored',
      'black': 'black-colored',
      'schwarz': 'black-colored',
      'white': 'white-colored',
      'weiss': 'white-colored',
      'weiß': 'white-colored',
    };
    String? color;
    String? matchedColorKey;
    for (final entry in colorModifiers.entries) {
      if (RegExp(r'\b' + RegExp.escape(entry.key) + r'\b').hasMatch(lower)) {
        color = entry.value;
        matchedColorKey = entry.key;
        break;
      }
    }

    // Hauptmotiv extrahieren + uebersetzen. Wichtig: das Farb-Wort selbst
    // NICHT als Topic werten (sonst kollidiert 'orange' mit der Frucht
    // 'orange' im _translate-Map).
    String mainEnglish = childPrompt.trim();
    for (final topic in _allowedTopics) {
      if (matchedColorKey != null && topic == matchedColorKey) continue;
      final regex = RegExp(r'\b' + RegExp.escape(topic) + r'\b');
      if (regex.hasMatch(lower)) {
        mainEnglish = _translate[topic] ?? topic;
        break;
      }
    }

    final colored = color != null ? '$color $mainEnglish' : mainEnglish;
    final fullPrompt = _buildPrompt(colored);
    final encoded = Uri.encodeComponent(fullPrompt);
    // Seed aus dem vollen Prompt: gleiche Eingabe -> gleiches Bild, aber
    // unterschiedliche Farb-Praefixe ergeben unterschiedliche Seeds und
    // damit unterschiedliche Pollinations-Renderings.
    final seed = fullPrompt.hashCode.abs() % 100000;
    return 'https://image.pollinations.ai/prompt/$encoded'
        '?width=$width&height=$height&nologo=true&safe=true&seed=$seed';
  }

  /// Heuristik: prueft ob die Kind-Nachricht nach einem Bild fragt.
  static bool seemsImageRequest(String text) {
    final lower = text.toLowerCase();
    const triggers = [
      'zeig mir', 'zeig mal', 'zeige mir', 'zeig es mir',
      'wie schaut', 'wie sieht', 'wie aussehen', 'wie ausschauen',
      'wie sieht aus', 'wie schaut aus',
      'kannst du malen', 'kannst du zeichnen',
      'mal mir', 'male mir', 'zeichne mir',
      'bild von', 'foto von', 'bild zeigen',
      'wie das aussieht',
    ];
    for (final t in triggers) {
      if (lower.contains(t)) return true;
    }
    return false;
  }

  /// Extrahiert das erste Allowlist-Thema das im Text vorkommt.
  /// Wird genutzt um pro-aktiv ein Bild zu zeigen wenn ein Kind ein
  /// bekanntes Thema nennt.
  static String? extractMainTopic(String text) {
    final lower = text.toLowerCase();
    for (final topic in _allowedTopics) {
      final regex = RegExp(r'\b' + RegExp.escape(topic) + r'\b');
      if (regex.hasMatch(lower)) return topic;
    }
    return null;
  }
}

/// Ergebnis einer Allowlist-Pruefung.
class ImageRequestResult {
  const ImageRequestResult({required this.allowed, this.hint});
  final bool allowed;
  /// Freundlicher Hinweis fuer das Kind wenn nicht allowed.
  final String? hint;
}
