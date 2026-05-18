/// Build-sichere Vorbereitung fuer Premium-TTS.
///
/// Diese Klasse haelt die dart-define-Konfiguration und Datenschutzfilter bereit,
/// erzeugt aber noch keinen nativen Audio-Player. Dadurch bleibt der Android-Build
/// stabil. LumoVoice faellt automatisch auf flutter_tts zurueck.
class LumoPremiumVoice {
  static const String endpoint = String.fromEnvironment('LUMO_PREMIUM_TTS_ENDPOINT');
  static const String voiceId = String.fromEnvironment('LUMO_PREMIUM_TTS_VOICE_ID');
  static const String apiKey = String.fromEnvironment('LUMO_PREMIUM_TTS_API_KEY');

  static const int _maxTextLength = 240;

  bool get configured => endpoint.trim().isNotEmpty;

  Future<bool> speak(String text) async {
    // Premium-Audio ist vorbereitet, aber ohne nativen Player bewusst deaktiviert.
    // Der stabile Offline-Fallback in LumoVoice uebernimmt immer.
    sanitizeForPremiumTts(text);
    return false;
  }

  Future<void> stop() async {}

  static String sanitizeForPremiumTts(String input) {
    var text = _stripEmojiAndSymbols(input)
        .replaceAll('\n', '. ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    text = text.replaceAll(RegExp(r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b', caseSensitive: false), '');
    text = text.replaceAll(RegExp(r'\b\+?\d[\d\s/().-]{6,}\d\b'), '');
    text = text.replaceAll(RegExp(r'\b\d{4}\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\-]+\b'), '');
    text = text.replaceAll(RegExp(r'\b(Hallo|Hi|Hey|Na)\s+[A-ZÄÖÜ][A-Za-zÄÖÜäöüß\-]{1,24}[,!]?', caseSensitive: false), r'$1!');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.length > _maxTextLength) {
      text = text.substring(0, _maxTextLength).trimRight();
    }
    return text;
  }

  static String _stripEmojiAndSymbols(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (_isEmojiOrPrivateSymbol(rune)) continue;
      buffer.writeCharCode(rune);
    }
    return buffer.toString();
  }

  static bool _isEmojiOrPrivateSymbol(int rune) {
    return (rune >= 0x1F000 && rune <= 0x1FAFF) ||
        (rune >= 0x2600 && rune <= 0x27BF) ||
        (rune >= 0xFE00 && rune <= 0xFE0F);
  }
}
