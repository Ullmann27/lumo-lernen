class LumoChildSpeechMatch {
  const LumoChildSpeechMatch({
    required this.rawText,
    required this.normalizedText,
    this.matchedChoice,
    this.confidence = 0,
    this.needsConfirmation = false,
  });

  final String rawText;
  final String normalizedText;
  final String? matchedChoice;
  final double confidence;
  final bool needsConfirmation;

  bool get hasMatch => matchedChoice != null && matchedChoice!.trim().isNotEmpty;
}

class LumoChildSpeechNormalizer {
  const LumoChildSpeechNormalizer();

  static const Map<String, String> _numberWords = <String, String>{
    'null': '0',
    'eins': '1',
    'ein': '1',
    'eine': '1',
    'einen': '1',
    'zwei': '2',
    'drei': '3',
    'vier': '4',
    'fuenf': '5',
    'funf': '5',
    'fünf': '5',
    'sechs': '6',
    'sieben': '7',
    'acht': '8',
    'neun': '9',
    'zehn': '10',
    'elf': '11',
    'zwoelf': '12',
    'zwolf': '12',
    'zwölf': '12',
    'dreizehn': '13',
    'vierzehn': '14',
    'fuenfzehn': '15',
    'fünfzehn': '15',
    'sechzehn': '16',
    'siebzehn': '17',
    'achtzehn': '18',
    'neunzehn': '19',
    'zwanzig': '20',
  };

  LumoChildSpeechMatch normalizeAnswer({
    required String spokenText,
    required List<String> choices,
  }) {
    final raw = spokenText.trim();
    final normalized = normalizeText(raw);
    if (normalized.isEmpty) {
      return LumoChildSpeechMatch(
        rawText: raw,
        normalizedText: normalized,
        confidence: 0,
        needsConfirmation: true,
      );
    }

    final cleanedChoices = choices.map((choice) => choice.trim()).where((choice) => choice.isNotEmpty).toList();
    for (final choice in cleanedChoices) {
      if (normalizeText(choice) == normalized) {
        return LumoChildSpeechMatch(
          rawText: raw,
          normalizedText: normalized,
          matchedChoice: choice,
          confidence: 1,
        );
      }
    }

    for (final choice in cleanedChoices) {
      final normalizedChoice = normalizeText(choice);
      if (_containsToken(normalized, normalizedChoice)) {
        return LumoChildSpeechMatch(
          rawText: raw,
          normalizedText: normalized,
          matchedChoice: choice,
          confidence: .86,
        );
      }
    }

    final loose = _bestLooseChoice(normalized, cleanedChoices);
    if (loose != null) {
      return LumoChildSpeechMatch(
        rawText: raw,
        normalizedText: normalized,
        matchedChoice: loose,
        confidence: .64,
        needsConfirmation: true,
      );
    }

    return LumoChildSpeechMatch(
      rawText: raw,
      normalizedText: normalized,
      confidence: .2,
      needsConfirmation: true,
    );
  }

