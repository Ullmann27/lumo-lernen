// Original production Spielewelt widget capture, not an illustrated concept.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

import '../helpers/lumo_capture.dart';

void main() {
  final dir = Platform.environment['LUMO_VILLAGE_CAPTURES'];
  setUpAll(loadLumoCaptureFonts);

  for (final config in <String, Size>{
    ...lumoCaptureSizes,
    'fold-landscape': const Size(1200, 900),
  }.entries) {
    testWidgets('Actual games hub includes a direct village ' + config.key,
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.binding.setSurfaceSize(config.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      addTearDown(app.dispose);
      const key = ValueKey('lumo-village-real-capture');
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
          key: key,
          child: Scaffold(body: GamesContent(appState: app)),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 800));
      final village = find.byKey(const ValueKey('spielwelt-portal-village'));
      expect(village, findsOneWidget);
      await tester.ensureVisible(village);
      await tester.pump(const Duration(milliseconds: 150));
      if (dir != null && dir.isNotEmpty) {
        await captureLumoBoundary(
            tester, key, '$dir/village-' + config.key + '.png', pixelRatio: 1);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
