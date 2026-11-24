import 'package:flutter/material.dart';
import '../../domain/learning/lumo_learning_domain.dart';
import 'guided_number_line.dart';
import 'guided_product_array.dart';
import 'guided_place_value_arithmetic.dart';

/// Uses the verified operands from the current task after the child requests help.
class ArithmeticTaskAid extends StatelessWidget {
  const ArithmeticTaskAid(
      {super.key, required this.task, required this.reduceMotion, this.showExtended = false});
  final TaskInstance task;
  final bool reduceMotion;
  final bool showExtended;

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
    final op = data['operation'];
    if (showExtended && a <= 100 && b > 0 && b <= 100 &&
        ((op == 'addition' && a + b == expected && a + b > 20 && a + b <= 100) ||
         (op == 'subtraction' && a > 20 && a - b == expected && a >= b))) {
      return GuidedPlaceValueArithmetic(
        key: ValueKey('place-value-${task.taskInstanceId}'),
        left: a,
        right: b,
        subtract: op == 'subtraction',
      );
    }
    final change = switch (op) {
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
