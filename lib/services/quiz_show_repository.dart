/// Tracks which quiz questions have already been shown to the player.
///
/// The bank consults [seenIds] to prefer unseen questions. When a subject pool
/// is exhausted, the caller falls back to the full pool so the game never
/// stalls.
class QuizShowRepository {
  /// IDs of all questions seen across previous game sessions.
  final Set<String> seenIds = {};

  /// Records [ids] as seen.
  void markSeen(Iterable<String> ids) => seenIds.addAll(ids);

  /// Returns true if [id] has been seen before.
  bool hasSeen(String id) => seenIds.contains(id);

  /// Clears the full history (e.g. when resetting the game).
  void clearHistory() => seenIds.clear();

  /// Number of unique questions seen so far.
  int get seenCount => seenIds.length;
}
