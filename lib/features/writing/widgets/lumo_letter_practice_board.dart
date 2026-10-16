import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/writing/expanded_writing_template_repository.dart';
import '../../../domain/writing/letter_practice_rules.dart';
import '../../../domain/writing/writing_domain.dart';
import '../../../domain/writing/writing_path_geometry.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import 'lumo_ink_surface.dart';

/// What the child chose at the end of a writing practice.
enum LetterPracticeOutcome {
  /// The child made a real attempt and tapped "Weiter".
  practiced,

  /// The child chose "Andere Aufgabe". No XP, no wrong answer.
  skipped,
}

class LetterPracticeResult {
  const LetterPracticeResult({
    required this.outcome,
    this.strokes = const <Stroke>[],
    this.evaluation,
  });

  final LetterPracticeOutcome outcome;
  final List<Stroke> strokes;

  /// Contour comparison of the practised letter, for gentle tips only.
  final WritingEvaluation? evaluation;

  bool get practiced => outcome == LetterPracticeOutcome.practiced;
  bool get skipped => outcome == LetterPracticeOutcome.skipped;
}

/// Opens the full-screen writing trainer.
///
/// Returns `null` when the child leaves with the close button.
Future<LetterPracticeResult?> showLumoLetterPractice(
  BuildContext context, {
  required WritingTemplate template,
  WritingMode mode = WritingMode.trace,
  String? title,
  String? progressLabel,
  String skipLabel = 'Andere Aufgabe',
  String continueLabel = 'Weiter',
  ValueChanged<String>? speak,
}) {
  return Navigator.of(context).push<LetterPracticeResult>(
    MaterialPageRoute<LetterPracticeResult>(
      fullscreenDialog: true,
      builder: (routeContext) => LumoLetterPracticePage(
        template: template,
        mode: mode,
        title: title,
        progressLabel: progressLabel,
        skipLabel: skipLabel,
        continueLabel: continueLabel,
        speak: speak,
        onDone: (result) => Navigator.of(routeContext).pop(result),
        onClose: () => Navigator.of(routeContext).maybePop(),
      ),
    ),
  );
}

/// Kindgerechter Schreibtrainer.
///
/// Großer Buchstabe, gut sichtbare Spur mit Startpunkt und Pfeilen, eine
/// Schreibfläche ohne Scrollkonflikt, positive Rückmeldung nach einem echten
/// Versuch, "Weiter", "Nochmals üben" und "Andere Aufgabe". Eine schlechte
/// Konturbewertung sperrt das Kind nie.
class LumoLetterPracticePage extends StatefulWidget {
  const LumoLetterPracticePage({
    super.key,
    required this.template,
    required this.onDone,
    this.mode = WritingMode.trace,
    this.title,
    this.progressLabel,
    this.skipLabel = 'Andere Aufgabe',
    this.continueLabel = 'Weiter',
    this.speak,
    this.onClose,
  });

  final WritingTemplate template;
  final WritingMode mode;
  final String? title;
  final String? progressLabel;
  final String skipLabel;
  final String continueLabel;
  final ValueChanged<String>? speak;
  final ValueChanged<LetterPracticeResult> onDone;
  final VoidCallback? onClose;

  @override
  State<LumoLetterPracticePage> createState() => _LumoLetterPracticePageState();
}

