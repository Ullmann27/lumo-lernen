import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../widgets/lumo_shape_trace_canvas.dart';

/// 2026-06-05 Iter 20: Renderer fuer ShapeTrace-Aufgaben.
/// Liest die Form aus task.parameters['shape'] (faellt sonst auf
/// die Antwort als Fallback zurueck) und reicht das Canvas-Result
/// nach oben durch.

class ShapeTraceTaskResult {
  const ShapeTraceTaskResult({
    required this.task,
    required this.correct,
    required this.shape,
    required this.feedback,
  });
  final TaskInstance task;
  final bool correct;
  final String shape;
  final String feedback;
}

class ShapeTraceTaskRenderer extends StatelessWidget {
  const ShapeTraceTaskRenderer({
    super.key,
    required this.task,
    this.onSubmitted,
  });

  final TaskInstance task;
  final ValueChanged<ShapeTraceTaskResult>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final shape = _shapeFrom(task);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: lumoCard(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF8ED), Color(0xFFFFFEFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Mathematik · Geometrie',
            style: LumoTextStyles.label
                .copyWith(color: LumoColors.orange, fontSize: 13),
          ),
          const SizedBox(height: 10),
          Text(
            task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          LumoShapeTraceCanvas(
            shape: shape,
            onSubmitted: (r) => onSubmitted?.call(
              ShapeTraceTaskResult(
                task: task,
                correct: r.correct,
                shape: r.shape,
                feedback: r.feedback,
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  String _shapeFrom(TaskInstance t) {
    final raw = t.parameters['shape'];
    if (raw is String) return raw;
    final ans = '${t.correctAnswer}'.toLowerCase();
    return switch (ans) {
      'quadrat' => 'square',
      'rechteck' => 'rectangle',
      'kreis' => 'circle',
      'dreieck' => 'triangle',
      'stern' => 'star',
      _ => 'square',
    };
  }
}
