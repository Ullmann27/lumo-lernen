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
///
/// Die Zahlen einer Geschichte wechseln mit jeder Aufgabe. Ein Bild darf
/// deshalb keine zählbaren Mengen zeigen, die der Aufgabe widersprechen:
/// Ohne [depictedAmounts] zeigt das Bild nur Ort und Figuren (Mengen sind
/// verdeckt, z. B. im zugedeckten Korb). Zeigt ein Bild zählbare Mengen,
/// stehen sie in [depictedAmounts]; dann erscheint es nur, wenn die Zahlen
/// der Aufgabe genau passen.
class StorySceneImage {
  const StorySceneImage(this.asset, this.semanticLabel, {this.depictedAmounts});

  final String asset;
  final String semanticLabel;
  final List<int>? depictedAmounts;

  /// Passt das Bild zu den Zahlen dieser Aufgabe?
  bool fitsAmounts(String prompt) {
    final amounts = depictedAmounts;
    if (amounts == null) return true;
    final numbers = RegExp(r'\d+')
        .allMatches(prompt)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    if (numbers.length < amounts.length) return false;
    for (var i = 0; i < amounts.length; i++) {
      if (numbers[i] != amounts[i]) return false;
    }
    return true;
  }
}

class _SceneRule {
  const _SceneRule(this.pattern, this.image);

  final RegExp pattern;
  final StorySceneImage image;
}

const StorySceneImage _aepfel = StorySceneImage(
    '$_dir/story3d_aepfel.webp', 'Ein Mädchen und die Oma tragen einen zugedeckten Apfelkorb');
const StorySceneImage _bus = StorySceneImage(
    '$_dir/story3d_bus.webp', 'Ein Bus steht mit offener Tür an der Haltestelle');
const StorySceneImage _buntstifte = StorySceneImage(
    '$_dir/story3d_buntstifte.webp', 'Ein Federpennal und ein rot-blaues Bild auf dem Schultisch');
const StorySceneImage _semmeln = StorySceneImage(
    '$_dir/story3d_semmeln.webp', 'Ein zugedeckter Brotkorb am Frühstückstisch');