class _LumoLetterPracticePageState extends State<LumoLetterPracticePage>
    with SingleTickerProviderStateMixin {
  static const _evaluator = WritingEvaluator();
  static const _smoother = StrokeSmoother();

  final _ink = _InkModel();
  late final AnimationController _demo;
  WritingEvaluation? _evaluation;
  bool _realAttempt = false;
  int _attempts = 0;
  bool _done = false;
  DateTime? _startedAt;

  bool get _hasGuide =>
      widget.mode != WritingMode.free && widget.template.strokes.isNotEmpty;

  bool get _isWord {
    final letters =
        widget.template.symbol.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '');
    return letters.length > 1;
  }

  @override
  void initState() {
    super.initState();
    _demo = AnimationController(
      vsync: this,
      duration: Duration(
          milliseconds: 900 + 900 * math.max(1, widget.template.strokes.length)),
    );
  }

  @override
  void dispose() {
    _demo.dispose();
    _ink.dispose();
    super.dispose();
  }

  void _startStroke(StrokePoint point) {
    if (_demo.isAnimating) _demo.stop();
    _startedAt ??= DateTime.now();
    _ink.begin(point);
  }

  void _finishStroke() {
    final finished = _ink.end(_smoother);
    if (finished == null) return;
    _reassess();
  }

  void _reassess() {
    final strokes = _ink.strokes;
    final real = LetterPracticeRules.isRealAttempt(strokes, word: _isWord);
    WritingEvaluation? evaluation;
    if (_hasGuide && strokes.isNotEmpty) {
      evaluation = _evaluator.evaluate(
        template: widget.template,
        attempt: WritingAttempt(
          taskInstanceId: 'practice',
          childId: 'practice',
          targetSymbol: widget.template.symbol,
          mode: widget.mode,
          strokes: strokes,
          startedAt: _startedAt ?? DateTime.now(),
          finishedAt: DateTime.now(),
        ),
      );
    }
    final firstSuccess = real && !_realAttempt;
    setState(() {
      _evaluation = evaluation;
      _realAttempt = real;
    });
    if (firstSuccess) {
      HapticFeedback.mediumImpact();
      widget.speak?.call(LetterPracticeRules.praise(_attempts));
    }
  }

  void _undo() {
    _ink.undo();
    _reassess();
  }

  void _practiceAgain() {
    HapticFeedback.lightImpact();
    _ink.clear();
    setState(() {
      _attempts++;
      _realAttempt = false;
      _evaluation = null;
      _startedAt = null;
    });
  }

  void _showDemo() {
    HapticFeedback.selectionClick();
    _demo.forward(from: 0);
  }

  void _finish(LetterPracticeOutcome outcome) {
    if (_done) return;
    if (outcome == LetterPracticeOutcome.practiced && !_realAttempt) return;
    _done = true;
    widget.onDone(LetterPracticeResult(
      outcome: outcome,
      strokes: outcome == LetterPracticeOutcome.practiced
          ? List<Stroke>.unmodifiable(_ink.strokes)
          : const <Stroke>[],
      evaluation:
          outcome == LetterPracticeOutcome.practiced ? _evaluation : null,
    ));
  }

  String get _title {
    final custom = widget.title;
    if (custom != null && custom.trim().isNotEmpty) return custom;
    final symbol = widget.template.symbol;
    if (_isWord) return 'Schreibe: $symbol';
    if (RegExp(r'^\d+$').hasMatch(symbol)) return 'Schreibe die Zahl $symbol';
    return 'Schreibe das $symbol';
  }

  String get _instruction {
    if (_hasGuide) {
      return 'Starte beim grünen Punkt 1 und fahre die helle Spur nach.';
    }
    if (_isWord) return 'Schreibe in die Linien. Schau dir oben das Muster an.';
    return 'Schreibe das Zeichen so groß und deutlich, wie du kannst.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A2B5C), LumoVisualTokens.night, Color(0xFF020F2A)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight * 1.12;
            final header = _PracticeHeader(
              compact: constraints.maxHeight < 800,
              title: _title,
              progressLabel: widget.progressLabel,
              symbol: widget.template.symbol,
              wordMode: _isWord,
              onClose: widget.onClose,
            );
            final compact = constraints.maxHeight < 800;
            final guide = _PracticeInstruction(text: _instruction, compact: compact);
            final board = _PracticeSurface(
              ink: _ink,
              demo: _demo,
              template: widget.template,
              showGuide: _hasGuide,
              wordMode: _isWord,
              onStart: _startStroke,
              onEnd: _finishStroke,
              onCancel: _ink.cancel,
            );
            final tools = _PracticeTools(
              canUndo: _ink.strokes.isNotEmpty,
              onUndo: _undo,
              onClear: _practiceAgain,
              onDemo: _hasGuide ? _showDemo : null,
            );
            final actions = _PracticeActions(
              realAttempt: _realAttempt,
              praise: LetterPracticeRules.praise(_attempts),
              tip: LetterPracticeRules.gentleTip(_evaluation),
              continueLabel: widget.continueLabel,
              skipLabel: widget.skipLabel,
              onContinue: () => _finish(LetterPracticeOutcome.practiced),
              onAgain: _practiceAgain,
              onSkip: () => _finish(LetterPracticeOutcome.skipped),
            );
            if (landscape) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(
                    flex: 5,
                    child: Column(children: [
                      Expanded(child: board),
                      const SizedBox(height: 8),
                      tools,
                    ]),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: math.min(360, constraints.maxWidth * .4),
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        header,
                        const SizedBox(height: 10),
                        guide,
                        const SizedBox(height: 12),
                        actions,
                      ]),
                    ),
                  ),
                ]),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                header,
                const SizedBox(height: 8),
                guide,
                const SizedBox(height: 10),
                Expanded(child: board),
                const SizedBox(height: 8),
                tools,
                const SizedBox(height: 8),
                actions,
              ]),
            );
          }),
        ),
      ),
    );
  }
}

