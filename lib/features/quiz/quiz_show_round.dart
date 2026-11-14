import 'dart:async';
import 'dart:convert';
import 'dart:math';

import '../../domain/quiz/quiz_show.dart';

/// The existing quiz engine is the only authority for answers, jokers and stars.
/// A save contains its question set and a bounded history, never renderer results.
class QuizRound {
  QuizRound({
    required this.owner,
    required this.id,
    required this.grade,
    required this.seed,
    required this.subject,
    required this.revision,
    required List<QuizQuestion> questions,
    required List<Map<String, Object?>> actions,
    this.rewarded = false,
  }) : questions = List.unmodifiable(
         questions.map(
           (q) => QuizQuestion(
             id: q.id,
             prompt: q.prompt,
             options: List.unmodifiable(q.options),
             correctIndex: q.correctIndex,
             difficulty: q.difficulty,
             subject: q.subject,
             explanation: q.explanation,
             hint: q.hint,
           ),
         ),
       ),
       actions = List.unmodifiable(
         actions.map(Map<String, Object?>.unmodifiable),
       );

  static const subjects = {'alle', 'Deutsch', 'Mathe', 'Sachunterricht'};
  final String owner, id, subject;
  final int grade, seed, revision;
  final List<QuizQuestion> questions;
  final List<Map<String, Object?>> actions;
  final bool rewarded;

  static String newId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static QuizShowState apply(QuizShowState state, Map<String, Object?> action) {
    const engine = QuizShowEngine();
    switch (action['action']) {
      case 'select':
        if (action.length != 2 || action['option'] is! int) return state;
        final option = action['option'] as int;
        if (option == state.selectedOption) return state;
        return engine.selectAnswer(state, option);
      case 'reveal':
        return action.length == 1 ? engine.reveal(state) : state;
      case 'next':
        return action.length == 1 ? engine.nextQuestion(state) : state;
      case 'joker':
        if (action.length != 2 ||
            !QuizJoker.values.any((j) => j.name == action['joker']))
          return state;
        return engine.useJoker(
          state,
          QuizJoker.values.firstWhere((j) => j.name == action['joker']),
        );
      default:
        return state;
    }
  }

