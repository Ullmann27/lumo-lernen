import 'dart:math';
import 'package:flutter/foundation.dart';
import 'wwm_question_service.dart';

enum WwmStatus {
  loading,
  error,
  playing, // question displayed, waiting for selection
  selected, // answer chosen, reveal animation running (~1.5 s)
  correct, // correct answer confirmed
  wrong, // wrong answer confirmed
  finished, // all 15 questions answered correctly
  quit, // player chose to walk away
}

class WwmGameState extends ChangeNotifier {
  final WwmQuestionService _service;

  // XP awarded for each of the 15 questions (0-based index)
  static const List<int> _xpLadder = [
    10, 25, 50, 75, 100, //  Q1–Q5   (safe at index 4)
    150, 200, 250, 300, 400, //  Q6–Q10  (safe at index 9)
    500, 600, 700, 800, 1000, //  Q11–Q15
  ];

  // 0-based indices of safe checkpoints
  static const Set<int> _safeIndices = {4, 9};

  WwmStatus _status = WwmStatus.loading;
  List<WwmQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _joker5050Used = false;
  bool _jokerPhoneUsed = false;
  bool _jokerAudienceUsed = false;
  Set<int> _hiddenOptions = {};
  List<double> _audienceVotes = [];
  String? _phoneHint;
  bool _phoneHintLoading = false;
  int _securedXP = 0;
  String? _errorMessage;

  WwmGameState(this._service);

  // ── Getters ─────────────────────────────────────────────────────

  WwmStatus get status => _status;
  List<WwmQuestion> get questions => _questions;
  int get currentIndex => _currentIndex;
  int? get selectedIndex => _selectedIndex;
  bool get joker5050Used => _joker5050Used;
  bool get jokerPhoneUsed => _jokerPhoneUsed;
  bool get jokerAudienceUsed => _jokerAudienceUsed;
  Set<int> get hiddenOptions => Set.unmodifiable(_hiddenOptions);
  List<double> get audienceVotes => List.unmodifiable(_audienceVotes);
  String? get phoneHint => _phoneHint;
  bool get phoneHintLoading => _phoneHintLoading;
  int get securedXP => _securedXP;
  String? get errorMessage => _errorMessage;

  WwmQuestion? get currentQuestion =>
      _questions.isNotEmpty && _currentIndex < _questions.length
          ? _questions[_currentIndex]
          : null;

  /// XP milestone for the currently active question.
  int get currentXP =>
      _currentIndex < _xpLadder.length ? _xpLadder[_currentIndex] : 0;

  /// Whether the current question is a safe-level checkpoint.
  bool get isCurrentSafeLevel => _safeIndices.contains(_currentIndex);

  /// XP the player takes home depending on final status.
  int get earnedXP {
    switch (_status) {
      case WwmStatus.finished:
        return _xpLadder.last;
      case WwmStatus.wrong:
        return _securedXP;
      case WwmStatus.quit:
        if (_currentIndex == 0) return _securedXP;
        return max(_securedXP, _xpLadder[_currentIndex - 1]);
      default:
        return _securedXP;
    }
  }

  static List<int> get xpLadder => _xpLadder;
  static Set<int> get safeIndices => _safeIndices;

  // ── Actions ──────────────────────────────────────────────────────

  Future<void> startGame() async {
    _status = WwmStatus.loading;
    _questions = [];
    _currentIndex = 0;
    _selectedIndex = null;
    _joker5050Used = false;
    _jokerPhoneUsed = false;
    _jokerAudienceUsed = false;
    _hiddenOptions = {};
    _audienceVotes = [];
    _phoneHint = null;
    _phoneHintLoading = false;
    _securedXP = 0;
    _errorMessage = null;
    notifyListeners();

    try {
      _questions = await _service.loadQuestions();
      _status = WwmStatus.playing;
    } catch (e) {
      _status = WwmStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  void selectAnswer(int index) {
    if (_status != WwmStatus.playing) return;
    if (_hiddenOptions.contains(index)) return;
    _selectedIndex = index;
    _status = WwmStatus.selected;
    notifyListeners();
  }

  void confirmAnswer() {
    if (_status != WwmStatus.selected) return;
    final q = currentQuestion;
    if (q == null || _selectedIndex == null) return;
    if (_selectedIndex == q.correctIndex) {
      _status = WwmStatus.correct;
      // Lock in XP at safe-level checkpoints
      if (_safeIndices.contains(_currentIndex)) {
        _securedXP = _xpLadder[_currentIndex];
      }
    } else {
      _status = WwmStatus.wrong;
    }
    notifyListeners();
  }

  /// Advance to the next question after a correct answer.
  void advance() {
    if (_status != WwmStatus.correct) return;
    _currentIndex++;
    _selectedIndex = null;
    _hiddenOptions = {};
    _audienceVotes = [];
    _phoneHint = null;
    _phoneHintLoading = false;
    _status =
        _currentIndex >= _questions.length ? WwmStatus.finished : WwmStatus.playing;
    notifyListeners();
  }

  void quit() {
    if (_status != WwmStatus.playing && _status != WwmStatus.selected) return;
    _status = WwmStatus.quit;
    notifyListeners();
  }

  // ── Jokers ───────────────────────────────────────────────────────

  void useJoker5050() {
    if (_joker5050Used || _status != WwmStatus.playing) return;
    final q = currentQuestion;
    if (q == null) return;

    final rng = Random();
    final wrongOptions = List.generate(4, (i) => i)
        .where((i) => i != q.correctIndex)
        .toList()
      ..shuffle(rng);

    _hiddenOptions = {wrongOptions[0], wrongOptions[1]};
    _joker5050Used = true;
    notifyListeners();
  }

  Future<void> useJokerPhone() async {
    if (_jokerPhoneUsed || _status != WwmStatus.playing) return;
    final q = currentQuestion;
    if (q == null) return;

    _jokerPhoneUsed = true;
    _phoneHintLoading = true;
    _phoneHint = null;
    notifyListeners();

    final hint = await _service.getPhoneHint(q);
    _phoneHint = hint?.isNotEmpty == true
        ? hint!
        : 'Hmm, ich bin nicht ganz sicher... Aber denke an das, '
            'was du in der Schule gelernt hast! 🦊';
    _phoneHintLoading = false;
    notifyListeners();
  }

  void useJokerAudience() {
    if (_jokerAudienceUsed || _status != WwmStatus.playing) return;
    final q = currentQuestion;
    if (q == null) return;

    final rng = Random();
    // Correct answer gets 50–80 %, remainder distributed over 3 wrong options
    final correctShare = 50.0 + rng.nextDouble() * 30.0;
    final remaining = 100.0 - correctShare;

    // Two random cut points to split 'remaining' into 3 parts
    double c1 = rng.nextDouble() * remaining;
    double c2 = rng.nextDouble() * remaining;
    if (c1 > c2) {
      final tmp = c1;
      c1 = c2;
      c2 = tmp;
    }
    final wrongShares = [c1, c2 - c1, remaining - c2];

    final votes = List<double>.filled(4, 0.0);
    int wIdx = 0;
    for (int i = 0; i < 4; i++) {
      votes[i] = i == q.correctIndex ? correctShare : wrongShares[wIdx++];
    }

    _audienceVotes = votes;
    _jokerAudienceUsed = true;
    notifyListeners();
  }
}
