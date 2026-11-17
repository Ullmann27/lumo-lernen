import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_assets.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_models.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_playing_card.dart';

import '../helpers/lumo_capture.dart';

/// Exports rendered LUMO faces as evidence without changing bundled assets.
/// Enable with LUMO_EXPORT_CARD_FACES=1 and LUMO_CARD_FACE_EXPORT_DIR=<dir>.
void main() {
  final enabled = Platform.environment['LUMO_EXPORT_CARD_FACES'] == '1';
  final directory = Platform.environment['LUMO_CARD_FACE_EXPORT_DIR'];

  setUpAll(() async {
    if (enabled) await loadLumoCaptureFonts();
  });

  testWidgets('export rendered LUMO faces without replacing bundled artwork',
      (tester) async {
    expect(directory, isNotNull);
    expect(directory, isNotEmpty);
    const key = ValueKey('export-card-face');
    Future<void> export(LumoCard card) async {
      final path = LumoCardsAssets.assetFor(card);
      expect(path, isNotNull, reason: card.toString());
      await tester.binding.setSurfaceSize(const Size(320, 460));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ColoredBox(
          color: const Color(0x00000000),
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: LumoPlayingCard(
                card: card,
                width: 240,
                height: 352,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      final render =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes, isNotNull);
        final file = File('$directory/$path');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final color in LumoCardColor.values) {
      for (var n = 0; n <= 9; n++) {
        await export(LumoCard(
            id: 'export-$n',
            color: color,
            type: LumoCardType.number,
            number: n));
      }
      for (final type in const [
        LumoCardType.lumoJump,
        LumoCardType.starRain,
        LumoCardType.whirlwind,
        LumoCardType.thinkPause,
      ]) {
        await export(
            LumoCard(id: 'export-${type.name}', color: color, type: type));
      }
    }
  }, skip: !enabled);
}
