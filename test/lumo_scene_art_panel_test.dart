import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/widgets/design/lumo_scene_art_panel.dart';

void main() {
  test('each scene declares its distinct cutout and accessible description', () {
    final paths = LumoSceneArt.values.map((scene) => scene.assetPath).toSet();
    expect(paths, hasLength(LumoSceneArt.values.length));
    for (final scene in LumoSceneArt.values) {
      expect(scene.assetPath, endsWith('_cutout.png'));
      expect(scene.description.trim(), isNotEmpty);
    }
  });

  for (final size in [const Size(320, 740), const Size(840, 720)]) {
    testWidgets('optional cutouts have safe native fox fallback on $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                for (final scene in LumoSceneArt.values)
                  LumoSceneArtPanel(
                    key: ValueKey('art-${scene.name}'),
                    scene: scene,
                    height: 115,
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (final scene in LumoSceneArt.values) {
        expect(find.byKey(ValueKey('art-${scene.name}')), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