/// Holds the child's ink outside the widget tree so that drawing repaints
/// only the canvas, never the whole page, for smooth finger input.
class _InkModel extends ChangeNotifier {
  final List<Stroke> _strokes = <Stroke>[];
  List<StrokePoint>? _active;
  int _serial = 0;

  List<Stroke> get strokes => List<Stroke>.unmodifiable(_strokes);
  List<StrokePoint>? get active => _active;

  void begin(StrokePoint point) {
    _active = <StrokePoint>[point];
    notifyListeners();
  }

  void add(StrokePoint point) {
    final active = _active;
    if (active == null) return;
    final last = active.last;
    final dx = last.x - point.x;
    final dy = last.y - point.y;
    if (dx * dx + dy * dy < .36) return;
    active.add(point);
    notifyListeners();
  }

  Stroke? end(StrokeSmoother smoother) {
    final active = _active;
    _active = null;
    if (active == null || active.isEmpty) {
      notifyListeners();
      return null;
    }
    // A tap is a dot (i, j, ä): keep it as a tiny visible stroke.
    final points = active.length == 1
        ? <StrokePoint>[
            active.first,
            StrokePoint(
              x: active.first.x,
              y: active.first.y + .6,
              timestampMs: active.first.timestampMs,
            ),
          ]
        : active;
    final raw = Stroke(id: 'ink_${_serial++}', points: points);
    final stroke = points.length >= 3 ? smoother.smooth(raw) : raw;
    _strokes.add(stroke);
    notifyListeners();
    return stroke;
  }

  void cancel() {
    if (_active == null) return;
    _active = null;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _active = null;
    notifyListeners();
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({
    required this.compact,
    required this.title,
    required this.progressLabel,
    required this.symbol,
    required this.wordMode,
    required this.onClose,
  });

  final bool compact;
  final String title;
  final String? progressLabel;
  final String symbol;
  final bool wordMode;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (onClose != null)
        Semantics(
          button: true,
          label: 'Schreibtrainer schließen',
          child: IconButton(
            key: const ValueKey('writing-modal-close'),
            onPressed: onClose,
            iconSize: 28,
            style: IconButton.styleFrom(
              minimumSize: Size.square(compact ? 48 : 52),
              backgroundColor: const Color(0x3337D2FD),
              foregroundColor: LumoVisualTokens.white,
            ),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: compact ? 19 : 21,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: LumoVisualTokens.white,
            ),
          ),
          if (progressLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              progressLabel!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: LumoVisualTokens.cyanBright,
              ),
            ),
          ],
        ]),
      ),
      if (!wordMode) ...[
        const SizedBox(width: 10),
        _LetterBadge(symbol: symbol, size: compact ? 56 : 64),
      ],
    ]);
  }
}

/// The target letter in large print: what the child is about to write.
class _LetterBadge extends StatelessWidget {
  const _LetterBadge({required this.symbol, required this.size});

  final String symbol;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Zielbuchstabe $symbol',
      child: Container(
        key: const ValueKey('writing-target-badge'),
        constraints: BoxConstraints(minWidth: size),
        height: size,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE08A), Color(0xFFFFB547)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFF4CF), width: 2),
          boxShadow: const [
            BoxShadow(color: Color(0x66FFB547), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: Text(
          symbol,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: size * .62,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0B2350),
          ),
        ),
      ),
    );
  }
}

