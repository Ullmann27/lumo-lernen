import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Themen-Karte nach Referenzbild "Deutsch mit Lumo".
///
/// Jede Karte hat:
///   - kleines Kreis-Icon oben links mit Emoji/Symbol
///   - Titel (z.B. "Woerter lesen")
///   - kurzer Untertitel (z.B. "Lies die Woerter und sammle Sterne!")
///   - rechts grosse Illustration (Emoji oder Bildchen)
///   - unten Level + Stern-Fortschritt (z.B. "Level 3 ⭐ 12/20")
///   - farbiger Pastell-Hintergrund je nach Akzent
class LumoSubjectTile extends StatelessWidget {
  const LumoSubjectTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.illustrationEmoji,
    required this.accent,
    required this.level,
    required this.starsCollected,
    required this.starsTotal,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String iconEmoji;       // small circle icon
  final String illustrationEmoji; // big illustration
  final Color accent;
  final int level;
  final int starsCollected;
  final int starsTotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: accent.withOpacity(0.10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _surfaceFromAccent(accent),
                Color.lerp(_surfaceFromAccent(accent), Colors.white, 0.35)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accent.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: small icon circle + title
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        iconEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Middle: subtitle + illustration
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    illustrationEmoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Bottom: level + star progress pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Level $level',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('⭐', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 3),
                    Text(
                      '$starsCollected / $starsTotal',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: LumoColors.ink700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _surfaceFromAccent(Color a) {
    // Heuristisch: pastellige Surface-Farbe aus Akzent ableiten
    if (a == LumoColors.purple) return const Color(0xFFF5EFFF);
    if (a == LumoColors.gold || a == LumoColors.goldLight) {
      return const Color(0xFFFFFBE6);
    }
    if (a == LumoColors.teal || a == LumoColors.tealLight) {
      return const Color(0xFFE8FBF3);
    }
    if (a == LumoColors.blue) return const Color(0xFFEDF5FF);
    if (a == LumoColors.practice) return const Color(0xFFFFF0EE);
    return const Color(0xFFFFF4E8);
  }
}
