// ════════════════════════════════════════════════════════════════════════
// VOICE READING EVALUATOR — Mit-Lese-Vergleich Wort-fuer-Wort
// ════════════════════════════════════════════════════════════════════════
// 2026-06-06 Iter 34: Vergleicht den live STT-Output mit dem Ziel-Text
// Wort-fuer-Wort. Liefert pro Wort einen Status (matched / partial /
// missing). Toleranz: Levenshtein-Distanz max 2 fuer 'partial', max 0
// fuer 'matched'. Umlaute werden normalisiert.
// ════════════════════════════════════════════════════════════════════════

enum ReadingWordStatus {
  /// Noch nicht erreicht im aktuellen STT-Stream.
  pending,

  /// Vom STT erkannt und zu Ziel-Wort passend (Levenshtein <= 0).
  matched,

  /// Vom STT erkannt aber Naeher-Match (Levenshtein 1-2).
  partial,
}

class ReadingProgress {
  const ReadingProgress({
    required this.statuses,
    required this.totalWords,
    required this.matchedCount,
    required this.partialCount,
    required this.currentIndex,
  });

  final List<ReadingWordStatus> statuses;
  final int totalWords;
  final int matchedCount;
  final int partialCount;

  /// Index des naechsten Worts das gelesen werden soll.
  /// Liegt zwischen 0 und totalWords - 1.
  final int currentIndex;

  double get accuracy {
    if (totalWords == 0) return 0;
    final scored = matchedCount + partialCount * 0.6;
    return (scored / totalWords).clamp(0.0, 1.0);
  }

  bool get isComplete => currentIndex >= totalWords;
}

class VoiceReadingEvaluator {
  const VoiceReadingEvaluator();

  /// Vergleicht den STT-Text mit dem Ziel-Wortarray und liefert pro
  /// Ziel-Wort einen Status. Greedy-Algorithmus: jedes erkannte Wort
  /// matcht das naechste passende Ziel-Wort.
  ReadingProgress evaluate({
    required List<String> targetWords,
    required String recognizedText,
  }) {
    final recognized = _tokenize(recognizedText);
    final statuses = List<ReadingWordStatus>.filled(
      targetWords.length,
      ReadingWordStatus.pending,
    );
    var matched = 0;
    var partial = 0;
    var targetIdx = 0;

    for (final recognizedWord in recognized) {
      if (targetIdx >= targetWords.length) break;
      final normRec = _normalize(recognizedWord);
      if (normRec.isEmpty) continue;

      // Im naechsten Window (3 Wort breit) das beste Match suchen.
      final windowEnd =
          (targetIdx + 3).clamp(0, targetWords.length).toInt();
      var bestIdx = -1;
      var bestDist = 999;
      for (var i = targetIdx; i < windowEnd; i++) {
        final normTarget = _normalize(targetWords[i]);
        final d = _levenshtein(normRec, normTarget);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
        // Frueher Abbruch bei perfektem Match
        if (d == 0) break;
      }

      if (bestIdx == -1) continue;

      // Bei 0 = matched, 1-2 = partial, sonst ignorieren (kein Treffer)
      if (bestDist == 0) {
        // Fuelle Luecke davor als pending (bleibt)
        statuses[bestIdx] = ReadingWordStatus.matched;
        matched++;
        targetIdx = bestIdx + 1;
      } else if (bestDist <= 2 &&
          _normalize(targetWords[bestIdx]).length >= 3) {
        statuses[bestIdx] = ReadingWordStatus.partial;
        partial++;
        targetIdx = bestIdx + 1;
      }
      // Sonst: ignorieren, targetIdx bleibt
    }

    return ReadingProgress(
      statuses: statuses,
      totalWords: targetWords.length,
      matchedCount: matched,
      partialCount: partial,
      currentIndex: targetIdx,
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────

  List<String> _tokenize(String text) {
    return text
        .split(RegExp(r'[^a-zA-ZäöüÄÖÜß]+'))
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }

  String _normalize(String s) {
    var x = s.toLowerCase();
    // Satzzeichen entfernen
    x = x.replaceAll(RegExp(r'[^a-zäöüß]'), '');
    // Umlaute zu ASCII-Aequivalenten (toleranter Vergleich)
    x = x
        .replaceAll('ä', 'a')
        .replaceAll('ö', 'o')
        .replaceAll('ü', 'u')
        .replaceAll('ß', 'ss');
    return x;
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    // Optimierte Single-Row-Variante
    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1, // insertion
          prev[j + 1] + 1, // deletion
          prev[j] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }
}
