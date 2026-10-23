import 'dart:math';

/// Opaque identity for a newly presented or accepted local learning attempt.
/// Create once and keep it with the task/pending save through every retry.
String newLearningAttemptId() {
  final random = Random.secure();
  return 'attempt-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
}