final List<_SceneRule> _rules = <_SceneRule>[
  _SceneRule(RegExp(r'^Lisa hat \d+ Äpfel'), _aepfel),
  _SceneRule(RegExp(r'^Im Korb liegen \d+ Äpfel'), _aepfel),
  _SceneRule(RegExp(r'^Tom hat \d+ Kekse'),
      const StorySceneImage('$_dir/story3d_kekse.webp', 'Ein Bub und die Oma mit der Keksdose in der Küche')),
  _SceneRule(RegExp(r'^Im Bus sitzen \d+ Kinder'), _bus),
  _SceneRule(RegExp(r'^Mia hat \d+ rote Buntstifte'), _buntstifte),
  _SceneRule(RegExp(r'^Lumo hat \d+ Buntstifte'), _buntstifte),
  _SceneRule(RegExp(r'^Am Schulhof spielen \d+ Kinder'),
      const StorySceneImage('$_dir/story3d_schulhof.webp', 'Der Schulhof mit Tempelhüpfen, Ball und Springschnur')),
  _SceneRule(RegExp(r'^Jonas sammelt Sticker'),
      const StorySceneImage('$_dir/story3d_sticker.webp', 'Ein Bub bekommt ein Geschenk für sein Stickeralbum')),
  _SceneRule(RegExp(r'^In Omas Garten blühen \d+ Tulpen'),
      const StorySceneImage('$_dir/story3d_garten.webp', 'Tulpen und Rosen in Omas Garten')),
  _SceneRule(RegExp(r'^Beim Schulfest liegen \d+ Würstelsemmeln'),
      const StorySceneImage('$_dir/story3d_schulfest.webp', 'Zwei zugedeckte Semmelkörbe beim Schulfest')),
  _SceneRule(RegExp(r'^In der Leseecke liegen \d+ Bilderbücher'),
      const StorySceneImage('$_dir/story3d_leseecke.webp', 'Die gemütliche Leseecke mit Polstern und Bücherregal')),
  _SceneRule(RegExp(r'^Auf dem Baum sitzen \d+ Vögel'),
      const StorySceneImage('$_dir/story3d_voegel.webp', 'Ein Baum mit Vogelhaus auf der Wiese')),
  _SceneRule(RegExp(r'^Für die Jause gibt es \d+ Apfelstücke'),
      const StorySceneImage('$_dir/story3d_jause.webp', 'Eine Jausenbox mit Apfel- und Birnenbild')),
  _SceneRule(RegExp(r'^Lumo bastelt \d+ Papiersterne'),
      const StorySceneImage('$_dir/story3d_basteln.webp', 'Zwei Kinder falten goldenes Bastelpapier')),
  _SceneRule(RegExp(r'^Auf dem Teller liegen \d+ Semmeln'), _semmeln),
  _SceneRule(RegExp(r'^Im Regal stehen \d+ Bücher'),
      const StorySceneImage('$_dir/story3d_buecherei.webp', 'Ein Kind geht mit der Büchertasche aus der Bücherei')),
  // Klasse 3: Zwei-Schritt-Geschichten, jugendlicher Bildstil.
  _SceneRule(RegExp(r'^Im Garten blühen \d+ Tulpen\. \d+ gehen neu auf'),
      const StorySceneImage('$_dir/story3d_k3_tulpen.webp', 'Ein Tulpenbeet mit Gartenschere und Handschuh')),
  _SceneRule(RegExp(r'^In der Bücherei stehen \d+ Bilderbücher'),
      const StorySceneImage('$_dir/story3d_buecherei.webp', 'Ein Kind geht mit der Büchertasche aus der Bücherei')),
  _SceneRule(RegExp(r'^Im Schwimmbad sind \d+ Kinder im großen Becken'),
      const StorySceneImage('$_dir/story3d_k3_schwimmbad.webp', 'Hallenbad mit großem und kleinem Becken und Rutsche')),
  _SceneRule(RegExp(r'^Im Aquarium schwimmen \d+ Goldfische'),
      const StorySceneImage('$_dir/story3d_k3_aquarium.webp', 'Aquarium mit Wasserpflanzen, hinter denen sich Fische verstecken')),
  _SceneRule(RegExp(r'^Am Markt liegen \d+ Paradeiser'),
      const StorySceneImage('$_dir/story3d_k3_markt.webp', 'Ein Marktstand mit zugedeckten Kisten')),
  _SceneRule(RegExp(r'^Lena liest am Montag \d+ Seiten'),
      const StorySceneImage('$_dir/story3d_k3_lesen.webp', 'Ein Mädchen liest am Fenster ein dickes Buch')),
  _SceneRule(RegExp(r'^Mama kauft \d+ Packungen mit je \d+ Semmeln'),
      const StorySceneImage('$_dir/story3d_k3_gebaeck.webp', 'Mama und Sohn bekommen beim Bäcker ein Sackerl')),
  _SceneRule(RegExp(r'^In der Garderobe hängen \d+ Jacken'),
      const StorySceneImage('$_dir/story3d_k3_garderobe.webp', 'Ein Bub zieht in der Schulgarderobe seine Jacke an')),
];

/// Alle Szenenbilder, die eine Geschichte auslösen kann.
Iterable<StorySceneImage> get allStorySceneImages =>
    _rules.map((rule) => rule.image).toSet();

/// Liefert das Szenenbild zu einer Rechengeschichte oder `null`.
StorySceneImage? storySceneImageFor(String prompt) {
  final text = prompt.trim();
  for (final rule in _rules) {
    if (rule.pattern.hasMatch(text)) {
      return rule.image.fitsAmounts(text) ? rule.image : null;
    }
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
