import 'dart:math' as math;

/// Length, rounds and returning mistakes of one practice session.
///
/// Pure rules without Flutter, so they can be checked on their own.

/// Quick practice is short enough for the age: six tasks in grade 1, eight
/// in grade 2, ten in grades 3 and 4.
int quickPracticeLength(int grade) => grade <= 1
    ? 6
    : grade == 2
        ? 8
        : 10;

/// Long sessions (20 or 30 tasks) are presented in rounds of ten, each with
/// a real stopping point.
class SessionRounds {
  const SessionRounds._();

  static const int size = 10;

  static bool applies(int totalTasks) => totalTasks > size;

  static int count(int totalTasks) =>
      totalTasks <= 0 ? 1 : ((totalTasks - 1) ~/ size) + 1;

  /// 1-based round of the 1-based [question]. Tasks appended to the very end
  /// of a session (returning mistakes) stay in its last round.
  static int roundOf(int question, int totalTasks) =>
      math.min((math.max(question, 1) - 1) ~/ size + 1, count(totalTasks));

  /// True after the last task of a round that is not the last round.
  static bool endsRound(int question, int totalTasks) =>
      applies(totalTasks) && question % size == 0 && question < totalTasks;

  /// A saved position is only usable at a round boundary inside the session.
  static bool isResumable(int completedTasks, int totalTasks) =>
      applies(totalTasks) &&
      completedTasks > 0 &&
      completedTasks < totalTasks &&
      completedTasks % size == 0;
}

/// Mistakes that come back as a similar task ("Zwillingsaufgabe").
///
/// A task that was started wrong or solved together returns two tasks later
/// (three, if that place is already taken) as a new task of the same kind.
/// If the session would end before that, it grows by at most
/// [maxExtension] tasks. What still does not fit is left to the spaced
/// review of the following days.
class TwinTaskQueue<T> {
  static const int gap = 2;
  static const int maxExtension = 2;

  final List<({T source, int due})> _pending = <({T source, int due})>[];

  bool get isEmpty => _pending.isEmpty;
  int get length => _pending.length;

  void clear() => _pending.clear();

  /// Queues the mistake made at the 1-based [question].
  void schedule(T source, {required int question}) {
    var due = question + gap;
    while (_pending.any((entry) => entry.due == due)) {
      due++;
    }
    _pending
      ..add((source: source, due: due))
      ..sort((a, b) => a.due.compareTo(b.due));
  }

  /// Extra tasks a session of [baseTotal] tasks needs for the queue.
  int extensionFor(int baseTotal) {
    if (_pending.isEmpty) return 0;
    return (_pending.last.due - baseTotal).clamp(0, maxExtension);
  }

  /// The mistake whose twin belongs at [question], or null for a normal
  /// task. Close to the end ([lastQuestion]) waiting twins take the
  /// remaining places.
  T? takeFor(int question, {required int lastQuestion}) {
    if (_pending.isEmpty || question > lastQuestion) return null;
    final first = _pending.first;
    final remainingPlaces = lastQuestion - question + 1;
    if (first.due > question && _pending.length < remainingPlaces) return null;
    _pending.removeAt(0);
    return first.source;
  }
}
