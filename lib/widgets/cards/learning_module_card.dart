import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

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
  final double width;
  final double height;

  @override
  State<LearningModuleCard> createState() => _LearningModuleCardState();
}

class _LearningModuleCardState extends State<LearningModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.surfaceColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(LumoRadius.xl),
              border: Border.all(color: Colors.white.withOpacity(_hovered ? .95 : .75), width: 1.5),
              boxShadow: [
                BoxShadow(color: widget.accent.withOpacity(_hovered ? .22 : .12), blurRadius: _hovered ? 30 : 20, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.white.withOpacity(.80), blurRadius: 8, offset: const Offset(-3, -3)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -2,
                  bottom: -4,
                  child: Text(widget.objectEmoji, style: TextStyle(fontSize: 62, shadows: [Shadow(color: widget.accent.withOpacity(.25), blurRadius: 20, offset: const Offset(0, 8))])),
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
                          decoration: BoxDecoration(color: Colors.white.withOpacity(.65), borderRadius: BorderRadius.circular(LumoRadius.sm), boxShadow: [BoxShadow(color: widget.accent.withOpacity(.15), blurRadius: 10)]),
                          child: Icon(widget.icon, color: widget.accent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Flexible(child: Text(widget.title, style: LumoTextStyles.heading3.copyWith(color: widget.accent, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(width: widget.width * .56, child: Text(widget.description, style: LumoTextStyles.cardSub, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Spacer(),
                      _CtaButton(label: widget.ctaLabel, accent: widget.accent),
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
  const _CtaButton({required this.label, required this.accent});
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: LumoTextStyles.cta.copyWith(color: accent), maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(width: 4),
      Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
    ]);
  }
}

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
  final double width;

  @override
  State<WideModuleCard> createState() => _WideModuleCardState();
}

class _WideModuleCardState extends State<WideModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.xl),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.width,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.surfaceColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(LumoRadius.xl),
              border: Border.all(color: Colors.white.withOpacity(_hovered ? .95 : .75), width: 1.5),
              boxShadow: [
                BoxShadow(color: widget.accent.withOpacity(_hovered ? .22 : .12), blurRadius: _hovered ? 30 : 20, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.white.withOpacity(.80), blurRadius: 8, offset: const Offset(-3, -3)),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: 4,
                  bottom: 0,
                  child: Text(widget.objectEmoji, style: TextStyle(fontSize: 68, shadows: [Shadow(color: widget.accent.withOpacity(.22), blurRadius: 20, offset: const Offset(0, 8))])),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(.65), borderRadius: BorderRadius.circular(LumoRadius.sm)), child: Icon(widget.icon, color: widget.accent, size: 20)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.heading3.copyWith(color: widget.accent, fontSize: 16))),
                      ]),
                      const SizedBox(height: 6),
                      SizedBox(width: widget.width * .54, child: Text(widget.description, style: LumoTextStyles.cardSub, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const Spacer(),
                      _CtaButton(label: widget.ctaLabel, accent: widget.accent),
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
