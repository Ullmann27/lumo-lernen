/// "Wer wird Lumo-Meister?" - Quiz-Show fuer Kinder.
///
/// Produktregeln:
///   - 20 Fragen mit steigender, schulstufengerechter Schwierigkeit
///   - sichere Stern-Stufen: 50 / 200 / 800 / 5.000
///   - Frage 20 ist die Finalfrage
///   - 3 Joker: 50:50, Publikum, Lumo-Hinweis
///   - falsche Antwort sichert die zuletzt erreichte Stern-Stufe
library;

import 'package:flutter/foundation.dart';

/// Schwierigkeit einer Quiz-Frage.
enum QuizDifficulty {
  easy,
  medium,
  hard,
}

/// Joker der Lumo-Quizshow.
enum QuizJoker {
  /// Zwei falsche Antworten werden ausgegraut.
  fiftyFifty,

  /// Publikums-Statistik wird angezeigt.
  audience,

  /// Lumo gibt einen kindgerechten Hinweis.
  callLumo,
}

/// Eine einzelne Quiz-Frage mit 4 Antwortoptionen.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.subject,
    this.explanation,
    this.hint,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final QuizDifficulty difficulty;
  final String subject;
  final String? explanation;
  final String? hint;

  String get correctAnswer => options[correctIndex];

  bool get isValid =>
      options.length == 4 &&
      correctIndex >= 0 &&
      correctIndex < 4 &&
      prompt.trim().isNotEmpty;
}

/// Zustand des laufenden Quiz-Spiels.
@immutable
class QuizShowState {
  const QuizShowState({
    required this.questions,
    this.currentQuestionIndex = 0,
    this.selectedOption,
    this.revealed = false,
    this.usedJokers = const <QuizJoker>{},
    this.fiftyFiftyHiddenOptions = const <int>{},
    this.securedStars = 0,
    this.awardedStars = 0,
    this.gameOver = false,
    this.won = false,
    this.audienceVotes,
    this.lumoHint,
  });

  /// Alle 20 Fragen dieses Spiels.
  final List<QuizQuestion> questions;

  /// Aktuelle Frage (0-19).
  final int currentQuestionIndex;

  final int? selectedOption;
  final bool revealed;
  final Set<QuizJoker> usedJokers;
  final Set<int> fiftyFiftyHiddenOptions;

  /// Zuletzt gesicherte Stern-Stufe.
  final int securedStars;

  /// Sterne, die bei Spielende tatsaechlich gutgeschrieben werden.
  ///
  /// Vor Spielende immer 0. Dadurch kann die UI exakt einmal buchen.
  final int awardedStars;

  final bool gameOver;
  final bool won;
  final List<int>? audienceVotes;
  final String? lumoHint;

  QuizQuestion get currentQuestion => questions[currentQuestionIndex];
  int get displayQuestionNumber => currentQuestionIndex + 1;
  int get remainingJokers => QuizJoker.values.length - usedJokers.length;

  QuizShowState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    int? selectedOption,
    bool? revealed,
    Set<QuizJoker>? usedJokers,
    Set<int>? fiftyFiftyHiddenOptions,
    int? securedStars,
    int? awardedStars,
    bool? gameOver,
    bool? won,
    List<int>? audienceVotes,
    String? lumoHint,
    bool clearSelection = false,
    bool clearAudience = false,
    bool clearLumoHint = false,
    bool clearFiftyFifty = false,
  }) {
    return QuizShowState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedOption: clearSelection ? null : (selectedOption ?? this.selectedOption),
      revealed: revealed ?? this.revealed,
      usedJokers: usedJokers ?? this.usedJokers,
      fiftyFiftyHiddenOptions: clearFiftyFifty
          ? const <int>{}
          : (fiftyFiftyHiddenOptions ?? this.fiftyFiftyHiddenOptions),
      securedStars: securedStars ?? this.securedStars,
      awardedStars: awardedStars ?? this.awardedStars,
      gameOver: gameOver ?? this.gameOver,
      won: won ?? this.won,
      audienceVotes: clearAudience ? null : (audienceVotes ?? this.audienceVotes),
      lumoHint: clearLumoHint ? null : (lumoHint ?? this.lumoHint),
    );
  }
}

/// Engine fuer das Quiz-Spiel. Stateless, deterministisch und UI-sicher.
class QuizShowEngine {
  const QuizShowEngine();

  /// Stern-Stufen nach Frage 5, 10, 15 und 20.
  static const Map<int, int> securedStarsAfterIndex = <int, int>{
    4: 50,
    9: 200,
    14: 800,
    19: 5000,
  };

