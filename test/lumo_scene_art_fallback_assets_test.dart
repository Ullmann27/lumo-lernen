import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_scene_art_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('All four learning scenes have distinct valid packaged PNG fallbacks',
      () async {
    const scenes = LumoSceneArt.values;
    expect(scenes, hasLength(4));
    final fallbackPaths =
        scenes.map((scene) => scene.fallbackAssetPath).toList();
    expect(fallbackPaths.toSet(), hasLength(scenes.length),
        reason: 'Stories, star maps, seasons and math must not reuse one pose');

    for (final scene in scenes) {
      if (scene != LumoSceneArt.seasons) {
        expect(scene.assetPath, isNot(scene.fallbackAssetPath));
      }
      final data = await rootBundle.load(scene.fallbackAssetPath);
      expect(data.lengthInBytes, greaterThan(24),
          reason: 'The Lumo fallback must be a real bundled image');
      final signature = List<int>.generate(8, data.getUint8);
      expect(signature, orderedEquals(const [137, 80, 78, 71, 13, 10, 26, 10]),
          reason: 'Only real PNG artwork is accepted');
    }
  });

  test('Seasons primary artwork is packaged and decodes as a real image',
      () async {
    final data = await rootBundle.load(LumoSceneArt.seasons.assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    try {
      final frame = await codec.getNextFrame();
      try {
        expect(frame.image.width, greaterThan(0));
        expect(frame.image.height, greaterThan(0));
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  });
}
