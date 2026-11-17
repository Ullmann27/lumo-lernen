// ════════════════════════════════════════════════════════════════════════
// LUMO PROMPT CARD — Lumo spricht zum Kind
// ════════════════════════════════════════════════════════════════════════
//
// Das visuelle Pattern aus Figma: Fox-Bubble links + 2 Zeilen Text rechts
// (Label "Hör gut zu!" + Title "Schreib das Wort Mama!").
//
// Aktuell ueberall ad-hoc nachgebaut (WordCoach, LetterCoach, …). Mit dem
// zentralen Widget bleiben Spacing, Border, Schriftgroessen konsistent.
//
// Nutzung:
//   LumoPromptCard(
//     label: 'Hör gut zu!',
//     title: 'Schreib das Wort Mama!',
//     accent: LumoColors.purple,  // setzt Border + Title-Farbe
//     onSpeakerTap: _speakPrompt,
//   )
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'lumo_design_kit.dart';

class LumoPromptCard extends StatelessWidget {
  const LumoPromptCard({
    super.key,
    required this.label,
    required this.title,
    this.accent = LumoColors.purple,
    this.emoji = '🦊',
    this.leading,
    this.onSpeakerTap,
    this.padding = const EdgeInsets.all(LumoKit.space16),
  });

  /// Kleine Zeile oben (z.B. "Hör gut zu!").
  final String label;

  /// Grosse Zeile drunter (z.B. "Schreib das Wort Mama!").
  final String title;

  /// Akzent-Farbe fuer Border + Title (default Lila, Sprechmodus).
  final Color accent;

  /// Emoji in der Bubble links (default Fuchs). Wird ignoriert wenn
  /// [leading] gesetzt ist.
  final String emoji;

  /// Optionales custom Widget links (z.B. LumoIdleFox fuer Animation).
  /// Wenn gesetzt, ersetzt es die Emoji-Bubble.
  final Widget? leading;

  /// Wenn gesetzt: zeigt rechts ein Lautsprecher-Icon, das das Prompt wiederholt.
  final VoidCallback? onSpeakerTap;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: LumoKit.cardWithBorder(accent, width: 2),
      child: Row(
        children: [
          // Leading: custom widget oder Emoji-Bubble
          leading ??
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF6EE),
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
          const SizedBox(width: LumoKit.space12),
          // Text-Spalte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: LumoColors.ink600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (onSpeakerTap != null) ...[
            const SizedBox(width: LumoKit.space8),
            IconButton(
              onPressed: onSpeakerTap,
              icon: Icon(Icons.volume_up_rounded, color: accent, size: 28),
              tooltip: 'Nochmal hören',
              splashRadius: 22,
            ),
          ],
        ],
      ),
    );
  }
}
