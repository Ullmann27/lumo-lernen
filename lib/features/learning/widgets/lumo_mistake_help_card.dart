import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';

/// Help that fits a mistake, in two calm steps and without any blame.
///
/// After the first wrong answer [LumoMistakeFeedbackCard] names what went
/// wrong (if that is known) and offers a first tip. After the second wrong
/// answer [LumoWorkedSolutionCard] walks through the solution; the child
/// then taps the explained answer and the task counts as solved together.

const _ink = Color(0xFFFFF6E3);
const _warm = Color(0xFFFFD36A);
const _panelTop = Color(0xF0143A6B);
const _panelBottom = Color(0xF00A2148);

BoxDecoration _panel(Color accent) => BoxDecoration(
      gradient: const LinearGradient(
        colors: [_panelTop, _panelBottom],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: .75), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: .16),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.title, this.accent});

  final IconData icon;
  final String title;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? _warm;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .18),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: .8)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1.2,
            ),
          ),
        ),
      ),
    ]);
  }
}

const _bodyStyle = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 15,
  fontWeight: FontWeight.w800,
  color: _ink,
  height: 1.35,
);

/// First wrong answer: what happened, and a first tip on request.
class LumoMistakeFeedbackCard extends StatelessWidget {
  const LumoMistakeFeedbackCard({
    super.key,
    required this.message,
    required this.recognised,
    required this.hint,
    required this.hintVisible,
    required this.onShowHint,
  });

  /// The sentence for the child: the recognised cause, or a neutral pointer
  /// back to the task.
  final String message;

  /// True if [message] explains a recognised kind of mistake.
  final bool recognised;

  /// Hint level 1. It never contains the answer.
  final String hint;
  final bool hintVisible;
  final VoidCallback onShowHint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const ValueKey('mistake-feedback-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
        decoration: _panel(_warm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              icon: recognised
                  ? Icons.search_rounded
                  : Icons.visibility_rounded,
              title: recognised
                  ? 'Das ist passiert'
                  : 'Schau noch einmal genau',
            ),
            const SizedBox(height: 9),
            Text(message,
                key: const ValueKey('mistake-feedback-message'),
                style: _bodyStyle),
            const SizedBox(height: 4),
            const Text(
              'Du hast noch einen Versuch.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC9DDEC),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            if (hintVisible)
              Container(
                key: const ValueKey('mistake-feedback-hint'),
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: const Color(0xCC0B2D5B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: LumoVisualTokens.cyan.withValues(alpha: .5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: _warm, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: _bodyStyle.copyWith(
                            fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                key: const ValueKey('mistake-feedback-hint-button'),
                onPressed: onShowHint,
                icon: const Icon(Icons.lightbulb_rounded),
                label: const Text('Tipp zeigen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _warm,
                  minimumSize: const Size(48, 48),
                  side: const BorderSide(color: Color(0xB3FFDA7B)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Second wrong answer: the way to the solution, step by step.
class LumoWorkedSolutionCard extends StatelessWidget {
  const LumoWorkedSolutionCard({
    super.key,
    required this.steps,
    required this.callToAction,
    this.nudge = false,
  });

  /// The solution path. The last step states the solution.
  final List<String> steps;

  /// What the child does next, for example "Tippe jetzt die 7 an."
  final String callToAction;

  /// Shown after a wrong tap while the solution is already explained.
  final bool nudge;

  @override
  Widget build(BuildContext context) {
    const accent = LumoVisualTokens.cyanBright;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const ValueKey('worked-solution-card'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        decoration: _panel(accent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(
              icon: Icons.route_rounded,
              title: 'Wir lösen es gemeinsam – Schritt für Schritt',
              accent: accent,
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == steps.length - 1
                            ? _warm
                            : accent.withValues(alpha: .9),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF07204A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          steps[i],
                          key: ValueKey('worked-solution-step-${i + 1}'),
                          style: _bodyStyle.copyWith(
                            fontSize: 14.5,
                            color: i == steps.length - 1
                                ? _warm
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF12447F),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.touch_app_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nudge
                        ? 'Schau auf Schritt ${steps.length}: Dort steht die '
                            'Lösung. $callToAction'
                        : callToAction,
                    key: const ValueKey('worked-solution-action'),
                    style: _bodyStyle.copyWith(
                        fontSize: 14.5, color: Colors.white),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Announces a returning mistake as a new, similar task.
class LumoTwinTaskBanner extends StatelessWidget {
  const LumoTwinTaskBanner({super.key});

  static const String text =
      'Noch eine ähnliche – jetzt schaffst du sie allein!';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('twin-task-banner'),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFF14506B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5EE6B8), width: 1.4),
        ),
        child: const Row(children: [
          Icon(Icons.replay_circle_filled_rounded,
              color: Color(0xFF5EE6B8), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.25,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
