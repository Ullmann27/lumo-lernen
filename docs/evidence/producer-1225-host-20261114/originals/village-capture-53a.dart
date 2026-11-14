// Original production Spielewelt widget capture, not an illustrated concept.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

import '../helpers/lumo_capture.dart';

void main() {
  final dir = Platform.environment['LUMO_VILLAGE_CAPTURES'];
  setUpAll(loadLumoCaptureFonts);

  for (final (device, size, textScale) in <(String, Size, double)>[
    for (final config in lumoCaptureSizes.entries)
      (config.key, config.value, 1),
    ('fold-landscape', const Size(1200, 900), 1),
    ('fold-wide-min', const Size(640, 829), 1),
    ('fold-open-large-text', const Size(690, 829), 1.2),
  ]) {
    testWidgets(
      'Actual games hub includes a direct village ' + device,
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        const bridge = MethodChannel('lumo_lernen/bridge');
        final calls = <MethodCall>[];
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(bridge, (call) async {
          calls.add(call);
          return {'destination': 'games'};
        });
        addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        addTearDown(app.dispose);
        const key = ValueKey('lumo-village-real-capture');
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: LumoAppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: key,
              child: Scaffold(body: GamesContent(appState: app)),
            ),
          ),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 800));
        final village = find.byKey(const ValueKey('spielwelt-portal-village'));
        expect(village, findsOneWidget);
        await tester.ensureVisible(village);
        await tester.pump(const Duration(milliseconds: 150));
        expect(tester.getSize(village).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(village).height, greaterThanOrEqualTo(48));
        expect(village.hitTestable(), findsOneWidget);
        final label = find.descendant(
          of: village,
          matching: find.text('Dorfwirtschaft'),
        );
        expect(label, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(label);
        expect(paragraph.text.toPlainText(), 'Dorfwirtschaft');
        expect(paragraph.didExceedMaxLines, isFalse);
        final boxes = paragraph.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 14),
        );
        expect(
          boxes,
          hasLength(1),
          reason: '$device must retain the entire village word on one line',
        );
        final glyphs = boxes.single.toRect();
        expect(glyphs.left, greaterThanOrEqualTo(0));
        expect(glyphs.right, lessThanOrEqualTo(paragraph.size.width));
        final globalGlyphs = glyphs.shift(paragraph.localToGlobal(Offset.zero));
        final cardRect = tester.getRect(village);
        expect(globalGlyphs.left, greaterThanOrEqualTo(cardRect.left));
        expect(globalGlyphs.right, lessThanOrEqualTo(cardRect.right));
        expect(globalGlyphs.top, greaterThanOrEqualTo(cardRect.top));
        expect(globalGlyphs.bottom, lessThanOrEqualTo(cardRect.bottom));
        expect(tester.widget<Text>(label).style?.fontSize, 17);
        expect(paragraph.textScaler.scale(17), closeTo(17 * textScale, .001));
        await captureLumoBoundary(
          tester,
          key,
          '$dir/village-$device.png',
          pixelRatio: 1,
        );
        await tester.tap(village);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await tester.pump(const Duration(milliseconds: 700));
        final launches = calls.where((call) => call.method == 'launch3D');
        expect(launches, hasLength(1));
        final options = launches.single.arguments as Map;
        expect(options['scene'], 'settlement');
        expect(options['livingVillage'], isTrue);
        expect(options['settlementMode'], 'settlement');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
      skip: dir == null,
      variant: TargetPlatformVariant.only(TargetPlatform.android),
    );
  }
}
