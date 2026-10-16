import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/writing_target_parser.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../domain/writing/expanded_writing_template_repository.dart';
import '../../../domain/writing/writing_domain.dart';
import '../widgets/lumo_writing_canvas.dart';

class WritingTaskResult {
  const WritingTaskResult({
    required this.task,
    required this.evaluation,
    required this.strokes,
    this.graded = true,
    this.typedAnswer,
    this.skipped = false,
  });

  final TaskInstance task;
  final WritingEvaluation evaluation;
  final List<Stroke> strokes;
  final bool graded;

  /// Keyboard writing checks spelling without pretending a stylus score.
  final String? typedAnswer;
  final bool skipped;
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
  bool _submitted = false;
  final TextEditingController _typedController = TextEditingController();

  // Placeholder only for the result transport. Typed answers bypass
  // stroke evaluation entirely in LearningContent._answerWriting.
  static const WritingEvaluation _typedTransport = WritingEvaluation(
    overallScore: 0,
    startPointScore: 0,
    directionScore: 0,
    coverageScore: 0,
    pathDistanceScore: 0,
    strokeOrderScore: 0,
    mirrored: false,
    incomplete: false,
    hints: <WritingHint>[],
  );

  @override
  void dispose() {
    _typedController.dispose();
    super.dispose();
  }

