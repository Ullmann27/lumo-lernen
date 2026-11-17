import 'dart:convert';

import '../../core/legacy_learning_data.dart';
import 'quiz_show_round.dart';

/// New per-child namespace. Existing profile, quiz and wallet keys are preserved.
class QuizRoundRepository implements QuizRoundStore {
  static String key(String owner) => 'lumo.quiz.round.v1.$owner';

  @override
  Future<QuizRound?> load(String owner, bool Function() current) =>
      LearningStorage.run((prefs) async {
        if (!current()) throw StateError('Kinderprofil hat gewechselt');
        final value = prefs.getString(key(owner));
        return value == null ? null : QuizRound.decode(value, owner);
      });

  @override
  Future<void> save(
    QuizRound next,
    QuizRound? previous,
    bool Function() current,
  ) => LearningStorage.run((prefs) async {
    if (!current()) throw StateError('Kinderprofil hat gewechselt');
    final raw = prefs.getString(key(next.owner));
    if ((previous == null && raw != null) ||
        (previous != null && raw != jsonEncode(previous.toJson()))) {
      throw StateError('Eine neuere Quizrunde ist bereits gespeichert');
    }
    next.replay();
    if (!current()) throw StateError('Kinderprofil hat gewechselt');
    await LearningStorage.write(
      prefs,
      key(next.owner),
      jsonEncode(next.toJson()),
    );
    if (!current()) throw StateError('Kinderprofil hat gewechselt');
  });
}
