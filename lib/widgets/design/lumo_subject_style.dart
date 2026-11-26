import 'package:flutter/material.dart';

/// Einheitliches Symbol und Akzentfarbe je Fach für Berichte, Elternbereich,
/// Lehrkräftebereich und Hausaufgaben. Ein Fach sieht überall gleich aus.
@immutable
class LumoSubjectStyle {
  const LumoSubjectStyle(this.icon, this.color);

  final IconData icon;
  final Color color;

  static const _cyan = Color(0xFF38E8FF);
  static const _amber = Color(0xFFFFC857);
  static const _violet = Color(0xFF9A7BFF);
  static const _mint = Color(0xFF4DFFB8);
  static const _rose = Color(0xFFFF6B9A);
  static const _blue = Color(0xFF6FA2FF);

  static LumoSubjectStyle of(String subject) => switch (subject.trim()) {
        'Mathematik' => const LumoSubjectStyle(Icons.calculate_rounded, _cyan),
        'Deutsch' => const LumoSubjectStyle(Icons.abc_rounded, _amber),
        'Lesen' => const LumoSubjectStyle(Icons.auto_stories_rounded, _amber),
        'Schreiben' => const LumoSubjectStyle(Icons.edit_rounded, _amber),
        'Rechtschreibung' =>
          const LumoSubjectStyle(Icons.spellcheck_rounded, _amber),
        'Englisch' ||
        'Lebende Fremdsprache' =>
          const LumoSubjectStyle(Icons.translate_rounded, _violet),
        'Sachunterricht' ||
        'Sachkunde' =>
          const LumoSubjectStyle(Icons.eco_rounded, _mint),
        'Logik' => const LumoSubjectStyle(Icons.extension_rounded, _rose),
        'Musik' => const LumoSubjectStyle(Icons.music_note_rounded, _violet),
        'Kunst und Gestaltung' =>
          const LumoSubjectStyle(Icons.palette_rounded, _rose),
        'Technik und Design' =>
          const LumoSubjectStyle(Icons.build_rounded, _cyan),
        'Bewegung und Sport' =>
          const LumoSubjectStyle(Icons.sports_gymnastics_rounded, _mint),
        _ => const LumoSubjectStyle(Icons.school_rounded, _blue),
      };
}

/// Rundes, leicht erhabenes Fachsymbol (Glas mit Lichtkante), z. B. vor einer
/// Empfehlung oder Hausaufgabe. Rein dekorativ: das Fach steht immer auch als
/// Text daneben, daher ohne eigene Bildschirmleser-Ansage.
class LumoSubjectBadge extends StatelessWidget {
  const LumoSubjectBadge({super.key, required this.subject, this.size = 40});

  final String subject;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = LumoSubjectStyle.of(subject);
    return ExcludeSemantics(
      child: Container(
        key: ValueKey('subject-badge-$subject'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-.35, -.45),
            colors: [
              style.color.withValues(alpha: .55),
              style.color.withValues(alpha: .18),
              const Color(0xFF0A1730),
            ],
            stops: const [0, .55, 1],
          ),
          border: Border.all(color: style.color.withValues(alpha: .8), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: style.color.withValues(alpha: .35),
                blurRadius: 12,
                spreadRadius: -2),
            const BoxShadow(
                color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Icon(style.icon, color: Colors.white, size: size * .55),
      ),
    );
  }
}

/// Goldene Hauptschaltfläche im LUMO-Stil (mindestens 52 dp hoch): leuchtendes
/// Gold mit dunkler Schrift, leicht erhaben. Für die eine wichtigste Aktion
/// einer Karte, z. B. „Jetzt üben“.
class LumoGoldButton extends StatelessWidget {
  const LumoGoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  static const _ink = Color(0xFF10243A);

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : .5,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52, minWidth: 48),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE69A), Color(0xFFFFC94A), Color(0xFFE9A92D)],
            ),
            border: Border.all(color: const Color(0xFFFFF3C4), width: 1.4),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x66FFC94A), blurRadius: 14, spreadRadius: -3),
              BoxShadow(
                  color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 4)),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(99),
              onTap: onPressed,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: _ink, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
