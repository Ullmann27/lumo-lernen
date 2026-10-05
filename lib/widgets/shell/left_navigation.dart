import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app_theme.dart';
import '../../theme/lumo_visual_tokens.dart';
import '../design/lumo_design_system.dart';

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

  static const _primaryItems = [
    _NavItem(LumoSection.home, Icons.home_rounded, 'Start'),
    _NavItem(LumoSection.learn, Icons.school_rounded, 'Lernen'),
    _NavItem(LumoSection.games, Icons.sports_esports_rounded, 'Spielen'),
    _NavItem(LumoSection.tests, Icons.assignment_turned_in_rounded, 'Tests'),
    _NavItem(LumoSection.rewards, Icons.star_rounded, 'Belohnungen'),
    _NavItem(LumoSection.profile, Icons.person_rounded, 'Profil'),
  ];

  static const _secondaryItems = [
    _NavItem(LumoSection.reading, Icons.record_voice_over_rounded, 'Lesemodus'),
    _NavItem(LumoSection.exercises, Icons.edit_rounded, 'Übungen'),
    _NavItem(LumoSection.schoolwork, Icons.description_rounded, 'Schularbeit'),
    _NavItem(LumoSection.scanner, Icons.photo_camera_rounded, 'Foto'),
    _NavItem(LumoSection.missions, Icons.flag_rounded, 'Missionen'),
    _NavItem(LumoSection.progress, Icons.bar_chart_rounded, 'Fortschritt'),
    _NavItem(LumoSection.agent, Icons.smart_toy_rounded, 'Lumo'),
    _NavItem(LumoSection.settings, Icons.settings_rounded, 'Eltern'),
  ];

  @override
  Widget build(BuildContext context) {
    final active = appState.state.section;
    final childName = appState.state.childName.trim().isEmpty ? 'Kind' : appState.state.childName.trim();
    final iconOnly = width < 160;
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: LumoVisualTokens.navigation,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(LumoRadius.xl),
          bottomRight: Radius.circular(LumoRadius.xl),
        ),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.22)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 24, offset: Offset(8, 0))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 22),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 14 : 20),
            child: Row(children: [
              if (!iconOnly) ...[
                const Text('LUMO', style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: LumoVisualTokens.white, height: 1.0)),
                const SizedBox(width: 4),
              ],
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: LumoVisualTokens.cyan,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: LumoVisualTokens.cyan.withOpacity(.5), blurRadius: 8)],
                ),
              ),
            ]),
          ),
          if (!iconOnly)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 16),
              child: Text('Lernen', style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w900, color: LumoVisualTokens.cyanBright, height: 1.1)),
            )
          else
            const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  ..._primaryItems.map((item) => _NavPill(
                        item: item,
                        isActive: item.section == active,
                        iconOnly: iconOnly,
                        onTap: () => onSelect(item.section),
                      )),
                  _MoreNavigationRoutes(
                    items: _secondaryItems,
                    active: active,
                    iconOnly: iconOnly,
                    onSelect: onSelect,
                  ),
                ],
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

class _MoreNavigationRoutes extends StatefulWidget {
  const _MoreNavigationRoutes({
    required this.items,
    required this.active,
    required this.iconOnly,
    required this.onSelect,
  });

  final List<_NavItem> items;
  final LumoSection active;
  final bool iconOnly;
  final ValueChanged<LumoSection> onSelect;

  @override
  State<_MoreNavigationRoutes> createState() => _MoreNavigationRoutesState();
}

class _MoreNavigationRoutesState extends State<_MoreNavigationRoutes> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.items.any((item) => item.section == widget.active);
  }

  @override
  void didUpdateWidget(covariant _MoreNavigationRoutes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active &&
        widget.items.any((item) => item.section == widget.active)) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (!widget.iconOnly)
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.more_horiz_rounded,
                color: LumoVisualTokens.cyan,
              ),
              label: Text(
                _expanded ? 'Weniger' : 'Mehr',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.muted,
                ),
              ),
            ),
          if (_expanded)
            ...widget.items.map(
              (item) => _NavPill(
                item: item,
                isActive: item.section == widget.active,
                iconOnly: widget.iconOnly,
                onTap: () => widget.onSelect(item.section),
              ),
            ),
        ],
      );
}

