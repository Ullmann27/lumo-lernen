/// 3D-Szenenbilder für Rechengeschichten (Textaufgaben).
///
/// Jede Geschichte aus `math_task_templates.dart` (Plus- und
/// Wegnehm-Geschichten der Klassen 1 und 2) bekommt ein eigenes,
/// gerendertes Szenenbild im einheitlichen 3D-Look. Die Zuordnung erfolgt
/// über den festen Wortlaut der Geschichte, nicht über einzelne Stichwörter,
/// damit jedes Bild genau zum Inhalt der Aufgabe passt. Geschichten ohne
/// eigenes Bild liefern `null`; die Ansicht zeigt dann das Themen-Symbol.
library;

import 'package:flutter/material.dart';

const String _dir = 'assets/lumo_design/task_objects';

/// Ein Szenenbild mit kurzer Beschreibung für Screenreader.
class StorySceneImage {
  const StorySceneImage(this.asset, this.semanticLabel);

  final String asset;
  final String semanticLabel;
}

class _SceneRule {
  const _SceneRule(this.pattern, this.image);

  final RegExp pattern;
  final StorySceneImage image;
}

const StorySceneImage _aepfel = StorySceneImage(
    '$_dir/story3d_aepfel.webp', 'Ein Mädchen bekommt im Obstgarten Äpfel geschenkt');
const StorySceneImage _bus = StorySceneImage(
    '$_dir/story3d_bus.webp', 'Kinder steigen an der Haltestelle in den Bus ein und aus');
const StorySceneImage _buntstifte = StorySceneImage(
    '$_dir/story3d_buntstifte.webp', 'Rote und blaue Buntstifte auf einem Schultisch');
const StorySceneImage _semmeln = StorySceneImage(
    '$_dir/story3d_semmeln.webp', 'Ein Teller mit Semmeln am Frühstückstisch');

final List<_SceneRule> _rules = <_SceneRule>[
  _SceneRule(RegExp(r'^Lisa hat \d+ Äpfel'), _aepfel),
  _SceneRule(RegExp(r'^Im Korb liegen \d+ Äpfel'), _aepfel),
  _SceneRule(RegExp(r'^Tom hat \d+ Kekse'),
      const StorySceneImage('$_dir/story3d_kekse.webp', 'Ein Bub und die Oma mit frisch gebackenen Keksen')),
  _SceneRule(RegExp(r'^Im Bus sitzen \d+ Kinder'), _bus),
  _SceneRule(RegExp(r'^Mia hat \d+ rote Buntstifte'), _buntstifte),
  _SceneRule(RegExp(r'^Lumo hat \d+ Buntstifte'), _buntstifte),
  _SceneRule(RegExp(r'^Am Schulhof spielen \d+ Kinder'),
      const StorySceneImage('$_dir/story3d_schulhof.webp', 'Kinder spielen am Schulhof Fangen und Tempelhüpfen')),
  _SceneRule(RegExp(r'^Jonas sammelt Sticker'),
      const StorySceneImage('$_dir/story3d_sticker.webp', 'Ein Bub bekommt neue Sticker für sein Album')),
  _SceneRule(RegExp(r'^In Omas Garten blühen \d+ Tulpen'),
      const StorySceneImage('$_dir/story3d_garten.webp', 'Tulpen und Rosen in Omas Garten')),
  _SceneRule(RegExp(r'^Beim Schulfest liegen \d+ Würstelsemmeln'),
      const StorySceneImage('$_dir/story3d_schulfest.webp', 'Würstelsemmeln und Käsesemmeln beim Schulfest')),
  _SceneRule(RegExp(r'^In der Leseecke liegen \d+ Bilderbücher'),
      const StorySceneImage('$_dir/story3d_leseecke.webp', 'Die Lehrerin bringt Bilderbücher in die Leseecke')),
  _SceneRule(RegExp(r'^Auf dem Baum sitzen \d+ Vögel'),
      const StorySceneImage('$_dir/story3d_voegel.webp', 'Vögel sitzen auf einem Ast, weitere fliegen dazu')),
  _SceneRule(RegExp(r'^Für die Jause gibt es \d+ Apfelstücke'),
      const StorySceneImage('$_dir/story3d_jause.webp', 'Jausenbox mit Apfelstücken und Birnenstücken')),
  _SceneRule(RegExp(r'^Lumo bastelt \d+ Papiersterne'),
      const StorySceneImage('$_dir/story3d_basteln.webp', 'Zwei Kinder basteln Papiersterne')),
  _SceneRule(RegExp(r'^Auf dem Teller liegen \d+ Semmeln'), _semmeln),
  _SceneRule(RegExp(r'^Im Regal stehen \d+ Bücher'),
      const StorySceneImage('$_dir/story3d_buecherei.webp', 'Ein Kind leiht in der Bücherei Bücher aus')),
];

/// Alle Szenenbilder, die eine Geschichte auslösen kann.
Iterable<StorySceneImage> get allStorySceneImages =>
    _rules.map((rule) => rule.image).toSet();

/// Liefert das Szenenbild zu einer Rechengeschichte oder `null`.
StorySceneImage? storySceneImageFor(String prompt) {
  final text = prompt.trim();
  for (final rule in _rules) {
    if (rule.pattern.hasMatch(text)) return rule.image;
  }
  return null;
}

/// Zeigt das gerenderte 3D-Szenenbild einer Rechengeschichte im
/// Bühnenrahmen. Fehlt die Datei, erscheint [fallback].
class StorySceneFrame extends StatelessWidget {
  const StorySceneFrame({
    super.key,
    required this.scene,
    required this.fallback,
    this.maxHeight = 240,
    this.glow = const Color(0xFFFB923C),
  });

  final StorySceneImage scene;
  final Widget fallback;
  final double maxHeight;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: scene.semanticLabel,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxHeight * 4 / 3, maxHeight: maxHeight),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.32),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  scene.asset,
                  key: ValueKey('story-scene-${scene.asset}'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                  errorBuilder: (_, __, ___) => Center(child: fallback),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