  QuizShowState start({required List<QuizQuestion> questions}) {
    assert(
      questions.length == 20,
      'Quiz braucht GENAU 20 Fragen, bekam ${questions.length}',
    );
    assert(questions.every((q) => q.isValid), 'Mindestens eine Frage ist invalid');
    return QuizShowState(questions: questions);
  }

  QuizShowState selectAnswer(QuizShowState s, int optionIndex) {
    if (s.revealed || s.gameOver) return s;
    if (optionIndex < 0 || optionIndex > 3) return s;
    if (s.fiftyFiftyHiddenOptions.contains(optionIndex)) return s;
    return s.copyWith(selectedOption: optionIndex);
  }

  /// Loest die aktuelle Antwort auf.
  ///
  /// Bei einer falschen Antwort endet das Spiel und die zuletzt gesicherte
  /// Stern-Stufe wird ausgezahlt. Bei der Finalfrage werden 5.000 Sterne
  /// gesichert und ausgezahlt.
  QuizShowState reveal(QuizShowState s) {
    if (s.revealed || s.gameOver || s.selectedOption == null) return s;

    final question = s.currentQuestion;
    final correct = s.selectedOption == question.correctIndex;

    if (!correct) {
      return s.copyWith(
        revealed: true,
        gameOver: true,
        won: false,
        awardedStars: s.securedStars,
      );
    }

    final newlySecured =
        securedStarsAfterIndex[s.currentQuestionIndex] ?? s.securedStars;
    final completedAll = s.currentQuestionIndex >= s.questions.length - 1;

    return s.copyWith(
      revealed: true,
      securedStars: newlySecured,
      awardedStars: completedAll ? newlySecured : 0,
      gameOver: completedAll,
      won: completedAll,
    );
  }

  QuizShowState nextQuestion(QuizShowState s) {
    if (s.gameOver || !s.revealed) return s;
    if (s.currentQuestionIndex >= s.questions.length - 1) return s;
    return s.copyWith(
      currentQuestionIndex: s.currentQuestionIndex + 1,
      revealed: false,
      clearSelection: true,
      clearFiftyFifty: true,
      clearAudience: true,
      clearLumoHint: true,
    );
  }

  QuizShowState useJoker(QuizShowState s, QuizJoker joker) {
    if (s.revealed || s.gameOver || s.usedJokers.contains(joker)) return s;

    final used = Set<QuizJoker>.from(s.usedJokers)..add(joker);
    switch (joker) {
      case QuizJoker.fiftyFifty:
        final wrong = <int>[0, 1, 2, 3]
            .where((i) => i != s.currentQuestion.correctIndex)
            .toList();
        final seed = _stableSeed('${s.currentQuestion.id}|5050');
        wrong.sort((a, b) => ((a + seed) % 7).compareTo((b + seed) % 7));
        return s.copyWith(
          usedJokers: used,
          fiftyFiftyHiddenOptions: wrong.take(2).toSet(),
        );
      case QuizJoker.audience:
        return s.copyWith(
          usedJokers: used,
          audienceVotes: _audienceVotesFor(s.currentQuestion),
        );
      case QuizJoker.callLumo:
        return s.copyWith(
          usedJokers: used,
          lumoHint: s.currentQuestion.hint ?? _genericHintFor(s.currentQuestion),
        );
    }
  }

  int safeSpotStarsForIndex(int questionIndex) =>
      securedStarsAfterIndex[questionIndex] ?? 0;

  bool isAtSafeSpot(int questionIndex) =>
      securedStarsAfterIndex.containsKey(questionIndex);

  List<int> _audienceVotesFor(QuizQuestion question) {
    final seed = _stableSeed('${question.id}|audience');
    final correctPercent = 64 + (seed % 18);
    final remaining = 100 - correctPercent;
    final wrong = <int>[0, 1, 2, 3]
        .where((i) => i != question.correctIndex)
        .toList();
    wrong.sort((a, b) => ((a + seed) % 11).compareTo((b + seed) % 11));

    final votes = List<int>.filled(4, 0);
    votes[question.correctIndex] = correctPercent;
    votes[wrong[0]] = remaining ~/ 2;
    votes[wrong[1]] = remaining ~/ 3;
    votes[wrong[2]] = 100 - votes.reduce((a, b) => a + b);
    return votes;
  }

  String _genericHintFor(QuizQuestion question) {
    return switch (question.subject.toLowerCase()) {
      'mathe' =>
        'Rechne langsam. Erst die Zahlen anschauen, dann Schritt für Schritt lösen.',
      'deutsch' =>
        'Lies die Frage laut. Achte auf Wortanfang, Wortende und Bedeutung.',
      'sachunterricht' =>
        'Denk an das, was du aus Alltag, Natur und Schule kennst.',
      _ =>
        'Schau dir jede Antwort ruhig an. Eine passt besser als die anderen.',
    };
  }

  int _stableSeed(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
