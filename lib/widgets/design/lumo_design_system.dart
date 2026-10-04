import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_state.dart';
import '../../core/progress_repository.dart';
import '../../features/shared/widgets/lumo_premium_effects.dart';
import '../../theme/lumo_visual_tokens.dart';

enum LumoDesignFoxPose {
  kartWave('fox_kart_wave', 'Lumo winkt im Kart'),
  tabletThumb('fox_tablet_thumb', 'Lumo zeigt das Tablet und Daumen hoch'),
  bookPoint('fox_book_point', 'Lumo zeigt auf das Buch'),
  pointSide('fox_point_side', 'Lumo zeigt zur Seite'),
  trophyWink('fox_trophy_wink', 'Lumo jubelt mit einem Pokal'),
  armsOpen('fox_arms_open', 'Lumo begrüßt dich mit offenen Armen'),
  thumbWink('fox_thumb_wink', 'Lumo zwinkert und zeigt Daumen hoch'),
  teacherStick('fox_teacher_stick', 'Lumo erklärt mit dem Zeigestab'),
  cheer('fox_cheer', 'Lumo jubelt'),
  avatar('fox_avatar', 'Lumo, dein Profilbild');

  const LumoDesignFoxPose(this.assetName, this.semanticLabel);

  final String assetName;
  final String semanticLabel;

  String get assetPath => 'assets/lumo_design/fox/$assetName.png';
}

enum LumoScene {
  home,
  learning,
  library,
  tests,
  games,
  profile,
  kart,
  wide,
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
    final asset = backgroundAsset ??
        switch (scene) {
          LumoScene.home => 'assets/lumo_design/bg/bg_home.png',
          LumoScene.learning => 'assets/lumo_design/bg/bg_learn.png',
          LumoScene.library => 'assets/lumo_design/bg/bg_library.png',
          LumoScene.tests => 'assets/lumo_design/bg/bg_tests.png',
          LumoScene.games => 'assets/lumo_design/bg/bg_games.png',
          LumoScene.profile => 'assets/lumo_design/bg/bg_profile.png',
          LumoScene.kart => 'assets/lumo_design/bg/bg_kart.png',
          LumoScene.wide => 'assets/lumo_design/bg/bg_wide.png',
        };
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    LumoVisualTokens.night,
                    LumoVisualTokens.glass,
                    LumoVisualTokens.navigation,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.landscape_rounded,
                  size: 72,
                  color: Color(0x4437D2FD),
                ),
              ),
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.hasBoundedHeight && constraints.maxHeight < 142;
          final padding = compact ? 8.0 : 16.0;
          final iconPadding = compact ? 5.0 : 10.0;
          final iconSize = compact ? 20.0 : 32.0;
          final arrowRadius = compact ? 12.0 : 17.0;
          return Semantics(
            button: true,
            label: '$title. $subtitle',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: compact ? 0 : 142),
                  child: Ink(
                    padding: EdgeInsets.all(padding),
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
                                padding: EdgeInsets.all(iconPadding),
                                child: Icon(icon,
                                    size: iconSize, color: Colors.white),
                              ),
                            ),
                            if (compact)
                              const SizedBox(height: 3)
                            else
                              const Spacer(),
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w900,
                                fontSize: compact ? 12 : 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: compact ? 0 : 2),
                            Padding(
                              padding:
                                  EdgeInsets.only(right: compact ? 22 : 32),
                              child: Text(
                                subtitle,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(.86),
                                  fontSize: compact ? 9 : 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: arrowRadius,
                            backgroundColor: Colors.white.withOpacity(.22),
                            child: Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: compact ? 14 : 19),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}

class LumoTopBar extends StatelessWidget {
  const LumoTopBar({
    super.key,
    required this.appState,
    this.onTapStatus,
    this.onTapFox,
  });

