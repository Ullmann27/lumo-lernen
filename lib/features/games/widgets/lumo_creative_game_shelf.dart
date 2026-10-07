import 'package:flutter/material.dart';

import '../../../domain/games/game_world.dart';
import '../../../theme/lumo_visual_tokens.dart';
import '../../../widgets/design/lumo_design_system.dart';

/// Previews are captures of the bundled playable Godot scenes.
class LumoCreativeGameShelf extends StatelessWidget {
  const LumoCreativeGameShelf({super.key, required this.onOpen,
    required this.unlocked, required this.busy});
  final ValueChanged<GameId> onOpen;
  final bool Function(GameId) unlocked;
  final bool busy;
  static const games = [
    (GameId.build, 'Bauwelt', 'Baue Burgen, Brücken und ein ganzes Dorf.', 'build', Icons.construction_rounded),
    (GameId.puzzle, 'Puzzle-Atelier', 'Setze echte 3D-Teile zusammen: 12 bis 96 Teile.', 'puzzle', Icons.extension_rounded),
    (GameId.treasure, 'Schatzsuche', 'Erkunde die Insel, löse Rätsel und fülle deinen Rucksack.', 'treasure', Icons.explore_rounded),
    (GameId.rhythm, 'Rhythm Party', 'Drei eigene Lieder mit Halten, Tippen und Gleiten.', 'rhythm', Icons.music_note_rounded),
  ];
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Deine neuen Spielwelten', style: TextStyle(fontSize: 24,
        color: LumoVisualTokens.white, fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      const Text('Bauen, entdecken und kreativ werden. Deine Welten bleiben gespeichert.',
        style: TextStyle(color: LumoVisualTokens.muted, fontSize: 15)),
      const SizedBox(height: 14),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 && MediaQuery.textScalerOf(context).scale(16) < 28 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(spacing: 14, runSpacing: 14, children: [for (final game in games)
          SizedBox(width: width, child: LumoGlassCard(padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: AspectRatio(aspectRatio: 16 / 9,
                child: Image.asset('assets/lumo_design/gameplay/${game.$4}.png', fit: BoxFit.cover,
                  semanticLabel: 'Echtes Spielbild: ${game.$2}'))),
              const SizedBox(height: 12),
              Text(game.$2, style: const TextStyle(fontSize: 23, color: LumoVisualTokens.white, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(game.$3, style: const TextStyle(fontSize: 15, color: LumoVisualTokens.muted, height: 1.35)),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                key: ValueKey('launch-creative-${game.$4}'),
                onPressed: busy ? null : () => onOpen(game.$1),
                icon: Icon(unlocked(game.$1) ? game.$5 : Icons.lock_rounded),
                label: Text(unlocked(game.$1) ? '${game.$2} spielen' : 'Freischaltung ansehen'),
                style: FilledButton.styleFrom(minimumSize: const Size(48, 50)),
              )),
            ]))),
        ]);
      }),
    ]));
}
