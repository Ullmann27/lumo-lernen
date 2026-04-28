import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';

class SoftChipButton extends StatelessWidget {
  const SoftChipButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.accentColor = LumoColors.brandOrange,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumoRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.74),
          borderRadius: BorderRadius.circular(LumoRadius.pill),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: accentColor),
              const SizedBox(width: LumoSpacing.xs),
            ],
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentColor)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 15, color: accentColor),
          ],
        ),
      ),
    );
  }
}
