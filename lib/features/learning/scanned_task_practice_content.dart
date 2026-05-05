import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../core/scanned_task_fallback_policy.dart';
import '../../core/lumo_voice.dart';

class ScannedTaskPracticeContent extends StatefulWidget {
  const ScannedTaskPracticeContent({
    super.key,
    required this.fallback,
    required this.appState,
    required this.onDone,
  });

  final RecognizedTaskFallback fallback;
  final LumoAppState appState;
  final VoidCallback onDone;

  @override
  State<ScannedTaskPracticeContent> createState() => _ScannedTaskPracticeContentState();
}

class _ScannedTaskPracticeContentState extends State<ScannedTaskPracticeContent> {
  final _controller = TextEditingController();
  String? _picked;
  bool? _correct;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallback = widget.fallback;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Header(fallback: fallback),
            const SizedBox(height: 18),
            if (fallback.route == RecognizedTaskRoute.parentReview)
              _ParentReviewCard(fallback: fallback, onDone: widget.onDone)
            else if (fallback.route == RecognizedTaskRoute.multipleChoice)
              _MultipleChoiceCard(
                fallback: fallback,
                picked: _picked,
                correct: _correct,
                onPick: _pick,
                onDone: widget.onDone,
              )
            else
              _FreeTextCard(
                fallback: fallback,
                controller: _controller,
                correct: _correct,
                onSubmit: _submitFreeText,
                onDone: widget.onDone,
              ),
          ]),
        ),
      ),
    );
  }

  void _pick(String value) {
    if (_correct != null) return;
    final isCorrect = value.trim() == (widget.fallback.correctAnswer ?? '').trim();
    setState(() {
      _picked = value;
      _correct = isCorrect;
    });
    _recordAnswer(isCorrect);
  }

  void _submitFreeText() {
    if (_correct != null) return;
    final expected = widget.fallback.correctAnswer?.trim().toLowerCase();
    final value = _controller.text.trim().toLowerCase();
    final isCorrect = expected == null || expected.isEmpty ? true : value == expected;
    setState(() => _correct = isCorrect);
    _recordAnswer(isCorrect);
  }

  void _recordAnswer(bool isCorrect) {
    if (isCorrect) {
      widget.appState.correctAnswer(widget.fallback.unit);
    } else {
      widget.appState.wrongAnswer(widget.fallback.unit);
    }
    widget.appState.recordLearningAnswer(
      subject: widget.fallback.subject,
      unit: widget.fallback.unit,
      correct: isCorrect,
    );
    final message = isCorrect
        ? 'Super, das passt. Lumo hat die erkannte Aufgabe gelöst gespeichert.'
        : 'Fast. Wir prüfen die Aufgabe ruhig noch einmal.';
    if (widget.appState.state.settings.voiceEnabled) {
      LumoVoice.instance.speak(message, style: isCorrect ? VoiceStyle.celebrate : VoiceStyle.comfort);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.fallback});
  final RecognizedTaskFallback fallback;

  @override
  Widget build(BuildContext context) {
    final review = fallback.route == RecognizedTaskRoute.parentReview;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: lumoCard(
        gradient: LinearGradient(
          colors: review
              ? const [Color(0xFFFFF7ED), Color(0xFFFFFFFF)]
              : const [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.82),
            borderRadius: BorderRadius.circular(LumoRadius.lg),
          ),
          child: Text(review ? '👀' : '🦊', style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              review ? 'Elternprüfung nötig' : 'Erkannte Aufgabe',
              style: LumoTextStyles.heading2,
            ),
            const SizedBox(height: 6),
            Text(
              review
                  ? 'Der Scan ist nicht sicher genug. Diese Aufgabe wird nicht automatisch ins Training übernommen.'
                  : '${fallback.subject} • ${fallback.unit} • Sicherheit ${(fallback.confidence * 100).round()} %',
              style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _MultipleChoiceCard extends StatelessWidget {
  const _MultipleChoiceCard({
    required this.fallback,
    required this.picked,
    required this.correct,
    required this.onPick,
    required this.onDone,
  });

  final RecognizedTaskFallback fallback;
  final String? picked;
  final bool? correct;
  final ValueChanged<String> onPick;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fallback.prompt, style: LumoTextStyles.heading1),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: fallback.choices.map((choice) {
            final isPicked = picked == choice;
            final isCorrect = choice == fallback.correctAnswer;
            final answered = correct != null;
            final color = !answered
                ? LumoColors.ink100
                : isCorrect
                    ? const Color(0xFF22C55E)
                    : isPicked
                        ? const Color(0xFFF43F5E)
                        : LumoColors.ink100;
            return OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              ),
              onPressed: answered ? null : () => onPick(choice),
              child: Text(choice, style: const TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900)),
            );
          }).toList(),
        ),
        if (correct != null) ...[
          const SizedBox(height: 18),
          _ResultBanner(correct: correct!, correctAnswer: fallback.correctAnswer),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onDone, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Weiter')),
        ],
      ]),
    );
  }
}

class _FreeTextCard extends StatelessWidget {
  const _FreeTextCard({
    required this.fallback,
    required this.controller,
    required this.correct,
    required this.onSubmit,
    required this.onDone,
  });

  final RecognizedTaskFallback fallback;
  final TextEditingController controller;
  final bool? correct;
  final VoidCallback onSubmit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fallback.prompt, style: LumoTextStyles.heading2),
        const SizedBox(height: 14),
        TextField(
          controller: controller,
          enabled: correct == null,
          decoration: const InputDecoration(
            labelText: 'Antwort eingeben',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: 14),
        if (correct == null)
          FilledButton.icon(onPressed: onSubmit, icon: const Icon(Icons.check_rounded), label: const Text('Antwort prüfen'))
        else ...[
          _ResultBanner(correct: correct!, correctAnswer: fallback.correctAnswer),
          const SizedBox(height: 14),
          FilledButton.icon(onPressed: onDone, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Weiter')),
        ],
      ]),
    );
  }
}

class _ParentReviewCard extends StatelessWidget {
  const _ParentReviewCard({required this.fallback, required this.onDone});
  final RecognizedTaskFallback fallback;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: lumoCard(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Scan-Text', style: LumoTextStyles.heading3),
        const SizedBox(height: 8),
        Text(fallback.rawText.isEmpty ? 'Kein sicher lesbarer Text.' : fallback.rawText, style: LumoTextStyles.body),
        const SizedBox(height: 12),
        Text('Grund: ${fallback.reason ?? 'unsicher'}', style: LumoTextStyles.caption),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onDone, icon: const Icon(Icons.home_rounded), label: const Text('Zurück')),
      ]),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.correct, this.correctAnswer});
  final bool correct;
  final String? correctAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
      ),
      child: Text(
        correct ? 'Richtig erkannt und gelöst! ⭐' : 'Noch nicht ganz. Die richtige Antwort ist ${correctAnswer ?? 'nicht sicher erkannt'}.',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontWeight: FontWeight.w900,
          color: correct ? const Color(0xFF14532D) : const Color(0xFF881337),
        ),
      ),
    );
  }
}