  QuizShowState replay() {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        !RegExp(r'^[a-f0-9]{32}$').hasMatch(id) ||
        grade < 1 ||
        grade > 4 ||
        seed < 0 ||
        seed > 0x7fffffff ||
        revision < 1 ||
        revision > 1000000000 ||
        !subjects.contains(subject) ||
        questions.length != 20 ||
        questions.map((q) => q.id).toSet().length != 20 ||
        questions.any(
          (q) =>
              !q.isValid ||
              q.id.isEmpty ||
              q.id.length > 160 ||
              q.prompt.length > 1200 ||
              q.options.any((x) => x.length > 400) ||
              (q.explanation?.length ?? 0) > 2000 ||
              (q.hint?.length ?? 0) > 1000 ||
              !{
                'Deutsch',
                'Mathe',
                'Sachunterricht',
                'Logik-Finale',
              }.contains(q.subject),
        ) ||
        actions.length > 100) {
      throw const FormatException('Ungültige Quizrunde');
    }
    var state = const QuizShowEngine().start(questions: questions);
    for (final action in actions) {
      final next = apply(state, action);
      if (identical(next, state)) {
        throw const FormatException('Ungültige Quiz-Zugfolge');
      }
      state = next;
    }
    if (rewarded && !state.gameOver) {
      throw const FormatException('Unfertige Quizrunde mit Belohnung');
    }
    return state;
  }

  Map<String, Object?> toJson() => {
    'schema': 1,
    'owner': owner,
    'id': id,
    'grade': grade,
    'seed': seed,
    'subject': subject,
    'revision': revision,
    'rewarded': rewarded,
    'questions': [
      for (final q in questions)
        {
          'id': q.id,
          'prompt': q.prompt,
          'options': q.options,
          'correctIndex': q.correctIndex,
          'difficulty': q.difficulty.name,
          'subject': q.subject,
          'explanation': q.explanation,
          'hint': q.hint,
        },
    ],
    'actions': actions,
  };

  factory QuizRound.decode(String source, String expectedOwner) {
    if (source.length > 65536) throw const FormatException('Quizrunde zu groß');
    final raw = jsonDecode(source);
    const keys = {
      'schema',
      'owner',
      'id',
      'grade',
      'seed',
      'subject',
      'revision',
      'rewarded',
      'questions',
      'actions',
    };
    if (raw is! Map<String, dynamic> ||
        raw.length != keys.length ||
        raw.keys.any((k) => !keys.contains(k)) ||
        raw['schema'] != 1 ||
        raw['schema'] is! int ||
        raw['owner'] != expectedOwner ||
        raw['id'] is! String ||
        raw['grade'] is! int ||
        raw['seed'] is! int ||
        raw['revision'] is! int ||
        raw['subject'] is! String ||
        raw['rewarded'] is! bool ||
        raw['questions'] is! List ||
        raw['actions'] is! List) {
      throw const FormatException('Ungültiger Quizspeicher');
    }
    final questions = <QuizQuestion>[];
    const qKeys = {
      'id',
      'prompt',
      'options',
      'correctIndex',
      'difficulty',
      'subject',
      'explanation',
      'hint',
    };
    for (final q in raw['questions'] as List) {
      if (q is! Map ||
          q.length != qKeys.length ||
          q.keys.any((k) => !qKeys.contains(k)) ||
          q['id'] is! String ||
          q['prompt'] is! String ||
          q['subject'] is! String ||
          q['options'] is! List ||
          (q['options'] as List).any((x) => x is! String) ||
          q['correctIndex'] is! int ||
          !QuizDifficulty.values.any((d) => d.name == q['difficulty']) ||
          (q['explanation'] != null && q['explanation'] is! String) ||
          (q['hint'] != null && q['hint'] is! String)) {
        throw const FormatException('Ungültige gespeicherte Frage');
      }
      questions.add(
        QuizQuestion(
          id: q['id'] as String,
          prompt: q['prompt'] as String,
          options: List<String>.from(q['options'] as List),
          correctIndex: q['correctIndex'] as int,
          difficulty: QuizDifficulty.values.firstWhere(
            (d) => d.name == q['difficulty'],
          ),
          subject: q['subject'] as String,
          explanation: q['explanation'] as String?,
          hint: q['hint'] as String?,
        ),
      );
    }
    final actions = <Map<String, Object?>>[];
    for (final action in raw['actions'] as List) {
      if (action is! Map<String, dynamic>) {
        throw const FormatException('Ungültiger gespeicherter Quiz-Zug');
      }
      actions.add(Map<String, Object?>.from(action));
    }
    final result = QuizRound(
      owner: expectedOwner,
      id: raw['id'] as String,
      grade: raw['grade'] as int,
      seed: raw['seed'] as int,
      subject: raw['subject'] as String,
      revision: raw['revision'] as int,
      rewarded: raw['rewarded'] as bool,
      questions: questions,
      actions: actions,
    );
    result.replay();
    return result;
  }

  QuizRound append(Map<String, Object?> action) {
    final history = [...actions];
    // Changing a provisional selection has no side effects; retain its latest
    // value so a child can reconsider freely without an unbounded save file.
    if (action['action'] == 'select' &&
        history.isNotEmpty &&
        history.last['action'] == 'select')
      history.removeLast();
    history.add(action);
    return QuizRound(
      owner: owner,
      id: id,
      grade: grade,
      seed: seed,
      subject: subject,
      revision: revision + 1,
      questions: questions,
      actions: history,
      rewarded: rewarded,
    );
  }

  QuizRound rewardAcknowledged() => QuizRound(
    owner: owner,
    id: id,
    grade: grade,
    seed: seed,
    subject: subject,
    revision: revision + 1,
    questions: questions,
    actions: actions,
    rewarded: true,
  );
}

abstract interface class QuizRoundStore {
  Future<QuizRound?> load(String owner, bool Function() current);
  Future<void> save(
    QuizRound next,
    QuizRound? previous,
    bool Function() current,
  );
}

typedef QuizQuestionFactory =
    List<QuizQuestion> Function(String subject, int seed);
typedef QuizAward = Future<void> Function(String id, int stars);

/// Shared by the existing Flutter controls and the native studio. It writes
/// before updating either presentation and uses the existing wallet's result ID.
class QuizRoundController {
  QuizRoundController._(
    this._round,
    this.store,
    this.canUseProfile,
    this.award,
    this.makeQuestions,
    this.newRoundGrade,
  ) : _state = _round.replay();
  final QuizRoundStore store;
  final bool Function() canUseProfile;
  final QuizAward award;
  final QuizQuestionFactory makeQuestions;
  final int newRoundGrade;
  QuizRound _round;
  QuizShowState _state;
  QuizRound get round => _round;
  QuizShowState get state => _state;
  bool _closed = false, _needsReload = false;
  final Set<void Function()> _listeners = {};
  Future<void> _tail = Future.value();

