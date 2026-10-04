import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/lumo_companion_pose.dart';
import '../../features/companion/lumo_companion_pose_image.dart';
import '../../theme/lumo_visual_tokens.dart';

enum LumoScene {
  home,
  learning,
  tests,
  games,
  profile,
}

class LumoSceneBackground extends StatelessWidget {
  const LumoSceneBackground({
    super.key,
    this.scene = LumoScene.home,
    this.backgroundAsset,
    this.showPlaceholderLabel = true,
    this.child,
  });

  final LumoScene scene;
  final String? backgroundAsset;
  final bool showPlaceholderLabel;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final asset = backgroundAsset ?? 'assets/design/scenes/${scene.name}.webp';
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(
              color: LumoVisualTokens.night,
            ),
          ),
        ),
        if (child != null) child!,
        if (showPlaceholderLabel)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: LumoVisualTokens.navigation.withOpacity(.92),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: LumoVisualTokens.cyan.withOpacity(.65)),
              ),
              child: const Text(
                'SZENENBILD-PLATZHALTER',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .5,
                  color: LumoVisualTokens.cyan,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class LumoGlassCard extends StatelessWidget {
  const LumoGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: (color ?? LumoVisualTokens.glass).withOpacity(.68),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: borderColor ?? LumoVisualTokens.cyan.withOpacity(.52),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.12),
              blurRadius: 22,
              spreadRadius: -4,
            ),
            const BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: child,
      );
}

class LumoColorTile extends StatelessWidget {
  const LumoColorTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$title. $subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Ink(
              constraints: const BoxConstraints(minHeight: 142),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, .20)!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(.38)),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.16),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(icon, size: 32, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.only(right: 32),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(.86),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.white.withOpacity(.22),
                      child: const Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 19),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class LumoTopBar extends StatelessWidget {
  const LumoTopBar({
    super.key,
    required this.appState,
    this.onTapStatus,
  });

  final LumoAppState appState;
  final VoidCallback? onTapStatus;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appState,
        builder: (context, _) => _buildForState(),
      );

  Widget _buildForState() {
    final state = appState.state;
    return Row(
      children: [
        const Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'LUMO',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'LUM',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: LumoVisualTokens.white,
                        shadows: [
                          Shadow(color: LumoVisualTokens.cyan, blurRadius: 12),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 29,
                      height: 30,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'O',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: LumoVisualTokens.white,
                              shadows: [
                                Shadow(
                                  color: LumoVisualTokens.cyan,
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: LumoVisualTokens.cyanBright,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Lernen. Spielen. Weiterkommen.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: LumoVisualTokens.cyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Semantics(
            button: onTapStatus != null,
            label:
                'Level ${state.level}, Klasse ${state.grade}, ${state.stars} Sterne, ${state.xp % 400} von 400 XP',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTapStatus,
                child: LumoGlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  radius: 24,
                  child: Row(
                    children: [
                      const LumoFoxPose(
                        pose: LumoCompanionPose.idle,
                        size: 36,
                        showPlaceholderLabel: false,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Level ${state.level} · ${state.grade}. Klasse',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: LumoVisualTokens.white,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: LumoVisualTokens.gold),
                                Text(
                                  '${state.stars}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    color: LumoVisualTokens.white,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: LinearProgressIndicator(
                                      minHeight: 5,
                                      value: (state.xp % 400) / 400,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        LumoVisualTokens.cyanBright,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${state.xp % 400} / 400 XP',
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                                color: LumoVisualTokens.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: LumoVisualTokens.cyan, size: 19),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class LumoSpeechBubble extends StatelessWidget {
  const LumoSpeechBubble({
    super.key,
    required this.text,
    this.handwritten = false,
    this.alignRight = false,
  });

  final String text;
  final bool handwritten;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Transform.rotate(
          angle: alignRight ? -.025 : .012,
          child: LumoGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            radius: 18,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: handwritten ? null : 'Nunito',
                fontSize: handwritten ? 20 : 14,
                fontWeight: handwritten ? FontWeight.w700 : FontWeight.w800,
                color: LumoVisualTokens.white,
              ),
            ),
          ),
        ),
      );
}

class LumoFoxPose extends StatelessWidget {
  const LumoFoxPose({
    super.key,
    required this.pose,
    this.size = 120,
    this.showPlaceholderLabel = true,
  });

  final LumoCompanionPose pose;
  final double size;
  final bool showPlaceholderLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: '${pose.semanticLabel}. Vorläufiges Posenbild.',
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            LumoCompanionPoseImage(
              pose: pose,
              size: size,
              showGlow: pose == LumoCompanionPose.cheer ||
                  pose == LumoCompanionPose.surprised,
            ),
            if (showPlaceholderLabel)
              Positioned(
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: LumoVisualTokens.navigation.withOpacity(.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: LumoVisualTokens.cyan.withOpacity(.60)),
                  ),
                  child: const Text(
                    'POSE-PLATZHALTER',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 7,
                      letterSpacing: .5,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.cyan,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class LumoBottomNavigation extends StatelessWidget {
  const LumoBottomNavigation({
    super.key,
    required this.active,
    required this.onSelect,
  });

  final LumoSection active;
  final ValueChanged<LumoSection> onSelect;

  static const _items = <_LumoNavigationItem>[
    _LumoNavigationItem(LumoSection.home, Icons.home_rounded, 'Start'),
    _LumoNavigationItem(LumoSection.learn, Icons.menu_book_rounded, 'Lernen'),
    _LumoNavigationItem(
        LumoSection.games, Icons.sports_esports_rounded, 'Spielen'),
    _LumoNavigationItem(
        LumoSection.tests, Icons.emoji_events_rounded, 'Tests'),
    _LumoNavigationItem(
        LumoSection.profile, Icons.sentiment_satisfied_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: LumoVisualTokens.navigation,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.24)),
          boxShadow: [
            BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.12),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: _items.map((item) {
            final selected = active == item.section;
            final color =
                selected ? LumoVisualTokens.cyanBright : LumoVisualTokens.muted;
            return Expanded(
              child: Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: InkWell(
                  key: ValueKey('lumo-nav-${item.label.toLowerCase()}'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(item.section);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.12 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(item.icon, size: 21, color: color),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 10,
                            color: color,
                            shadows: selected
                                ? const [
                                    Shadow(
                                      color: LumoVisualTokens.cyan,
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
}

class _LumoNavigationItem {
  const _LumoNavigationItem(this.section, this.icon, this.label);

  final LumoSection section;
  final IconData icon;
  final String label;
}
