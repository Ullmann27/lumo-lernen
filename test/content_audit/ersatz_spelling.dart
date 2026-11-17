// Prüfhilfe: findet Ersatzschreibungen für Umlaute und ß (ae, oe, ue, ss) in
// kindersichtbaren Texten. Fachprüfung 2026-11 (D-S4, D-S5, D-M22).

/// Wörter, in denen ae/oe/ue richtig ist.
const _allowedWords = <String>{
  'zuerst', 'duell', 'duett', 'aktuell', 'aktuelle', 'aktuellen', 'manuell',
  'eventuell', 'individuell', 'poesie', 'soeben', 'israel', 'michael',
  'raphael', 'oboe', 'statue', 'zuende', 'tuende', 'partituren', 'virtuell',
  'koexistenz', 'aerobic', 'joe', 'zoe', 'manuel', 'manuela', 'samuel',
  'emanuel', 'bellevue', 'revue', 'true', 'blue', 'tuesday', 'shoe', 'shoes',
  'does', 'goes', 'toe', 'toes', 'queue', 'glue', 'rescue', 'statuen',
  'genuesisch', 'aloe', 'kanoe', 'ruefen',
};

/// ß-Wörter, die mit ss geschrieben falsch sind (österreichische Schreibung).
final _ssForEszett = RegExp(
  r'\b(gro(ss)(e[mnrs]?|artig\w*)?|grösse\w*|strasse\w*|spass\w*|fuss\w*|'
  r'heiss\w*|weiss\w*|draussen|aussen\w*|ausser\w*|schliess\w*|fleiss\w*|'
  r'beiss\w*|reiss\w*|giess\w*|fliess\w*|geniess\w*|stoss\w*|gruss\w*|'
  r'gruess\w*|grüss\w*|suess\w*|süss\w*|schweiss\w*|bloss|kloss|'
  r'strauss\w*|liess|hiess|stiess|sass|vergass|fuesse\w*|füsse\w*|'
  r'massband|regelmaessig|regelmässig|gemaess|gemäss|mässig\w*)\b',
  caseSensitive: false,
  unicode: true,
);

/// Liefert alle verdächtigen Wörter in [text] (leer = sauber).
List<String> ersatzSpellingsIn(String text) {
  final hits = <String>[];
  for (final match
      in RegExp(r'[A-Za-zÄÖÜäöüß]+', unicode: true).allMatches(text)) {
    final word = match.group(0)!;
    final lower = word.toLowerCase();
    if (_allowedWords.contains(lower)) continue;
    final hasAeOe = lower.contains('ae') || lower.contains('oe');
    // "ue" nach a, e, ä oder q ist ein echter Zwielaut (Mauer, neue, Quelle).
    final hasUe = RegExp(r'(^|[^aeäq])ue').hasMatch(lower);
    if (hasAeOe || hasUe) hits.add(word);
  }
  for (final match in _ssForEszett.allMatches(text)) {
    hits.add(match.group(0)!);
  }
  return hits;
}
