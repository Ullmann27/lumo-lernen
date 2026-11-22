import 'package:flutter/material.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import 'guided_number_line.dart';
import 'guided_product_array.dart';

/// Uses the verified operands from the current task after the child requests help.
class ArithmeticTaskAid extends StatelessWidget {
  const ArithmeticTaskAid(
      {super.key, required this.task, required this.reduceMotion});
  final TaskInstance task;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    if (task.subject != LearningSubject.mathematik) {
      return const SizedBox.shrink();
    }
    final data = task.visualPayload.data;
    final a = data['left'], b = data['right'];
    if (a is! int || b is! int || a < 0 || b < 0) {
      return const SizedBox.shrink();
    }
    final expected = int.tryParse('${task.correctAnswer}'.trim());
    if (data['operation'] == 'multiplication' &&
        a > 0 &&
        b > 0 &&
        a <= 10 &&
        b <= 10 &&
        a * b == expected) {
      return GuidedProductArray(
          key: ValueKey(task.taskInstanceId),
          rows: a,
          columns: b,
          practice: true,
          reduceMotion: reduceMotion);
    }
    final change = switch (data['operation']) {
      'addition' when a + b <= 20 => b,
      'subtraction' when a <= 20 && a - b >= 0 => -b,
      _ => 0,
    };
    if (change == 0 || a + change != expected) return const SizedBox.shrink();
    return GuidedNumberLine(
        key: ValueKey(task.taskInstanceId),
        start: a,
        change: change,
        reduceMotion: reduceMotion);
  }
}
