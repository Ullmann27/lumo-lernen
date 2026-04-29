import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

/// Lernmodul-Karte (3-Spalten-Raster).
///
/// Features:
/// - animierter Hintergrund (optional via [background]) hinter dem Inhalt
/// - 3D-Press-Effekt beim Tippen (Karte „drückt“ sich nach unten)
/// - Hover-Glow in Akzentfarbe
/// - Großes 3D-Emoji rechts unten
/// - Soft-Glas-Optik mit Doppel-Schatten
class LearningModuleCard extends StatefulWidget {
  const LearningModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.objectEmoji,
    required this.icon,
    required this.accent,
    required this.surfaceColors,
    required this.onTap,
    this.onHoverChange,
    this.background,
    this.width = 240,
    this.height = 160,
  });

  final String title;
  final String description;
  final String ctaLabel;
  final String objectEmoji;
  final IconData icon;
  final Color accent;
  final List<Color> surfaceColors;
  final VoidCallback onTap;

  /// Wird aufgerufen wenn Hover beginnt (true) oder endet (false).
  final ValueChanged<bool>? onHoverChange;

  /// Optionaler animierter Hintergrund hinter dem Content.
  final Widget? background;

  final double width;
  final double height;

  @override
  State<LearningModuleCard> createState() => _LearningModuleCardState();
}

class _LearningModuleCardState extends State<LearningModuleCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHoverChange?.call(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHoverChange?.call(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: widget.width,
          height: widget.height,
          // 3D-Press: kleine Translation nach unten + Skalierung
          transform: Matrix4.identity()
            ..translate(0.0, _pressed ? 4.0 : 0.0)
            ..scale(_pressed ? 0.98 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.surfaceColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            border: Border.all(
              color: Colors.white.withOpacity(_hovered ? .95 : .75),
              width: 1.5,
            ),
            boxShadow: [
              // Akzent-Glow (heftiger bei Hover, kleiner bei Press)
              BoxShadow(
                color: widget.accent.withOpacity(
                  _pressed ? .10 : (_hovered ? .28 : .14),
                ),
                blurRadius: _pressed ? 14 : (_hovered ? 36 : 22),
                offset: Offset(0, _pressed ? 4 : (_hovered ? 14 : 10)),
              ),
              // Lichthighlight oben links
              BoxShadow(
                color: Colors.white.withOpacity(.80),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.xl - 2),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ── Animierter Hintergrund ────────────────────
                if (widget.background != null)
                  Positioned.fill(child: widget.background!),

                // ── 3D-Objekt (Emoji rechts unten) ────────────
                Positioned(
                  right: -6,
                  bottom: -8,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: _hovered ? 1.08 : 1.0,
                    curve: Curves.easeOutCubic,
                    child: Text(
                      widget.objectEmoji,
                      style: TextStyle(
                        fontSize: 70,
                        shadows: [
                          Shadow(
                            color: widget.accent.withOpacity(.30),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.75),
                            borderRadius:
                                BorderRadius.circular(LumoRadius.sm),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accent.withOpacity(.20),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(widget.icon,
                              color: widget.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: widget.accent,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: widget.width * .56,
                        child: Text(
                          widget.description,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: LumoColors.ink500,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      _CtaButton(
                        label: widget.ctaLabel,
                        accent: widget.accent,
                        active: _hovered,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaButton extends StatelessWidget {
  const _CtaButton({
    required this.label,
    required this.accent,
    this.active = false,
  });
  final String label;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: active ? 12 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: active ? Colors.white.withOpacity(.55) : Colors.transparent,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedSlide(
            duration: const Duration(milliseconds: 200),
            offset: active ? const Offset(.2, 0) : Offset.zero,
            child: Icon(Icons.arrow_forward_rounded,
                color: accent, size: 14),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  WIDE CARD — für die zwei breiten Karten (Foto / Weiterlernen)
// ────────────────────────────────────────────────────────────

class WideModuleCard extends StatefulWidget {
  const WideModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.objectEmoji,
    required this.icon,
    required this.accent,
    required this.surfaceColors,
    required this.onTap,
    this.onHoverChange,
    this.background,
    this.width = 360,
  });

  final String title;
  final String description;
  final String ctaLabel;
  final String objectEmoji;
  final IconData icon;
  final Color accent;
  final List<Color> surfaceColors;
  final VoidCallback onTap;
  final ValueChanged<bool>? onHoverChange;
  final Widget? background;
  final double width;

  @override
  State<WideModuleCard> createState() => _WideModuleCardState();
}

class _WideModuleCardState extends State<WideModuleCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        widget.onHoverChange?.call(true);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        widget.onHoverChange?.call(false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          width: widget.width,
          height: 130,
          transform: Matrix4.identity()
            ..translate(0.0, _pressed ? 4.0 : 0.0)
            ..scale(_pressed ? 0.985 : 1.0),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.surfaceColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(LumoRadius.xl),
            border: Border.all(
              color: Colors.white.withOpacity(_hovered ? .95 : .75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(
                  _pressed ? .10 : (_hovered ? .26 : .14),
                ),
                blurRadius: _pressed ? 14 : (_hovered ? 32 : 22),
                offset: Offset(0, _pressed ? 4 : (_hovered ? 14 : 10)),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(.80),
                blurRadius: 8,
                offset: const Offset(-3, -3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(LumoRadius.xl - 2),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                if (widget.background != null)
                  Positioned.fill(child: widget.background!),
                Positioned(
                  right: -4,
                  bottom: -8,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: _hovered ? 1.08 : 1.0,
                    curve: Curves.easeOutCubic,
                    child: Text(
                      widget.objectEmoji,
                      style: TextStyle(
                        fontSize: 80,
                        shadows: [
                          Shadow(
                            color: widget.accent.withOpacity(.28),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.75),
                            borderRadius:
                                BorderRadius.circular(LumoRadius.sm),
                          ),
                          child: Icon(widget.icon,
                              color: widget.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: widget.accent,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: widget.width * .55,
                        child: Text(
                          widget.description,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: LumoColors.ink500,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Spacer(),
                      _CtaButton(
                        label: widget.ctaLabel,
                        accent: widget.accent,
                        active: _hovered,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
