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
    final word = RegExp(r'Schreibe\s+das\s+Wort:\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (word != null) return word.group(1)!.trim();

    final number = RegExp(r'Schreibe\s+die\s+Zahl\s+(\d{1,2})', caseSensitive: false).firstMatch(prompt);
    if (number != null) return number.group(1)!;

    final copySentence = RegExp(r'Schreibe:\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (copySentence != null) return copySentence.group(1)!.trim();

    final traceLetter = RegExp(r'(?:Buchstaben|grosses|großes)\s+([A-ZÄÖÜ])\b', caseSensitive: false).firstMatch(prompt);
    if (traceLetter != null) return traceLetter.group(1)!.toUpperCase();

    final loneNumber = RegExp(r'Zahl\s+(\d{1,2})', caseSensitive: false).firstMatch(prompt);
    if (loneNumber != null) return loneNumber.group(1)!;

    final singleLetter = RegExp(r'\b([A-ZÄÖÜ])\b').firstMatch(prompt);
    if (singleLetter != null) return singleLetter.group(1)!;

    return 'A';
  }
}
