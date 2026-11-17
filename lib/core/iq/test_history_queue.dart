import 'dart:async';

/// Serializes read/modify/write operations across repository instances.
/// A failed write does not block a later explicit retry.
abstract final class TestHistoryQueue {
  static final Map<String, Future<void>> _pending = {};

  static Future<T> run<T>(String key, Future<T> Function() action) {
    final previous = _pending[key] ?? Future<void>.value();
    final result = previous.then((_) => action());
    final completed =
        result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    _pending[key] = completed;
    unawaited(completed.then((_) {
      if (identical(_pending[key], completed)) _pending.remove(key);
    }));
    return result;
  }
}
