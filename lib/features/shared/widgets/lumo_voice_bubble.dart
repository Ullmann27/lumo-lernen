import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import 'lumo_modern_card.dart';

class LumoVoiceBubble extends StatelessWidget {
  const LumoVoiceBubble({
    super.key,
    required this.message,
    required this.onMicPressed,
    this.statusLabel = 'Frag Lumo',
    this.transcript,
    this.isListening = false,
    this.isThinking = false,
    this.enabled = true,
    this.mascotEmoji = '🦊',
  });

  final String message;
  final VoidCallback? onMicPressed;
  final String statusLabel;
  final String? transcript;
  final bool isListening;
  final bool isThinking;
  final bool enabled;
  final String mascotEmoji;

  @override
  Widget build(BuildContext context) {
    final accent = isListening ? LumoColors.teal : isThinking ? LumoColors.purple : LumoColors.orange;
    final stateText = isListening ? 'Ich höre zu ...' : isThinking ? 'Lumo denkt nach ...' : statusLabel;

    return LumoModernCard(
      padding: const EdgeInsets.all(18),
      color: LumoColors.cardBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LumoMascotBadge(emoji: mascotEmoji, color: accent, listening: isListening),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(stateText, style: LumoTextStyles.label.copyWith(color: accent)),
                const SizedBox(height: 7),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: LumoTextStyles.heading3.copyWith(color: LumoColors.ink900, height: 1.18),
                ),
                if (transcript != null && transcript!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(.10),
                      borderRadius: BorderRadius.circular(LumoRadius.md),
                      border: Border.all(color: accent.withOpacity(.14)),
                    ),
                    child: Text(
                      transcript!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: LumoTextStyles.body.copyWith(color: LumoColors.ink700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _MicButton(
            enabled: enabled && onMicPressed != null,
            listening: isListening,
            color: accent,
            onPressed: onMicPressed,
          ),
        ],
      ),
    );
  }
}

class _LumoMascotBadge extends StatelessWidget {
  const _LumoMascotBadge({required this.emoji, required this.color, required this.listening});

  final String emoji;
  final Color color;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: listening ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: <Color>[color.withOpacity(.18), LumoColors.cardBg]),
          shape: BoxShape.circle,
          boxShadow: LumoShadow.hologram(color),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 31)),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.enabled, required this.listening, required this.color, required this.onPressed});

  final bool enabled;
  final bool listening;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: listening ? 'Spracheingabe stoppen' : 'Mit Lumo sprechen',
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? <Color>[color.withOpacity(.88), color]
                  : <Color>[LumoColors.ink300, LumoColors.ink400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: enabled ? LumoShadow.hologram(color) : null,
          ),
          child: Icon(listening ? Icons.graphic_eq_rounded : Icons.mic_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
