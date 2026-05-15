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
/// Premium-Themen-Karte nach Referenzbild "Deutsch mit Lumo".
///
/// Pro Karte:
///   - kleiner Kreis-Avatar mit Glow oben links
///   - Titel + Untertitel
///   - rechts grosse runde Illustration auf Pastell-Kreis
///   - Sternen-Progress-Balken statt nur Text
///   - Press-Animation (Scale 0.96)
///   - "Spielen ->" Pfeil rechts unten
///   - reicher Pastell-Verlauf + farbiger Glow-Schatten
class LumoSubjectTile extends StatefulWidget {
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
  final String iconEmoji;
  final String illustrationEmoji;
  final Color accent;
  final int level;
  final int starsCollected;
  final int starsTotal;
  final VoidCallback onTap;

  @override
  State<LumoSubjectTile> createState() => _LumoSubjectTileState();
}

class _LumoSubjectTileState extends State<LumoSubjectTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final progress = widget.starsTotal > 0
        ? (widget.starsCollected / widget.starsTotal).clamp(0.0, 1.0)
        : 0.0;
    // Auf sehr kleinen Geraeten (z.B. 320dp Width) wird die Karte sonst zu eng.
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;
    final illustrationSize = isCompact ? 52.0 : 60.0;
    final illustrationFont = isCompact ? 24.0 : 28.0;
    final subtitleMaxLines = isCompact ? 2 : 3;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _surfaceFromAccent(widget.accent),
                Color.lerp(_surfaceFromAccent(widget.accent), Colors.white, 0.45)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.accent.withOpacity(0.22), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.65),
                blurRadius: 6,
                offset: const Offset(-2, -2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OBEN: kleiner Avatar + Titel
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Colors.white, _surfaceFromAccent(widget.accent)],
                        radius: .9,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.accent.withOpacity(0.35), width: 1.4),
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.iconEmoji,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: widget.accent,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // MITTE: Untertitel + grosse Illustration
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.subtitle,
                      maxLines: subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: LumoColors.ink500,
                        height: 1.32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Illustration auf weichem Pastell-Kreis
                  Container(
                    width: illustrationSize,
                    height: illustrationSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          _surfaceFromAccent(widget.accent),
                        ],
                        radius: 0.85,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.accent.withOpacity(0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.illustrationEmoji,
                      style: TextStyle(
                        fontSize: illustrationFont,
                        fontWeight: FontWeight.w900,
                        color: widget.accent,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // UNTEN: Stern-Progressbar + Level + Spielen-Pfeil
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: widget.accent.withOpacity(0.20), width: 1.0),
                    ),
                    child: Text(
                      'Level ${widget.level}',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: widget.accent,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 540),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0.0, end: progress),
                            builder: (_, animProg, __) => LinearProgressIndicator(
                              value: animProg,
                              minHeight: 7,
                              color: widget.accent,
                              backgroundColor: widget.accent.withOpacity(0.16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.starsCollected}/${widget.starsTotal}',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: LumoColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _surfaceFromAccent(Color a) {
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
