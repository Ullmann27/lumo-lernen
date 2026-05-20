import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../widgets/fox/lumo_idle_fox.dart';

/// Motivations-Karte am Ende der Lernseite ("Weiter so, Alina!")
class LumoEncourageCard extends StatelessWidget {
  const LumoEncourageCard({
    super.key,
    required this.childName,
    required this.message,
    this.foxAsset,
    this.accent = LumoColors.orange,
  });

  final String childName;
  final String message;

  /// Optionaler Override fuer den Fuchs-Asset-Pfad. Wenn null wird die
  /// 8-Frame-Idle-Animation (LumoIdleFox) gerendert.
  final String? foxAsset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF6E8), Color(0xFFFFE6CB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD9B0)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
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
                      color: Colors.white,
                      child: foxAsset == null
                          ? const Center(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: LumoIdleFox(size: 76),
                              ),
                            )
                          : Image.asset(
                              foxAsset!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text('🦊',
                                    style: TextStyle(fontSize: 44)),
                              ),
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
                      color: Colors.white,
                      shape: BoxShape.circle,
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
                          color: LumoColors.ink900,
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
                    color: LumoColors.ink500,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
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
                    color: LumoColors.ink700,
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
