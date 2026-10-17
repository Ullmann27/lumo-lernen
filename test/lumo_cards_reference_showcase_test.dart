import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_showcase_screen.dart';

/// Fail closed on the original 390x844 screenshot regression: the WebP
/// key art was missing despite a nonempty PNG and active menu buttons.
bool _hasVisibleCardsArtwork(Uint8List rgba, int width, int height) {
  if (width <= 0 || height <= 0 || rgba.length < width * height * 4) {
    return false;
  }
  var bright = 0;
  var samples = 0;
  for (var y = (height * .22).floor(); y < (height * .72).floor(); y += 7) {
    for (var x = (width * .22).floor(); x < (width * .78).floor(); x += 7) {
      final i = 4 * (y * width + x);
      if ((rgba[i] + rgba[i + 1] + rgba[i + 2]) / 3 > 105) bright++;
      samples++;
    }
  }
  return samples > 0 && bright / samples > .07;
}

void main() {
  test('original blank dark Cards hero fixture cannot pass screenshot gate', () {
    final pixels = Uint8List(60 * 90 * 4);
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = 3;
      pixels[i + 1] = 19;
      pixels[i + 2] = 41;
      pixels[i + 3] = 255;
    }
    expect(_hasVisibleCardsArtwork(pixels, 60, 90), isFalse);
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  test('approved concept key art is packaged into the real Flutter bundle',
      () async {
    final bytes = await rootBundle.load(LumoCardsShowcaseScreen.referenceArt);
    final header = bytes.buffer.asUint8List(0, 12);
    expect(String.fromCharCodes(header.take(4)), 'RIFF');
    expect(String.fromCharCodes(header.skip(8).take(4)), 'WEBP');
    expect(bytes.lengthInBytes, greaterThan(10000));
  });

  testWidgets('solo and local modes are wired to distinct real callbacks',
      (tester) async {
    var solo = 0;
    var local = 0;
    await tester.pumpWidget(MaterialApp(
      home: LumoCardsShowcaseScreen(
        onSolo: () => solo++,
        onLocal: () => local++,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const ValueKey('cards-approved-reference-art')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cards-hub-solo')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(solo, 1);
    expect(local, 0);
    await tester.tap(find.byKey(const ValueKey('cards-hub-local')));
    await tester.pump(const Duration(milliseconds: 150));
    expect(solo, 1);
    expect(local, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image and both action buttons fit phone, Fold and landscape',
      (tester) async {
    final folder = Directory('visual-evidence')..createSync(recursive: true);
    const viewports = <(String, Size)>[
      ('phone_390x844', Size(390, 844)),
      ('fold_cover_320x780', Size(320, 780)),
      ('fold_open_840x760', Size(840, 760)),
      ('landscape_840x400', Size(840, 400)),
    ];
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final (name, size) in viewports) {
      await tester.binding.setSurfaceSize(size);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          home: LumoCardsShowcaseScreen(
            onSolo: () {},
            onLocal: () {},
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 250));
      // PNG dimensions/byte sizes alone let the first cold 390x844 frame
      // pass even though the central hero was entirely dark. Decode and
      // paint the actual bundled ORIGINAL approved WebP before capture.
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage(LumoCardsShowcaseScreen.referenceArt),
          tester.element(
            find.byKey(const ValueKey('cards-approved-reference-art')),
          ),
        );
      });
      await tester.pump();
      for (final id in ['cards-hub-solo', 'cards-hub-local']) {
        final rect = tester.getRect(find.byKey(ValueKey(id)));
        final viewport = Offset.zero & size;
        expect(viewport.contains(rect.topLeft), isTrue);
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
        expect(rect.height, greaterThanOrEqualTo(56));
      }
      expect(tester.takeException(), isNull);
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        try {
          final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          expect(rgba, isNotNull);
          expect(
            _hasVisibleCardsArtwork(
              rgba!.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
              image.width,
              image.height,
            ),
            isTrue,
            reason: 'Original Lumo Cards artwork was absent at $name; '
                'a nonblank PNG with buttons is not adequate proof.',
          );
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          expect(bytes, isNotNull);
          await File('${folder.path}/cards_hub_$name.png')
              .writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
        } finally {
          image.dispose();
        }
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