class _PracticeInstruction extends StatelessWidget {
  const _PracticeInstruction({required this.text, required this.compact});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
      decoration: BoxDecoration(
        color: const Color(0xCC0B2E5E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .45)),
      ),
      child: Row(children: [
        LumoFoxPose(pose: LumoDesignFoxPose.teacherStick, size: compact ? 40 : 50),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: compact ? 13 : 14,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: LumoVisualTokens.white,
            ),
          ),
        ),
      ]),
    );
  }
}

class _PracticeTools extends StatelessWidget {
  const _PracticeTools({
    required this.canUndo,
    required this.onUndo,
    required this.onClear,
    required this.onDemo,
  });

  final bool canUndo;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  /// "Zeigen": Lumo traces the letter once, only when a guide exists.
  final VoidCallback? onDemo;

  @override
  Widget build(BuildContext context) {
    Widget tool(String label, IconData icon, VoidCallback? onTap, Key key,
        {Color? accent}) {
      return Expanded(
        child: OutlinedButton.icon(
          key: key,
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            foregroundColor: accent ?? LumoVisualTokens.white,
            disabledForegroundColor: LumoVisualTokens.muted.withValues(alpha: .55),
            side: BorderSide(
                color: (accent ?? LumoVisualTokens.cyan).withValues(alpha: .55)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900),
          ),
        ),
      );
    }

    return Row(children: [
      tool('Zurück', Icons.undo_rounded, canUndo ? onUndo : null,
          const ValueKey('writing-modal-undo')),
      const SizedBox(width: 8),
      tool('Neu', Icons.refresh_rounded, canUndo ? onClear : null,
          const ValueKey('writing-modal-clear')),
      if (onDemo != null) ...[
        const SizedBox(width: 8),
        tool('Zeigen', Icons.play_circle_fill_rounded, onDemo,
            const ValueKey('writing-modal-demo'),
            accent: const Color(0xFFFFE08A)),
      ],
    ]);
  }
}

class _PracticeActions extends StatelessWidget {
  const _PracticeActions({
    required this.realAttempt,
    required this.praise,
    required this.tip,
    required this.continueLabel,
    required this.skipLabel,
    required this.onContinue,
    required this.onAgain,
    required this.onSkip,
  });

  final bool realAttempt;
  final String praise;
  final String? tip;
  final String continueLabel;
  final String skipLabel;
  final VoidCallback onContinue;
  final VoidCallback onAgain;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AnimatedSwitcher(
        duration: Duration(milliseconds: reduceMotion ? 0 : 260),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        ),
        child: realAttempt
            ? _PraiseCard(key: const ValueKey('writing-praise'), praise: praise, tip: tip)
            : const _WaitingHint(key: ValueKey('writing-waiting')),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 56,
        child: FilledButton.icon(
          key: const ValueKey('writing-modal-finish'),
          onPressed: realAttempt ? onContinue : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFFFB547),
            foregroundColor: const Color(0xFF0B2350),
            disabledBackgroundColor: const Color(0xFF1C3A66),
            disabledForegroundColor: LumoVisualTokens.muted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            textStyle: const TextStyle(
                fontFamily: 'Nunito', fontSize: 19, fontWeight: FontWeight.w900),
          ),
          iconAlignment: IconAlignment.end,
          icon: const Icon(Icons.arrow_forward_rounded, size: 26),
          label: Text(continueLabel),
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        if (realAttempt) ...[
          Expanded(
            child: TextButton.icon(
              key: const ValueKey('writing-modal-again'),
              onPressed: onAgain,
              style: TextButton.styleFrom(
                foregroundColor: LumoVisualTokens.white,
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.replay_rounded),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Nochmals üben',
                    maxLines: 1,
                    style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: TextButton.icon(
            key: const ValueKey('writing-modal-skip'),
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD6EEFF),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.skip_next_rounded),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(skipLabel,
                  maxLines: 1,
                  style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ]),
    ]);
  }
}

