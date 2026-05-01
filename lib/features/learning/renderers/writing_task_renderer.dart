import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/writing_target_parser.dart';
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

  String get _target {
    final raw = widget.task.visualPayload.data['symbol'] ??
        widget.task.parameters['symbol'] ??
        WritingTargetParser.parse(widget.task.prompt);
    final value = raw?.toString().trim();
    return value == null || value.isEmpty ? 'A' : value;
  }

  bool get _isWordTarget {
    final target = _target.trim();
    if (RegExp(r'^\d{1,2}$').hasMatch(target)) return false;
    final lettersOnly = target.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '');
    return lettersOnly.length > 1;
  }

  WritingTemplate get _template {
    if (_isWordTarget) {
      return WritingTemplate(
        symbol: _target,
        grade: 1,
        viewBoxWidth: 100,
        viewBoxHeight: 100,
        strokes: const <WritingTemplateStroke>[],
      );
    }
    return _templates.findOrFallback(_target);
  }

  WritingMode get _mode {
    if (_isWordTarget) return WritingMode.free;
    return widget.task.helpPayload.level >= 2 ? WritingMode.guided : WritingMode.trace;
  }

  @override
  Widget build(BuildContext context) {
    final template = _template;
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
            _isWordTarget ? 'Schreibwort' : 'Schreibaufgabe',
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
            _isWordTarget
                ? 'Zielwort: ${template.symbol}'
                : 'Ziel: ${template.symbol}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: LumoColors.orange,
            ),
          ),
          if (_isWordTarget) ...[
            const SizedBox(height: 8),
            _WordTargetStrip(word: template.symbol),
            const SizedBox(height: 8),
            Text(
              'Schreibe das ganze Wort frei auf die Linien. Keine A-Vorlage wird angezeigt.',
              style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 16),
          LumoWritingCanvas(
            template: template,
            mode: _mode,
            onChanged: (strokes) => _strokes = strokes,
            onEvaluated: (next) => setState(() => _evaluation = next),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      if (evaluation != null) _WritingFeedbackCard(evaluation: evaluation, wordMode: _isWordTarget),
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

class _WordTargetStrip extends StatelessWidget {
  const _WordTargetStrip({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: letters
          .map((letter) => Container(
                width: 38,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LumoRadius.sm),
                  border: Border.all(color: LumoColors.orange.withOpacity(.28), width: 1.4),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: LumoColors.ink900,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _WritingFeedbackCard extends StatelessWidget {
  const _WritingFeedbackCard({required this.evaluation, this.wordMode = false});

  final WritingEvaluation evaluation;
  final bool wordMode;

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
              wordMode ? 'Wort geschrieben $scorePercent%' : 'Zeichenqualitaet $scorePercent%',
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
