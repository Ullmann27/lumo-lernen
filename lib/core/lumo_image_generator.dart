// ════════════════════════════════════════════════════════════════════════
// LUMO IMAGE GENERATOR — Kindersicher mit positiver Allowlist
// ════════════════════════════════════════════════════════════════════════
// Prinzip: Nur was in der Allowlist steht wird gemalt. Tiere, Pflanzen,
// Essen, Spielzeug, Fahrzeuge, Maerchenfiguren, Lernthemen, Natur.
// Alles andere -> freundlicher Hinweis was Lumo malen kann.
// ════════════════════════════════════════════════════════════════════════

class LumoImageGenerator {
  LumoImageGenerator._();
  static final LumoImageGenerator instance = LumoImageGenerator._();

  // ── ALLOWLIST: Themen die gemalt werden duerfen ───────────────────
  static const Set<String> _allowedTopics = {
    // Tiere - Haustiere
    'hund', 'katze', 'haeschen', 'haschen', 'hase', 'hamster',
    'meerschweinchen', 'fisch', 'goldfisch', 'vogel', 'kanarienvogel',
    'wellensittich', 'papagei', 'schildkroete', 'schildkröte',
    // Tiere - Bauernhof
    'kuh', 'pferd', 'fohlen', 'schaf', 'lamm', 'ziege', 'schwein',
    'ferkel', 'huhn', 'kueken', 'küken', 'ente', 'gans', 'esel',
    // Tiere - Wald
    'reh', 'hirsch', 'fuchs', 'eichhoernchen', 'eichhörnchen', 'igel',
    'wildschwein', 'baer', 'bär', 'wolf', 'eule', 'kaninchen', 'maus',
    'fledermaus', 'biber', 'frosch',
    // Tiere - Zoo + exotisch
    'loewe', 'löwe', 'tiger', 'elefant', 'giraffe', 'affe', 'zebra',
    'nilpferd', 'krokodil', 'schlange', 'kamel', 'pinguin', 'eisbaer',
    'eisbär', 'panda', 'koala', 'kaenguruh', 'känguru', 'lama', 'pfau',
    // Tiere - Meer
    'delphin', 'delfin', 'wal', 'haifisch', 'tintenfisch', 'krabbe',
    'seestern', 'seepferdchen', 'krebs',
    // Tiere - Insekten
    'schmetterling', 'biene', 'marienkaefer', 'marienkäfer',
    'libelle', 'spinne', 'ameise', 'raupe',
    // Tiere - Dino + Fantasie
    'dinosaurier', 'dino', 'einhorn', 'drache', 'pegasus',
    // Pflanzen
    'baum', 'blume', 'rose', 'tulpe', 'sonnenblume', 'gaensebluemchen',
    'gänseblümchen', 'loewenzahn', 'löwenzahn', 'kaktus', 'pilz',
    'gras', 'klee', 'farn', 'tanne', 'eiche', 'birke',
    // Obst + Gemuese
    'apfel', 'birne', 'banane', 'orange', 'mandarine', 'zitrone',
    'kirsche', 'erdbeere', 'himbeere', 'heidelbeere', 'wassermelone',
    'ananas', 'traube', 'pflaume', 'kiwi', 'karotte', 'tomate',
    'gurke', 'paprika', 'mais', 'kartoffel', 'salat', 'broccoli',
    // Essen
    'pizza', 'spaghetti', 'nudeln', 'pasta', 'kuchen', 'torte',
    'muffin', 'kekse', 'plaetzchen', 'brot', 'broetchen', 'brötchen',
    'eis', 'eiscreme', 'schokolade', 'pommes', 'burger', 'sandwich',
    'milch', 'saft', 'kakao', 'tee', 'wasser', 'limo', 'limonade',
    // Spielzeug + Alltag
    'ball', 'fussball', 'fußball', 'basketball', 'puppe', 'teddy',
    'teddybaer', 'teddybär', 'baerchen', 'bärchen', 'plueschtier',
    'plüschtier', 'roboter', 'bauklotz', 'lego', 'puzzle', 'wuerfel',
    'würfel', 'luftballon', 'drachen', 'kreisel', 'jojo', 'springseil',
    // Fahrzeuge
    'auto', 'sportwagen', 'lastwagen', 'lkw', 'traktor', 'bus',
    'feuerwehr', 'krankenwagen', 'polizeiauto', 'rakete', 'ufo',
    'flugzeug', 'helikopter', 'hubschrauber', 'heissluftballon',
    'heißluftballon', 'schiff', 'segelboot', 'u-boot', 'fahrrad',
    'roller', 'skateboard', 'einrad', 'zug', 'eisenbahn', 'lokomotive',
    // Natur + Himmel
    'wolke', 'sonne', 'mond', 'stern', 'regenbogen', 'regen',
    'schnee', 'schneeflocke', 'schneemann', 'wind', 'feder',
    'blatt', 'berg', 'gebirge', 'fluss', 'meer', 'see', 'bach',
    'wald', 'wiese', 'feld', 'huegel', 'hügel', 'insel', 'strand',
    'sandburg', 'wasserfall', 'hoehle', 'höhle',
    // Maerchenfiguren
    'pirat', 'piratenschiff', 'ritter', 'prinzessin', 'prinz',
    'koenig', 'könig', 'koenigin', 'königin', 'fee', 'elf', 'gnom',
    'zauberer', 'kobold', 'meerjungfrau', 'engel',
    // Berufe
    'feuerwehrmann', 'polizist', 'arzt', 'baecker', 'bäcker',
    'koch', 'lehrer', 'gaertner', 'gärtner', 'bauer', 'astronaut',
    'taucher', 'pilot', 'kapitaen', 'kapitän',
    // Familie + Alltag
    'mama', 'papa', 'oma', 'opa', 'baby', 'kind', 'familie',
    'haus', 'zimmer', 'tisch', 'stuhl', 'sofa', 'bett', 'lampe',
    'fenster', 'tuer', 'tür', 'garten', 'spielplatz', 'schaukel',
    'rutsche', 'sandkasten', 'klettergeruest', 'klettergerüst',
    // Lernthemen
    'buchstabe', 'zahl', 'farbe', 'form', 'kreis', 'quadrat',
    'dreieck', 'rechteck', 'herz', 'uhr', 'kalender',
    'buch', 'stift', 'schultasche', 'tafel',
    // Sport + Bewegung
    'klettern', 'rennen', 'huepfen', 'hüpfen', 'springen',
    'schwimmen', 'tanzen', 'reiten', 'turnen',
    // Musik
    'gitarre', 'klavier', 'trommel', 'fluete', 'flöte', 'note',
    // Kleidung
    'muetze', 'mütze', 'schal', 'jacke', 'schuhe', 'stiefel',
    'kleid', 'hut', 'krone',
    // Jahreszeiten
    'fruehling', 'frühling', 'sommer', 'herbst', 'winter',
    'weihnachten', 'ostern', 'geburtstag', 'fasching', 'karneval',
  };

  // ── COMIC-STYLE WRAPPER ───────────────────────────────────────────
  // Wird VOR die Kind-Anfrage gestellt - sorgt dass Pollinations einen
  // kindgerechten Comic-Stil erzeugt.
  static const String _styleWrapper =
      'cute kid-friendly cartoon for young children, soft pastel colors, '
      'friendly smile, simple shapes, illustration style, ';

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
          'Fahrzeuge, Maerchenfiguren oder die Natur. Was magst du sehen?',
    );
  }

  /// Baut die URL zum Bildgenerator wenn das Thema in der Allowlist ist.
  /// Returns null wenn nicht erlaubt.
  String? buildSafeImageUrl(String childPrompt,
      {int width = 512, int height = 512}) {
    final result = check(childPrompt);
    if (!result.allowed) return null;
    final fullPrompt = _styleWrapper + childPrompt.trim();
    final encoded = Uri.encodeComponent(fullPrompt);
    return 'https://image.pollinations.ai/prompt/$encoded'
        '?width=$width&height=$height&nologo=true&safe=true';
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
  /// bekanntes Thema nennt (z.B. 'Wie macht eine Kuh?' -> Bild von Kuh).
  /// Returns null wenn kein Allowlist-Wort gefunden wurde.
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
