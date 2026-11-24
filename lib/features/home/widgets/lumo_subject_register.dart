import 'package:flutter/material.dart';

import '../../../theme/lumo_visual_tokens.dart';

/// Schul-Demo 24.11.2026: Die Fächer als klare Register direkt auf der
/// Startseite. Jede Kachel ist gleich groß (mindestens 96 dp hoch, also
/// deutlich über dem 48-dp-Touch-Ziel) und führt ohne Zwischenseite in das
/// Fach. Die Untergruppen (Themen/Einheiten) zeigt die bestehende
/// Fachseite (LumoAkademieScreen) – hier wird nichts dupliziert.
class LumoSubjectRegister extends StatelessWidget {
  const LumoSubjectRegister({
    super.key,
    required this.onSubject,
    required this.onGames,
    this.extras = const <LumoRegisterAction>[],
  });

  /// Zusätzliche Kacheln in derselben Reihe (z. B. Intro, Für Lehrkräfte).
  final List<LumoRegisterAction> extras;

  /// Öffnet das Fach mit seinen Untergruppen.
  final ValueChanged<String> onSubject;

  /// Öffnet den getrennten Spielebereich.
  final VoidCallback onGames;

  static const entries = <LumoRegisterEntry>[
    LumoRegisterEntry(
      id: 'Mathematik',
      title: 'Mathematik',
      hint: 'Plus, Minus, Einmaleins',
      icon: Icons.calculate_rounded,
      color: Color(0xFF2E86DE),
    ),
    LumoRegisterEntry(
      id: 'Deutsch',
      title: 'Deutsch',
      hint: 'Lesen, Schreiben, Wörter',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFE67E22),
    ),
    LumoRegisterEntry(
      id: 'Englisch',
      title: 'Englisch',
      hint: 'Erste Wörter und Sätze',
      icon: Icons.translate_rounded,
      color: Color(0xFF8E44AD),
    ),
    LumoRegisterEntry(
      id: 'Sachunterricht',
      title: 'Sachkunde',
      hint: 'Natur, Körper, Umwelt',
      icon: Icons.eco_rounded,
      color: Color(0xFF27AE60),
    ),
    LumoRegisterEntry(
      id: 'games',
      title: 'Spiele',
      hint: 'Kart, Memory und mehr',
      icon: Icons.sports_esports_rounded,
      color: Color(0xFFC0392B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Fächer',
      child: LayoutBuilder(builder: (context, constraints) {
        final textScale =
            MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
        final count = entries.length + extras.length;
        // Eine einzige Reihe: passt sie nicht, wird sie seitlich gewischt.
        // Jede Kachel bleibt mindestens 84 x 76 dp groß (>= 48 dp).
        final fitWidth = (constraints.maxWidth - (count - 1) * 8) / count;
        final tileWidth = fitWidth >= 84 ? fitWidth : 84.0;
        final showHint = tileWidth >= 110;
        final height = (showHint ? 96.0 : 76.0) * textScale;
        final tiles = <Widget>[
          for (final entry in entries)
            _RegisterTile(
              entry: entry,
              showHint: showHint,
              onTap: entry.id == 'games' ? onGames : () => onSubject(entry.id),
            ),
          for (final extra in extras)
            _RegisterTile(
              entry: extra.entry,
              showHint: showHint,
              onTap: extra.onTap,
            ),
        ];
        return SizedBox(
          key: const ValueKey('home-subject-register'),
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: tiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => SizedBox(width: tileWidth, child: tiles[i]),
          ),
        );
      }),
    );
  }
}

/// Eine zusätzliche Kachel mit eigener Aktion.
class LumoRegisterAction {
  const LumoRegisterAction({required this.entry, required this.onTap});

  final LumoRegisterEntry entry;
  final VoidCallback onTap;
}

class LumoRegisterEntry {
  const LumoRegisterEntry({
    required this.id,
    required this.title,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
}

class _RegisterTile extends StatelessWidget {
  const _RegisterTile(
      {required this.entry, required this.onTap, this.showHint = true});

  final LumoRegisterEntry entry;
  final bool showHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${entry.title}. ${entry.hint}',
        excludeSemantics: true,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Material(
            color: entry.color,
            borderRadius: BorderRadius.circular(22),
            elevation: 3,
            child: InkWell(
              key: ValueKey('home-register-${entry.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(entry.icon, color: LumoVisualTokens.white, size: 34),
                      const SizedBox(height: 6),
                      Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: LumoVisualTokens.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (showHint) const SizedBox(height: 2),
                      if (showHint)
                        Text(
                          entry.hint,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xEEFFFFFF),
                            fontSize: 12,
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
