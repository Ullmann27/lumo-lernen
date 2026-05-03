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
}
