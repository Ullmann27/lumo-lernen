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
    required this.onKart,
    required this.busy,
    required this.reduceMotion,
  });

  final VoidCallback onCards;
  final VoidCallback onKart;
  final bool busy;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Jetzt spielen', style: TextStyle(
          fontFamily: 'Nunito', fontSize: 24,
          fontWeight: FontWeight.w900, color: LumoVisualTokens.white,
        )),
        const SizedBox(height: 4),
        const Text('Karten-Duell oder 3D-Rennen – du entscheidest.',
          style: TextStyle(fontFamily: 'Nunito', fontSize: 14,
            height: 1.4, color: LumoVisualTokens.muted)),
        const SizedBox(height: 14),
        LayoutBuilder(builder: (context, constraints) {
          final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
          final columns = constraints.maxWidth >= 650 && !largeText ? 2 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            SizedBox(width: width, child: _Spotlight(
              title: 'Lumo Cards', eyebrow: 'KARTENSPIEL',
              description: 'Lege passende Karten ab und spiele gegen Lumo.',
              action: 'Kartenspiel starten', actionKey: 'launch-lumo-cards',
              pose: LumoDesignFoxPose.spielweltCards,
              accent: const Color(0xFFB5A1FF), icon: Icons.style_rounded,
              onPressed: busy ? null : onCards, reduceMotion: reduceMotion,
            )),
            SizedBox(width: width, child: _Spotlight(
              title: 'Lumo Kart', eyebrow: '3D-RENNSPIEL',
              description: 'Fahre Rennen und nutze Items. Keine Lernfragen während der Fahrt.',
              action: 'Losfahren', actionKey: 'launch-lumo-kart',
              pose: LumoDesignFoxPose.kartWave,
              accent: LumoVisualTokens.cyanBright,
              icon: Icons.sports_motorsports_rounded,
              onPressed: busy ? null : onKart, reduceMotion: reduceMotion,
            )),
          ]);
        }),
        if (busy)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Semantics(liveRegion: true, child: const Text(
              'Spiel wird geöffnet. Bitte einen Moment warten.',
              style: TextStyle(color: LumoVisualTokens.muted),
            )),
          ),
      ],
    ),
  );
}

class _Spotlight extends StatelessWidget {
  const _Spotlight({
    required this.title, required this.eyebrow, required this.description,
    required this.action, required this.actionKey, required this.pose,
    required this.accent, required this.icon, required this.onPressed,
    required this.reduceMotion,
  });

  final String title, eyebrow, description, action, actionKey;
  final LumoDesignFoxPose pose;
  final Color accent;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(accent.withValues(alpha: .13), const Color(0xFF0B3155)),
          const Color(0xF2071A3E),
        ],
      ),
      border: Border.all(color: accent.withValues(alpha: .68)),
      boxShadow: [BoxShadow(color: accent.withValues(alpha: .12), blurRadius: 16)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ExcludeSemantics(child: RepaintBoundary(child: LumoCharacter(
            pose: pose, celebratePose: null, size: 82,
            shadow: false, reduceMotion: reduceMotion,
          ))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow, style: TextStyle(fontFamily: 'Nunito', fontSize: 11,
              letterSpacing: .9, fontWeight: FontWeight.w800, color: accent)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontFamily: 'Nunito', fontSize: 23,
              fontWeight: FontWeight.w900, color: LumoVisualTokens.white)),
          ])),
        ]),
        const SizedBox(height: 6),
        Text(description, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14,
          color: LumoVisualTokens.muted, height: 1.35)),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          key: ValueKey(actionKey), onPressed: onPressed,
          icon: Icon(icon, size: 22), label: Text(action, textAlign: TextAlign.center),
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            backgroundColor: accent, foregroundColor: LumoVisualTokens.night,
            disabledBackgroundColor: const Color(0xFF29476E),
            disabledForegroundColor: LumoVisualTokens.muted,
            textStyle: const TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        )),
      ]),
    ),
  );
}