  static Future<QuizRoundController> open({
    required String owner,
    required int grade,
    required QuizRoundStore store,
    required bool Function() canUseProfile,
    required QuizAward award,
    required QuizQuestionFactory makeQuestions,
    int? seed,
  }) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(owner) ||
        grade < 1 ||
        grade > 4 ||
        (seed != null && (seed < 0 || seed > 0x7fffffff))) {
      throw ArgumentError('Ungültige Quizidentität');
    }
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    var round = await store.load(owner, canUseProfile);
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    if (round == null) {
      final initialSeed = seed ?? Random.secure().nextInt(0x7fffffff);
      round = QuizRound(
        owner: owner,
        id: QuizRound.newId(),
        grade: grade,
        seed: initialSeed,
        subject: 'alle',
        revision: 1,
        questions: makeQuestions('alle', initialSeed),
        actions: const [],
      );
      round.replay();
      await store.save(round, null, canUseProfile);
    }
    if (!canUseProfile()) throw StateError('Kinderprofil hat gewechselt');
    final result = QuizRoundController._(
      round,
      store,
      canUseProfile,
      award,
      makeQuestions,
      grade,
    );
    await result.settleReward();
    return result;
  }

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);
  void _notify() {
    if (_closed) return;
    for (final listener in _listeners.toList()) {
      if (_listeners.contains(listener)) listener();
    }
  }

  void _guard() {
    if (_closed || !canUseProfile())
      throw StateError('Kinderprofil hat gewechselt');
  }

  Future<void> _recover() async {
    if (!_needsReload) return;
    final latest = await store.load(
      _round.owner,
      () => !_closed && canUseProfile(),
    );
    _guard();
    if (latest == null)
      throw StateError('Gespeicherte Runde ist nicht verfügbar');
    _state = latest.replay();
    _round = latest;
    _needsReload = false;
    _notify();
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) async {
      _guard();
      await _recover();
      return action();
    });
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _commit(QuizRound next) async {
    _guard();
    final state = next.replay();
    try {
      await store.save(next, _round, () => !_closed && canUseProfile());
    } catch (_) {
      _needsReload = true;
      rethrow;
    }
    _guard();
    _round = next;
    _state = state;
    _notify();
  }

  Future<bool> act(Map<String, Object?> action) => _serial(() async {
    final next = QuizRound.apply(_state, action);
    if (identical(next, _state)) return false;
    await _commit(_round.append(action));
    await _settleReward();
    return true;
  });
  Future<bool> select(int option) =>
      act({'action': 'select', 'option': option});
  Future<bool> reveal() => act({'action': 'reveal'});
  Future<bool> next() => act({'action': 'next'});
  Future<bool> joker(QuizJoker joker) =>
      act({'action': 'joker', 'joker': joker.name});

  Future<void> restart({String? subject, int? seed}) =>
      _serial(() async {
        final selected = subject ?? _round.subject;
        final nextSeed = seed ?? Random.secure().nextInt(0x7fffffff);
        if (!QuizRound.subjects.contains(selected) ||
            nextSeed < 0 ||
            nextSeed > 0x7fffffff) {
          throw ArgumentError('Ungültige Quizwahl');
        }
        await _settleReward();
        await _commit(
          QuizRound(
            owner: _round.owner,
            id: QuizRound.newId(),
            grade: newRoundGrade,
            seed: nextSeed,
            subject: selected,
            revision: _round.revision + 1,
            questions: makeQuestions(selected, nextSeed),
            actions: const [],
          ),
        );
      });

  Future<void> settleReward() => _serial(_settleReward);
  Future<void> _settleReward() async {
    if (!_state.gameOver || _round.rewarded) return;
    _guard();
    // Zero-star losses also receive a durable round ACK, without a wallet write.
    if (_state.awardedStars > 0) {
      await award('quiz:${_round.owner}:${_round.id}', _state.awardedStars);
      _guard();
    }
    await _commit(_round.rewardAcknowledged());
  }

  void dispose() {
    _closed = true;
    _listeners.clear();
  }
}
