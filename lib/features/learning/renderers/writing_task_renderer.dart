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
  List<Stroke> _strokes = <Stroke>[];
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
          // Statt inline-Canvas: Tipp-Karte die ein Vollbild-Modal oeffnet.
          // Verhindert den Scroll-Konflikt: im Modal gibt es keinen Scroll
          // dahinter, das Kind kann frei zeichnen.
          _CanvasLaunchCard(
            template: template,
            mode: _mode,
            existingStrokes: _strokes,
            onResult: (strokes, evaluation) {
              if (!mounted) return;
              setState(() {
                _strokes = strokes;
                _evaluation = evaluation;
              });
            },
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

/// Tipp-Karte die ein Vollbild-Schreib-Modal oeffnet.
/// Loest den Scroll-Konflikt: solange das Modal offen ist, gibt es
/// keinen Scroll dahinter, das Kind kann frei zeichnen - horizontal
/// wie vertikal - ohne dass der Bildschirm wegspringt.
class _CanvasLaunchCard extends StatelessWidget {
  const _CanvasLaunchCard({
    required this.template,
    required this.mode,
    required this.existingStrokes,
    required this.onResult,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final List<Stroke> existingStrokes;
  final void Function(List<Stroke> strokes, WritingEvaluation? evaluation) onResult;

  @override
  Widget build(BuildContext context) {
    final hasStrokes = existingStrokes.isNotEmpty;
    return GestureDetector(
      onTap: () => _openModal(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasStrokes
                ? const [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
                : const [Color(0xFFFFF8DC), Color(0xFFFFE08A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(
            color: hasStrokes ? const Color(0xFF22C55E) : LumoColors.orange,
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: (hasStrokes ? const Color(0xFF22C55E) : LumoColors.orange).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF7A2F).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                hasStrokes ? '✏️' : '✋',
                style: const TextStyle(fontSize: 28, height: 1.0),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasStrokes ? 'Schreiben fertig?' : 'Hier tippen zum Schreiben',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: LumoColors.ink900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasStrokes
                        ? 'Antippen um nachzubessern oder zu bestätigen.'
                        : 'Großer Mal-Bildschirm öffnet sich.',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LumoColors.ink500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: LumoColors.orange, size: 28),
          ],
        ),
      ),
    );
  }

  Future<void> _openModal(BuildContext context) async {
    final result = await Navigator.of(context).push<_WritingModalResult>(
      MaterialPageRoute<_WritingModalResult>(
        fullscreenDialog: true,
        builder: (_) => _WritingFullscreenModal(
          template: template,
          mode: mode,
          initialStrokes: existingStrokes,
        ),
      ),
    );
    if (result != null) {
      onResult(result.strokes, result.evaluation);
    }
  }
}

class _WritingModalResult {
  const _WritingModalResult({required this.strokes, required this.evaluation});
  final List<Stroke> strokes;
  final WritingEvaluation? evaluation;
}

/// Vollbild-Schreib-Modal.
/// Kein Scroll dahinter, also keine Konflikte mit Pan-Gesten.
/// Das Kind kann frei in beide Richtungen zeichnen.
class _WritingFullscreenModal extends StatefulWidget {
  const _WritingFullscreenModal({
    required this.template,
    required this.mode,
    required this.initialStrokes,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final List<Stroke> initialStrokes;

  @override
  State<_WritingFullscreenModal> createState() => _WritingFullscreenModalState();
}

class _WritingFullscreenModalState extends State<_WritingFullscreenModal> {
  List<Stroke> _strokes = <Stroke>[];
  WritingEvaluation? _evaluation;

  @override
  void initState() {
    super.initState();
    _strokes = List<Stroke>.from(widget.initialStrokes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: AppBar(
        backgroundColor: LumoColors.orange,
        foregroundColor: Colors.white,
        title: Text(
          'Schreibe: ${widget.template.symbol}',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop<_WritingModalResult>(
              _WritingModalResult(strokes: _strokes, evaluation: _evaluation),
            ),
            child: const Text(
              'Fertig',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                  border: Border.all(color: LumoColors.orange.withOpacity(0.4), width: 1.4),
                ),
                child: Row(
                  children: [
                    const Text('✏️', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Schreibe "${widget.template.symbol}". Du kannst frei zeichnen, der Bildschirm bewegt sich nicht mehr.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LumoColors.ink700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Canvas mit grossem Bereich. Keine Scroll-Konflikte mehr,
              // weil das Modal keinen aeusseren Scroll hat.
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final available = constraints.maxHeight.isFinite
                        ? constraints.maxHeight
                        : 460.0;
                    // 70px Puffer fuer Zurueck/Neustart-Buttons + Spacer
                    final canvasHeight = (available - 70).clamp(220.0, 1200.0);
                    return LumoWritingCanvas(
                      template: widget.template,
                      mode: widget.mode,
                      height: canvasHeight,
                      // Bewusst kein setState: _strokes und _evaluation werden
                      // nicht im build() verwendet (nur beim Pop). Ein setState
                      // bei jedem Stroke wuerde das ganze Modal neu layouten
                      // und das Canvas-Feld koennte dabei sichtbar springen.
                      onChanged: (strokes) => _strokes = strokes,
                      onEvaluated: (next) => _evaluation = next,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
