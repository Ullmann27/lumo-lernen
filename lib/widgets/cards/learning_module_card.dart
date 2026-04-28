import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../common/soft_chip_button.dart';

class LearningModuleCard extends StatelessWidget {
  const LearningModuleCard({
    super.key,
    required this.title,
    required this.description,
    required this.ctaLabel,
    required this.icon,
    required this.accentColor,
    required this.visual,
    this.onTap,
    this.width = 245,
    this.height = 165,
  });

  final String title;
  final String description;
  final String ctaLabel;
  final IconData icon;
  final Color accentColor;
  final Widget visual;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumoRadius.card),
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(18),
        decoration: LumoSurfaces.module(accentColor),
        child: Stack(
          children: [
            Positioned(right: 0, bottom: 0, child: visual),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: LumoSurfaces.softCard(color: Colors.white.withOpacity(.88), radius: LumoRadius.small, shadowColor: accentColor),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: LumoSpacing.sm),
                    Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.cardTitle.copyWith(color: accentColor))),
                  ],
                ),
                const SizedBox(height: LumoSpacing.sm),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: LumoTextStyles.cardBody),
                const Spacer(),
                SoftChipButton(label: ctaLabel, onTap: onTap, accentColor: accentColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LearningModuleVisualText extends StatelessWidget {
  const LearningModuleVisualText({super.key, required this.text, required this.accentColor, this.fontSize = 45});

  final String text;
  final Color accentColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1,
        fontWeight: FontWeight.w900,
        color: accentColor,
        shadows: const [Shadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
    );
  }
}
