import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/lernen_screen.dart';
import '../screens/lumo_agent_screen.dart';
import '../screens/aufgabe_erkennen_screen.dart';
import '../screens/kognitiver_lerncheck_screen.dart';
import '../screens/bonus_screen.dart';
import '../screens/elternbereich_screen.dart';
import '../screens/memory_graph_screen.dart';
import '../screens/datenschutz_screen.dart';
import '../screens/wwm_screen.dart';
import '../screens/wettbewerb_screen.dart';
import '../theme/app_theme.dart';

class AdaptiveNav extends StatefulWidget {
  const AdaptiveNav({super.key});

  @override
  State<AdaptiveNav> createState() => _AdaptiveNavState();
}

class _AdaptiveNavState extends State<AdaptiveNav> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.school_rounded, label: 'Lernen'),
    _NavItem(icon: Icons.quiz_rounded, label: 'Quiz'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'Lumo'),
    _NavItem(icon: Icons.camera_alt_rounded, label: 'Erkennen'),
    _NavItem(icon: Icons.psychology_rounded, label: 'Lern-Check'),
    _NavItem(icon: Icons.card_giftcard_rounded, label: 'Bonus'),
    _NavItem(icon: Icons.emoji_events_rounded, label: 'Wettbewerb'),
    _NavItem(icon: Icons.family_restroom_rounded, label: 'Eltern'),
    _NavItem(icon: Icons.account_tree_rounded, label: 'Lernbaum'),
    _NavItem(icon: Icons.security_rounded, label: 'Datenschutz'),
  ];

  static final List<Widget> _screens = [
    const HomeScreen(),
    const LernenScreen(),
    const WwmScreen(),
    const LumoAgentScreen(),
    const AufgabeErkennenScreen(),
    const KognitiverLernCheckScreen(),
    const BonusScreen(),
    const WettbewerbScreen(),
    const ElternbereichScreen(),
    const MemoryGraphScreen(),
    const DatenschutzScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    if (isWide) {
      return _buildWideLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _navItems.length,
            itemBuilder: (context, i) {
              final item = _navItems[i];
              final isSelected = i == _selectedIndex;
              return ListTile(
                leading: Icon(
                  item.icon,
                  color: isSelected
                      ? AppTheme.orange
                      : const Color(0xFF4A4A4A),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.orange
                        : const Color(0xFF2D2D2D),
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                tileColor: isSelected
                    ? AppTheme.orange.withOpacity(0.08)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  setState(() => _selectedIndex = i);
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
      body: Stack(
        children: [
          _screens[_selectedIndex],
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF2D1B69),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.orange.withOpacity(0.2),
            destinations: _navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
