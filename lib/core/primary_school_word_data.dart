/// Pädagogisch geprüfte Wortdaten für Volksschul-Aufgaben.
///
/// Diese Datei enthält bewusst statische, lokale Daten:
/// - keine Cloud
/// - keine Zufallslogik
/// - keine Schülerdaten
///
/// Die Silben folgen dem Sprechrhythmus für die Volksschule und dienen
/// den Workbook-Visuals. Sie ersetzen unsichere heuristische Zerlegung.
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

    // Klasse 2: zwei bis drei Silben
    'Banane': <String>['Ba', 'na', 'ne'],
    'Tomate': <String>['To', 'ma', 'te'],
    'Rakete': <String>['Ra', 'ke', 'te'],
    'Kinder': <String>['Kin', 'der'],
    'Blume': <String>['Blu', 'me'],
    'Lampe': <String>['Lam', 'pe'],
    'Katze': <String>['Kat', 'ze'],
    'Tasse': <String>['Tas', 'se'],
    'Wolke': <String>['Wol', 'ke'],
    'Garten': <String>['Gar', 'ten'],
    'Fenster': <String>['Fens', 'ter'],
    'Elefant': <String>['E', 'le', 'fant'],

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
  };

  static const List<String> startSoundWordsGrade1 = <String>[
    'Sonne', 'Mama', 'Apfel', 'Ball', 'Tasse', 'Lampe', 'Hund', 'Igel',
    'Katze', 'Nase', 'Oma', 'Papa', 'Rose', 'Tisch', 'Uhr', 'Fisch',
    'Garten',
  ];

  static const List<String> endSoundWordsGrade1 = <String>[
    'Hund', 'Tisch', 'Mama', 'Sonne', 'Auto', 'Schule', 'Hut', 'Maus',
    'Buch', 'Apfel',
  ];

  static List<String>? syllablesFor(String word) => syllables[_normalizeKey(word)];

  static String? firstSoundWordForGrade(int grade) {
    if (startSoundWordsGrade1.isEmpty) return null;
    final index = grade.clamp(1, 4) % startSoundWordsGrade1.length;
    return startSoundWordsGrade1[index];
  }

  static String? endSoundWordForGrade(int grade) {
    if (endSoundWordsGrade1.isEmpty) return null;
    final index = grade.clamp(1, 4) % endSoundWordsGrade1.length;
    return endSoundWordsGrade1[index];
  }

  static String _normalizeKey(String value) {
    final cleaned = value.trim();
    for (final key in syllables.keys) {
      if (key.toLowerCase() == cleaned.toLowerCase()) return key;
    }
    return cleaned;
  }
}
