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
    final settings = appState.state.settings;
    final reduceMotion = settings.reduceAnimations ||
        settings.calmMode ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final childName = appState.state.childName.trim().isEmpty ? 'Kind' : appState.state.childName.trim();
    final iconOnly = width < 110;
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
                        reduceMotion: reduceMotion,
                        onTap: () => onSelect(item.section),
                      )),
                  // All 14 destinations remain in one continuous scroll
                  // without a hidden "Discover" dropdown or additional tap.
                  _NavGroupTitle('Lernen & Üben', iconOnly: iconOnly),
                  ..._secondaryItems.take(4).map((item) => _NavPill(
                        item: item,
                        isActive: item.section == active,
                        iconOnly: iconOnly,
                        reduceMotion: reduceMotion,
                        onTap: () => onSelect(item.section),
                      )),
                  _NavGroupTitle('Meine Erfolge', iconOnly: iconOnly),
                  ..._secondaryItems.skip(4).take(2).map((item) => _NavPill(
                        item: item,
                        isActive: item.section == active,
                        iconOnly: iconOnly,
                        reduceMotion: reduceMotion,
                        onTap: () => onSelect(item.section),
                      )),
                  _NavGroupTitle('Lumo & Eltern', iconOnly: iconOnly),
                  ..._secondaryItems.skip(6).map((item) => _NavPill(
                        item: item,
                        isActive: item.section == active,
                        iconOnly: iconOnly,
                        reduceMotion: reduceMotion,
                        onTap: () => onSelect(item.section),
                      )),
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

class _NavGroupTitle extends StatelessWidget {
  const _NavGroupTitle(this.text, {required this.iconOnly});
  final String text;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(iconOnly ? 4 : 22, 16, 6, 4),
        child: Semantics(
          header: true,
          child: iconOnly
              ? Divider(color: LumoVisualTokens.cyan.withOpacity(.35))
              : Text(
                  text,
                  style: const TextStyle(
                    color: LumoVisualTokens.cyanBright,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
        ),
      );
}

class _NavPill extends StatefulWidget {
  const _NavPill({required this.item, required this.isActive, required this.iconOnly, required this.reduceMotion, required this.onTap});
  final _NavItem item;
  final bool isActive;
  final bool iconOnly;
  final bool reduceMotion;
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
    );
    _syncGlow();
  }

  @override
  void didUpdateWidget(covariant _NavPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.reduceMotion != widget.reduceMotion) {
      _syncGlow();
    }
  }

  void _syncGlow() {
    // Explicit calm/reduced-motion preferences stop the ticker itself,
    // including when changed while this same sidebar remains on screen.
    if (widget.isActive && !widget.reduceMotion) {
      if (!_glowCtrl.isAnimating) _glowCtrl.repeat(reverse: true);
    } else {
      _glowCtrl.stop();
      if (widget.reduceMotion) _glowCtrl.value = 0;
    }
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
          child: Semantics(
            button: true,
            selected: widget.isActive,
            label: widget.item.label,
            child: GestureDetector(
              key: ValueKey('lumo-nav-${widget.item.section.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: AnimatedContainer(
              duration: widget.reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
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
                  : LayoutBuilder(builder: (context, constraints) {
                      // A 160px Fold rail leaves only 56px beside the icon.
                      // Stack the complete label instead of painting it over
                      // the neighbouring page; larger system text also wraps.
                      final enlarged = MediaQuery.textScalerOf(context).scale(14) > 16;
                      return constraints.maxWidth < 145 || enlarged
                          ? _compactLayout(fontSize: 14)
                          : _fullLayout();
                    }),
                ),
              ),
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
            overflow: TextOverflow.ellipsis,
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
  Widget _compactLayout({double fontSize = 9.5}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconBox(32),
        const SizedBox(height: 4),
        Text(
          widget.item.label,
          maxLines: 3,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            fontSize: fontSize,
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
      duration: widget.reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
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
