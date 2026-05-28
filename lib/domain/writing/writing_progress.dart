// ════════════════════════════════════════════════════════════════════════
// WRITING PROGRESS — Phase 6 vom Lumo-Schreibcoach-Plan
// ════════════════════════════════════════════════════════════════════════
// Was Lumo sich merkt:
//   - wie oft welcher Buchstabe geuebt wurde,
//   - wie oft er richtig war,
//   - welche Buchstaben schwach sind (accuracy < 0.7 bei min 3 Versuchen),
//   - welche Woerter im Wortmodus abgeschlossen wurden,
//   - wann zuletzt geuebt wurde.
//
// Wird vom WritingProgressRepository persistiert (SharedPreferences/JSON).
// ════════════════════════════════════════════════════════════════════════

class WritingLetterStat {
  const WritingLetterStat({
    required this.letter,
    required this.attempts,
    required this.correct,
  });

  final String letter;
  final int attempts;
  final int correct;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;

  WritingLetterStat copyWith({int? attempts, int? correct}) =>
      WritingLetterStat(
        letter: letter,
        attempts: attempts ?? this.attempts,
        correct: correct ?? this.correct,
      );

  Map<String, dynamic> toJson() => {
        'letter': letter,
        'attempts': attempts,
        'correct': correct,
      };

  factory WritingLetterStat.fromJson(Map<String, dynamic> json) =>
      WritingLetterStat(
        letter: (json['letter'] as String? ?? '').toUpperCase(),
        attempts: (json['attempts'] as num? ?? 0).toInt(),
        correct: (json['correct'] as num? ?? 0).toInt(),
      );
}

class WritingProgress {
  const WritingProgress({
    this.letterStats = const {},
    this.completedWords = const {},
    this.lastPracticedAt,
    this.totalAttempts = 0,
    this.totalCorrect = 0,
  });

  /// Statistiken pro Buchstabe, Key = Grossbuchstabe.
  final Map<String, WritingLetterStat> letterStats;

  /// Im Wortmodus abgeschlossene Woerter (Grossschreibung normalisiert).
  final Set<String> completedWords;

  final DateTime? lastPracticedAt;
  final int totalAttempts;
  final int totalCorrect;

  /// Buchstaben mit niedriger Genauigkeit (< 0.7) und mindestens 3 Versuchen.
  /// Sortiert nach schlechtester Genauigkeit zuerst.
  List<String> get weakLetters {
    final entries = letterStats.entries
        .where((e) => e.value.attempts >= 3 && e.value.accuracy < 0.7)
        .toList();
    entries.sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    return entries.map((e) => e.key).toList(growable: false);
  }

  /// Buchstaben, die schon ein Mal richtig waren.
  Set<String> get practicedLetters =>
      letterStats.entries.where((e) => e.value.attempts > 0).map((e) => e.key).toSet();

  double get overallAccuracy =>
      totalAttempts == 0 ? 0 : totalCorrect / totalAttempts;

  WritingProgress copyWith({
    Map<String, WritingLetterStat>? letterStats,
    Set<String>? completedWords,
    DateTime? lastPracticedAt,
    int? totalAttempts,
    int? totalCorrect,
  }) =>
      WritingProgress(
        letterStats: letterStats ?? this.letterStats,
        completedWords: completedWords ?? this.completedWords,
        lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
        totalAttempts: totalAttempts ?? this.totalAttempts,
        totalCorrect: totalCorrect ?? this.totalCorrect,
      );

  /// Erzeugt eine neue Progress-Instanz mit dem zusaetzlichen Versuch.
  WritingProgress withAttempt({
    required String letter,
    required bool correct,
    DateTime? at,
  }) {
    final key = letter.toUpperCase();
    if (key.isEmpty) return this;
    final prev = letterStats[key] ??
        WritingLetterStat(letter: key, attempts: 0, correct: 0);
    final next = prev.copyWith(
      attempts: prev.attempts + 1,
      correct: prev.correct + (correct ? 1 : 0),
    );
    return copyWith(
      letterStats: {...letterStats, key: next},
      lastPracticedAt: at ?? DateTime.now(),
      totalAttempts: totalAttempts + 1,
      totalCorrect: totalCorrect + (correct ? 1 : 0),
    );
  }

  WritingProgress withCompletedWord(String word, {DateTime? at}) {
    final clean = word.trim().toUpperCase();
    if (clean.isEmpty) return this;
    return copyWith(
      completedWords: {...completedWords, clean},
      lastPracticedAt: at ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'letterStats': letterStats.values.map((s) => s.toJson()).toList(),
        'completedWords': completedWords.toList(),
        'lastPracticedAt': lastPracticedAt?.toIso8601String(),
        'totalAttempts': totalAttempts,
        'totalCorrect': totalCorrect,
      };

  factory WritingProgress.fromJson(Map<String, dynamic> json) {
    final statsList = (json['letterStats'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(WritingLetterStat.fromJson);
    final stats = <String, WritingLetterStat>{
      for (final s in statsList)
        if (s.letter.isNotEmpty) s.letter: s,
    };
    final words = <String>{
      for (final w in (json['completedWords'] as List<dynamic>? ?? const []))
        if (w is String && w.trim().isNotEmpty) w.trim().toUpperCase(),
    };
    DateTime? last;
    final iso = json['lastPracticedAt'];
    if (iso is String && iso.isNotEmpty) {
      last = DateTime.tryParse(iso);
    }
    return WritingProgress(
      letterStats: stats,
      completedWords: words,
      lastPracticedAt: last,
      totalAttempts: (json['totalAttempts'] as num? ?? 0).toInt(),
      totalCorrect: (json['totalCorrect'] as num? ?? 0).toInt(),
    );
  }

  static const empty = WritingProgress();
}