  String get _target {
    // A blank symbol may be present in imported task payloads. Do not let
    // it suppress the real letter present in the prompt, or invent 'A'.
    for (final raw in <Object?>[
      widget.task.visualPayload.data['symbol'],
      widget.task.parameters['symbol'],
      WritingTargetParser.parse(widget.task.prompt),
    ]) {
      final text = raw?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
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

  bool get _isFreeTarget => _template.strokes.isEmpty;
  bool get _isSentenceTarget => _target.trim().contains(RegExp(r'\s'));

  WritingMode get _mode {
    if (_isFreeTarget) return WritingMode.free;
    return widget.task.helpPayload.level >= 2 ? WritingMode.guided : WritingMode.trace;
  }

  @override
  void didUpdateWidget(covariant WritingTaskRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.taskInstanceId != widget.task.taskInstanceId) {
      _strokes = <Stroke>[];
      _evaluation = null;
      _submitted = false;
      _typedController.clear();
    }
  }

  void _finishPractice(List<Stroke> strokes, WritingEvaluation? evaluation) {
    if (_submitted || !mounted || strokes.isEmpty) return;
    _submitted = true;
    widget.onSubmitted?.call(WritingTaskResult(
      task: widget.task,
      evaluation: evaluation ?? _typedTransport,
      strokes: List<Stroke>.unmodifiable(strokes),
      graded: false, // Practice, never an automatic handwriting exam.
    ));
  }

  void _skipPractice() {
    if (_submitted || !mounted) return;
    _submitted = true;
    widget.onSubmitted?.call(WritingTaskResult(
      task: widget.task,
      evaluation: _typedTransport,
      strokes: const <Stroke>[],
      graded: false,
      skipped: true, // No artificial XP or incorrect-answer history.
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_target.isEmpty) {
      return Semantics(
        label: 'Schreibaufgabe ohne Zielbuchstaben',
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Für diese Schreibaufgabe fehlt der Zielbuchstabe. '
            'Bitte wähle eine neue Aufgabe. Wir zeigen keinen zufälligen '
            'Buchstaben als angeblich richtige Lösung.',
            style: TextStyle(fontFamily: 'Nunito', fontSize: 16),
          ),
        ),
      );
    }
    final template = _template;
    final evaluation = _evaluation;
    final typedText = _isWordTarget ? _typedController.text.trim() : '';
    final canSubmit = typedText.isNotEmpty ||
        (evaluation != null && _strokes.isNotEmpty);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: lumoCard(
          gradient: const LinearGradient(
            colors: [Color(0xEA0B2B58), Color(0xEE071B3D), Color(0xE60A315F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            _isSentenceTarget ? 'Schreibsatz' : _isWordTarget ? 'Schreibwort' : 'Schreibaufgabe',
            style: LumoTextStyles.label.copyWith(color: LumoVisualTokens.cyanBright, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            widget.task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
              height: 1.12,
              shadows: [Shadow(color: Color(0x8837D2FD), blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isWordTarget
                ? '${_isSentenceTarget ? 'Zielsatz' : 'Zielwort'}: ${template.symbol}'
                : 'Ziel: ${template.symbol}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.cyanBright,
            ),
          ),
          if (!_isWordTarget) ...[
            const SizedBox(height: 12),
            Semantics(
              label: 'So sieht dein Zeichen aus: ${template.symbol}',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xAA092344),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: LumoVisualTokens.cyan.withOpacity(.55)),
                ),
                child: Row(children: [
                  Container(
                    constraints: const BoxConstraints(minWidth: 74),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    child: Text(
                      template.symbol,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 53,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD27E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Sieh dir den Buchstaben an. '
                      'Fahre dann die blaue Spur mit dem Finger nach.',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: LumoVisualTokens.white,
                      ),
                    ),
                  ),
                  const LumoFoxPose(
                    pose: LumoDesignFoxPose.teacherStick, size: 58),
                ]),
              ),
            ),
          ],
          if (_isWordTarget) ...[
            const SizedBox(height: 8),
            _WordTargetStrip(word: template.symbol),
            const SizedBox(height: 8),
            Text(
              'Wähle selbst: mit dem Finger schreiben und gemeinsam vergleichen '
              'oder das Wort mit der Tastatur eingeben und direkt prüfen.',
              style: LumoTextStyles.body.copyWith(
                color: LumoVisualTokens.white,
                fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('writing-keyboard-answer'),
              controller: _typedController,
              maxLines: _isSentenceTarget ? 2 : 1,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _isSentenceTarget
                    ? 'Deinen Satz hier schreiben'
                    : 'Dein Wort hier schreiben',
                hintText: 'Hier selbst tippen ...',
                filled: true,
                fillColor: const Color(0xFF092B55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                prefixIcon: const Icon(Icons.keyboard_rounded),
              ),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
          if (_isFreeTarget && !_isWordTarget)
            Text('Freie Schreibübung ohne automatische Bewertung. Für dieses Zeichen ist noch keine geprüfte Spur hinterlegt.', style: LumoTextStyles.body),
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
            onFinish: _finishPractice,
            onSkip: _skipPractice,
          ),
        ]),
      ),
      const SizedBox(height: 14),
      if (evaluation != null && _strokes.isNotEmpty)
        const _WritingPracticeFeedback(),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            key: const ValueKey('writing-parent-skip'),
            onPressed: _skipPractice,
            icon: const Icon(Icons.skip_next_rounded),
            label: const Text('Andere Aufgabe'),
            style: TextButton.styleFrom(
              foregroundColor: LumoVisualTokens.white,
              minimumSize: const Size(48, 52),
            ),
          ),
          GestureDetector(
          onTap: !canSubmit
              ? null
              : () {
                  if (typedText.isNotEmpty) {
                    if (_submitted) return;
                    _submitted = true;
                    widget.onSubmitted?.call(WritingTaskResult(
                      task: widget.task,
                      evaluation: _typedTransport,
                      strokes: List<Stroke>.unmodifiable(_strokes),
                      graded: true,
                      typedAnswer: typedText,
                    ));
                  } else {
                    _finishPractice(_strokes, evaluation);
                  }
                },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: canSubmit ? 1 : .45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]),
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                boxShadow: LumoShadow.pill,
              ),
              child: const Text(
                'Weiter',
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
      ]),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xCC174E8B), Color(0xCC0D356A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(LumoRadius.sm),
                  border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.45), width: 1.4),
                  boxShadow: [
                    BoxShadow(color: LumoVisualTokens.cyan.withOpacity(.14), blurRadius: 8),
                  ],
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Non-numeric encouragement; handwriting cannot block a child's progress.
class _WritingPracticeFeedback extends StatelessWidget {
  const _WritingPracticeFeedback();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Gut gemacht, du hast geübt und darfst weiterlernen.',
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD146B60), Color(0xEE0A3A4D)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF54E7B6)),
      ),
      child: const Row(children: [
        Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD776)),
        SizedBox(width: 12),
        Expanded(child: Text(
          'Toll geübt! Jeder Versuch zählt. Du darfst jetzt weiter.',
          style: TextStyle(fontFamily: 'Nunito',
            fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
        )),
      ]),
    ),
  );
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
    required this.onFinish,
    required this.onSkip,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final List<Stroke> existingStrokes;
  final void Function(List<Stroke> strokes, WritingEvaluation? evaluation) onResult;
  final void Function(List<Stroke> strokes, WritingEvaluation? evaluation) onFinish;
  final VoidCallback onSkip;

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
                ? const [Color(0xDD176C5B), Color(0xEE0B3A35)]
                : const [Color(0xDD123D72), Color(0xEE0A2852)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(
            color: hasStrokes ? const Color(0xFF5FF0BF) : LumoVisualTokens.cyanBright,
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
                    hasStrokes ? 'Nochmals üben' : 'Jetzt mit dem Finger schreiben',
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
                        ? 'Du kannst den Buchstaben noch einmal malen.'
                        : 'Ein Versuch reicht. Keine Noten oder Prozentzahlen.',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: LumoVisualTokens.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: LumoVisualTokens.cyanBright, size: 28),
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
    if (result == null) return; // X = back, no attempt submitted.
    if (result.skipped) {
      onSkip();
    } else if (result.completed) {
      onFinish(result.strokes, result.evaluation);
    } else {
      onResult(result.strokes, result.evaluation);
    }
  }
}

