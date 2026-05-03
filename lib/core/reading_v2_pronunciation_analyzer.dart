import 'dart:math' as math;

import '../domain/reading/reading_domain.dart';

/// Lesemodus 2.0 Analyzer.
///
/// Ziel:
/// - wortnäher als der alte Fuzzy-Abgleich
/// - keine Satzpunkt-Abhängigkeit
/// - kindgerecht tolerant bei Aussprache, aber nicht blind bestätigend
/// - Problemwort wird gezielt gespeichert
class ReadingV2PronunciationAnalyzer extends PronunciationAnalyzer {
  const ReadingV2PronunciationAnalyzer();

  @override
  SentenceReadingAnalysis analyze({
    required String expectedSentence,
    required String spokenTranscript,
    double confidence = 1,
  }) {
    final expectedVisible = _visibleWords(expectedSentence);
    final expected = expectedVisible.map(_normalize).where((t) => t.isNotEmpty).toList(growable: false);
    final spoken = _visibleWords(spokenTranscript).map(_normalize).where((t) => t.isNotEmpty).toList(growable: false);

    if (expected.isEmpty || spoken.isEmpty) {
      return SentenceReadingAnalysis(
        expectedText: _cleanSentence(expectedSentence),
        spokenText: spokenTranscript.trim(),
        alignmentScore: 0,
        correctEnough: false,
        events: expectedVisible.isEmpty
            ? const <PronunciationEvent>[]
            : <PronunciationEvent>[
                PronunciationEvent(
                  type: PronunciationEventType.omittedWord,
                  expectedToken: expectedVisible.first,
                  confidence: confidence,
                ),
              ],
        problemWord: expectedVisible.isEmpty ? null : expectedVisible.first,
      );
    }

    final results = _align(expected: expected, expectedVisible: expectedVisible, spoken: spoken);
    final events = <PronunciationEvent>[];
    var accepted = 0;
    var weighted = 0.0;
    var lastAcceptedIndex = -1;

    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      if (r.accepted) {
        accepted++;
        weighted += r.score.clamp(.72, 1.0).toDouble();
        lastAcceptedIndex = i;
      } else if (!_softOptional(_normalize(r.expected))) {
        events.add(PronunciationEvent(
          type: r.eventType ?? PronunciationEventType.lowConfidence,
          expectedToken: r.expected,
          spokenToken: r.spoken,
          confidence: confidence,
        ));
      }
    }

    final score = (weighted / expected.length).clamp(0.0, 1.0).toDouble();
    final shortSentence = expected.length <= 4;
    final requiredScore = shortSentence ? .86 : expected.length <= 7 ? .80 : .76;
    final allowedProblems = shortSentence ? 0 : 1;
    final endReached = lastAcceptedIndex >= expected.length - 1;
    final correctEnough = score >= requiredScore && endReached && events.length <= allowedProblems && accepted >= expected.length - allowedProblems;

    return SentenceReadingAnalysis(
      expectedText: _cleanSentence(expectedSentence),
      spokenText: spokenTranscript.trim(),
      alignmentScore: score,
      correctEnough: correctEnough,
      events: events,
      problemWord: events.isEmpty ? null : events.first.expectedToken,
    );
  }

  List<_WordResult> _align({required List<String> expected, required List<String> expectedVisible, required List<String> spoken}) {
    final out = <_WordResult>[];
    var spokenIndex = 0;
    String? previousAccepted;

    for (var i = 0; i < expected.length; i++) {
      final exp = expected[i];
      final visible = expectedVisible[i];
      if (spokenIndex >= spoken.length) {
        out.add(_WordResult(expected: visible, score: 0, accepted: false, eventType: PronunciationEventType.omittedWord));
        continue;
      }

      final current = spoken[spokenIndex];
      final score = _similarity(exp, current);
      if (_accepted(exp, current, score)) {
        out.add(_WordResult(expected: visible, spoken: current, score: score, accepted: true));
        previousAccepted = exp;
        spokenIndex++;
        continue;
      }

      final next = spokenIndex + 1 < spoken.length ? spoken[spokenIndex + 1] : null;
      if (next != null && _accepted(exp, next, _similarity(exp, next))) {
        final repeated = previousAccepted != null && _similarity(previousAccepted, current) >= _threshold(previousAccepted);
        out.add(_WordResult(
          expected: visible,
          spoken: current,
          score: score,
          accepted: false,
          eventType: repeated ? PronunciationEventType.repeatedWord : PronunciationEventType.substitutedWord,
        ));
        spokenIndex += 2;
        continue;
      }

      out.add(_WordResult(
        expected: visible,
        spoken: current,
        score: score,
        accepted: false,
        eventType: score >= _threshold(exp) - .12 && exp.length >= 4 ? PronunciationEventType.lowConfidence : PronunciationEventType.substitutedWord,
      ));
      spokenIndex++;
    }

    return out;
  }

  bool _accepted(String expected, String spoken, double score) {
    if (expected == spoken) return true;
    if (_knownVariant(expected, spoken)) return true;
    return score >= _threshold(expected);
  }

  double _threshold(String expected) {
    if (expected.length <= 2) return .93;
    if (expected.length <= 3) return .84;
    if (expected.length <= 5) return .72;
    return .66;
  }

  bool _knownVariant(String expected, String spoken) {
    if (expected == 'lumo') return <String>{'lumo', 'limo', 'loma', 'luna', 'luno', 'lumos', 'humo', 'lu'}.contains(spoken);
    if (expected == 'fuchs') return <String>{'fuchs', 'fux', 'fuks'}.contains(spoken);
    if (expected == 'ich') return <String>{'ich', 'isch', 'ik'}.contains(spoken);
    if (expected.endsWith('er') && spoken == expected.substring(0, expected.length - 2)) return true;
    return false;
  }

  bool _softOptional(String token) => token == 'der' || token == 'die' || token == 'das' || token == 'ein' || token == 'eine';

  double _similarity(String a, String b) {
    if (a == b) return 1;
    if (a.isEmpty || b.isEmpty) return 0;
    final d = _levenshtein(a, b);
    final longest = math.max(a.length, b.length);
    return (1 - d / longest).clamp(0.0, 1.0).toDouble();
  }

  int _levenshtein(String a, String b) {
    final prev = List<int>.generate(b.length + 1, (i) => i);
    final curr = List<int>.filled(b.length + 1, 0);
    for (var i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        final insert = curr[j] + 1;
        final delete = prev[j + 1] + 1;
        final replace = prev[j] + (a[i] == b[j] ? 0 : 1);
        curr[j + 1] = math.min(math.min(insert, delete), replace);
      }
      for (var j = 0; j < prev.length; j++) {
        prev[j] = curr[j];
      }
    }
    return prev[b.length];
  }

  List<String> _visibleWords(String value) => _cleanSentence(value).split(RegExp(r'\s+')).where((w) => w.trim().isNotEmpty).toList(growable: false);

  String _cleanSentence(String value) => value
      .replaceAll(RegExp(r'[.!?;:]+'), '')
      .replaceAll(RegExp(r'[„“"()]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String _normalize(String value) => _cleanSentence(value)
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp(r'[^a-z\s]'), '')
      .trim();
}

class _WordResult {
  const _WordResult({
    required this.expected,
    this.spoken,
    required this.score,
    required this.accepted,
    this.eventType,
  });

  final String expected;
  final String? spoken;
  final double score;
  final bool accepted;
  final PronunciationEventType? eventType;
}
