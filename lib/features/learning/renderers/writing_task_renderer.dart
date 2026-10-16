import 'package:flutter/material.dart';

import '../../../core/writing_target_parser.dart';
import '../../../domain/learning/lumo_learning_domain.dart';
import '../../../domain/writing/expanded_writing_template_repository.dart';
import '../../../domain/writing/writing_domain.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../writing/widgets/lumo_letter_practice_board.dart';

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

  /// "Andere Aufgabe": no XP, no wrong answer, a different task follows.
  final bool skipped;
}

/// Schreibaufgabe im Lernpfad.
///
/// Schreiben mit dem Finger ist Üben: ein echter Versuch im Schreibtrainer
/// führt immer weiter, ohne Prozentbewertung. Die Rechtschreibung über die
/// Tastatur ist davon getrennt und wird wirklich geprüft.
class WritingTaskRenderer extends StatefulWidget {
  const WritingTaskRenderer({
    super.key,
    required this.task,
    this.onSubmitted,
    this.speak,
  });

  final TaskInstance task;
  final ValueChanged<WritingTaskResult>? onSubmitted;

  /// Optional voice for Lumo's praise in the trainer.
  final ValueChanged<String>? speak;

  @override
  State<WritingTaskRenderer> createState() => _WritingTaskRendererState();
}

class _WritingTaskRendererState extends State<WritingTaskRenderer> {
  final _templates = const ExpandedWritingTemplateRepository();
  final TextEditingController _typedController = TextEditingController();

  /// Practice and skip finish the task exactly once. Typed spelling stays
  /// open: after a wrong spelling the child corrects it and checks again.
  bool _finished = false;
  bool _trainerOpen = false;

  // Placeholder only for the result transport. Typed answers and practice
  // never use a contour score as a grade.
  static const WritingEvaluation _noScore = WritingEvaluation(
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

  bool get _isSentenceTarget => _target.trim().contains(RegExp(r'\s'));

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
    if (_template.strokes.isEmpty) return WritingMode.free;
    return widget.task.helpPayload.level >= 2
        ? WritingMode.guided
        : WritingMode.trace;
  }

  @override
  void didUpdateWidget(covariant WritingTaskRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.taskInstanceId != widget.task.taskInstanceId) {
      _finished = false;
      _typedController.clear();
    }
  }

  Future<void> _openTrainer() async {
    if (_trainerOpen || _finished) return;
    _trainerOpen = true;
    final result = await showLumoLetterPractice(
      context,
      template: _template,
      mode: _mode,
      title: _isWordTarget ? 'Schreibe: ${_template.symbol}' : null,
      speak: widget.speak,
    );
    _trainerOpen = false;
    if (!mounted || result == null) return; // Closed: nothing submitted.
    if (result.skipped) {
      _skipPractice();
    } else if (result.practiced) {
      _finishPractice(result);
    }
  }

  void _finishPractice(LetterPracticeResult result) {
    if (_finished || result.strokes.isEmpty) return;
    _finished = true;
    widget.onSubmitted?.call(WritingTaskResult(
      task: widget.task,
      evaluation: result.evaluation ?? _noScore,
      strokes: result.strokes,
      graded: false, // Practice, never an automatic handwriting exam.
    ));
  }

  void _skipPractice() {
    if (_finished || !mounted) return;
    _finished = true;
    widget.onSubmitted?.call(WritingTaskResult(
      task: widget.task,
      evaluation: _noScore,
      strokes: const <Stroke>[],
      graded: false,
      skipped: true, // No artificial XP or incorrect-answer history.
    ));
  }

  void _checkSpelling() {
    final typed = _typedController.text.trim();
    if (typed.isEmpty || _finished) return;
    FocusScope.of(context).unfocus();
    widget.onSubmitted?.call(WritingTaskResult(
      task: widget.task,
      evaluation: _noScore,
      strokes: const <Stroke>[],
      graded: true,
      typedAnswer: typed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_target.isEmpty) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const _HoloPanel(
          child: Text(
            'Für diese Schreibaufgabe fehlt der Zielbuchstabe. Wir zeigen keinen '
            'zufälligen Buchstaben als angeblich richtige Lösung.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: LumoVisualTokens.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _SkipButton(onPressed: _skipPractice),
      ]);
    }
    final template = _template;
    final kicker = _isSentenceTarget
        ? 'Schreibsatz'
        : _isWordTarget
            ? 'Schreibwort'
            : 'Schreiben üben';

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _HoloPanel(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            kicker.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              letterSpacing: .8,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.cyanBright,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.task.prompt,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
              height: 1.12,
              shadows: [Shadow(color: Color(0x8837D2FD), blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 14),
          if (_isWordTarget)
            _WordTargetStrip(word: template.symbol)
          else
            _LetterShowcase(template: template),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const ValueKey('writing-start'),
            onPressed: _openTrainer,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: const Color(0xFFFFB547),
              foregroundColor: const Color(0xFF0B2350),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  height: 1.15,
                  fontWeight: FontWeight.w900),
            ),
            icon: const Icon(Icons.draw_rounded, size: 26),
            label: const Text(
              'Jetzt mit dem Finger schreiben',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ein echter Versuch reicht. Keine Noten, keine Prozente.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFCEF4FF),
            ),
          ),
        ]),
      ),
      if (_isWordTarget) ...[
        const SizedBox(height: 12),
        _SpellingPanel(
          controller: _typedController,
          sentence: _isSentenceTarget,
          onChanged: () => setState(() {}),
          onCheck: _typedController.text.trim().isEmpty ? null : _checkSpelling,
        ),
      ],
      const SizedBox(height: 10),
      _SkipButton(onPressed: _skipPractice),
    ]);
  }
}

