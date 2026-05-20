// ════════════════════════════════════════════════════════════════════════
// LUMO IMAGE GENERATOR — Kindersicherer Bildgenerator via Pollinations.ai
// ════════════════════════════════════════════════════════════════════════
// Heinz' Wunsch: 'Bildgenerator wenn Kind fragt wie schaut Pinguin aus.
// Beschraenkt auf Kinderzeichnungen, Tiere, Alltag, Comic. KEINE Krieg-,
// Gewalt-, monografische Bilder. Striktes Verbot.'
//
// Architektur:
//   1. Pollinations.ai liefert kostenlose Bilder per URL (kein API-Key).
//   2. Vor jeder Anfrage: SAFETY-CHECK.
//      - Block-Liste: 60+ Begriffe rund um Krieg/Gewalt/Sex/Horror
//      - Strict-Mode: wenn EIN Wort matcht -> blockiert
//   3. Sicherer Prompt-Wrapper: 'cute kid-friendly cartoon for children, no
//      violence, no weapons, no scary, soft colors' + Kindfrage
//   4. URL wird zurueckgegeben - Flutter rendert via Image.network() das
//      automatisch im RAM cached.
//
// KEIN Network-Code hier - nur URL-Bau + Safety. Display via Image.network.
// ════════════════════════════════════════════════════════════════════════

class LumoImageGenerator {
  LumoImageGenerator._();
  static final LumoImageGenerator instance = LumoImageGenerator._();

  // ── BLOCK-LISTE (Heinz: 'striktes Verbot') ────────────────────────
  // Alle Begriffe werden case-insensitive verglichen.
  // Bei JEDEM Match wird die Anfrage komplett blockiert.
  static const Set<String> _blockedWords = {
    // Krieg / Gewalt / Waffen
    'krieg', 'kampf', 'schlacht', 'panzer', 'bombe', 'rakete', 'granate',
    'soldat', 'militaer', 'militär', 'armee', 'general',
    'pistole', 'gewehr', 'waffe', 'messer', 'schwert', 'dolch', 'mp5',
    'gewalt', 'schlag', 'pruegel', 'prügel', 'misshandlung',
    // Tod / Verletzung
    'tot', 'tod', 'sterben', 'leiche', 'grab', 'sarg', 'friedhof',
    'blut', 'blutig', 'verletzt', 'verletzung', 'wunde', 'narbe',
    'mord', 'morden', 'killen', 'kill', 'erschiessen', 'erschießen',
    'selbstmord', 'suizid',
    // Sex / Nackt
    'sex', 'sexual', 'nackt', 'porno', 'porn', 'erotik', 'naked', 'nude',
    'busen', 'penis', 'vagina',
    // Horror / Okkult
    'satan', 'teufel', 'daemon', 'dämon', 'demon', 'hoelle', 'hölle',
    'horror', 'gruselig sehr', 'monster grausam', 'zombie blutig',
    // Drogen
    'droge', 'drogen', 'kokain', 'heroin', 'spritze', 'gift',
    // Realistisch/monografisch (Heinz' Wunsch: nur Comic)
    'realistisch', 'fotorealistisch', 'photo', 'foto echt', 'realistic',
    'photograph', 'hyperrealistic', 'monograph',
    // Politik (vermeiden fuer Kinder)
    'hitler', 'stalin', 'putin', 'trump', 'biden',
  };

  // ── PROMPT-WRAPPER (Heinz: 'nur Kinderzeichnungen, Comic') ────────
  // Wird VOR die Kind-Anfrage gestellt damit Pollinations das richtige
  // Style-Bias bekommt.
  static const String _safetyPrefix =
      'cute kid-friendly cartoon for young children, soft colors, '
      'friendly smile, simple shapes, no violence, no weapons, no scary, '
      'no realistic photo, illustration style, ';

  /// Bewertet ob ein Prompt sicher ist.
  /// Liefert (allowed, reason).
  static ImageSafetyResult checkSafety(String prompt) {
    final lower = prompt.toLowerCase();
    for (final word in _blockedWords) {
      // Word-Boundary-Check damit "tot" nicht "Totem" blockiert
      final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b');
      if (regex.hasMatch(lower)) {
        return ImageSafetyResult(
          allowed: false,
          blockedWord: word,
          reason:
              'Dieses Bild kann ich nicht zeigen. Versuch was Liebes wie ein Tier, eine Blume oder dein Lieblingsessen!',
        );
      }
    }
    if (prompt.trim().length < 2) {
      return ImageSafetyResult(
          allowed: false,
          reason: 'Sag mir was ich malen soll - zum Beispiel "Pinguin"!');
    }
    return const ImageSafetyResult(allowed: true);
  }

  /// Baut die URL zum sicheren Bildgenerator.
  /// Returns null wenn Prompt blockiert ist.
  String? buildSafeImageUrl(String childPrompt, {int width = 512, int height = 512}) {
    final check = checkSafety(childPrompt);
    if (!check.allowed) return null;
    final fullPrompt = _safetyPrefix + childPrompt.trim();
    // Pollinations.ai - kostenlos, kein API-Key, Content-Filter integriert
    final encoded = Uri.encodeComponent(fullPrompt);
    return 'https://image.pollinations.ai/prompt/$encoded'
        '?width=$width&height=$height&nologo=true&safe=true';
  }

  /// Heuristik: prueft ob die Kind-Nachricht nach einem Bild fragt.
  /// 'zeig mir', 'wie schaut', 'wie sieht aus', 'kannst du malen'...
  static bool seemsImageRequest(String text) {
    final lower = text.toLowerCase();
    const triggers = [
      'zeig mir', 'zeig mal', 'zeige mir',
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
}

/// Ergebnis einer Safety-Pruefung.
class ImageSafetyResult {
  const ImageSafetyResult({
    required this.allowed,
    this.reason,
    this.blockedWord,
  });
  final bool allowed;
  final String? reason;
  final String? blockedWord;
}
