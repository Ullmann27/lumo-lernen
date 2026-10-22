import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Device sizes of the Fold matrix in logical pixels.
const lumoCaptureSizes = <String, Size>{
  'fold-cover': Size(344, 882),
  'phone': Size(412, 915),
  'fold-open': Size(690, 829),
};

/// Real Nunito and Material icons, so captures show the actual typography.
Future<void> loadLumoCaptureFonts() async {
  final font = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await font.load();
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
}

/// The production Android device supplies its own color emoji font.
/// GitHub's headless Linux Flutter test process does not. Load a real
/// platform emoji font only for the rasterization test, never bundle or
/// substitute an invented emoji image in the application.
Future<void> loadLumoCaptureEmojiFont() async {
  const path = '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf';
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Missing Linux Noto Color Emoji test font: $path');
  }
  final emoji = FontLoader('Noto Color Emoji')
    ..addFont(file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)));
  await emoji.load();
}

/// Decodes visible images, pumps a few frames and writes the boundary
/// [key] as PNG to [path]. The image is the real widget tree, unretouched.
Future<void> captureLumoBoundary(
  WidgetTester tester,
  Key key,
  String path, {
  double pixelRatio = 2,
}) async {
  await tester.runAsync(() async {
    await Future.wait(tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => precacheImage(
                image.image, tester.element(find.byWidget(image)))
            .catchError((_) {})));
  });
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  final render = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  await tester.runAsync(() async {
    final image = await render.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