class _HoloPanel extends StatelessWidget {
  const _HoloPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xEA0D3166), Color(0xEE071B3D), Color(0xE60A315F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .5), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: LumoVisualTokens.cyan.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Big print letter, the real guide path and Lumo, wrapping on narrow
/// screens (Fold cover) instead of overflowing.
class _LetterShowcase extends StatelessWidget {
  const _LetterShowcase({required this.template});

  final WritingTemplate template;

  @override
  Widget build(BuildContext context) {
    final hasGuide = template.strokes.isNotEmpty;
    Widget tile(Widget child, String label) => Semantics(
          label: label,
          child: Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xAA092344),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .55)),
            ),
            child: child,
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 12, runSpacing: 12, children: [
        tile(
          Text(
            template.symbol,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 64,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD27E),
            ),
          ),
          'So sieht dein Zeichen aus: ${template.symbol}',
        ),
        if (hasGuide)
          tile(
            Padding(
              padding: const EdgeInsets.all(10),
              child: LumoLetterGuidePreview(template: template, size: 84),
            ),
            'Die Schreibspur für ${template.symbol}',
          ),
      ]),
      const SizedBox(height: 10),
      const Row(children: [
        LumoFoxPose(pose: LumoDesignFoxPose.teacherStick, size: 54),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Schau dir den Buchstaben an. Dann fährst du die helle Spur '
            'mit dem Finger nach.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: LumoVisualTokens.white,
            ),
          ),
        ),
      ]),
    ]);
  }
}

class _SpellingPanel extends StatelessWidget {
  const _SpellingPanel({
    required this.controller,
    required this.sentence,
    required this.onChanged,
    required this.onCheck,
  });

  final TextEditingController controller;
  final bool sentence;
  final VoidCallback onChanged;
  final VoidCallback? onCheck;

  @override
  Widget build(BuildContext context) {
    return _HoloPanel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Row(children: [
          Icon(Icons.keyboard_rounded, color: LumoVisualTokens.cyanBright),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rechtschreiben mit der Tastatur',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
          sentence
              ? 'Tippe den Satz ab. Lumo prüft die Schreibweise.'
              : 'Tippe das Wort. Lumo prüft die Schreibweise.',
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFFCEF4FF),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('writing-keyboard-answer'),
          controller: controller,
          maxLines: sentence ? 2 : 1,
          textCapitalization: TextCapitalization.sentences,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onCheck?.call(),
          decoration: InputDecoration(
            labelText: sentence ? 'Dein Satz' : 'Dein Wort',
            labelStyle: const TextStyle(color: LumoVisualTokens.cyanBright),
            hintText: 'Hier tippen …',
            hintStyle: const TextStyle(color: LumoVisualTokens.muted),
            filled: true,
            fillColor: const Color(0xFF092B55),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: LumoVisualTokens.cyan.withValues(alpha: .55)),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: FilledButton.icon(
            key: const ValueKey('writing-keyboard-check'),
            onPressed: onCheck,
            style: FilledButton.styleFrom(
              backgroundColor: LumoVisualTokens.cyan,
              foregroundColor: const Color(0xFF04203F),
              disabledBackgroundColor: const Color(0xFF1C3A66),
              disabledForegroundColor: LumoVisualTokens.muted,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(
                  fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900),
            ),
            icon: const Icon(Icons.spellcheck_rounded),
            label: const Text('Rechtschreibung prüfen'),
          ),
        ),
      ]),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const ValueKey('writing-parent-skip'),
        onPressed: onPressed,
        icon: const Icon(Icons.skip_next_rounded),
        label: const Text(
          'Andere Aufgabe',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900),
        ),
        style: TextButton.styleFrom(
          foregroundColor: LumoVisualTokens.white,
          minimumSize: const Size(48, 52),
        ),
      ),
    );
  }
}

class _WordTargetStrip extends StatelessWidget {
  const _WordTargetStrip({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return Semantics(
      label: 'Muster: $word',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: letters
            .map((letter) => Container(
                  width: letter.trim().isEmpty ? 16 : 40,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: letter.trim().isEmpty
                      ? null
                      : BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xCC174E8B), Color(0xCC0D356A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: LumoVisualTokens.cyan.withValues(alpha: .45),
                              width: 1.4),
                        ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
