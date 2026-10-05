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
  spielweltDance('fox_spielwelt_dance',
      'Lumo tanzt mit Kopfhörern, Halstuch und Rucksack'),
  spielweltJump('fox_spielwelt_jump',
      'Lumo springt fröhlich mit Halstuch und Rucksack'),
  spielweltWave('fox_spielwelt_wave',
      'Lumo mit Halstuch und Rucksack winkt dich in die Spielwelt'),
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
    this.showPlaceholderLabel = false,
    this.dimmed = false,
    this.child,
  });

  final LumoScene scene;
  final String? backgroundAsset;
  final bool showPlaceholderLabel;

  /// Dunkelt die Szene nach unten zum Nachthimmel ab, damit Glas-Karten und
  /// weiße Schrift lesbar bleiben (wie in den Zielbildern).
  final bool dimmed;
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
        // Die Szenenbilder haben einen hellen Rand von wenigen Pixeln.
        Positioned(
          left: -10,
          right: -10,
          top: -10,
          bottom: -10,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
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
        if (dimmed)
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, .22, .42, .62, 1],
                  colors: [
                    Color(0x5503193F),
                    Color(0x1003193F),
                    Color(0x6603193F),
                    Color(0xD903193F),
                    Color(0xF203193F),
                  ],
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

/// Hintergrund für Lernmodule: die Bibliotheks-Szene und darauf eine helle
/// „Heftseite“ unter dem farbigen Modul-Kopf. So bleiben die hellen
/// Aufgabenkarten und farbigen Texte der Module gut lesbar.
class LumoModuleBackdrop extends StatelessWidget {
  const LumoModuleBackdrop({super.key, required this.child, this.headerHeight = 78});

