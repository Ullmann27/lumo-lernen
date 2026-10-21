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
      final footerScale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
      final artworkSize = compact ? 51.0 : 76.0;
      final radius = BorderRadius.circular(24);
      final progress = (completed / 10).clamp(0.0, 1.0);
      // Midnight-glass island palette preserves per-subject identity
      // without the old pale template cards breaking the Lumo art direction.
      final base = Color.lerp(const Color(0xFF0C2A59), accent, .16)!;
      final light = Color.lerp(const Color(0xFF164A85), accent, .18)!;

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
                    colors: [
                      light,
                      base,
                      const Color(0xFF071B3C),
                      const Color(0xFF06142F),
                    ],
                    stops: const [0, .33, .76, 1],
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
                      // Tiny deterministic highlights anchor the illustration
                      // in the magical scene; this is not a costly animation.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _LumoSubjectStarlightPainter(accent),
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
                                            color: const Color(0xFFF3FBFF),
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
                                            color: const Color(0xFFC8E8FA),
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
                            // Large Android text needs genuine vertical room;
                            // never hide overflowing progress or reward labels.
                            height: 65 * footerScale,
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
                                    Expanded(
                                      child: FittedBox(
                                        alignment: Alignment.centerLeft,
                                        fit: BoxFit.scaleDown,
                                        child: Text(
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
                                      ),
                                    ),
                                    const SizedBox(width: 4),
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

/// Static four-point starlight; no ticker, blur filter or asset decoding.
class _LumoSubjectStarlightPainter extends CustomPainter {
  const _LumoSubjectStarlightPainter(this.accent);
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final highlight = Paint()
      ..color = Color.lerp(accent, Colors.white, .7)!.withValues(alpha: .7)
      ..style = PaintingStyle.fill;
    final rays = Paint()
      ..color = Colors.white.withValues(alpha: .38)
      ..strokeWidth = .8
      ..strokeCap = StrokeCap.round;
    const locations = <(double, double, double)>[
      (.12, .19, 4.5), (.83, .12, 3.8), (.56, .42, 2.8),
      (.23, .59, 3.1), (.88, .55, 2.4),
    ];
    for (final (x, y, radius) in locations) {
      final center = Offset(size.width * x, size.height * y * .64);
      final path = Path()
        ..moveTo(center.dx, center.dy - radius * 1.8)
        ..quadraticBezierTo(center.dx + radius * .27,
            center.dy - radius * .27, center.dx + radius, center.dy)
        ..quadraticBezierTo(center.dx + radius * .27,
            center.dy + radius * .27, center.dx, center.dy + radius * 1.8)
        ..quadraticBezierTo(center.dx - radius * .27,
            center.dy + radius * .27, center.dx - radius, center.dy)
        ..quadraticBezierTo(center.dx - radius * .27,
            center.dy - radius * .27, center.dx, center.dy - radius * 1.8)
        ..close();
      canvas.drawPath(path, highlight);
      canvas.drawLine(
        Offset(center.dx - radius * 1.3, center.dy),
        Offset(center.dx + radius * 1.3, center.dy),
        rays,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LumoSubjectStarlightPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
