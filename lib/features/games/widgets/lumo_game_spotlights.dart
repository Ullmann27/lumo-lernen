import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';
import '../../../widgets/fox/lumo_character.dart';

/// Real entry points before the optional decorative world. Intrinsic heights
/// preserve complete labels at large text scales and narrow widths.
class LumoGameSpotlights extends StatelessWidget {
  const LumoGameSpotlights({
    super.key,
    required this.onCards,
    this.showBuildPreview = false,
    required this.onKart,
    required this.busy,
    required this.reduceMotion,
  });

  final VoidCallback onCards;
  final bool showBuildPreview;
  final VoidCallback onKart;
  final bool busy;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final narrow = constraints.maxWidth < 410;
              return Container(
                key: const ValueKey('games-1990-hero'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF424DAD),
                      Color(0xFF164884),
                      Color(0xFF086B83),
                    ],
                    stops: [0, .58, 1],
                  ),
                  border: Border.all(
                      color: const Color(0xFF84EEFF), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6646CDFF),
                      blurRadius: 30, spreadRadius: -9,
                      offset: Offset(0, 14)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(children: [
                    const Positioned(
                      right: -64, top: -89,
                      child: IgnorePointer(child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            Color(0x99B4F9FF),
                            Color(0x4477DDFE),
                            Color(0x001B8FDC),
                          ]),
                        ),
                        child: SizedBox(width: 290, height: 290),
                      )),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 10, 16),
                      child: Row(children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xCC0B214F),
                                borderRadius: BorderRadius.circular(99),
                                border: Border.all(color: const Color(0xFFB3F5FF)),
                              ),
                              child: const Text('LUMOS SPIELEWELT',
                                style: TextStyle(fontFamily: 'Nunito',
                                  fontSize: 10, fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0, color: Color(0xFFE8FDFF))),
                            ),
                            const SizedBox(height: 11),
                            Text('Jetzt spielen',
                              style: TextStyle(fontFamily: 'Nunito',
                                fontSize: narrow ? 27 : 34, height: 1.06,
                                fontWeight: FontWeight.w900, color: Colors.white,
                                shadows: const [Shadow(
                                  color: Color(0x66041B45), blurRadius: 8)])),
                            const SizedBox(height: 8),
                            Text(
                              showBuildPreview
                                ? 'Cards und Kart warten auf dich! Die Bauwelt entsteht.'
                                : 'Wähle dein Abenteuer: Karten oder Rennstrecke.',
                              style: const TextStyle(fontFamily: 'Nunito',
                                fontSize: 13, height: 1.3,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE6F8FF))),
                          ],
                        )),
                        SizedBox(
                          width: narrow ? 87 : 139,
                          child: ExcludeSemantics(child: LumoCharacter(
                            pose: LumoDesignFoxPose.spielweltJump,
                            size: narrow ? 92 : 136,
                            idleHops: false,
                            shadow: false,
                            reduceMotion: reduceMotion,
                          )),
                        ),
                      ]),
                    ),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 16),
            LayoutBuilder(builder: (context, constraints) {
              final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
              final columns = constraints.maxWidth >= 650 && !largeText ? 2 : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 14) / columns;
              return Wrap(spacing: 14, runSpacing: 14, children: [
                SizedBox(
                  width: width,
                  child: _Spotlight(
                    title: 'Lumo Cards',
                    eyebrow: 'KARTENSPIEL',
                    description: 'Lege passende Karten ab und spiele gegen Lumo.',
                    action: 'Kartenspiel starten',
                    actionKey: 'launch-lumo-cards',
                    pose: LumoDesignFoxPose.cardsWelcome,
                    previewAsset: 'assets/lumo_design/spielwelt/portal_cards.png',
                    accent: const Color(0xFFD8BDFF),
                    icon: Icons.style_rounded,
                    onPressed: busy ? null : onCards,
                    reduceMotion: reduceMotion,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _Spotlight(
                    title: 'Lumo Kart',
                    eyebrow: '3D-RENNSPIEL',
                    description:
                      'Fahre durch zwölf Rennwelten: Meer, Wolken und Vulkane.',
                    previewAsset:
                      'assets/lumo_design/gameplay/kart_sonnenhafen_preview.webp',
                    showWorldTags: true,
                    showRecoveredKartArt: true,
                    action: 'Losfahren',
                    actionKey: 'launch-lumo-kart',
                    pose: LumoDesignFoxPose.kartRear,
                    accent: LumoVisualTokens.cyanBright,
                    icon: Icons.sports_motorsports_rounded,
                    onPressed: busy ? null : onKart,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ]);
            }),
            if (busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Semantics(
                  liveRegion: true,
                  child: Text('Spiel wird geöffnet. Bitte einen Moment warten.',
                    style: TextStyle(color: LumoVisualTokens.muted)),
                ),
              ),
          ],
        ),
      );
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.action,
    required this.actionKey,
    required this.pose,
    required this.accent,
    required this.icon,
    required this.onPressed,
    required this.reduceMotion,
    this.previewAsset,
    this.showWorldTags = false,
    this.showRecoveredKartArt = false,
  });

  final String? previewAsset;
  final bool showWorldTags;
  final bool showRecoveredKartArt;
  final String title, eyebrow, description, action, actionKey;
  final LumoDesignFoxPose pose;
  final Color accent;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool reduceMotion;

  Widget _heading() => Row(children: [
        ExcludeSemantics(
            child: RepaintBoundary(
                child: LumoCharacter(
          pose: pose,
          celebratePose: null,
          size: 102,
          shadow: false,
          reduceMotion: reduceMotion,
        ))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow,
              style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  letterSpacing: .9,
                  fontWeight: FontWeight.w800,
                  color: accent)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: LumoVisualTokens.white)),
        ])),
      ]);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: .28), const Color(0xFF133963)),
              const Color(0xFF071B3B),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: .88), width: 1.7),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: .27),
              blurRadius: 25, spreadRadius: -7,
              offset: const Offset(0, 12)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (previewAsset != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 228 : 208,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.asset(previewAsset!, fit: BoxFit.cover,
                      alignment: const Alignment(0, -.12),
                      excludeFromSemantics: true,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(gradient: LinearGradient(
                          colors: [accent, const Color(0xFF163D71)])),
                        child: Center(child: Icon(icon, color: Colors.white, size: 64)),
                      )),
                    const DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, .41, .78, 1],
                        colors: [
                          Color(0x11041538), Color(0x00041538),
                          Color(0xBB061A3C), Color(0xFB06142F),
                        ],
                      ),
                    )),
                    Positioned(top: 13, right: 13,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xDA071A3E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: accent, width: 1.3),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                      ),
                    ),
                    Positioned(left: 10, right: 10, bottom: 8,
                      child: _heading()),
                  ]),
                ),
              )
            else
              _heading(),
            const SizedBox(height: 6),
            Text(description,
                style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: LumoVisualTokens.muted,
                    height: 1.35)),
            const SizedBox(height: 12),
            if (showWorldTags) ...[
              Wrap(spacing: 8, runSpacing: 6, children: [
                _WorldTag(
                    label: '12 Welten',
                    icon: Icons.public_rounded,
                    color: accent),
                _WorldTag(
                    label: '5 Spielmodi',
                    icon: Icons.flag_rounded,
                    color: accent),
              ]),
              const SizedBox(height: 14),
            ],
            if (showRecoveredKartArt) ...[
              const _RecoveredKartArtStrip(),
              const SizedBox(height: 14),
            ],
            SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: ValueKey(actionKey),
                  onPressed: onPressed,
                  icon: Icon(icon, size: 22),
                  label: Text(action, textAlign: TextAlign.center),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    backgroundColor: accent,
                    foregroundColor: LumoVisualTokens.night,
                    disabledBackgroundColor: const Color(0xFF29476E),
                    disabledForegroundColor: LumoVisualTokens.muted,
                    textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                )),
          ]),
        ),
      );
}

