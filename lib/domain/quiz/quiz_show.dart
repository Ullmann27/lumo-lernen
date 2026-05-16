/// "Wer wird Lumo-Champion" - Quiz-Show fuer Kinder.
///
/// Heinz' Konzept:
///   - 15 Fragen, steigende Schwierigkeit
///   - Schwellen wie bei "Wer wird Millionaer":
///       Frage 5  -> kleiner Coupon (Eis, Schoki)
///       Frage 10 -> mittlerer Coupon (Kino, Family Park)
///       Frage 15 -> grosser Coupon (Spielzeug, Lego)
///   - 3 Joker: 50:50, Publikum, Lumo-Anruf
///   - Falsche Antwort = zurueck auf letzte Schwelle
///
/// SKELETON von Claude Opus 4.7 - Codex implementiert die Logik.

import 'package:flutter/foundation.dart';

import 'quiz_rewards.dart';

/// Schwierigkeit einer Quiz-Frage.
enum QuizDifficulty {
  easy,   // Frage 1-4
  medium, // Frage 5-9
  hard,   // Frage 10-15
}

/// Joker-Typen wie bei "Wer wird Millionaer".
enum QuizJoker {
  /// Zwei falsche Antworten werden ausgegraut.
  fiftyFifty,

  /// Publikums-Statistik wird angezeigt (Balkendiagramm).
  audience,

  /// Lumo-Fuchs gibt einen kindgerechten Hinweis.
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

  /// Eindeutige ID fuer Anti-Wiederholung.
  final String id;

  /// Die Frage-Text (kindgerecht formuliert).
  final String prompt;

  /// Genau 4 Antwort-Optionen.
  final List<String> options;

  /// Index 0-3, welche Option richtig ist.
  final int correctIndex;

  final QuizDifficulty difficulty;

  /// 'Mathe' / 'Deutsch' / 'Sachunterricht' / 'Mix'.
  final String subject;

  /// Optional: Erklaerung nach Antwort.
  final String? explanation;

  /// Optional: Hinweis fuer Lumo-Anruf-Joker.
  final String? hint;

  /// Liefert die richtige Antwort als String.
  String get correctAnswer => options[correctIndex];

  /// Validitaets-Check.
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
    this.earnedCoupons = const <QuizCoupon>[],
    this.gameOver = false,
    this.won = false,
    this.audienceVotes,
    this.lumoHint,
  });

  /// Alle 15 Fragen dieses Spiels.
  final List<QuizQuestion> questions;

  /// Aktuelle Frage (0-14).
  final int currentQuestionIndex;

  /// Vom Kind gewaehlte Option (null wenn noch nicht gewaehlt).
  final int? selectedOption;

  /// Ob die Aufloesung schon gezeigt wurde.
  final bool revealed;

  /// Welche Joker bereits verwendet wurden.
  final Set<QuizJoker> usedJokers;

  /// Bei 50:50-Joker: welche 2 Optionen versteckt sind.
  final Set<int> fiftyFiftyHiddenOptions;

  /// Bei Schwellen gesicherte Coupons.
  final List<QuizCoupon> earnedCoupons;

  /// Spiel zu Ende (entweder gewonnen oder verloren).
  final bool gameOver;

  /// Hat das Kind alle 15 Fragen geschafft?
  final bool won;

  /// Bei Publikum-Joker: Prozent-Verteilung [opt0, opt1, opt2, opt3].
  final List<int>? audienceVotes;

  /// Bei Lumo-Anruf-Joker: aktueller Hinweis-Text.
  final String? lumoHint;

  /// Aktuelle Frage als bequeme Property.
  QuizQuestion get currentQuestion => questions[currentQuestionIndex];

  /// Frage-Nummer fuer UI (1-15).
  int get displayQuestionNumber => currentQuestionIndex + 1;

  /// Wie viele Joker noch verfuegbar.
  int get remainingJokers => QuizJoker.values.length - usedJokers.length;

  QuizShowState copyWith({
    List<QuizQuestion>? questions,
    int? currentQuestionIndex,
    int? selectedOption,
    bool? revealed,
    Set<QuizJoker>? usedJokers,
    Set<int>? fiftyFiftyHiddenOptions,
    List<QuizCoupon>? earnedCoupons,
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
      fiftyFiftyHiddenOptions: clearFiftyFifty ? const <int>{} : (fiftyFiftyHiddenOptions ?? this.fiftyFiftyHiddenOptions),
      earnedCoupons: earnedCoupons ?? this.earnedCoupons,
      gameOver: gameOver ?? this.gameOver,
      won: won ?? this.won,
      audienceVotes: clearAudience ? null : (audienceVotes ?? this.audienceVotes),
      lumoHint: clearLumoHint ? null : (lumoHint ?? this.lumoHint),
    );
  }
}

