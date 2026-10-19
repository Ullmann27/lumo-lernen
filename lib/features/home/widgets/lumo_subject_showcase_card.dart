import 'package:flutter/material.dart';

import '../../../widgets/design/lumo_motion.dart';

/// The nine home learning routes share one art-directed, touch-safe card.
///
/// Presentation only: achievements and navigation are supplied by the caller.
/// All illustrations below are original assets already shipped with Lumo.
class LumoSubjectShowcaseCard extends StatelessWidget {
  const LumoSubjectShowcaseCard({
    super.key,
    required this.subject,
    required this.shortName,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.completed,
    required this.onTap,
    this.artwork,
  });

  final String subject;
  final String shortName;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final int completed;
  final VoidCallback onTap;
  final String? artwork;

  int get earnedStars => completed >= 10
      ? 3
      : completed >= 5
          ? 2
          : completed > 0
              ? 1
              : 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 172;
      final artworkSize = compact ? 51.0 : 76.0;
      final radius = BorderRadius.circular(24);
      final progress = (completed / 10).clamp(0.0, 1.0);
      final base = Color.lerp(accent, Colors.white, .79)!;
      final light = Color.lerp(accent, Colors.white, .94)!;

      return Semantics(
        button: true,
        label: '$subject: $subtitle. $completed Aufgaben geschafft.',
        child: LumoPressable(
          glowColor: accent,
          radius: 24,
          pressedScale: .975,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('home-island-${shortName.toLowerCase()}'),
              borderRadius: radius,
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: accent.withValues(alpha: .74), width: 1.7,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [light, base, Colors.white],
                    stops: const [0, .62, 1],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: .32),
                      blurRadius: 23,
                      spreadRadius: -4,
                      offset: const Offset(0, 11),
                    ),
                    const BoxShadow(
                      color: Color(0x35000F32),
                      blurRadius: 5,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: [
                      Positioned(
                        top: -72,
                        right: -42,
                        child: IgnorePointer(
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(colors: [
                                Colors.white.withValues(alpha: .9),
                                accent.withValues(alpha: .16),
                                accent.withValues(alpha: 0),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -14,
                        top: 5,
                        right: 14,
                        child: IgnorePointer(
                          child: Container(
                            height: 24,
                            transform: Matrix4.skewX(-.2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              gradient: LinearGradient(colors: [
                                Colors.white.withValues(alpha: .64),
                                Colors.white.withValues(alpha: .04),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                compact ? 10 : 14, compact ? 14 : 17,
                                compact ? 6 : 10, 7,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          shortName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w900,
                                            fontSize: compact ? 15 : 18,
                                            height: 1.08,
                                            color: const Color(0xFF10264A),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          subtitle,
                                          maxLines: compact ? 3 : 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w800,
                                            fontSize: compact ? 10 : 11,
                                            height: 1.15,
                                            color: const Color(0xFF395378),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  ExcludeSemantics(
                                    child: Container(
                                      width: artworkSize,
                                      height: artworkSize,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(colors: [
                                          Colors.white,
                                          Color.lerp(accent, Colors.white, .47)!,
                                          accent.withValues(alpha: .53),
                                        ]),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: .95),
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withValues(alpha: .52),
                                            blurRadius: 15,
                                            offset: const Offset(0, 7),
                                          ),
                                        ],
                                      ),
                                      child: artwork == null
                                          ? Icon(icon,
                                              size: compact ? 28 : 40,
                                              color: const Color(0xFF153B68))
                                          : Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Image.asset(
                                                artwork!,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(icon,
                                                        size: compact ? 28 : 40,
                                                        color: const Color(0xFF153B68)),
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 65,
                            padding: EdgeInsets.fromLTRB(
                              compact ? 10 : 13, 7, compact ? 10 : 13, 7,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF183E70),
                                  const Color(0xFF081C3C),
                                ],
                              ),
                              border: Border(
                                top: BorderSide(
                                  color: accent.withValues(alpha: .9), width: 1.4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'MEIN FORTSCHRITT',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontSize: compact ? 8 : 9,
                                        letterSpacing: .3,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFFE2F6FF),
                                      ),
                                    ),
                                    const Spacer(),
                                    for (var index = 0; index < 3; index++)
                                      Icon(
                                        index < earnedStars
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: compact ? 12 : 14,
                                        color: index < earnedStars
                                            ? const Color(0xFFFFD45E)
                                            : const Color(0xFF91AAC8),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: const Color(0xFF365576),
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '$completed ${completed == 1 ? 'Aufgabe' : 'Aufgaben'} geschafft',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 10 : 11,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
