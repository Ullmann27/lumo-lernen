import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Additive Design-Erweiterung fuer Lumo Lernen.
///
/// Dieses File erweitert das bestehende app_theme.dart um:
///   - LumoSpacing  : einheitliche Abstaende fuer alle Screens
///   - LumoMotion   : einheitliche Animations-Dauern und -Kurven
///   - LumoGradients: warme Pastell-Verlaeufe fuer Hero-Bereiche
///   - LumoCard, LumoBadge, LumoPrimaryButton, LumoSoftButton
///     als wiederverwendbare Bausteine
///
/// WICHTIG: Hier wird bewusst NICHTS bestehendes umbenannt. Alle alten
/// Komponenten in der App verwenden weiterhin LumoColors/LumoRadius/
/// LumoShadow/LumoTextStyles aus app_theme.dart und sind unveraendert.
/// Neue Bildschirme nutzen die hier definierten Bausteine.
class LumoSpacing {
  LumoSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 28.0;
  static const double xxl = 40.0;

  static const EdgeInsets pageMobile = EdgeInsets.fromLTRB(18, 18, 18, 24);
  static const EdgeInsets pageTablet = EdgeInsets.fromLTRB(28, 24, 28, 32);
  static const EdgeInsets cardPadding = EdgeInsets.all(18);
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 14);
}

class LumoMotion {
  LumoMotion._();
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 520);
  static const Duration breathe = Duration(milliseconds: 3500);

  static const Curve emphasized = Curves.easeOutBack;
  static const Curve standard = Curves.easeInOutSine;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

class LumoGradients {
  LumoGradients._();

  /// Warmer Pfirsich-Verlauf fuer den Lumo-Buehnen-Hintergrund und Hero-Karten.
  static const LinearGradient peach = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF6EE), Color(0xFFFFE4C0)],
  );

  /// Sanfter Goldverlauf fuer Belohnungs-/Erfolgsmomente.
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD166), Color(0xFFFFB800)],
  );

  /// Lavendel fuer Trost-/Comfort-Momente.
  static const LinearGradient comfort = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8DDFB), Color(0xFFC8B6F2)],
  );

  /// Tuerkis-Mint fuer Sprache/Englisch-Bereich.
  static const LinearGradient mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD5F5EE), Color(0xFF9DE5D2)],
  );

  /// Himmelblau fuer Sachunterricht/Forschen.
  static const LinearGradient sky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDFEFFF), Color(0xFFA8D0F5)],
  );

  /// Sonnenuntergang-Verlauf fuer Hilfe-Karten (Tutor-Hint).
  static const LinearGradient sunsetWarm = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFBEB), Color(0xFFFFF3D6)],
  );

  /// Indigo-Verlauf fuer Visual-Aid-Karten als 4. Hilfsstufe.
  static const LinearGradient visualCool = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
  );

  /// Frische Mint-Wiese fuer Erfolgs-Karten bei richtiger Antwort.
  static const LinearGradient successFresh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
  );

  /// Sanfter Pfirsich fuer "Mut machen"-Momente nach falscher Antwort.
  static const LinearGradient peachComfort = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFEF3C7), Color(0xFFFED7AA)],
  );

  /// Lumo-Brand-Verlauf: warmes Orange zum Pfirsich.
  static const LinearGradient lumoBrand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF7A2F), Color(0xFFFFB96B)],
  );
}

/// Eine wiederverwendbare warme Karte. Folgt der Lumo-Designsprache:
/// runde Ecken, weiche Schatten, weisser Untergrund, kleiner Akzent-Glow.
class LumoCard extends StatelessWidget {
  const LumoCard({
    super.key,
    required this.child,
    this.padding = LumoSpacing.cardPadding,
    this.accent,
    this.elevated = true,
    this.onTap,
    this.borderRadius = 22,
  });

  final Widget child;
  final EdgeInsets padding;

  /// Akzentfarbe fuer Glow und Highlight. Ohne Wert: kein Akzent.
  final Color? accent;

  final bool elevated;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final card = AnimatedContainer(
      duration: LumoMotion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(color: const Color(0xFFF0E0CC), width: 1),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: (accent ?? LumoColors.orange).withOpacity(0.10),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: const Color(0xFF3D342C).withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: (accent ?? LumoColors.orange).withOpacity(0.08),
        highlightColor: (accent ?? LumoColors.orange).withOpacity(0.04),
        child: card,
      ),
    );
  }
}

/// Pillenfoermiges Badge fuer Status, Fach-Kennzeichnung, kleine Kategorien.
class LumoBadge extends StatelessWidget {
  const LumoBadge({
    super.key,
    required this.label,
    this.color = LumoColors.orange,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: color.withOpacity(0.30), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: compact ? 14 : 16),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primaer-Button im Lumo-Stil. Gross, gut tappbar, mit weichem Drop-Shadow.
class LumoPrimaryButton extends StatelessWidget {
  const LumoPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = LumoColors.orange,
    this.minWidth = 120,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final double minWidth;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final btn = AnimatedContainer(
      duration: LumoMotion.fast,
      padding: LumoSpacing.buttonPadding,
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 52),
      decoration: BoxDecoration(
        gradient: disabled
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, Color.lerp(color, Colors.black, 0.10)!],
              ),
        color: disabled ? const Color(0xFFE5DCD3) : null,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: color.withOpacity(0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        child: btn,
      ),
    );
  }
}

/// Soft-Button: weniger prominent, fuer sekundaere Aktionen.
class LumoSoftButton extends StatelessWidget {
  const LumoSoftButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = LumoColors.orange,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(LumoRadius.pill),
            border: Border.all(color: color.withOpacity(0.24)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kompakter Sterne/XP-Status-Streifen, der oben in jedem Header
/// platziert werden kann.
class LumoStatusStrip extends StatelessWidget {
  const LumoStatusStrip({
    super.key,
    required this.stars,
    required this.xp,
    required this.level,
  });

  final int stars;
  final int xp;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _statusChip(Icons.star_rounded, '$stars', LumoColors.gold),
        const SizedBox(width: 8),
        _statusChip(Icons.bolt_rounded, '$xp XP', LumoColors.orange),
        const SizedBox(width: 8),
        _statusChip(Icons.diamond_rounded, 'Level $level', LumoColors.purple),
      ],
    );
  }

  Widget _statusChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(LumoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
