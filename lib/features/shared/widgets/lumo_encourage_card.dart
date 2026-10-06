import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';

/// Motivations-Karte am Ende der Lernseite ("Weiter so, Alina!")
class LumoEncourageCard extends StatelessWidget {
  const LumoEncourageCard({
    super.key,
    required this.childName,
    required this.message,
    this.foxAsset = 'assets/images/lumo_fox.png',
    this.accent = LumoColors.orange,
  });

  final String childName;
  final String message;
  final String foxAsset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xDD123D72), Color(0xEE0A2852)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.40)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Fox holding trophy (compose with emoji overlay)
          SizedBox(
            width: 76,
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF0D315F),
                      child: LumoCharacter(
                        pose: LumoDesignFoxPose.trophyWink,
                        ambientPoses: const <LumoDesignFoxPose>[
                          LumoDesignFoxPose.cheer,
                          LumoDesignFoxPose.thumbWink,
                        ],
                        size: 76,
                        reduceMotion: MediaQuery.disableAnimationsOf(context),
                        intro: false,
                        shadow: false,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF123D72),
                      shape: BoxShape.circle,
                      border: Border.all(color: LumoVisualTokens.gold.withOpacity(.55)),
                      boxShadow: [
                        BoxShadow(
                          color: LumoColors.gold.withOpacity(0.40),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Weiter so, $childName!',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: LumoVisualTokens.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🌟', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LumoVisualTokens.muted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Calendar tomorrow chip
          Container(
            width: 52,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xCC174E8B), Color(0xCC0D356A)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.32)),
              boxShadow: [
                BoxShadow(
                  color: LumoColors.orange.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 2),
                Text(
                  'Morgen',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: LumoVisualTokens.muted,
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
