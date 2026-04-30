import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';

/// Premium-Hero-Header nach Referenzbild "Mathe mit Lumo" / "Deutsch mit Lumo".
///
/// Aufbau:
///   - kleine Lumo-Avatar Pille oben links
///   - Begruessung "Hallo, [Name]!" mit Wink-Emoji
///   - kurzer Motivations-Untertitel
///   - Stern- und Streak-Chip oben rechts
///   - grosses farbiges Fach-Headline ("Mathe mit Lumo")
///   - Lumo-Illustration rechts mit Sprechblase
///   - warmer Verlauf als Hintergrund
///
/// Auf schmalen Phones: Layout faltet zu kompaktem Stack.
class LumoHeroHeader extends StatelessWidget {
  const LumoHeroHeader({
    super.key,
    required this.childName,
    required this.title,
    required this.titleAccent,
    required this.subtitle,
    required this.greeting,
    required this.lumoMessage,
    required this.stars,
    required this.streakDays,
    this.accent = LumoColors.orange,
    this.heroIllustrationAsset = 'assets/images/lumo_fox.png',
  });

  final String childName;
  final String title;          // "Mathe"
  final String titleAccent;    // "mit Lumo"
  final String subtitle;       // "Rechnen macht Spaß!"
  final String greeting;       // "Weiter so, du bist spitze!"
  final String lumoMessage;    // Sprechblase-Text
  final int stars;
  final int streakDays;
  final Color accent;
  final String heroIllustrationAsset;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 20, isCompact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8EE), Color(0xFFFFE4C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.18),
            blurRadius: 32,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: const Color(0xFF3D342C).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row: avatar + greeting + status chips
          Row(
            children: [
              _MiniLumoAvatar(asset: heroIllustrationAsset, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Hallo, ',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: LumoColors.ink900,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            childName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: accent,
                            ),
                          ),
                        ),
                        const Text(
                          ' 👋',
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: '⭐',
                value: '$stars',
                label: 'Sterne',
                color: LumoColors.gold,
              ),
              const SizedBox(width: 6),
              _StatChip(
                icon: '🔥',
                value: '$streakDays',
                label: 'Tage in Folge',
                color: const Color(0xFFFF6B35),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Hero row: big title + lumo with bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: isCompact ? 30 : 38,
                          fontWeight: FontWeight.w900,
                          color: LumoColors.ink900,
                          height: 1.05,
                        ),
                        children: [
                          TextSpan(text: '$title\n'),
                          TextSpan(
                            text: titleAccent,
                            style: TextStyle(color: accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: LumoColors.ink700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: _LumoWithBubble(
                  asset: heroIllustrationAsset,
                  message: lumoMessage,
                  accent: accent,
                  size: isCompact ? 110 : 150,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLumoAvatar extends StatelessWidget {
  const _MiniLumoAvatar({required this.asset, required this.accent});
  final String asset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Text('🦊', style: TextStyle(fontSize: 22)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final String icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.ink900,
                  height: 1,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LumoWithBubble extends StatelessWidget {
  const _LumoWithBubble({
    required this.asset,
    required this.message,
    required this.accent,
    required this.size,
  });
  final String asset;
  final String message;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Lumo image
          Positioned(
            right: 0,
            bottom: 0,
            child: Image.asset(
              asset,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: Text('🦊', style: TextStyle(fontSize: size * 0.6)),
                ),
              ),
            ),
          ),
          // Speech bubble
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              constraints: BoxConstraints(maxWidth: size * 1.05),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8DFCF)),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: LumoColors.ink900,
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
