import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';

class LeftNavigation extends StatelessWidget {
  const LeftNavigation({
    super.key,
    required this.appState,
    required this.onSelect,
    this.width = 230,
  });

  final LumoAppState appState;
  final ValueChanged<LumoSection> onSelect;
  final double width;

  static const _items = [
    _NavItem(LumoSection.home, Icons.home_rounded, 'Start'),
    _NavItem(LumoSection.learn, Icons.school_rounded, 'Lernen'),
    _NavItem(LumoSection.reading, Icons.record_voice_over_rounded, 'Lesemodus'),
    _NavItem(LumoSection.exercises, Icons.edit_rounded, 'Übungen'),
    _NavItem(LumoSection.tests, Icons.assignment_turned_in_rounded, 'Test'),
    _NavItem(LumoSection.schoolwork, Icons.description_rounded, 'Schularbeit'),
    _NavItem(LumoSection.scanner, Icons.photo_camera_rounded, 'Foto'),
    _NavItem(LumoSection.missions, Icons.flag_rounded, 'Missionen'),
    _NavItem(LumoSection.progress, Icons.bar_chart_rounded, 'Fortschritt'),
    _NavItem(LumoSection.rewards, Icons.star_rounded, 'Belohnungen'),
    _NavItem(LumoSection.agent, Icons.smart_toy_rounded, 'Lumo'),
    _NavItem(LumoSection.profile, Icons.person_rounded, 'Profil'),
    _NavItem(LumoSection.settings, Icons.settings_rounded, 'Eltern'),
  ];

  @override
  Widget build(BuildContext context) {
    final active = appState.state.section;
    final childName = appState.state.childName.trim().isEmpty ? 'Kind' : appState.state.childName.trim();
    final iconOnly = width < 180;
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: LumoColors.leftNavBg,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(LumoRadius.xl),
          bottomRight: Radius.circular(LumoRadius.xl),
        ),
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 24, offset: Offset(8, 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 14 : 20),
            child: Row(children: [
              if (!iconOnly) ...[
                const Text('Lumo', style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: LumoColors.orange, height: 1.0)),
                const SizedBox(width: 4),
              ],
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [LumoColors.gold, LumoColors.orange]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: LumoColors.gold.withOpacity(.5), blurRadius: 8)],
                ),
              ),
            ]),
          ),
          if (!iconOnly)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 16),
              child: Text('Lernen', style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: LumoColors.orange, height: 1.1)),
            )
          else
            const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: _items.map((item) => _NavPill(item: item, isActive: item.section == active, iconOnly: iconOnly, onTap: () => onSelect(item.section))).toList(),
              ),
            ),
          ),
          _ProfileChip(name: childName, grade: 'Klasse ${appState.state.grade}', iconOnly: iconOnly, onTap: () => onSelect(LumoSection.profile)),
          const SizedBox(height: 16),
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
  const _NavPill({required this.item, required this.isActive, required this.iconOnly, required this.onTap});
  final _NavItem item;
  final bool isActive;
  final bool iconOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Padding(
      padding: EdgeInsets.symmetric(horizontal: iconOnly ? 9 : 14, vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: iconOnly ? 10 : 13, vertical: 9),
          decoration: BoxDecoration(
            gradient: isActive ? const LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight]) : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            boxShadow: isActive ? LumoShadow.pill : [],
          ),
          child: Row(mainAxisAlignment: iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(.25) : LumoColors.orangeSurface,
                borderRadius: BorderRadius.circular(LumoRadius.sm),
              ),
              child: Icon(item.icon, color: isActive ? Colors.white : LumoColors.orange, size: 19),
            ),
            if (!iconOnly) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: isActive ? LumoTextStyles.navItemActive : LumoTextStyles.navItem.copyWith(color: LumoColors.ink700),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
    return iconOnly ? Tooltip(message: item.label, child: pill) : pill;
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.name, required this.grade, required this.iconOnly, required this.onTap});
  final String name;
  final String grade;
  final bool iconOnly;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'K' : name.trim().characters.first.toUpperCase();
    final chip = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: iconOnly ? 9 : 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LumoColors.orangeSurface,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: LumoColors.orange.withOpacity(.15)),
        ),
        child: Row(mainAxisAlignment: iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [LumoColors.orange, LumoColors.orangeLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(initial, style: const TextStyle(fontFamily: 'Nunito', color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
          ),
          if (!iconOnly) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 14, color: LumoColors.ink900)),
                Text(grade, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.caption),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: LumoColors.ink300),
          ],
        ]),
      ),
    );
    return iconOnly ? Tooltip(message: '$name · $grade', child: chip) : chip;
  }
}
