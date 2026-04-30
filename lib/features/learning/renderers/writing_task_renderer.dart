import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/writing/expanded_writing_template_repository.dart';
import '../../../domain/writing/writing_domain.dart';
import '../widgets/lumo_writing_canvas.dart';

class WritingTaskResult {
  const WritingTaskResult({
    required this.task,
    required this.evaluation,
    required this.strokes,
  });

  final TaskInstance task;
  final WritingEvaluation evaluation;
  final List<Stroke> strokes;
}

class WritingTaskRenderer extends StatefulWidget {
  const WritingTaskRenderer({
    super.key,
    required this.task,
    this.onSubmitted,
  });

  final TaskInstance task;
  final ValueChanged<WritingTaskResult>? onSubmitted;

  @override
  State<WritingTaskRenderer> createState() => _WritingTaskRendererState();
}

class _WritingTaskRendererState extends State<WritingTaskRenderer> {
  final _templates = const ExpandedWritingTemplateRepository();
  List<Stroke> _strokes = const <Stroke>[];
  WritingEvaluation? _evaluation;

  String get _symbol {
    final raw = widget.task.visualPayload.data['symbol'] ?? widget.task.parameters['symbol'];
    return raw?.toString() ?? 'A';
  }

  @override
  Widget build(BuildContext context) {
    final template = _templates.findOrFallback(_symbol);
    final evaluation = _evaluation;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: lumoCard(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4BD), Color(0xFFFFF8DC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Schreibaufgabe',
            style: LumoTextStyles.label.copyWith(color: LumoColors.orange, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ziel: ${template.symbol}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: LumoColors.orange,
            ),
          ),
          const SizedBox(height: 16),
          LumoWritingCanvas(
            template: template,
            mode: widget.task.helpPayload.level >= 2 ? WritingMode.guided : WritingMode.trace,
            onChanged: (strokes) => _strokes = strokes,
            onEvaluated: (next) => setState(() => _evaluation = next),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      if (evaluation != null) _WritingFeedbackCard(evaluation: evaluation),
      const SizedBox(height: 14),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: evaluation == null
              ? null
              : () {
                  widget.onSubmitted?.call(
                    WritingTaskResult(
                      task: widget.task,
                      evaluation: evaluation,
                      strokes: List<Stroke>.unmodifiable(_strokes),
                    ),
                  );
                },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: evaluation == null ? .45 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                boxShadow: LumoShadow.pill,
              ),
              child: const Text(
                'Fertig',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _WritingFeedbackCard extends StatelessWidget {
  const _WritingFeedbackCard({required this.evaluation});

  final WritingEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final scorePercent = (evaluation.overallScore * 100).round();
    final primaryHint = evaluation.hints.isEmpty
        ? 'Gut gemacht.'
        : evaluation.hints.first.message;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: lumoCard(
        gradient: LinearGradient(
          colors: evaluation.overallScore >= .70
              ? [const Color(0xFFDCFCE7), const Color(0xFFF0FFF4)]
              : [const Color(0xFFFFF7ED), const Color(0xFFFFFBEB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
            evaluation.overallScore >= .70 ? Icons.check_circle_rounded : Icons.tips_and_updates_rounded,
            color: evaluation.overallScore >= .70 ? const Color(0xFF22C55E) : LumoColors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Zeichenqualitaet $scorePercent%',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: LumoColors.ink900,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          primaryHint,
          style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          child: LinearProgressIndicator(
            value: evaluation.overallScore.clamp(0.0, 1.0),
            minHeight: 8,
            color: evaluation.overallScore >= .70 ? const Color(0xFF22C55E) : LumoColors.orange,
            backgroundColor: LumoColors.orange.withOpacity(.14),
          ),
        ),
      ]),
    );
  }
}
