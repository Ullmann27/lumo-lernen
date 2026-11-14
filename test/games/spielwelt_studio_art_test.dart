import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/features/games/spielwelt/spielwelt_game_icon.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_hub.dart';
import 'package:lumo_lernen/features/games/spielwelt/spielwelt_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all ten studio worlds are bundled as distinct transparent images',
      (tester) async {
    const assets = SpielweltGameIcon.studioAssets;
    expect(assets.keys, unorderedEquals(SpielweltRoutes.identities));
    expect(assets.values.toSet(), hasLength(10));
    final hashes = <String>{};
    await tester.runAsync(() async {
      for (final entry in assets.entries) {
        final bytes = await rootBundle.load(entry.value);
        final data = bytes.buffer
            .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
        hashes.add(sha256.convert(data).toString());
        final codec = await ui.instantiateImageCodec(data);
        try {
          final frame = await codec.getNextFrame();
          try {
            expect(frame.image.width, 512, reason: entry.key);
            expect(frame.image.height, 512, reason: entry.key);
            final rgba = await frame.image.toByteData();
            expect(rgba, isNotNull, reason: entry.key);
            var clearPixels = 0;
            var paintedPixels = 0;
            for (var offset = 3; offset < rgba!.lengthInBytes; offset += 4) {
              final alpha = rgba.getUint8(offset);
              if (alpha == 0) clearPixels++;
              if (alpha > 0) paintedPixels++;
            }
            expect(clearPixels, greaterThan(0),
                reason: '${entry.key}: transparent background');
            expect(paintedPixels, greaterThan(0),
                reason: '${entry.key}: real visible render');
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      }
    });
    expect(hashes, hasLength(10), reason: 'Every portal has its own scene');
  });

  testWidgets('the cover title stays complete with large system text',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final scale in [1.0, 1.8, 2.3]) {
      await tester.binding.setSurfaceSize(const Size(320, 620));
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scale),
            disableAnimations: true,
          ),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SpielweltHub(
              portals: const [],
              stars: 5732,
              reduceMotion: true,
              onAdventure: () {},
              onHome: () {},
              onLearn: () {},
              onTests: () {},
              onParents: () {},
              onProgress: () {},
              onSettings: () {},
            ),
          ),
        ),
      ));
      await tester.pump();
      final title = tester.renderObject<RenderParagraph>(find.text('Spielewelt'));
      expect(title.didExceedMaxLines, isFalse, reason: '$scale text scale');
      expect(tester.getRect(find.text('Spielewelt')).width,
          lessThanOrEqualTo(288));
      expect(tester.takeException(), isNull, reason: '$scale text scale');
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
