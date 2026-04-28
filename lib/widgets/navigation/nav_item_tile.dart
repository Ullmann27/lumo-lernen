import 'package:flutter/material.dart';
import '../../app/lumo_design_tokens.dart';
import '../common/lumo_badge_icon.dart';

class NavItemData {
  const NavItemData({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class NavItemTile extends StatelessWidget {
  const NavItemTile({
    super.key,
    required this.item,
    required this.selected,
  });

  final NavItemData item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: LumoSpacing.md),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(LumoRadius.kpi),
        child: AnimatedContainer(
          duration: LumoDurations.fast,
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: selected
              ? BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xfffff1df), Color(0xffffdfb9)]),
                  borderRadius: BorderRadius.circular(LumoRadius.kpi),
                  boxShadow: [BoxShadow(color: LumoColors.brandOrange.withOpacity(.24), blurRadius: 22, offset: const Offset(0, 10))],
                )
              : null,
          child: Row(
            children: [
              LumoBadgeIcon(icon: item.icon, accentColor: item.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: selected ? LumoColors.brandOrange : const Color(0xff655b54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
