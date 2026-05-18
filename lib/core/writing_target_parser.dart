/// Zentraler Parser fuer Schreib-Aufgaben-Prompts.
///
/// Liest aus dem Prompt heraus, was das Kind tatsaechlich schreiben
/// soll. Reihenfolge der Pattern ist bewusst spezifisch zu allgemein.
///
/// Verwendet von:
///   - LegacyLumoTaskAdapter (setzt parameters['symbol'])
///   - WritingTaskRenderer (Fallback wenn parameters fehlen)
class WritingTargetParser {
  const WritingTargetParser._();

  static String parse(String prompt) {
    final trimmed = prompt.trim();

    // "Schreibe das Wort: Mama" oder "Schreibe das Wort Mama"
    final word = RegExp(r'Schreibe\s+das\s+Wort[:\s]+(.+)$', caseSensitive: false).firstMatch(trimmed);
    if (word != null) return word.group(1)!.trim().replaceAll(RegExp(r'[.!?]+$'), '').trim();

    // "Schreibe die Zahl 7"
    final number = RegExp(r'Schreibe\s+die\s+Zahl\s+(\d{1,3})', caseSensitive: false).firstMatch(trimmed);
    if (number != null) return number.group(1)!;

    // "Schreibe: Lumo lernt." oder "Schreibe: Mama"
    final copySentence = RegExp(r'Schreibe:\s*(.+)$', caseSensitive: false).firstMatch(trimmed);
    if (copySentence != null) return copySentence.group(1)!.trim().replaceAll(RegExp(r'[.!?]+$'), '').trim();

    // "Schreibe langsam: Apfel" oder "Schreibe schön: Rose"
    final copyWithAdverb = RegExp(r'Schreibe\s+\w+[:\s]+([A-ZÄÖÜ][a-zäöüß]+(?:\s+[A-Za-zÄÖÜäöüß]+)*)\.?$', caseSensitive: false).firstMatch(trimmed);
    if (copyWithAdverb != null) return copyWithAdverb.group(1)!.trim();

    // "Buchstaben A" oder "großes/grosses B"
    final traceLetter = RegExp(r'(?:Buchstaben|grosses|großes)\s+([A-ZÄÖÜ])\b', caseSensitive: false).firstMatch(trimmed);
    if (traceLetter != null) return traceLetter.group(1)!.toUpperCase();

    // Bare number: "Zahl 15"
    final loneNumber = RegExp(r'Zahl\s+(\d{1,3})', caseSensitive: false).firstMatch(trimmed);
    if (loneNumber != null) return loneNumber.group(1)!;

    // Letztes Kapitalwort am Ende des Satzes, wenn es nach "Wort" oder ":" steht
    final afterColon = RegExp(r'[:\s]([A-ZÄÖÜ][a-zäöüß]{1,20}(?:\s+[A-ZÄÖÜ][a-zäöüß]+)?)\s*[.!?]?$').firstMatch(trimmed);
    if (afterColon != null) {
      final candidate = afterColon.group(1)!.trim();
      if (candidate.length > 1) return candidate;
    }

    // Einzelner Grossbuchstabe
    final singleLetter = RegExp(r'\b([A-ZÄÖÜ])\b').firstMatch(trimmed);
    if (singleLetter != null) return singleLetter.group(1)!;

    return 'A';
  }
}
