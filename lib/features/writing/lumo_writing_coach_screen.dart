// ════════════════════════════════════════════════════════════════════════
//                LUMO SCHREIBCOACH - HAUPTSCREEN (Phase 1+2+Mini-3)
// ════════════════════════════════════════════════════════════════════════
//
// Heinz-Auftrag: Lumo schaut beim Schreiben mit, gibt freundliches
// Feedback und kann den korrekten Buchstaben vorzeichnen.
//
// Phase 1: Canvas, Stroke-Erfassung, Undo, Clear.
// Phase 2: Heuristische Analyse fuer I/L/O/H.
// Phase 3 (minimal): Lumo zeichnet vor.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/lumo_voice.dart';
import 'data/coach_letter_templates.dart';
import 'logic/letter_shape_analyzer.dart';
import 'logic/stroke_capture_controller.dart';
import 'logic/writing_feedback_engine.dart';
import 'models/coach_writing_models.dart';
import 'widgets/coach_writing_canvas.dart';

class LumoWritingCoachScreen extends StatefulWidget {
  const LumoWritingCoachScreen({super.key, this.startLetter = 'I'});

  /// Welcher Buchstabe wird beim Oeffnen aktiv? Default: I.
  final String startLetter;

  @override
  State<LumoWritingCoachScreen> createState() => _LumoWritingCoachScreenState();
}

