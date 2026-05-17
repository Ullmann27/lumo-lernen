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

  static final RegExp _trailingPunctuation = RegExp(r'[.!?]+$');

  static String parse(String prompt) {
    final word = RegExp(r'Schreibe\s+das\s+Wort\s*:?\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (word != null) return _cleanWordTarget(word.group(1));

    final number = RegExp(r'Schreibe\s+die\s+Zahl\s+(\d{1,2})', caseSensitive: false).firstMatch(prompt);
    if (number != null) return number.group(1)!;

    final sentence = RegExp(r'Schreibe\s+den\s+Satz\s*:?\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (sentence != null) return _cleanSentenceTarget(sentence.group(1));

    final copyText = RegExp(r'Schreibe:\s*(.+)$', caseSensitive: false).firstMatch(prompt);
    if (copyText != null) return _cleanSentenceTarget(copyText.group(1));

    final traceLetter = RegExp(r'(?:Buchstaben?|grosses|großes)\s+([A-ZÄÖÜ])\b', caseSensitive: false).firstMatch(prompt);
    if (traceLetter != null) return traceLetter.group(1)!.toUpperCase();

    final loneNumber = RegExp(r'Zahl\s+(\d{1,2})', caseSensitive: false).firstMatch(prompt);
    if (loneNumber != null) return loneNumber.group(1)!;

    final singleLetter = RegExp(r'\b([A-ZÄÖÜ])\b').firstMatch(prompt);
    if (singleLetter != null) return singleLetter.group(1)!;

    return 'A';
  }

  static String _cleanWordTarget(String? value) {
    final cleaned = _stripWrappingQuotes(
      (value ?? '').trim().replaceAll(_trailingPunctuation, ''),
    );
    return cleaned.isEmpty ? 'A' : cleaned;
  }

  static String _cleanSentenceTarget(String? value) {
    final cleaned = _stripWrappingQuotes(value).trim();
    return cleaned.isEmpty ? 'A' : cleaned;
  }

  static String _stripWrappingQuotes(String? value) {
    return (value ?? '').trim()
        .replaceFirst(RegExp(r"""^[„"'‚]+"""), '')
        .replaceFirst(RegExp(r"""[“"'‘]+$"""), '')
        .trim();
  }
}
