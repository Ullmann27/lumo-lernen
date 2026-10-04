import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lumo_lernen/widgets/fox/lumo_animated_fox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled fox and kart variants resolve to decodable visible images',
      () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final asset in [
      'assets/images/lumo_fox.png',
      'assets/images/lumo_kart_cover.png',
      'assets/lumo_jump/fox/master/lumo_fox_master_512.png',
      LumoFoxFrames.runAsset,
      LumoFoxFrames.idleAsset,
      'assets/lumo_sprite_pack/cheer/cheer_01.png',
    ]) {
      final variants = manifest.getAssetVariants(asset);
      expect(variants, isNotNull, reason: asset);
      final key = await AssetImage(asset)
          .obtainKey(const ImageConfiguration(devicePixelRatio: 2.625));
      expect(variants!.map((v) => v.key), contains(key.name), reason: asset);
      final bytes = await key.bundle.load(key.name);
      final codec = await ui.instantiateImageCodec(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
      final image = (await codec.getNextFrame()).image;
      try {
        final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        expect(rgba, isNotNull, reason: asset);
        // Transparent padding is intentional, but each decoded source must
        // contain actual visible artwork, including the complete fox sheets.
        var visible = 0;
        for (var i = 3; i < rgba!.lengthInBytes; i += 4 * 128) {
          if (rgba.getUint8(i) > 32) visible++;
        }
        expect(visible, greaterThan(100), reason: asset);
      } finally {
        image.dispose();
        codec.dispose();
      }
    }
  });
}
