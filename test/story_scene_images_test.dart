import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/math_task_templates.dart';
import 'package:lumo_lernen/features/learning/renderers/story_scene_images.dart';

/// Jede Plus- und Wegnehm-Geschichte der Klassen 1 und 2 zeigt ein eigenes,
/// gerendertes 3D-Szenenbild, und jedes Bild liegt wirklich im Projekt.
void main() {
  final storyTemplates = MathTaskTemplates.templates
      .where((t) => t.kind == MathTemplateKind.wordProblemOneStep)
      .toList();

  test('es gibt Ein-Schritt-Geschichten', () {
    expect(storyTemplates, isNotEmpty);
  });

  test('jede generierte Ein-Schritt-Geschichte hat ein Szenenbild', () {
    final missing = <String>{};
    final used = <String>{};
    for (final template in storyTemplates) {
      for (var seed = 0; seed < 400; seed++) {
        final prompt = template.concretize(seed).prompt;
        final scene = storySceneImageFor(prompt);
        if (scene == null) {
          missing.add(prompt.replaceAll(RegExp(r'\d+'), '#'));
        } else {
          used.add(scene.asset);
          // Zahlen im Bild dürfen den Zahlen der Aufgabe nie widersprechen.
          expect(scene.fitsAmounts(prompt), isTrue, reason: '${scene.asset}: $prompt');
        }
      }
    }
    expect(missing, isEmpty, reason: 'Geschichten ohne Bild: $missing');
    expect(used.length, greaterThanOrEqualTo(10));
  });

  test('alle Szenenbilder existieren als Asset-Datei', () {
    for (final scene in allStorySceneImages) {
      expect(File(scene.asset).existsSync(), isTrue, reason: scene.asset);
      expect(scene.semanticLabel, isNotEmpty);
    }
  });

  test('Bild passt zum Inhalt, nicht nur zum Stichwort', () {
    expect(storySceneImageFor('Im Bus sitzen 9 Kinder. An der Haltestelle steigen 3 aus.')?.asset,
        endsWith('story3d_bus.webp'));
    expect(storySceneImageFor('Im Regal stehen 12 Bücher. 4 werden ausgeliehen.')?.asset,
        endsWith('story3d_buecherei.webp'));
    expect(storySceneImageFor('In der Leseecke liegen 5 Bilderbücher.')?.asset,
        endsWith('story3d_leseecke.webp'));
    expect(storySceneImageFor('Ein Zug hat 4 Wagen.'), isNull);
  });

  test('alle Bilder der Ein-Schritt-Geschichten zeigen keine zählbaren Mengen', () {
    for (final scene in allStorySceneImages) {
      expect(scene.depictedAmounts, isNull, reason: scene.asset);
    }
  });

  test('Bild mit sichtbaren Mengen erscheint nur bei passenden Zahlen', () {
    const counted = StorySceneImage('assets/x.webp', 'fünf rote und fünf blaue Stifte',
        depictedAmounts: <int>[5, 5]);
    expect(counted.fitsAmounts('Mia hat 5 rote Buntstifte und 5 blaue.'), isTrue);
    expect(counted.fitsAmounts('Mia hat 3 rote Buntstifte und 5 blaue.'), isFalse);
    expect(counted.fitsAmounts('Mia hat 5 rote Buntstifte.'), isFalse);
    const open = StorySceneImage('assets/y.webp', 'zugedeckter Korb');
    expect(open.fitsAmounts('Im Korb liegen 7 Äpfel.'), isTrue);
  });
}
