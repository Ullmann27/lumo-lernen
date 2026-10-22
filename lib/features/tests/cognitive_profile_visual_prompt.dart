import 'package:flutter/material.dart';

import '../../domain/cognitive/cognitive_profile.dart';
import '../../theme/lumo_visual_tokens.dart';
import 'iq/iq_widgets.dart';
import 'iq/iq_style.dart';

/// Visualizes information already present in the real Denkprofil question.
/// This does not alter answers, difficulty, grading or the original wording.
/// Only the given clues are rendered; the missing solution stays hidden.
class CognitiveProfileVisualPrompt extends StatelessWidget {
  const CognitiveProfileVisualPrompt({super.key, required this.question});

  final CognitiveQuestion question;

  @override
  Widget build(BuildContext context) {
    final prompt = question.prompt;
    final isNumberPattern =
        question.domain == CognitiveDomain.patternReasoning &&
        prompt.startsWith('Welche Zahl folgt?');
    final isShapePattern =
        question.domain == CognitiveDomain.patternReasoning &&
        prompt.startsWith('Setze das Muster fort:');
    final isRotation = question.domain == CognitiveDomain.spatialReasoning &&
        prompt.contains('gedreht');

    if (!isNumberPattern && !isShapePattern && !isRotation) {
      return const SizedBox.shrink();
    }

    if (isRotation) {
      final arrow = RegExp(r'[↑→↓←]').firstMatch(prompt)?.group(0);
      final angle = RegExp(r'\d+°').firstMatch(prompt)?.group(0);
      if (arrow == null || angle == null) return const SizedBox.shrink();
      return Semantics(
        label: 'Gezeigter Ausgangspfeil $arrow, Drehung um $angle',
        child: IqTile(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(arrow, style: iqText(52, weight: FontWeight.w900)),
              const SizedBox(width: 24),
              const Icon(Icons.rotate_right_rounded,
                  size: 36, color: LumoVisualTokens.cyanBright),
              const SizedBox(width: 6),
              Text(angle, style: iqText(24, weight: FontWeight.w900)),
              const SizedBox(width: 24),
              Text('?', style: iqText(32, weight: FontWeight.w900)),
            ],
          ),
        ),
      );
    }

    final part = prompt.substring(
        isShapePattern
            ? prompt.indexOf(':') + 1
            : prompt.indexOf('?') + 1);
    final pattern = isShapePattern
        ? RegExp(r'[●▲■◆?]')
        : RegExp(r'\d+|\?');
    final symbols = pattern.allMatches(part).map((m) => m.group(0)!).toList();
    if (symbols.length < 3 || symbols.last != '?') {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'Muster zum Fortsetzen: ${symbols.join(', ')}',
      child: IqTile(
        radius: 22,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        child: Wrap(
          key: const ValueKey('cognitive-visual-pattern'),
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 9,
          children: [
            for (final item in symbols)
              Container(
                constraints: const BoxConstraints(minWidth: 44, minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  color: item == '?'
                      ? LumoVisualTokens.cyanBright.withValues(alpha: .25)
                      : const Color(0x88204472),
                  border: Border.all(
                    color: item == '?'
                        ? LumoVisualTokens.cyanBright
                        : Colors.white.withValues(alpha: .27),
                  ),
                ),
                child: Text(item,
                    textAlign: TextAlign.center,
                    style: iqText(
                      isShapePattern ? 29 : 22,
                      weight: FontWeight.w900,
                      color: item == '?'
                          ? LumoVisualTokens.cyanBright
                          : Colors.white,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
