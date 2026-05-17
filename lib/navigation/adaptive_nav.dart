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
import '../theme/app_theme.dart';

class AdaptiveNav extends StatefulWidget {
  const AdaptiveNav({super.key});

  @override
  State<AdaptiveNav> createState() => _AdaptiveNavState();
}

class _AdaptiveNavState extends State<AdaptiveNav> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.school_rounded, label: 'Lernen'),
    _NavItem(icon: Icons.quiz_rounded, label: 'Quiz'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'Lumo'),
    _NavItem(icon: Icons.camera_alt_rounded, label: 'Erkennen'),
    _NavItem(icon: Icons.psychology_rounded, label: 'Lern-Check'),
    _NavItem(icon: Icons.card_giftcard_rounded, label: 'Bonus'),
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
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.orange.withOpacity(0.2),
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
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