/// Engine fuer das Quiz-Spiel. Stateless, deterministisch.
///
/// CODEX: Implementiere die untenstehenden Methoden.
class QuizShowEngine {
  const QuizShowEngine();

  /// Die Frage-Indizes (0-indexed) NACH denen eine Schwelle gesichert wird.
  /// Frage 5 = Index 4, Frage 10 = Index 9, Frage 15 = Index 14.
  static const List<int> safeSpotsAfterIndex = <int>[4, 9, 14];

  /// Startet ein neues Spiel mit 15 vorab generierten Fragen.
  ///
  /// CODEX TODO: Pruefe dass questions.length == 15 und alle Fragen valid sind.
  /// Wirft assertion bei Fehler.
  QuizShowState start({required List<QuizQuestion> questions}) {
    assert(questions.length == 15, 'Quiz braucht GENAU 15 Fragen, bekam ${questions.length}');
    assert(questions.every((q) => q.isValid), 'Mindestens eine Frage ist invalid');
    return QuizShowState(questions: questions);
  }

  /// Kind waehlt eine Antwort-Option.
  /// Wenn bereits revealed: ignoriert.
  ///
  /// CODEX TODO: implementiere
  QuizShowState selectAnswer(QuizShowState s, int optionIndex) {
    if (s.revealed || s.gameOver) return s;
    if (optionIndex < 0 || optionIndex > 3) return s;
    if (s.fiftyFiftyHiddenOptions.contains(optionIndex)) return s; // versteckte Option
    return s.copyWith(selectedOption: optionIndex);
  }

  /// Aufloesung der gewaehlten Antwort.
  ///
  /// CODEX TODO:
  /// - Wenn richtig: revealed = true, gameOver bleibt false
  /// - Wenn richtig UND aktueller Index ist Schwelle: Coupon ergaenzen
  /// - Wenn richtig UND Index 14: won = true, gameOver = true
  /// - Wenn falsch: revealed = true, gameOver = true, won = false
  QuizShowState reveal(QuizShowState s, {required QuizCoupon Function(int milestoneLevel) drawCouponForMilestone}) {
    throw UnimplementedError('CODEX: implementiere reveal()');
  }

  /// Weiter zur naechsten Frage. Reset selection, fiftyFifty, audience, lumoHint.
  ///
  /// CODEX TODO:
  /// - Wenn currentQuestionIndex < 14: increment + clear runde-spezifische felder
  /// - Wenn currentQuestionIndex == 14: nichts tun (Spiel ist eh schon zu Ende)
  QuizShowState nextQuestion(QuizShowState s) {
    throw UnimplementedError('CODEX: implementiere nextQuestion()');
  }

  /// Joker einsetzen.
  ///
  /// CODEX TODO:
  /// - 50:50: zufaellig 2 falsche Optionen versteckt setzen
  /// - audience: zufaellige Verteilung wo richtige Option 60-85% bekommt
  /// - callLumo: Hint aus current question oder generic anzeigen
  /// - Setze usedJokers
  /// - Wenn Joker schon used: return s unchanged
  QuizShowState useJoker(QuizShowState s, QuizJoker joker) {
    throw UnimplementedError('CODEX: implementiere useJoker()');
  }

  /// Gibt zurueck welcher Coupon-Tier nach diesem Frage-Index gesichert wird.
  /// Returns 0 wenn keine Schwelle.
  int safeSpotTierForIndex(int questionIndex) {
    if (questionIndex == 4) return 1;   // kleine
    if (questionIndex == 9) return 2;   // mittlere
    if (questionIndex == 14) return 3;  // grosse
    return 0;
  }

  /// True wenn der aktuelle Frage-Index eine Schwelle ist.
  bool isAtSafeSpot(int questionIndex) => safeSpotTierForIndex(questionIndex) > 0;
}