  final LumoAppState appState;
  final VoidCallback? onTapStatus;
  final VoidCallback? onTapFox;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appState,
        builder: (context, _) => _buildForState(context),
      );

  Widget _buildForState(BuildContext context) {
    final state = appState.state;
    final reduceMotion = state.settings.reduceAnimations ||
        state.settings.calmMode ||
        MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;
        return Row(
          children: [
            Expanded(
              flex: compact ? 5 : 4,
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
                              Shadow(
                                  color: LumoVisualTokens.cyan, blurRadius: 12),
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
            SizedBox(width: compact ? 6 : 10),
            Expanded(
              flex: compact ? 5 : 6,
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
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 6 : 10,
                        vertical: compact ? 6 : 8,
                      ),
                      radius: 24,
                      child: Row(
                        children: [
                          Semantics(
                            label: 'Lumo, dein Lernfuchs. Hilfe öffnen',
                            button: true,
                            onTap: onTapFox,
                            excludeSemantics: true,
                            child: GestureDetector(
                              key: const ValueKey('mobile-lumo-button'),
                              excludeFromSemantics: true,
                              onTap: onTapFox,
                              child: SizedBox(
                                width: compact ? 32 : 52,
                                height: compact ? 32 : 52,
                                child: ExcludeSemantics(
                                  child: reduceMotion
                                      ? _avatar(size: compact ? 32 : 52)
                                      : LumoFloating(
                                          amplitude: 3,
                                          duration: const Duration(
                                              milliseconds: 2800),
                                          child: LumoGlowPulse(
                                            color: LumoVisualTokens.cyan,
                                            minBlur: 6,
                                            maxBlur: 18,
                                            child: _avatar(
                                                size: compact ? 32 : 52),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 4 : 8),
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
                                              const AlwaysStoppedAnimation<
                                                  Color>(
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
                          Icon(Icons.chevron_right_rounded,
                              color: LumoVisualTokens.cyan,
                              size: compact ? 16 : 19),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _avatar({double size = 52}) => Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LumoVisualTokens.glass,
          border: Border.all(color: LumoVisualTokens.cyan, width: 2),
          boxShadow: [
            BoxShadow(
              color: LumoVisualTokens.cyan.withOpacity(.40),
              blurRadius: 9,
            ),
          ],
        ),
        child: ClipOval(
          child: LumoFoxPose(
            pose: LumoDesignFoxPose.avatar,
            size: size - 8,
          ),
        ),
      );
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
                fontStyle: handwritten ? FontStyle.italic : FontStyle.normal,
                letterSpacing: handwritten ? .35 : 0,
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
  });

  final LumoDesignFoxPose pose;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: pose.semanticLabel,
        child: Image.asset(
          pose.assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          cacheWidth: (size * 2).round(),
          cacheHeight: (size * 2).round(),
          errorBuilder: (context, error, stackTrace) => SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: LumoVisualTokens.glass,
                border: Border.all(color: LumoVisualTokens.cyan),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'POSE FEHLT\n${pose.assetName}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: LumoVisualTokens.cyanBright,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
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
    _LumoNavigationItem(LumoSection.tests, Icons.emoji_events_rounded, 'Tests'),
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

class LumoFoldProgressPanel extends StatelessWidget {
  const LumoFoldProgressPanel({
    super.key,
    required this.appState,
    required this.onOpenRewards,
  });

  final LumoAppState appState;
  final VoidCallback onOpenRewards;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: appState,
        builder: (context, _) {
          final skills = appState.learningSkills();
          final dailyGoal = appState.state.settings.dailyGoal.clamp(1, 500);
          final dailyDone = appState.learningDailyDone();
          return SizedBox(
            width: 226,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LumoGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dein Lernfortschritt',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: LumoVisualTokens.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 12,
                          children: [
                            _FoldSkillRing(
                              label: 'Mathe',
                              value: _masteryFor(skills.values, 'Mathematik'),
                            ),
                            _FoldSkillRing(
                              label: 'Deutsch',
                              value: _masteryFor(skills.values, 'Deutsch'),
                            ),
                            _FoldSkillRing(
                              label: 'Lesen',
                              value: _masteryFor(skills.values, 'Lesen'),
                            ),
                            _FoldSkillRing(
                              label: 'Sachkunde',
                              value:
                                  _masteryFor(skills.values, 'Sachunterricht'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  LumoGlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tägliche Aufgaben',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            color: LumoVisualTokens.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$dailyDone von $dailyGoal Aufgaben geschafft',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: LumoVisualTokens.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (dailyDone / dailyGoal).clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: LumoVisualTokens.navigation,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              LumoVisualTokens.cyanBright,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenRewards,
                      borderRadius: BorderRadius.circular(24),
                      child: LumoGlassCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: LumoVisualTokens.gold,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Deine Belohnungen',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w900,
                                      color: LumoVisualTokens.white,
                                    ),
                                  ),
                                  Text(
                                    '${appState.state.stars} Sterne',
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      color: LumoVisualTokens.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: LumoVisualTokens.cyan),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

  double _masteryFor(Iterable<SkillRecord> records, String subject) {
    final matching =
        records.where((record) => record.subject == subject).toList();
    if (matching.isEmpty) return 0;
    return matching.fold<int>(0, (total, record) => total + record.mastery) /
        matching.length /
        100;
  }
}

class _FoldSkillRing extends StatelessWidget {
  const _FoldSkillRing({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 84,
        child: Column(
          children: [
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: value,
                    strokeWidth: 6,
                    backgroundColor: LumoVisualTokens.navigation,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      LumoVisualTokens.cyanBright,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: LumoVisualTokens.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: LumoVisualTokens.muted,
              ),
            ),
          ],
        ),
      );
}

class _LumoNavigationItem {
  const _LumoNavigationItem(this.section, this.icon, this.label);

  final LumoSection section;
  final IconData icon;
  final String label;
}
