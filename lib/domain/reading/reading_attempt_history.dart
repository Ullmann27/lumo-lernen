import 'reading_domain.dart';

enum ReadingAttemptOutcome {
  accepted,
  retryBecauseRecognitionWasUnclear,
  retryBecauseReadingNeedsPractice,
  confirmedProblemWord,
}

class ReadingSentenceAttempt {
  const ReadingSentenceAttempt({
    required this.sentenceId,
    required this.sentenceText,
    required this.attemptNumber,
    required this.transcript,
    required this.alignmentScore,
    required this.correctEnough,
    required this.recognitionUnclear,
    required this.occurredAt,
    this.problemWord,
  });

  final String sentenceId;
  final String sentenceText;
  final int attemptNumber;
  final String transcript;
  final double alignmentScore;
  final bool correctEnough;
  final bool recognitionUnclear;
  final DateTime occurredAt;
  final String? problemWord;

  bool get reliableReadingProblem =>
      !correctEnough && !recognitionUnclear && problemWord != null && problemWord!.trim().isNotEmpty;
}

class ReadingAttemptDecision {
  const ReadingAttemptDecision({
    required this.outcome,
    required this.childMessage,
    this.confirmedProblemWord,
  });

  final ReadingAttemptOutcome outcome;
  final String childMessage;
  final String? confirmedProblemWord;

  bool get shouldCountAsIntervention =>
      outcome == ReadingAttemptOutcome.retryBecauseReadingNeedsPractice ||
      outcome == ReadingAttemptOutcome.confirmedProblemWord;

  bool get shouldKeepSameAttempt => outcome == ReadingAttemptOutcome.retryBecauseRecognitionWasUnclear;
}

class ReadingAttemptLedger {
  final Map<String, List<ReadingSentenceAttempt>> _attemptsBySentence = <String, List<ReadingSentenceAttempt>>{};
  final Set<String> _completedSentenceIds = <String>{};

  ReadingAttemptDecision recordAnalysis({
    required StorySentence sentence,
    required int attemptNumber,
    required SentenceReadingAnalysis analysis,
  }) {
    final recognitionUnclear = _isRecognitionUnclear(sentence.text, analysis);
    final attempt = ReadingSentenceAttempt(
      sentenceId: sentence.id,
      sentenceText: sentence.text,
      attemptNumber: attemptNumber,
      transcript: analysis.spokenText,
      alignmentScore: analysis.alignmentScore,
      correctEnough: analysis.correctEnough,
      recognitionUnclear: recognitionUnclear,
      problemWord: analysis.problemWord,
      occurredAt: DateTime.now(),
    );
    final attempts = _attemptsBySentence.putIfAbsent(sentence.id, () => <ReadingSentenceAttempt>[]);
    attempts.add(attempt);

    if (analysis.correctEnough) {
      _completedSentenceIds.add(sentence.id);
      return const ReadingAttemptDecision(
        outcome: ReadingAttemptOutcome.accepted,
        childMessage: 'Gut gelesen. Jetzt kommt der naechste Satz. Lies ihn laut vor.',
      );
    }

    if (recognitionUnclear) {
      return const ReadingAttemptDecision(
        outcome: ReadingAttemptOutcome.retryBecauseRecognitionWasUnclear,
        childMessage: 'Ich habe dich nicht gut verstanden. Wir zaehlen das nicht als Fehler. Lies denselben Satz nochmal langsam.',
      );
    }

    final confirmed = _confirmedProblemWordFor(sentence.id);
    if (confirmed != null) {
      return ReadingAttemptDecision(
        outcome: ReadingAttemptOutcome.confirmedProblemWord,
        confirmedProblemWord: confirmed,
        childMessage: 'Das Wort "$confirmed" ueben wir kurz. Lies den ganzen Satz nochmal langsam.',
      );
    }

    return const ReadingAttemptDecision(
      outcome: ReadingAttemptOutcome.retryBecauseReadingNeedsPractice,
      childMessage: 'Fast. Lies den Satz noch einmal langsam und deutlich. Ich hoere wieder zu.',
    );
  }

  ReadingAttemptDecision recordNoSpeech({required StorySentence sentence, required int attemptNumber}) {
    final attempts = _attemptsBySentence.putIfAbsent(sentence.id, () => <ReadingSentenceAttempt>[]);
    attempts.add(ReadingSentenceAttempt(
      sentenceId: sentence.id,
      sentenceText: sentence.text,
      attemptNumber: attemptNumber,
      transcript: '',
      alignmentScore: 0,
      correctEnough: false,
      recognitionUnclear: true,
      occurredAt: DateTime.now(),
    ));
    return const ReadingAttemptDecision(
      outcome: ReadingAttemptOutcome.retryBecauseRecognitionWasUnclear,
      childMessage: 'Ich habe dich nicht gut verstanden. Wir zaehlen das nicht als Fehler. Lies denselben Satz nochmal langsam.',
    );
  }

  List<String> get persistentProblemWords {
    final words = <String>{};
    for (final entry in _attemptsBySentence.entries) {
      if (_completedSentenceIds.contains(entry.key)) continue;
      final confirmed = _confirmedProblemWordFor(entry.key);
      if (confirmed != null) words.add(confirmed);
    }
    return words.toList(growable: false);
  }

  int get totalAttempts => _attemptsBySentence.values.fold<int>(0, (sum, attempts) => sum + attempts.length);

  int get recognitionUnclearCount => _attemptsBySentence.values
      .expand((attempts) => attempts)
      .where((attempt) => attempt.recognitionUnclear)
      .length;

  String? _confirmedProblemWordFor(String sentenceId) {
    if (_completedSentenceIds.contains(sentenceId)) return null;
    final attempts = _attemptsBySentence[sentenceId] ?? const <ReadingSentenceAttempt>[];
    final counts = <String, int>{};
    for (final attempt in attempts.where((attempt) => attempt.reliableReadingProblem)) {
      final word = attempt.problemWord!.trim().toLowerCase();
      counts[word] = (counts[word] ?? 0) + 1;
    }
    for (final entry in counts.entries) {
      if (entry.value >= 2) return entry.key;
    }
    return null;
  }

  bool _isRecognitionUnclear(String expectedText, SentenceReadingAnalysis analysis) {
    final spokenTokens = _tokens(analysis.spokenText);
    final expectedTokens = _tokens(expectedText);
    if (spokenTokens.isEmpty) return true;
    if (analysis.correctEnough) return false;
    if (spokenTokens.length <= 1 && expectedTokens.length >= 3) return true;
    if (analysis.alignmentScore < .24) return true;
    if (analysis.problemWord == null && analysis.events.isEmpty) return true;
    return false;
  }

  List<String> _tokens(String value) {
    return value
        .toLowerCase()
        .replaceAll('ü', 'ue')
        .replaceAll('ö', 'oe')
        .replaceAll('ä', 'ae')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z\s]'), '')
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }
}
