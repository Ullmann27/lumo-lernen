/// A renderer carries bounded intentions; the Dart controller owns the rules.
/// Keeping this boundary free of Flutter permits the real controllers to run
/// in ordinary Dart processes and lets a failed transport be tested directly.
abstract interface class NativeTableTransport {
  Future<void> open(String token, Map<String, Object?> state);
  Future<Map<String, dynamic>> poll(String token);
  Future<void> publish(String token, Map<String, Object?> state);
  Future<void> close(String token);
}
