import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class LeftNavigation extends StatelessWidget {
  const LeftNavigation({
    super.key,
    required this.appState,
    required this.onSelect,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSelect;

  static const _items = [
    _NavItem(LumoSection.home,     Icons.home_rounded,        'Start'),
    _NavItem(LumoSection.learn,    Icons.school_rounded,      'Lernen'),
    _NavItem(LumoSection.exercises,Icons.edit_rounded,        'Übungen'),
    _NavItem(LumoSection.progress, Icons.bar_chart_rounded,   'Fortschritt'),
    _NavItem(LumoSection.rewards,  Icons.star_rounded,        'Belohnungen'),
    _NavItem(LumoSection.profile,  Icons.person_rounded,      'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    final active = appState.state.section;
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        color: LumoColors.leftNavBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(LumoRadius.xl),
          bottomRight: Radius.circular(LumoRadius.xl),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          // ── Logo ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text(
                'Lumo',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: LumoColors.orange,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LumoColors.gold, LumoColors.orange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LumoColors.gold.withOpacity(.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 28),
            child: const Text(
              'Lernen',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: LumoColors.orange,
                height: 1.1,
              ),
            ),
          ),

          // ── Nav Items ─────────────────────────────────────
          ..._items.map((item) => _NavPill(
                item: item,
                isActive: item.section == active,
                onTap: () => onSelect(item.section),
              )),

          const Spacer(),

          // ── Profile Chip ──────────────────────────────────
          _ProfileChip(
            name: 'Lena',
            grade: 'Klasse 2',
            onTap: () => onSelect(LumoSection.profile),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.section, this.icon, this.label);
  final LumoSection section;
  final IconData icon;
  final String label;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.isActive,
    required this.onTap,
  });
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [LumoColors.orange, LumoColors.orangeLight],
                  )
                : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            boxShadow: isActive ? LumoShadow.pill : [],
          ),
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(.25)
                    : LumoColors.orangeSurface,
                borderRadius: BorderRadius.circular(LumoRadius.sm),
              ),
              child: Icon(
                item.icon,
                color: isActive ? Colors.white : LumoColors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              item.label,
              style: isActive
                  ? LumoTextStyles.navItemActive
                  : LumoTextStyles.navItem.copyWith(
                      color: LumoColors.ink700,
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.name,
    required this.grade,
    required this.onTap,
  });
  final String name;
  final String grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LumoColors.orangeSurface,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(
            color: LumoColors.orange.withOpacity(.15),
          ),
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LumoColors.orange, LumoColors.orangeLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: LumoColors.ink900,
                  ),
                ),
                Text(
                  grade,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LumoTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 18, color: LumoColors.ink300),
        ]),
      ),
    );
  }
}
