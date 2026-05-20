import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import '../../../widgets/fox/lumo_idle_fox.dart';
import 'lumo_premium_effects.dart';

/// Premium-Hero-Header nach Referenzbild "Mathe mit Lumo" / "Deutsch mit Lumo".
///
/// Aufbau:
///   - kleine Lumo-Avatar Pille oben links
///   - Begruessung "Hallo, [Name]!" mit Wink-Emoji
///   - kurzer Motivations-Untertitel
///   - Stern- und Streak-Chip oben rechts
///   - grosses farbiges Fach-Headline ("Mathe mit Lumo")
///   - Lumo-Illustration rechts mit Sprechblase
///   - warmer Verlauf als Hintergrund
///
/// Auf schmalen Phones: Layout faltet zu kompaktem Stack.
class LumoHeroHeader extends StatelessWidget {
  const LumoHeroHeader({
    super.key,
    required this.childName,
    required this.title,
    required this.titleAccent,
    required this.subtitle,
    required this.greeting,
    required this.lumoMessage,
    required this.stars,
    required this.streakDays,
    this.accent = LumoColors.orange,
    this.heroIllustrationAsset,
    this.backgroundImageAsset = 'assets/images/lumo_classroom_header.png',
    this.showBackgroundImage = true,
  });

  final String childName;
  final String title;
  final String titleAccent;
  final String subtitle;
  final String greeting;
  final String lumoMessage;
  final int stars;
  final int streakDays;
  final Color accent;
  /// Optionaler Override fuer das Fuchs-Asset. Wenn null wird die
  /// LumoIdleFox-Animation gerendert (kein altmodisches Cartoon mehr).
  final String? heroIllustrationAsset;
  final String backgroundImageAsset;
  final bool showBackgroundImage;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isCompact = availableWidth < 520;
        final veryCompact = availableWidth < 390;

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              if (showBackgroundImage)
                Positioned.fill(
                  child: Image.asset(
                    backgroundImageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              if (showBackgroundImage)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF8EE).withOpacity(0.78),
                          const Color(0xFFFFE4C0).withOpacity(0.92),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 18, 20, isCompact ? 18 : 22),
                decoration: BoxDecoration(
                  gradient: showBackgroundImage
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFFFFF8EE), Color(0xFFFFE4C0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.6),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.18),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                      spreadRadius: -6,
                    ),
                    BoxShadow(
                      color: const Color(0xFF3D342C).withOpacity(0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopBar(
                      childName: childName,
                      greeting: greeting,
                      stars: stars,
                      streakDays: streakDays,
                      accent: accent,
                      asset: heroIllustrationAsset,
                      compact: veryCompact,
                    ),
                    const SizedBox(height: 14),
                    if (isCompact)
                      _CompactHeroBody(
                        title: title,
                        titleAccent: titleAccent,
                        subtitle: subtitle,
                        asset: heroIllustrationAsset,
                        message: lumoMessage,
                        accent: accent,
                      )
                    else
                      _WideHeroBody(
                        title: title,
                  titleAccent: titleAccent,
                  subtitle: subtitle,
                  asset: heroIllustrationAsset,
                  message: lumoMessage,
                  accent: accent,
                ),
            ],
          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.childName,
    required this.greeting,
    required this.stars,
    required this.streakDays,
    required this.accent,
    required this.asset,
    required this.compact,
  });

  final String childName;
  final String greeting;
  final int stars;
  final int streakDays;
  final Color accent;
  final String? asset;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final profile = Row(
      children: [
        _MiniLumoAvatar(asset: asset, accent: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Hallo, ',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: LumoColors.ink900,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      childName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ),
                  const Text(' 👋', style: TextStyle(fontSize: 17)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: LumoColors.ink500,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final chips = Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        _StatChip(icon: '⭐', value: '$stars', label: 'Sterne', color: LumoColors.gold),
        _StatChip(icon: '🔥', value: '$streakDays', label: 'Tage in Folge', color: const Color(0xFFFF6B35)),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profile,
          const SizedBox(height: 10),
          chips,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: profile),
        const SizedBox(width: 8),
        Flexible(child: Align(alignment: Alignment.centerRight, child: chips)),
      ],
    );
  }
}

class _WideHeroBody extends StatelessWidget {
  const _WideHeroBody({
    required this.title,
    required this.titleAccent,
    required this.subtitle,
    required this.asset,
    required this.message,
    required this.accent,
  });

  final String title;
  final String titleAccent;
  final String subtitle;
  final String? asset;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: _TitleBlock(title: title, titleAccent: titleAccent, subtitle: subtitle, accent: accent, compact: false)),
        const SizedBox(width: 8),
        Expanded(flex: 4, child: _LumoWithBubble(asset: asset, message: message, accent: accent, size: 150)),
      ],
    );
  }
}

class _CompactHeroBody extends StatelessWidget {
  const _CompactHeroBody({
    required this.title,
    required this.titleAccent,
    required this.subtitle,
    required this.asset,
    required this.message,
    required this.accent,
  });

  final String title;
  final String titleAccent;
  final String subtitle;
  final String? asset;
  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleBlock(title: title, titleAccent: titleAccent, subtitle: subtitle, accent: accent, compact: true),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: _LumoWithBubble(asset: asset, message: message, accent: accent, size: 118),
          ),
        ),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.titleAccent, required this.subtitle, required this.accent, required this.compact});

  final String title;
  final String titleAccent;
  final String subtitle;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: compact ? 30 : 38,
              fontWeight: FontWeight.w900,
              color: LumoColors.ink900,
              height: 1.05,
            ),
            children: [
              TextSpan(text: '$title\n'),
              TextSpan(text: titleAccent, style: TextStyle(color: accent)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: LumoColors.ink700,
          ),
        ),
      ],
    );
  }
}

class _MiniLumoAvatar extends StatelessWidget {
  const _MiniLumoAvatar({required this.asset, required this.accent});
  final String? asset;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: accent.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: asset == null
                ? const FittedBox(
                    fit: BoxFit.cover,
                    child: LumoIdleFox(size: 44),
                  )
                : Image.asset(
                    asset!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Text('🦊', style: TextStyle(fontSize: 22))),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value, required this.label, required this.color});
  final String icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1),
              ),
              Text(
                label,
                style: TextStyle(fontFamily: 'Nunito', fontSize: 8.5, fontWeight: FontWeight.w700, color: color, height: 1.2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LumoWithBubble extends StatelessWidget {
  const _LumoWithBubble({required this.asset, required this.message, required this.accent, required this.size});
  final String? asset;
  final String message;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: LumoFloating(
              amplitude: 4,
              duration: const Duration(seconds: 4),
              child: asset == null
                  ? LumoIdleFox(size: size)
                  : Image.asset(
                      asset!,
                      height: size,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: size,
                        height: size,
                        child: Center(child: Text('🦊', style: TextStyle(fontSize: size * 0.6))),
                      ),
                    ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              constraints: BoxConstraints(maxWidth: size * 1.05),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8DFCF)),
                boxShadow: [BoxShadow(color: accent.withOpacity(0.10), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: Text(
                message,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 11.5, fontWeight: FontWeight.w800, color: LumoColors.ink900, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
