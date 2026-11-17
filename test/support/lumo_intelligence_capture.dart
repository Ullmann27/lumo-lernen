import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const intelligenceBoundary = ValueKey('intelligence-actual-app-capture');
Future<void> loadIntelligenceCaptureFonts() async {
  if (Platform.environment['LUMO_INTELLIGENCE_EVIDENCE'] == null) return;
  await (FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
      .load();
  await (FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
      .load();
}

Future<void> captureIntelligence(WidgetTester tester, String name) async {
  final dir = Platform.environment['LUMO_INTELLIGENCE_EVIDENCE'];
  if (dir == null) return;
  await tester.runAsync(() async {
    await Future.wait(find
        .byType(Image)
        .evaluate()
        .map((e) => precacheImage((e.widget as Image).image, e)));
  });
  await tester.pump();
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(intelligenceBoundary));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}
