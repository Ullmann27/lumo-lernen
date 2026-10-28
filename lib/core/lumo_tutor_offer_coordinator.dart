/// Deterministic, offline tutoring invitation policy for a single lesson.
///
/// Never infers a learning disability or interrupts a child after one mistake.
/// Every scope includes the current child and real task ID; questions and
/// profiles cannot inherit a declined or accepted offer from another task.
/// This policy does not speak, show answers, call a network or persist data.
class LumoTutorOfferCoordinator {
  static const int mistakesBeforeOffer = 2;

  String? _scope;
  int _mistakes = 0;
  bool _offered = false;
  bool _resolved = false;

  bool get shouldOffer => _offered && !_resolved;
  int get mistakesInTask => _mistakes;

  void reset() {
    _scope = null;
    _mistakes = 0;
    _offered = false;
    _resolved = false;
  }

  /// Return whether the optional invitation should be shown.
  bool recordAnswer({
    required String childId,
    required String taskId,
    required bool correct,
    required bool canOfferHelp,
  }) {
    if (childId.trim().isEmpty || taskId.trim().isEmpty) {
      reset();
      return false;
    }
    final scope = '$childId|$taskId';
    if (_scope != scope) {
      reset();
      _scope = scope;
    }
    // Tests, schoolwork, completed answers and inaccessible help never
    // surface an invitation (and cannot leak a previous one).
    if (correct || !canOfferHelp) {
      _offered = false;
      _resolved = true;
      return false;
    }
    _mistakes++;
    if (_mistakes >= mistakesBeforeOffer && !_resolved) {
      _offered = true;
    }
    return shouldOffer;
  }

  /// Either choice is final for this task; a fresh task can invite again.
  void accept() {
    _offered = false;
    _resolved = true;
  }

  void decline() {
    _offered = false;
    _resolved = true;
  }
}