class _LumoWritingCoachScreenState extends State<LumoWritingCoachScreen>
    with SingleTickerProviderStateMixin {
  late final StrokeCaptureController _capture;
  late final LetterShapeAnalyzer _analyzer;
  late final WritingFeedbackEngine _feedbackEngine;
  late final AnimationController _demoCtrl;

  late String _currentLetter;
  CoachWritingFeedback? _lastFeedback;
  bool _showDemo = false;
  bool _disposed = false;

  static const List<String> _availableLetters = ['I', 'L', 'O', 'H'];

  @override
  void initState() {
    super.initState();
    _capture = StrokeCaptureController();
    _analyzer = const LetterShapeAnalyzer();
    _feedbackEngine = WritingFeedbackEngine();
    _demoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _demoCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        // Nach Demo: kurz halten, dann ausblenden
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() => _showDemo = false);
            _demoCtrl.reset();
          }
        });
      }
    });
    _currentLetter = widget.startLetter.toUpperCase();
    if (!CoachLetterTemplates.isSupported(_currentLetter)) {
      _currentLetter = 'I';
    }
    // Initial-Prompt nach erstem Frame sprechen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _speakSafely('Schreib den Buchstaben $_currentLetter.');
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _capture.dispose();
    _demoCtrl.dispose();
    super.dispose();
  }

  Future<void> _speakSafely(String text) async {
    if (_disposed) return;
    try {
      await LumoVoice.instance.speak(text);
    } catch (e) {
      if (kDebugMode) debugPrint('[Schreibcoach] Voice fail: $e');
    }
  }

  void _checkAttempt() {
    HapticFeedback.lightImpact();
    final strokes = _capture.snapshotForAnalysis();
    final result = _analyzer.analyze(
      expectedLetter: _currentLetter,
      strokes: strokes,
    );
    final feedback = _feedbackEngine.feedbackFor(result);
    setState(() => _lastFeedback = feedback);
    _speakSafely(feedback.message);
  }

  void _playDemo() {
    if (!CoachLetterTemplates.isSupported(_currentLetter)) return;
    HapticFeedback.selectionClick();
    setState(() {
      _showDemo = true;
      _demoCtrl.reset();
      _demoCtrl.forward();
    });
    _speakSafely('Schau, so schreibe ich den Buchstaben.');
  }

  void _undo() {
    HapticFeedback.lightImpact();
    _capture.undo();
  }

  void _clear() {
    HapticFeedback.mediumImpact();
    _capture.clear();
    setState(() => _lastFeedback = null);
  }

  void _retryLetter() {
    HapticFeedback.lightImpact();
    _capture.clear();
    setState(() {
      _lastFeedback = null;
      _showDemo = false;
    });
  }

  void _selectLetter(String letter) {
    if (letter == _currentLetter) return;
    setState(() {
      _currentLetter = letter;
      _lastFeedback = null;
      _showDemo = false;
    });
    _capture.clear();
    _demoCtrl.reset();
    _speakSafely('Jetzt der Buchstabe $letter.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF7C2D12)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Lumo Schreibcoach',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Color(0xFF7C2D12),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _demoCtrl,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _PromptBar(letter: _currentLetter, onSpeak: () {
                    _speakSafely('Schreib den Buchstaben $_currentLetter.');
                  }),
                  const SizedBox(height: 12),
                  Expanded(
                    child: CoachWritingCanvas(
                      controller: _capture,
                      demoLetter: _showDemo ? _currentLetter : null,
                      demoProgress: _demoCtrl.value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_lastFeedback != null)
                    _FeedbackBubble(feedback: _lastFeedback!),
                  if (_lastFeedback != null) const SizedBox(height: 12),
                  _LetterPicker(
                    letters: _availableLetters,
                    current: _currentLetter,
                    onSelected: _selectLetter,
                  ),
                  const SizedBox(height: 12),
                  _Toolbar(
                    onUndo: _undo,
                    onClear: _clear,
                    onDemo: _playDemo,
                    onCheck: _checkAttempt,
                    onRetry: _retryLetter,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Prompt-Leiste mit grossem Buchstaben und Lautsprecher ───────────────

class _PromptBar extends StatelessWidget {
  const _PromptBar({required this.letter, required this.onSpeak});
  final String letter;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFFFE5C2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD89A), width: 1.4),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFCD34D).withOpacity(0.45),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              letter,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: 36,
                color: Color(0xFF7C2D12),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Schreib den Buchstaben so gross wie moeglich auf die Linie.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF7C2D12),
                height: 1.3,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Nochmal hoeren',
            onPressed: onSpeak,
            icon: const Icon(
              Icons.volume_up_rounded,
              color: Color(0xFF7C2D12),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feedback-Bubble ────────────────────────────────────────────────────

class _FeedbackBubble extends StatelessWidget {
  const _FeedbackBubble({required this.feedback});
  final CoachWritingFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final correct = feedback.isCorrect;
    final color = correct
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEF3C7);
    final border = correct
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    final icon = correct
        ? Icons.celebration_rounded
        : Icons.lightbulb_rounded;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.4),
      ),
      child: Row(
        children: [
          Icon(icon, color: border, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feedback.message,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: Color(0xFF1F2937),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Buchstaben-Picker ──────────────────────────────────────────────────

class _LetterPicker extends StatelessWidget {
  const _LetterPicker({
    required this.letters,
    required this.current,
    required this.onSelected,
  });

  final List<String> letters;
  final String current;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final l in letters)
          _LetterChip(
            letter: l,
            selected: l == current,
            onTap: () => onSelected(l),
          ),
      ],
    );
  }
}

class _LetterChip extends StatelessWidget {
  const _LetterChip({
    required this.letter,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF97316) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFFF97316)
                : const Color(0xFFE5E7EB),
            width: 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.35),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Text(
          letter,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 26,
            color: selected ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
      ),
    );
  }
}

// ── Toolbar (Aktionsleiste) ────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onUndo,
    required this.onClear,
    required this.onDemo,
    required this.onCheck,
    required this.onRetry,
  });

  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onDemo;
  final VoidCallback onCheck;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ToolButton(
          label: 'Zurueck',
          icon: Icons.undo_rounded,
          onTap: onUndo,
        ),
        const SizedBox(width: 6),
        _ToolButton(
          label: 'Loeschen',
          icon: Icons.cleaning_services_rounded,
          onTap: onClear,
        ),
        const SizedBox(width: 6),
        _ToolButton(
          label: 'Zeig es',
          icon: Icons.play_arrow_rounded,
          onTap: onDemo,
        ),
        const SizedBox(width: 6),
        _ToolButton(
          label: 'Nochmal',
          icon: Icons.refresh_rounded,
          onTap: onRetry,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _PrimaryButton(label: 'Fertig', onTap: onCheck),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF7C2D12), size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: Color(0xFF7C2D12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF97316).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Fertig',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
