/// Reading-Display-Hilfen.
///
/// Saetze und Woerter, die das Kind sieht, sollen kindgerecht dargestellt
/// werden:
///   - keine stoerenden Satzzeichen am Ende (.,!?)
///   - echte deutsche Umlaute (ue/ae/oe/ss -> ü/ä/ö/ß)
///   - keine doppelten Leerzeichen
///
/// Wichtig: Diese Funktionen sind ausschliesslich fuer die SICHTBARE
/// Anzeige. Die interne Tokenisierung/Vergleichslogik darf weiter
/// normalisieren (ue/ae/oe/ss). Niemals dieses Modul fuer Vergleich
/// nutzen.
class ReadingDisplay {
  const ReadingDisplay._();

  static const _umlautMap = <String, String>{
    'ae': 'ä',
    'oe': 'ö',
    'ue': 'ü',
    'Ae': 'Ä',
    'Oe': 'Ö',
    'Ue': 'Ü',
    'AE': 'Ä',
    'OE': 'Ö',
    'UE': 'Ü',
    'ss': 'ß',
  };

  // Spezialfall: 'ss' wird nur in bestimmten Kontexten zu 'ß'.
  // Wir ersetzen nicht alle 'ss', weil 'Wasser' und 'lassen' korrekt sind.
  // Wir nutzen daher eine Whitelist von Stems, in denen 'ss' -> 'ß' soll.
  static const _ssToSharpS = <String, String>{
    'fliesst': 'fließt',
    'fliessen': 'fließen',
    'gross': 'groß',
    'grosse': 'große',
    'grosser': 'großer',
    'grosses': 'großes',
    'grossen': 'großen',
    'grossem': 'großem',
    'heisst': 'heißt',
    'heissen': 'heißen',
    'weiss': 'weiß',
    'weisse': 'weiße',
    'weisses': 'weißes',
    'spass': 'Spaß',
    'fuess': 'füß',
    'fuesse': 'Füße',
    'strasse': 'Straße',
    'strassen': 'Straßen',
    'liess': 'ließ',
    'liesse': 'ließe',
    'liessen': 'ließen',
    'massvoll': 'maßvoll',
    'mass': 'Maß',
    'massen': 'Massen', // 'Masse' bleibt 'Masse' (Menge), aber 'Maßen' selten -> default Masse
  };

  /// Bereitet einen Anzeige-Satz fuer das Kind auf.
  ///
  /// Beispiel:
  ///   "Lumo geht ueber die Bruecke." -> "Lumo geht über die Brücke"
  ///
  /// Regeln:
  ///  - Endpunkte . ! ? am SATZENDE entfernt
  ///  - Doppelte Leerzeichen kollabiert
  ///  - Umlaute wiederhergestellt
  static String sentence(String value) {
    final umlauted = _restoreUmlauts(value);
    final cleaned = umlauted.replaceAll(RegExp(r'\s+'), ' ').trim();
    return _stripTrailingPunctuation(cleaned);
  }

  /// Bereitet ein einzelnes Anzeige-Wort fuer das Kind auf.
  ///
  /// Beispiel:
  ///   "Bluete," -> "Blüte"
  static String word(String value) {
    final umlauted = _restoreUmlauts(value);
    final cleaned = umlauted.trim();
    return _stripTrailingPunctuation(cleaned).replaceAll(
      RegExp(r'^[.,!?;:]+|[.,!?;:]+$'),
      '',
    );
  }

  /// Identitaets-erhaltend fuer die UI — kein Trim, keine Zeichen weg.
  /// Nur Umlaute werden korrigiert. Wird fuer Lumo-Sprechblasen verwendet,
  /// in denen Mehrzeiligkeit oder Satzzeichen bewusst sein koennen.
  static String spoken(String value) => _restoreUmlauts(value);

  static String _restoreUmlauts(String value) {
    var out = value;
    // Whole-word ss-special-cases zuerst (case-insensitive Wortgrenzen)
    _ssToSharpS.forEach((needle, replacement) {
      final pattern = RegExp(
        '\\b' + RegExp.escape(needle) + '\\b',
        caseSensitive: false,
      );
      out = out.replaceAllMapped(pattern, (m) {
        // Casing aus der Quelle uebernehmen
        final original = m.group(0)!;
        if (original == original.toUpperCase()) return replacement.toUpperCase();
        if (original.isNotEmpty && original[0].toUpperCase() == original[0]) {
          return replacement.isEmpty
              ? replacement
              : replacement[0].toUpperCase() + replacement.substring(1);
        }
        return replacement;
      });
    });
    // Generische ue/ae/oe-Ersetzung. KEINE 'ss'-Auto-Ersetzung mehr,
    // da diese kontextabhaengig ist (Wasser, lassen, Klasse muessen ss bleiben).
    _umlautMap.forEach((needle, replacement) {
      if (needle == 'ss') return;
      out = out.replaceAll(needle, replacement);
    });
    return out;
  }

  static String _stripTrailingPunctuation(String value) {
    return value.replaceAll(RegExp(r'[.!?]+$'), '').trimRight();
  }
}
