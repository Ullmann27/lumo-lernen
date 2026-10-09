import 'package:flutter/material.dart';

import '../../../domain/iq/iq_puzzle.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_motion.dart';
import '../../../app/app_state.dart';

/// Farbfamilie einer Figur: Glanz, Kern und Schatten.
///
/// Die sechs Töne unterscheiden sich nicht nur im Farbton, sondern auch in
/// der Helligkeit (Gelb und Türkis hell, Lila dunkel), damit sie auch für
/// Kinder mit Farbschwäche auseinanderzuhalten sind.
@immutable
class IqTintColors {
  const IqTintColors(this.light, this.base, this.dark);

  factory IqTintColors.from(Color base) => IqTintColors(
        Color.lerp(base, Colors.white, .45)!,
        base,
        Color.lerp(base, const Color(0xFF0B1D45), .46)!,
      );

  final Color light;
  final Color base;
  final Color dark;
}

const _tintBase = <IqTint, Color>{
  IqTint.orange: Color(0xFFFF8F3D),
  IqTint.cyan: Color(0xFF35D6FF),
  IqTint.violet: Color(0xFF9170FF),
  IqTint.green: Color(0xFF46D36B),
  IqTint.pink: Color(0xFFFF5FA8),
  IqTint.gold: Color(0xFFFFD43B),
};

final Map<IqTint, IqTintColors> _tintColors = {
  for (final entry in _tintBase.entries)
    entry.key: IqTintColors.from(entry.value),
};

IqTintColors iqTintColors(IqTint tint) => _tintColors[tint]!;

/// Symbol, Farbe und Kurzname eines Denkbereichs.
@immutable
class IqAreaStyle {
  const IqAreaStyle(this.icon, this.color);

  final IconData icon;
  final Color color;
}

IqAreaStyle iqAreaStyle(IqArea area) => switch (area) {
      IqArea.matrix => const IqAreaStyle(Icons.grid_view_rounded, Color(0xFF35D6FF)),
      IqArea.series => const IqAreaStyle(Icons.timeline_rounded, Color(0xFFFF8F3D)),
      IqArea.oddOneOut => const IqAreaStyle(Icons.search_rounded, Color(0xFFFF5FA8)),
      IqArea.rotation =>
        const IqAreaStyle(Icons.threed_rotation_rounded, Color(0xFF9170FF)),
      IqArea.numbers =>
        const IqAreaStyle(Icons.onetwothree_rounded, Color(0xFFFFD43B)),
      IqArea.memory => const IqAreaStyle(Icons.bolt_rounded, Color(0xFF46D36B)),
    };

/// Freundlicher Übungstipp je Bereich (für „Hier hilft Üben“).
String iqPracticeTip(IqArea area) => switch (area) {
      IqArea.matrix =>
        'Schau in jeder Reihe und jeder Spalte: Was bleibt gleich? Was ändert sich? So findest du die Regel.',
      IqArea.series =>
        'Sag dir die Figuren leise vor. Was ändert sich bei jedem Schritt? Das machst du dann einfach weiter.',
      IqArea.oddOneOut =>
        'Nimm zwei Figuren und vergleiche sie: Was ist gleich, was ist anders? Die Figur, die aus der Reihe tanzt, ist die Lösung.',
      IqArea.rotation =>
        'Dreh das Bauteil in Gedanken. Oder dreh dein Blatt Papier ein Stück. Umgeklappte Teile zählen nicht!',
      IqArea.numbers =>
        'Rechne aus, um wie viel die Zahlen springen. Bleibt der Sprung gleich? Dann kennst du die fehlende Zahl.',
      IqArea.memory =>
        'Sag dir die Felder leise vor oder male dir einen Weg im Kopf. Kleine Merk-Spiele jeden Tag helfen sehr.',
    };

/// Hinweis für Eltern – ehrlich, was der Test kann und was nicht.
const iqParentNote =
    'Das ist ein spielerischer Denktest und kein klinisch normierter '
    'Intelligenztest. Er zeigt Stärken und erzeugt bewusst keine erfundene '
    'IQ-Zahl. Vergleiche sind nur mit früheren Knobel-Tests sinnvoll, und '
    'eine Wiederholung lohnt sich erst nach einigen Monaten. Bei Fragen zu '
    'Begabung oder Förderung hilft die Schulpsychologie.';

/// Schrift im Lumo-Stil.
TextStyle iqText(
  double size, {
  FontWeight weight = FontWeight.w800,
  Color color = LumoVisualTokens.white,
  double? height,
  List<Shadow>? shadows,
  double? letterSpacing,
}) =>
    TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      shadows: shadows,
      letterSpacing: letterSpacing,
    );

/// Dunkler Schatten, der weiße Schrift über der hellen Szene lesbar hält.
const iqScrim = <Shadow>[
  Shadow(color: Color(0xE603122E), blurRadius: 10),
  Shadow(color: Color(0x9903122E), offset: Offset(0, 1), blurRadius: 2),
];

/// Gilt „Bewegung reduzieren“ – vom System oder in der App?
bool iqReduceMotion(BuildContext context, LumoAppState appState) {
  final settings = appState.state.settings;
  return LumoMotion.reduced(context) ||
      settings.reduceAnimations ||
      settings.calmMode;
}

/// Schmaler Lichtschein hinter Symbolen und Karten.
List<BoxShadow> iqGlow(Color color, {double alpha = .35, double blur = 22}) => [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: blur,
        spreadRadius: -4,
      ),
    ];