class _WaitingHint extends StatelessWidget {
  const _WaitingHint({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(children: [
        Icon(Icons.gesture_rounded, color: LumoVisualTokens.cyanBright),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mal so, wie du kannst. Hier gibt es keine Noten.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFFCEF4FF),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PraiseCard extends StatelessWidget {
  const _PraiseCard({super.key, required this.praise, required this.tip});

  final String praise;
  final String? tip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: '$praise ${tip ?? 'Jeder Versuch zählt.'}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEE137062), Color(0xEE0B3D52)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF5FF0BF), width: 1.6),
          boxShadow: const [
            BoxShadow(color: Color(0x5534D399), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Row(children: [
          const LumoFoxPose(pose: LumoDesignFoxPose.cheer, size: 54),
          const SizedBox(width: 6),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                praise,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tip ?? 'Jeder Versuch zählt. Du darfst jetzt weiter.',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD9FFF1),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// The writing board: school lines, the light guide track with start dots
/// and arrows, an optional "Zeigen" animation and the child's ink.
class _PracticeSurface extends StatelessWidget {
  const _PracticeSurface({
    required this.ink,
    required this.demo,
    required this.template,
    required this.showGuide,
    required this.wordMode,
    required this.onStart,
    required this.onEnd,
    required this.onCancel,
  });

  final _InkModel ink;
  final Animation<double> demo;
  final WritingTemplate template;
  final bool showGuide;
  final bool wordMode;
  final ValueChanged<StrokePoint> onStart;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight.isFinite ? constraints.maxHeight : maxW;
      late final double width;
      late final double height;
      if (wordMode) {
        width = maxW;
        height = math.min(maxH, math.max(150.0, maxW * .62));
      } else {
        // Equal x/y scale: a 100x100 letter never gets stretched.
        final side = math.max(120.0, math.min(maxW, maxH));
        width = side;
        height = side;
      }
      // Template units: y spans 0..100, x keeps the same scale.
      final unitsWide = 100 * width / height;
      StrokePoint? toPoint(Offset local) {
        if (local.dx < 0 || local.dy < 0 || local.dx > width || local.dy > height) {
          return null;
        }
        return StrokePoint(
          x: local.dx / width * unitsWide,
          y: local.dy / height * 100,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        );
      }

      return Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: LumoVisualTokens.cyan.withValues(alpha: .65), width: 2),
            boxShadow: [
              BoxShadow(
                  color: LumoVisualTokens.cyan.withValues(alpha: .22),
                  blurRadius: 26,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: LumoInkSurface(
              key: const ValueKey('lumo-learning-ink-surface'),
              onStart: (position) {
                final point = toPoint(position);
                if (point != null) onStart(point);
              },
              onUpdate: (position) {
                final point = toPoint(position);
                if (point != null) ink.add(point);
              },
              onEnd: onEnd,
              onCancel: onCancel,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _PracticePainter(
                    ink: ink,
                    demo: demo,
                    template: template,
                    showGuide: showGuide,
                    wordMode: wordMode,
                    unitsWide: unitsWide,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _PracticePainter extends CustomPainter {
  _PracticePainter({
    required this.ink,
    required this.demo,
    required this.template,
    required this.showGuide,
    required this.wordMode,
    required this.unitsWide,
  }) : super(repaint: Listenable.merge(<Listenable>[ink, demo]));

  final _InkModel ink;
  final Animation<double> demo;
  final WritingTemplate template;
  final bool showGuide;
  final bool wordMode;
  final double unitsWide;

  static final Map<String, List<List<Offset>>> _guideCache = {};

  double _scale(Size size) => size.height / 100;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123C73), Color(0xFF0A2552), Color(0xFF071B3F)],
        ).createShader(rect),
    );
    _paintLines(canvas, size);
    final guides = showGuide ? _guides() : const <List<Offset>>[];
    if (guides.isNotEmpty) _paintGuide(canvas, size, guides);
    if (guides.isNotEmpty && demo.value > 0 && demo.value < 1) {
      _paintDemo(canvas, size, guides, demo.value);
    }
    _paintInk(canvas, size);
  }

  List<List<Offset>> _guides() {
    final key = '${template.symbol}|${template.strokes.length}';
    return _guideCache.putIfAbsent(key, () {
      return [
        for (final stroke in template.strokes)
          WritingPathGeometry.sample(stroke.pathData)
              .map((p) => Offset(p.x, p.y))
              .toList(),
      ];
    });
  }

  void _paintLines(Canvas canvas, Size size) {
    final s = _scale(size);
    final lineature = wordMode
        ? WritingLineature.fourLines
        : ExpandedWritingTemplateRepository.lineatureFor(template.symbol);
    final ys = lineature == WritingLineature.fourLines
        ? const <double>[10, 38, 70, 94]
        : const <double>[10, 50, 90];
    if (lineature == WritingLineature.fourLines) {
      canvas.drawRect(
        Rect.fromLTRB(0, 38 * s, size.width, 70 * s),
        Paint()..color = const Color(0x1437D2FD),
      );
    }
    for (var i = 0; i < ys.length; i++) {
      final y = ys[i] * s;
      // The base line (third line in both systems) is solid and brighter.
      final base = i == 2;
      final paint = Paint()
        ..color = LumoVisualTokens.cyan.withValues(alpha: base ? .7 : .3)
        ..strokeWidth = base ? 2.4 : 1.4;
      if (base) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      } else {
        _dashedLine(canvas, Offset(0, y), Offset(size.width, y), paint, 10, 8);
      }
    }
  }

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint, double dash, double gap) {
    final total = (b - a).distance;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d = end + gap;
    }
  }

  Path _pathOf(List<Offset> points, double s) {
    final path = Path()..moveTo(points.first.dx * s, points.first.dy * s);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx * s, p.dy * s);
    }
    return path;
  }

  void _paintGuide(Canvas canvas, Size size, List<List<Offset>> guides) {
    final s = _scale(size);
    final laneWidth = math.max(18.0, size.height * .085);
    final glow = Paint()
      ..color = LumoVisualTokens.cyan.withValues(alpha: .16)
      ..strokeWidth = laneWidth * 1.35
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final lane = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = laneWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final center = Paint()
      ..color = const Color(0xE6BFF3FF)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final points in guides) {
      if (points.length < 2) continue;
      final path = _pathOf(points, s);
      canvas.drawPath(path, glow);
      canvas.drawPath(path, lane);
      for (final metric in path.computeMetrics()) {
        var d = 0.0;
        while (d < metric.length) {
          final end = math.min(d + 9, metric.length);
          canvas.drawPath(metric.extractPath(d, end), center);
          d = end + 7;
        }
      }
    }
    // Arrows first, start dots on top so the number stays readable.
    final arrow = Paint()
      ..color = const Color(0xFFFFC94A)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final points in guides) {
      if (points.length < 6) continue;
      for (final at in const <double>[.35, .72]) {
        final i = (points.length * at).round().clamp(1, points.length - 1);
        final tip = points[i] * s;
        final prev = points[math.max(0, i - 3)] * s;
        final angle = math.atan2(tip.dy - prev.dy, tip.dx - prev.dx);
        final len = math.max(9.0, size.height * .03);
        canvas.drawPath(
          Path()
            ..moveTo(tip.dx - len * math.cos(angle - .55), tip.dy - len * math.sin(angle - .55))
            ..lineTo(tip.dx, tip.dy)
            ..lineTo(tip.dx - len * math.cos(angle + .55), tip.dy - len * math.sin(angle + .55)),
          arrow,
        );
      }
    }
    final radius = math.max(11.0, size.height * .045);
    final placed = <Offset>[];
    for (var i = 0; i < guides.length; i++) {
      final points = guides[i];
      if (points.isEmpty) continue;
      final start = points.first * s;
      var c = start;
      // Two strokes may start close together (a, d, ä): move the later
      // number sideways and point at its real start with a short line.
      for (var tries = 0;
          tries < 4 && placed.any((p) => (p - c).distance < radius * 2.2);
          tries++) {
        final side = c.dx + radius * 2.4 < size.width - radius ? 1.0 : -1.0;
        c = c + Offset(side * radius * 2.3, -radius * .6);
      }
      if (c != start) {
        canvas.drawLine(start, c, Paint()
          ..color = Colors.white
          ..strokeWidth = 2.4);
        canvas.drawCircle(start, 4.5, Paint()..color = const Color(0xFF16A36F));
      }
      placed.add(c);
      canvas.drawCircle(c, radius + 2.5, Paint()..color = Colors.white);
      canvas.drawCircle(c, radius, Paint()..color = const Color(0xFF16A36F));
      final order = template.strokes[i].order;
      final label = TextPainter(
        text: TextSpan(
          text: '$order',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: radius * 1.15,
            height: 1,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, c - Offset(label.width / 2, label.height / 2));
    }
  }

  void _paintDemo(Canvas canvas, Size size, List<List<Offset>> guides, double t) {
    final s = _scale(size);
    final lengths = <double>[];
    for (final points in guides) {
      var l = 0.0;
      for (var i = 1; i < points.length; i++) {
        l += (points[i] - points[i - 1]).distance;
      }
      lengths.add(l);
    }
    final total = lengths.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    var remaining = total * Curves.easeInOut.transform(t);
    final pen = Paint()
      ..color = const Color(0xFFFFE08A)
      ..strokeWidth = math.max(7.0, size.height * .03)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    Offset? head;
    for (var g = 0; g < guides.length && remaining > 0; g++) {
      final points = guides[g];
      final path = _pathOf(points, s);
      for (final metric in path.computeMetrics()) {
        final draw = math.min(remaining * s, metric.length);
        canvas.drawPath(metric.extractPath(0, draw), pen);
        head = metric.getTangentForOffset(draw)?.position;
        remaining -= draw / s;
      }
    }
    if (head != null) {
      canvas.drawCircle(head, pen.strokeWidth * .9, Paint()..color = Colors.white);
    }
  }

  void _paintInk(Canvas canvas, Size size) {
    final s = _scale(size);
    final width = math.max(8.0, size.height * .034);
    final glow = Paint()
      ..color = const Color(0x55FF9A3C)
      ..strokeWidth = width * 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final pen = Paint()
      ..color = const Color(0xFFFFB547)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    void drawPoints(List<StrokePoint> points) {
      if (points.isEmpty) return;
      final first = Offset(points.first.x * s, points.first.y * s);
      if (points.length == 1 || _tiny(points)) {
        canvas.drawCircle(first, width * .7, Paint()..color = pen.color);
        return;
      }
      final path = Path()..moveTo(first.dx, first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.x * s, p.y * s);
      }
      canvas.drawPath(path, glow);
      canvas.drawPath(path, pen);
    }

    for (final stroke in ink.strokes) {
      drawPoints(stroke.points);
    }
    final active = ink.active;
    if (active != null) drawPoints(active);
  }

