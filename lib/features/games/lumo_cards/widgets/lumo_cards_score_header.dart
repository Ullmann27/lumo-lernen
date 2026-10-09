import 'package:flutter/material.dart';

import '../../../../theme/lumo_visual_tokens.dart';

/// Native, reusable Lumo Cards scoreboard. No emoji or platform font
/// substitutes: the real fox portrait keeps the app and game identity aligned.
class LumoCardsScoreHeader extends StatelessWidget {
  const LumoCardsScoreHeader({
    super.key,
    required this.round,
    required this.totalRounds,
    required this.targetPoints,
    this.onClose,
    this.onEmoji,
    this.onSettings,
    this.onAudioSettings,
  });

  final int round;
  final int totalRounds;
  final int targetPoints;
  final VoidCallback? onClose;
  final VoidCallback? onEmoji;
  final VoidCallback? onSettings;
  final VoidCallback? onAudioSettings;

  Widget _action(IconData icon, String label, VoidCallback? action) {
    return IconButton(
      tooltip: label,
      onPressed: action,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      iconSize: 22,
      padding: const EdgeInsets.all(8),
      style: IconButton.styleFrom(
        foregroundColor: LumoVisualTokens.cyanBright,
      ),
      icon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _action(Icons.arrow_back_rounded, 'Pausieren / Zurück', onClose),
              const SizedBox(width: 2),
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LumoVisualTokens.night,
                  border: Border.all(color: LumoVisualTokens.cyanBright, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6637D2FD), blurRadius: 9),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/lumo_design/fox/fox_avatar.png',
                    key: const ValueKey('lumo-cards-real-fox'),
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pets_rounded,
                      color: LumoVisualTokens.cyanBright,
                      size: 23,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Lumo Cards',
                  key: ValueKey('lumo-cards-brand'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.white,
                    shadows: [
                      Shadow(color: Color(0x8037D2FD), blurRadius: 9),
                    ],
                  ),
                ),
              ),
              if (onEmoji != null)
                _action(Icons.face_rounded, 'Avatar', onEmoji),
              if (onAudioSettings != null)
                _action(Icons.volume_up_rounded, 'Ton einstellen', onAudioSettings),
              if (onSettings != null)
                _action(Icons.pause_rounded, 'Pause und Neustart', onSettings),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(Icons.flag_rounded,
                    color: LumoVisualTokens.cyanBright, size: 15),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'Runde $round/$totalRounds',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star_rounded,
                    color: LumoVisualTokens.gold, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$targetPoints Sterne',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: LumoVisualTokens.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