class _WritingModalResult {
  const _WritingModalResult({
    required this.strokes,
    required this.evaluation,
    this.completed = false,
    this.skipped = false,
  });
  final List<Stroke> strokes;
  final WritingEvaluation? evaluation;
  final bool completed;
  final bool skipped;
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
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        backgroundColor: const Color(0xFF071F46),
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
            key: const ValueKey('writing-modal-finish'),
            onPressed: _strokes.isEmpty
                ? null
                : () => Navigator.of(context).pop<_WritingModalResult>(
                    _WritingModalResult(
                        strokes: _strokes, evaluation: _evaluation, completed: true),
                  ),
            child: const Text(
              'Weiter',
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
                  gradient: const LinearGradient(
                    colors: [Color(0xDD123D72), Color(0xEE0A2852)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                  border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.45), width: 1.4),
                ),
                child: Row(
                  children: [
                    const LumoFoxPose(
                      pose: LumoDesignFoxPose.teacherStick, size: 54),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Fahre die blaue Vorlage für "${widget.template.symbol}" '
                        'mit dem Finger nach. Du kannst jeden Strich zurücknehmen.',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: LumoVisualTokens.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Mal so, wie du kannst. Es gibt hier keine Noten.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
                  color: Color(0xFFCEF4FF), fontWeight: FontWeight.w800),
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
                    // Eine 100x100-Vorlage darf nicht auf das gesamte
                    // Hochformat gestreckt werden. Quadratische, zentrierte
                    // Leinwand: gleiche x/y-Skalierung für Finger und Modell.
                    final canvasHeight =
                        math.min(constraints.maxWidth, available - 82)
                            .clamp(120.0, 680.0)
                            .toDouble();
                    return Center(
                      child: SizedBox(
                        width: canvasHeight,
                        child: LumoWritingCanvas(
                      template: widget.template,
                      mode: widget.mode,
                      height: canvasHeight,
                      initialStrokes: widget.initialStrokes,
                      // Bewusst kein setState: _strokes und _evaluation werden
                      // nicht im build() verwendet (nur beim Pop). Ein setState
                      // bei jedem Stroke wuerde das ganze Modal neu layouten
                      // und das Canvas-Feld koennte dabei sichtbar springen.
                      // Nur nach Abschluss eines Strichs neu aufbauen,
                      // niemals bei jeder Pointer-Bewegung.
                      onChanged: (strokes) {
                        if (mounted) setState(() => _strokes = strokes);
                      },
                      onEvaluated: (next) => _evaluation = next,
                        ),
                      ),
                    );
                  },
                ),
              ),
              TextButton.icon(
                key: const ValueKey('writing-modal-skip'),
                onPressed: () => Navigator.of(context).pop<_WritingModalResult>(
                  const _WritingModalResult(
                    strokes: <Stroke>[],
                    evaluation: null,
                    skipped: true,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD6EEFF),
                  minimumSize: const Size(48, 52),
                ),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Andere Aufgabe versuchen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