class _WorldTag extends StatelessWidget {
  const _WorldTag(
      {required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ]),
        ),
      );
}


class _RecoveredKartArtStrip extends StatelessWidget {
  const _RecoveredKartArtStrip();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('assets/lumo_design/characters/fox_kart_front.webp', 'Lumo im Kart'),
      ('assets/lumo_design/kart_items/turbo_pad.webp', 'Turbo'),
      ('assets/lumo_design/deco/finish_gate.webp', 'Zieltor'),
      ('assets/lumo_design/rewards/reward_trophy.webp', 'Pokal'),
    ];
    final compact = MediaQuery.sizeOf(context).width <= 360;
    final gap = compact ? 4.0 : 6.0;
    return Semantics(
      label: 'Lumo Kart Vorschau mit Fahrer, Turbo, Zieltor und Pokal',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 5 : 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0x44123863),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: LumoVisualTokens.cyanBright.withValues(alpha: .26)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: AspectRatio(
                  // Keep the recovered art visible on the narrow cover display
                  // without pushing the real launch control against the viewport.
                  aspectRatio: compact ? 1.75 : 1.18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(compact ? 9 : 12),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x6637D2FD), Color(0x22113355)],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 3 : 5),
                      child: Image.asset(
                        items[index].$1,
                        fit: BoxFit.contain,
                        semanticLabel: items[index].$2,
                      ),
                    ),
                  ),
                ),
              ),
              if (index != items.length - 1) SizedBox(width: gap),
            ],
          ],
        ),
      ),
    );
  }
}