  String normalizeText(String value) {
    final words = value
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9\s]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => _numberWords[word] ?? word)
        .toList(growable: false);

    return words.join(' ').trim();
  }

  bool _containsToken(String text, String token) {
    if (token.isEmpty) return false;
    final parts = text.split(' ');
    return parts.contains(token) || text == token;
  }

  String? _bestLooseChoice(String normalized, List<String> choices) {
    String? best;
    var bestScore = 0;
    for (final choice in choices) {
      final normalizedChoice = normalizeText(choice);
      if (normalizedChoice.length < 3) continue;
      final score = _sharedPrefixLength(normalized, normalizedChoice);
      if (score > bestScore && score >= 3) {
        bestScore = score;
        best = choice;
      }
    }
    return best;
  }

  int _sharedPrefixLength(String a, String b) {
    final max = a.length < b.length ? a.length : b.length;
    var count = 0;
    while (count < max && a.codeUnitAt(count) == b.codeUnitAt(count)) {
      count++;
    }
    return count;
  }

  /// Macht einen Aufgabentext fuer Lumo's TTS schoener und natuerlicher.
  ///
  /// Vorher: '3 + 4 = ?' wird vom TTS oft als 'drei plus vier gleich
  /// Fragezeichen' oder noch schlechter gesprochen.
  /// Nachher: 'Drei plus vier. Was kommt heraus?'
  ///
  /// Bekannte Faelle:
  ///   '3 + 4 = ?'     -> 'Drei plus vier. Was kommt heraus?'
  ///   '10 - 7 = ?'    -> 'Zehn minus sieben. Was bleibt?'
  ///   '10€'           -> 'zehn Euro'
  ///   '5 cent'        -> 'fuenf Cent'
  ///   '1/2'           -> 'ein Halb'
  ///   '07:30'         -> 'sieben Uhr dreissig'
  ///   '>'             -> 'ist groesser als'
  ///   '<'             -> 'ist kleiner als'
  ///   '='             -> 'ist gleich'
  ///   '🍎🍎🍎'         -> 'drei Aepfel'
  ///   'X = ?'         -> 'X gleich was?'
  ///
  /// Wenn nichts zu tun ist, wird der Originaltext zurueckgegeben.
  static String forSpeech(String input) {
    if (input.trim().isEmpty) return input;
    var s = input;

    // Zuerst Emoji-Folgen erkennen und in Wortform umwandeln.
    s = _replaceEmojiSequences(s);

    // Frueher Spezialfall: '7+5=?' Plus-Aufgabe, kein Leerzeichen
    s = s.replaceAllMapped(
      RegExp(r'(\d+)\s*\+\s*(\d+)\s*=\s*\?'),
      (m) => '${_speakNumber(m.group(1)!)} plus ${_speakNumber(m.group(2)!)}. Was kommt heraus?',
    );
    // Minus mit Frage
    s = s.replaceAllMapped(
      RegExp(r'(\d+)\s*-\s*(\d+)\s*=\s*\?'),
      (m) => '${_speakNumber(m.group(1)!)} minus ${_speakNumber(m.group(2)!)}. Was bleibt?',
    );
    // Mal mit Frage
    s = s.replaceAllMapped(
      RegExp(r'(\d+)\s*[\*x×·]\s*(\d+)\s*=\s*\?'),
      (m) => '${_speakNumber(m.group(1)!)} mal ${_speakNumber(m.group(2)!)}. Was kommt heraus?',
    );
    // Geteilt durch mit Frage
    s = s.replaceAllMapped(
      RegExp(r'(\d+)\s*[/:÷]\s*(\d+)\s*=\s*\?'),
      (m) => '${_speakNumber(m.group(1)!)} geteilt durch ${_speakNumber(m.group(2)!)}. Was kommt heraus?',
    );

    // Brueche (1/2, 3/4 etc.) - vor Geld weil 5/10 sonst falsch
    s = s.replaceAllMapped(RegExp(r'\b1/2\b'), (_) => 'ein Halb');
    s = s.replaceAllMapped(RegExp(r'\b1/3\b'), (_) => 'ein Drittel');
    s = s.replaceAllMapped(RegExp(r'\b2/3\b'), (_) => 'zwei Drittel');
    s = s.replaceAllMapped(RegExp(r'\b1/4\b'), (_) => 'ein Viertel');
    s = s.replaceAllMapped(RegExp(r'\b3/4\b'), (_) => 'drei Viertel');

    // Uhrzeit hh:mm
    s = s.replaceAllMapped(
      RegExp(r'\b(\d{1,2}):(\d{2})\b'),
      (m) {
        final h = int.tryParse(m.group(1)!) ?? 0;
        final mi = int.tryParse(m.group(2)!) ?? 0;
        return _speakTime(h, mi);
      },
    );

    // Geld: 10€, 1,50€
    s = s.replaceAllMapped(
      RegExp(r'(\d+)(?:[.,](\d{1,2}))?\s*€'),
      (m) {
        final euro = m.group(1)!;
        final cent = m.group(2);
        if (cent == null) return '${_speakNumber(euro)} Euro';
        return '${_speakNumber(euro)} Euro ${_speakNumber(cent)}';
      },
    );
    // Cent
    s = s.replaceAllMapped(
      RegExp(r'(\d+)\s*cent\b', caseSensitive: false),
      (m) => '${_speakNumber(m.group(1)!)} Cent',
    );

    // Vergleichszeichen
    s = s.replaceAllMapped(RegExp(r'\s*>\s*'), (_) => ' ist groesser als ');
    s = s.replaceAllMapped(RegExp(r'\s*<\s*'), (_) => ' ist kleiner als ');
    // Restliches '=' nach Aufgabentyp-Replacement
    s = s.replaceAllMapped(RegExp(r'\s*=\s*'), (_) => ' ist gleich ');

    // Mehrfache Leerzeichen weg
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  /// Liest eine Zahl wenn moeglich als Wort - das hilft TTS bei
  /// Aussprache. Bei groesseren Zahlen (>20) lassen wir die Ziffer.
  static String _speakNumber(String numStr) {
    final n = int.tryParse(numStr);
    if (n == null) return numStr;
    const words = <int, String>{
      0: 'null', 1: 'eins', 2: 'zwei', 3: 'drei', 4: 'vier',
      5: 'fuenf', 6: 'sechs', 7: 'sieben', 8: 'acht', 9: 'neun',
      10: 'zehn', 11: 'elf', 12: 'zwoelf', 13: 'dreizehn',
      14: 'vierzehn', 15: 'fuenfzehn', 16: 'sechzehn',
      17: 'siebzehn', 18: 'achtzehn', 19: 'neunzehn', 20: 'zwanzig',
    };
    return words[n] ?? numStr;
  }

  /// Liest eine Uhrzeit als natuerlichen Satz.
  static String _speakTime(int hour, int minute) {
    final h = hour % 24;
    if (minute == 0) return '${_speakNumber('$h')} Uhr';
    if (minute == 15) return 'viertel nach ${_speakNumber('$h')}';
    if (minute == 30) {
      final next = (h + 1) % 24;
      return 'halb ${_speakNumber('$next')}';
    }
    if (minute == 45) {
      final next = (h + 1) % 24;
      return 'viertel vor ${_speakNumber('$next')}';
    }
    return '${_speakNumber('$h')} Uhr ${_speakNumber('$minute')}';
  }

  /// Erkennt einfache Emoji-Folgen und ersetzt sie durch Wortform.
  /// Nur die haeufigsten 5 - mehr wuerde Code aufblaehen.
  static String _replaceEmojiSequences(String s) {
    var out = s;
    out = _replaceEmojiCount(out, '🍎', 'Apfel', 'Aepfel');
    out = _replaceEmojiCount(out, '⭐', 'Stern', 'Sterne');
    out = _replaceEmojiCount(out, '🌟', 'Stern', 'Sterne');
    out = _replaceEmojiCount(out, '🐶', 'Hund', 'Hunde');
    out = _replaceEmojiCount(out, '🐱', 'Katze', 'Katzen');
    return out;
  }

  static String _replaceEmojiCount(String s, String emoji, String singular, String plural) {
    final regex = RegExp('($emoji)+');
    return s.replaceAllMapped(regex, (m) {
      final text = m.group(0)!;
      final count = text.length ~/ emoji.length;
      if (count == 1) return 'ein $singular';
      return '${_speakNumber('$count')} $plural';
    });
  }
}