class _NavPill extends StatefulWidget {
  const _NavPill({required this.item, required this.isActive, required this.iconOnly, required this.onTap});
  final _NavItem item;
  final bool isActive;
  final bool iconOnly;
  final VoidCallback onTap;

  @override
  State<_NavPill> createState() => _NavPillState();
}

class _NavPillState extends State<_NavPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Heinz: 'Buttons im Tablet-Modus haben keine Beschriftung'
    // Loesung: Compact-Modus mit kleinen Labels unter Icons.
    // Nur in extrem schmaler Sidebar (<100px) zeigen wir nur Icons.
    final isUltraCompact = widget.iconOnly;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, _) {
        final pulse = 0.5 + (math.sin(_glowCtrl.value * math.pi * 2) + 1) * 0.25;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 9 : 14, vertical: 3),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                  horizontal: isUltraCompact ? 6 : 13,
                  vertical: isUltraCompact ? 8 : 9),
              decoration: BoxDecoration(
                gradient: widget.isActive
                    ? const LinearGradient(
                        colors: [
                          LumoVisualTokens.cyan,
                          LumoVisualTokens.cyanBright,
                        ])
                    : null,
                color: widget.isActive ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(LumoRadius.pill),
                // HOLOGRAM-GLOW: aktive Pille pulsiert + farbiger Schein
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: LumoVisualTokens.cyan.withOpacity(0.45 * pulse),
                          blurRadius: 22 + pulse * 6,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: LumoVisualTokens.cyanBright.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
                border: widget.isActive
                    ? Border.all(
                        color: Colors.white.withOpacity(0.45 + pulse * 0.20),
                        width: 1.2)
                    : null,
              ),
              child: isUltraCompact
                  ? _compactLayout()
                  : _fullLayout(),
            ),
          ),
        );
      },
    );
  }

  Widget _fullLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _iconBox(40),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            widget.item.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: widget.isActive
                ? LumoTextStyles.navItemActive
                    .copyWith(color: LumoVisualTokens.night)
                : LumoTextStyles.navItem
                    .copyWith(color: LumoVisualTokens.muted),
          ),
        ),
      ],
    );
  }

  /// Compact-Layout: Icon + kleine Beschriftung darunter.
  /// Heinz: 'Buttons im Tablet-Modus muessen beschriftet werden.'
  Widget _compactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconBox(32),
        const SizedBox(height: 4),
        Text(
          widget.item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: 9.5,
            letterSpacing: 0.2,
            height: 1.0,
            color: widget.isActive ? LumoVisualTokens.night : LumoVisualTokens.muted,
          ),
        ),
      ],
    );
  }

  Widget _iconBox(double size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: widget.isActive
            ? Colors.white.withOpacity(.40)
            : LumoVisualTokens.glassRow,
        borderRadius: BorderRadius.circular(LumoRadius.sm),
      ),
      child: Icon(widget.item.icon,
          color:
              widget.isActive ? LumoVisualTokens.night : LumoVisualTokens.cyan,
          size: size * 0.58),
    );
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
    final chip = GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: iconOnly ? 9 : 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: LumoVisualTokens.glass,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.3)),
        ),
        child: Row(mainAxisAlignment: iconOnly ? MainAxisAlignment.center : MainAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: LumoVisualTokens.glass,
              shape: BoxShape.circle,
              border: Border.all(color: LumoVisualTokens.cyan, width: 1.5),
            ),
            child: const ClipOval(
              child: LumoFoxPose(
                pose: LumoDesignFoxPose.avatar,
                size: 34,
              ),
            ),
          ),
          if (!iconOnly) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w900, fontSize: 14, color: LumoVisualTokens.white)),
                Text(grade, maxLines: 1, overflow: TextOverflow.ellipsis, style: LumoTextStyles.caption.copyWith(color: LumoVisualTokens.muted)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: LumoVisualTokens.cyan),
          ],
        ]),
      ),
    );
    return iconOnly ? Tooltip(message: '$name · $grade', child: chip) : chip;
  }
}
