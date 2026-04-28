import 'package:flutter/material.dart';
import '../app/lumo_design_tokens.dart';
import 'navigation/nav_item_tile.dart';
import 'shell/left_navigation.dart';
import 'shell/lumo_stage_panel.dart';
import 'shell/main_content_host.dart';

class StableLumoShell extends StatelessWidget {
  const StableLumoShell({
    super.key,
    required this.activeIndex,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.lumo,
    required this.stars,
    required this.xp,
    required this.level,
    required this.progress,
    required this.onHome,
    required this.onLearn,
    required this.onPractice,
    required this.onTest,
    required this.onScan,
    required this.onProfile,
    this.onVoice,
  });

  final int activeIndex;
  final String title;
  final String subtitle;
  final Widget body;
  final Widget lumo;
  final int stars;
  final int xp;
  final int level;
  final int progress;
  final VoidCallback onHome;
  final VoidCallback onLearn;
  final VoidCallback onPractice;
  final VoidCallback onTest;
  final VoidCallback onScan;
  final VoidCallback onProfile;
  final VoidCallback? onVoice;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 840;
    final items = _navItems;

    return Container(
      decoration: const BoxDecoration(gradient: LumoGradients.appBackground),
      padding: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: LumoSurfaces.shell(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LumoRadius.shell),
          child: Material(
            color: Colors.transparent,
            child: wide
                ? Row(
                    children: [
                      LeftNavigation(items: items, activeIndex: activeIndex),
                      Expanded(
                        child: MainContentHost(
                          title: title,
                          body: body,
                          stars: stars,
                          xp: xp,
                          level: level,
                          progress: progress,
                          onVoice: onVoice,
                        ),
                      ),
                      LumoStagePanel(lumo: lumo, subtitle: subtitle),
                    ],
                  )
                : Column(
                    children: [
                      Expanded(
                        child: MainContentHost(
                          title: title,
                          body: body,
                          stars: stars,
                          xp: xp,
                          level: level,
                          progress: progress,
                          onVoice: onVoice,
                        ),
                      ),
                      NavigationBar(
                        selectedIndex: activeIndex.clamp(0, items.length - 1),
                        onDestinationSelected: (i) => items[i].onTap(),
                        destinations: [for (final n in items) NavigationDestination(icon: Icon(n.icon), label: n.label)],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  List<NavItemData> get _navItems => [
        NavItemData(label: 'Start', icon: Icons.home_rounded, color: LumoColors.brandOrange, onTap: onHome),
        NavItemData(label: 'Lernen', icon: Icons.school_rounded, color: LumoColors.lavender, onTap: onLearn),
        NavItemData(label: 'Übungen', icon: Icons.edit_rounded, color: const Color(0xffff6b6b), onTap: onPractice),
        NavItemData(label: 'Fortschritt', icon: Icons.bar_chart_rounded, color: LumoColors.mint, onTap: onProfile),
        NavItemData(label: 'Belohnungen', icon: Icons.star_rounded, color: LumoColors.softGold, onTap: onPractice),
        NavItemData(label: 'Profil', icon: Icons.person_rounded, color: const Color(0xffa855f7), onTap: onProfile),
      ];
}
