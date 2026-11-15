/// Conservative, explainable assessment for a child's written/recognized
/// retelling. This is a keyword aid, not an AI assessment of understanding.
class LumoStorySummaryScore {
  const LumoStorySummaryScore({
    required this.hits,
    required this.stars,
    this.matchedKeyPoints = const [],
    this.keyPointCount = 0,
    this.wordCount = 0,
  });

  final int hits;
  final int stars;
  final List<String> matchedKeyPoints;
  final int keyPointCount;
  final int wordCount;

  /// Mentions do not establish relationships, chronology, negation, or meaning.
  /// A paraphrase without these words may also be a sound retelling.
  bool get assessesComprehension => false;
}

class LumoStorySummaryScorer {
  const LumoStorySummaryScorer._();

  static final RegExp _separators = RegExp(r'[^a-z0-9]+');
  static const List<String> _inflections = <String>[
    'e',
    'en',
    'er',
    'ern',
    'es',
    's',
    'n',
  ];

  static List<String> _words(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    return normalized
        .split(_separators)
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static bool _matchesWord(String expected, String observed) {
    if (expected == observed) return true;
    // Common German inflections count; accidental embedded substrings do not.
    // In particular "Buchhaltung" must not earn the keyword "Buch".
    if (expected.length < 4) return false;
    return _inflections.any((suffix) => observed == expected + suffix);
  }

  static bool _hasPhrase(List<String> words, List<String> phrase) {
    if (phrase.isEmpty || phrase.length > words.length) return false;
    for (var start = 0; start <= words.length - phrase.length; start++) {
      var matched = true;
      for (var offset = 0; offset < phrase.length; offset++) {
        if (!_matchesWord(phrase[offset], words[start + offset])) {
          matched = false;
          break;
        }
      }
      if (matched) return true;
    }
    return false;
  }

  static LumoStorySummaryScore evaluate({
    required String summary,
    required List<String> keyPoints,
  }) {
    if (keyPoints.isEmpty || summary.trim().isEmpty) {
      return const LumoStorySummaryScore(hits: 0, stars: 0);
    }
    final words = _words(summary);
    if (words.isEmpty) {
      return const LumoStorySummaryScore(hits: 0, stars: 0);
    }
    final uniquePoints = <String, String>{};
    for (final point in keyPoints) {
      final normalized = _words(point).join(' ');
      if (normalized.isNotEmpty) {
        uniquePoints.putIfAbsent(normalized, () => point.trim());
      }
    }
    if (uniquePoints.isEmpty) {
      return LumoStorySummaryScore(hits: 0, stars: 0, wordCount: words.length);
    }
    final matched = [
      for (final point in uniquePoints.values)
        if (_hasPhrase(words, _words(point))) point
    ];
    final hits = matched.length;
    final ratio = hits / uniquePoints.length;
    final stars = ratio >= .7
        ? 5
        : ratio >= .5
            ? 4
            : ratio >= .3
                ? 3
                : 2;
    return LumoStorySummaryScore(
      hits: hits,
      stars: stars,
      matchedKeyPoints: List.unmodifiable(matched),
      keyPointCount: uniquePoints.length,
      wordCount: words.length,
    );
  }
}