  bool _tiny(List<StrokePoint> points) {
    final a = points.first;
    final b = points.last;
    return points.length <= 3 && (a.x - b.x).abs() < 1 && (a.y - b.y).abs() < 1;
  }

  @override
  bool shouldRepaint(covariant _PracticePainter oldDelegate) =>
      oldDelegate.template != template ||
      oldDelegate.showGuide != showGuide ||
      oldDelegate.wordMode != wordMode ||
      oldDelegate.unitsWide != unitsWide;
}

/// Small preview of a template, e.g. on lesson cards: the real guide path.
class LumoLetterGuidePreview extends StatelessWidget {
  const LumoLetterGuidePreview({super.key, required this.template, this.size = 96});

  final WritingTemplate template;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _GuidePreviewPainter(template)),
    );
  }
}

class _GuidePreviewPainter extends CustomPainter {
  _GuidePreviewPainter(this.template);

  final WritingTemplate template;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 100;
    final paint = Paint()
      ..color = const Color(0xFFFFE08A)
      ..strokeWidth = math.max(3.0, size.height * .07)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in template.strokes) {
      final points = WritingPathGeometry.sample(stroke.pathData);
      if (points.length < 2) continue;
      final path = Path()..moveTo(points.first.x * s, points.first.y * s);
      for (final p in points.skip(1)) {
        path.lineTo(p.x * s, p.y * s);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuidePreviewPainter oldDelegate) =>
      oldDelegate.template != template;
}