  final Widget child;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + headerHeight;
    return LumoSceneBackground(
      scene: LumoScene.library,
      showPlaceholderLabel: false,
      dimmed: true,
      child: Stack(children: [
        Positioned(
          left: 8,
          right: 8,
          top: top,
          bottom: MediaQuery.paddingOf(context).bottom + 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB).withValues(alpha: .94),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                    color: LumoVisualTokens.cyan.withValues(alpha: .55), width: 1.4),
                boxShadow: [
                  BoxShadow(
                      color: LumoVisualTokens.cyan.withValues(alpha: .25),
                      blurRadius: 18),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ]),
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
    this.iconAsset,
  });

  final IconData icon;
  final String? iconAsset;
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
          final centered = iconAsset != null;
          // Kachel-Symbole wie in Bild 01: groß und mittig über dem Titel.
          final iconSize = centered
              ? (constraints.maxWidth * .42).clamp(20.0, 56.0).toDouble()
              : compact
                  ? 20.0
                  : 32.0;
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
                        if (centered)
                          _centeredContent(compact, iconSize, arrowRadius,
                              MediaQuery.textScalerOf(context).scale(1) > 1.2)
                        else
                          Column(
                            crossAxisAlignment: centered
                                ? CrossAxisAlignment.center
                                : CrossAxisAlignment.start,
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
                                  child: iconAsset == null
                                      ? Icon(icon,
                                          size: iconSize, color: Colors.white)
                                      : Image.asset(
                                          iconAsset!,
                                          key: ValueKey(
                                              'lumo-color-tile-icon-${title.toLowerCase()}'),
                                          width: iconSize,
                                          height: iconSize,
                                          fit: BoxFit.contain,
                                          excludeFromSemantics: true,
                                          errorBuilder: (_, __, ___) => Icon(
                                            icon,
                                            size: iconSize,
                                            color: Colors.white,
                                          ),
                                        ),
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
                                textAlign: centered
                                    ? TextAlign.center
                                    : TextAlign.start,
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  fontSize: compact ? 12 : 18,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: compact ? 0 : 2),
                              Padding(
                                padding: centered
                                    ? EdgeInsets.zero
                                    : EdgeInsets.only(right: compact ? 22 : 32),
                                child: Text(
                                  subtitle,
                                  maxLines: compact ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: centered
                                      ? TextAlign.center
                                      : TextAlign.start,
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

  /// Bild 01: großes Symbol mittig, Titel ganz lesbar (notfalls kleiner),
  /// Unterzeile bis zu drei Zeilen, Platz für den Pfeil unten rechts.
  Widget _centeredContent(
          bool compact, double iconSize, double arrowRadius, bool largeText) =>
      Column(
        children: [
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Image.asset(
                  iconAsset!,
                  key: ValueKey('lumo-color-tile-icon-${title.toLowerCase()}'),
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, size: iconSize, color: Colors.white),
                ),
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w900,
                fontSize: compact ? 15 : 18,
                color: Colors.white,
                shadows: const [
                  Shadow(color: Color(0x55000000), blurRadius: 4),
                ],
              ),
            ),
          ),
          Text(
            subtitle,
            maxLines: largeText ? 1 : 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(.9),
              fontSize: compact ? 9.5 : 12,
              height: 1.1,
            ),
          ),
          SizedBox(height: arrowRadius * 2 - 2),
        ],
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
    final xpInLevel = state.xp % 400;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 300;
        final avatarSize = compact ? 32.0 : 52.0;
        const glow = [Shadow(color: LumoVisualTokens.cyan, blurRadius: 14)];
        final logoSize = compact ? 24.0 : 34.0;
        return Row(
          children: [
            Expanded(
              flex: compact ? 5 : 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'LUMO',
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'LUM',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: logoSize,
                              height: 1.05,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .6,
                              color: LumoVisualTokens.white,
                              shadows: glow,
                            ),
                          ),
                          // Das O trägt den Stern wie im Logo der Zielbilder.
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Text(
                                'O',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: logoSize,
                                  height: 1.05,
                                  fontWeight: FontWeight.w900,
                                  color: LumoVisualTokens.white,
                                  shadows: glow,
                                ),
                              ),
                              Icon(
                                Icons.star_rounded,
                                size: logoSize * .36,
                                color: LumoVisualTokens.cyan,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lernen. Spielen. Weiterkommen.',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: compact ? 9 : 10.5,
                        fontWeight: FontWeight.w800,
                        color: LumoVisualTokens.cyanBright,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            Expanded(
              flex: compact ? 5 : 11,
              child: Semantics(
                button: onTapStatus != null,
                label:
                    'Level ${state.level}, Klasse ${state.grade}, ${state.stars} Sterne, $xpInLevel von 400 XP',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: onTapStatus,
                    child: LumoGlassCard(
                      padding: EdgeInsets.fromLTRB(
                          compact ? 4 : 5, compact ? 4 : 5, 4, compact ? 4 : 5),
                      radius: 26,
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
                                width: avatarSize,
                                height: avatarSize,
                                child: ExcludeSemantics(
                                  child: reduceMotion
                                      ? _avatar(size: avatarSize)
                                      : LumoFloating(
                                          amplitude: 3,
                                          duration: const Duration(
                                              milliseconds: 2800),
                                          child: LumoGlowPulse(
                                            color: LumoVisualTokens.cyan,
                                            minBlur: 6,
                                            maxBlur: 16,
                                            child: _avatar(size: avatarSize),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: compact ? 4 : 7),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Level ${state.level}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w900,
                                          fontSize: compact ? 10 : 12.5,
                                          height: 1.1,
                                          color: LumoVisualTokens.white,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.star_rounded,
                                        size: compact ? 13 : 17,
                                        color: LumoVisualTokens.gold),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${state.stars}',
                                      style: TextStyle(
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w900,
                                        fontSize: compact ? 11 : 14,
                                        height: 1.1,
                                        color: LumoVisualTokens.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${state.grade}. Klasse',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: compact ? 9 : 10.5,
                                    height: 1.15,
                                    color: LumoVisualTokens.muted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(5),
                                        child: TweenAnimationBuilder<double>(
                                          tween: Tween(
                                              begin: 0, end: xpInLevel / 400),
                                          duration: reduceMotion
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 900),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, _) =>
                                              LinearProgressIndicator(
                                            minHeight: 6,
                                            value: value,
                                            backgroundColor:
                                                const Color(0xFF0B2A52),
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(
                                              LumoVisualTokens.cyanBright,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      flex: 5,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$xpInLevel / 400 XP',
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w800,
                                            fontSize: compact ? 8 : 10,
                                            color: LumoVisualTokens.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: LumoVisualTokens.white,
                              size: compact ? 16 : 20),
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
    this.fontSize,
    this.padding,
  });

  final String text;
  final bool handwritten;
  final bool alignRight;
  final double? fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Transform.rotate(
          angle: alignRight ? -.025 : .012,
          child: LumoGlassCard(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            radius: 18,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: handwritten ? null : 'Nunito',
                fontSize: fontSize ?? (handwritten ? 20 : 14),
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

/// Glas-Sprechblase mit Cyan-Rand über der Szene, mit Herz am Ende
/// (Bild 02/03: „Du kannst das!“, „Kleine Schritte Große Zukunft!“).
class LumoHeroBubble extends StatelessWidget {
  const LumoHeroBubble({
    super.key,
    required this.text,
    this.title,
    this.handwritten = false,
  });

  final String? title;
  final String text;
  final bool handwritten;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Nunito',
      color: LumoVisualTokens.white,
      fontSize: handwritten ? 12.5 : 11,
      height: 1.15,
      fontStyle: handwritten ? FontStyle.italic : FontStyle.normal,
      fontWeight: handwritten ? FontWeight.w700 : FontWeight.w800,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B3C78).withOpacity(.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LumoVisualTokens.cyan.withOpacity(.8)),
        boxShadow: [
          BoxShadow(
            color: LumoVisualTokens.cyan.withOpacity(.35),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: LumoVisualTokens.white,
                fontSize: 15,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          if (title != null) const SizedBox(height: 3),
          Text.rich(
              TextSpan(children: [
                TextSpan(text: '$text '),
                // Herz wie in den Zielbildern (als Symbol, nicht als Schriftzeichen).
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(Icons.favorite_border_rounded,
                      size: style.fontSize! + 3, color: LumoVisualTokens.white),
                ),
              ]),
              style: style),
        ],
      ),
    );
  }
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
        // Wie im Zielbild: Leiste über die ganze Breite, oben abgerundet.
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
        decoration: BoxDecoration(
          color: LumoVisualTokens.navigation.withOpacity(.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border(
            top: BorderSide(color: LumoVisualTokens.cyan.withOpacity(.35)),
          ),
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
                          child: Icon(item.icon,
                              size: 25,
                              color: color,
                              shadows: selected
                                  ? const [
                                      Shadow(
                                          color: LumoVisualTokens.cyan,
                                          blurRadius: 12)
                                    ]
                                  : null),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight:
                                selected ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 11,
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
