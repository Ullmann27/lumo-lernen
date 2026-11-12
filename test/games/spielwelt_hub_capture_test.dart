import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

import '../helpers/lumo_capture.dart';

const _devices = <String, Size>{
  'phone': Size(412, 915),
  'fold7-cover': Size(344, 882),
  'phone-full': Size(412, 2400),
  'fold7-open-portrait': Size(690, 829),
  'fold7-open-landscape': Size(840, 560),
  'tablet-portrait': Size(768, 1024),
  'tablet-landscape': Size(1024, 768),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadLumoCaptureFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in _devices.entries) {
    testWidgets('Spielwelt hub capture ${entry.key}', (tester) async {
      await tester.binding.setSurfaceSize(entry.value);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const boundary = ValueKey('spielwelt-hub-capture');
      final app = LumoAppState();
      addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: GamesContent(appState: app),
          ),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 350)));
      await tester.pump(const Duration(milliseconds: 800));

      for (final identity in const [
        'memory',
        'cards',
        'puzzle',
        'jumpRun',
        'rhythm',
        'treasure',
        'build',
        'kart',
        'connectFour',
        'quizShow',
      ]) {
        final portal = find.byKey(ValueKey('spielwelt-portal-$identity'));
        expect(portal, findsOneWidget, reason: '${entry.key} $identity');
        final box = tester.getRect(portal);
        expect(box.width, greaterThanOrEqualTo(48 - .001),
            reason: '${entry.key} $identity width');
        expect(box.height, greaterThanOrEqualTo(48 - .001),
            reason: '${entry.key} $identity height');
        if (entry.key == 'fold7-open-portrait') {
          expect(box.top, greaterThanOrEqualTo(0),
              reason: 'All ten games start inside the open Fold viewport');
          expect(box.bottom, lessThanOrEqualTo(entry.value.height),
              reason: 'The compact stage must not push $identity off screen');
        }
      }

      final kart =
          tester.getRect(find.byKey(const ValueKey('spielwelt-portal-kart')));
      expect(kart.bottom, lessThanOrEqualTo(entry.value.height),
          reason: 'The complete Kart launch tile is visible immediately');

      for (final title in const [
        'Memory',
        'Cards',
        'Puzzle',
        'Jump & Run',
        'Rhythm',
        'Schatzsuche',
        'Bauwelt',
        'Lumo Kart',
        '4 Gewinnt',
        'Quizshow',
      ]) {
        expect(find.text(title), findsWidgets, reason: '${entry.key} $title');
      }

      final out = Platform.environment['LUMO_HUB_CAPTURES'];
      if (out != null && out.isNotEmpty) {
        await captureLumoBoundary(tester, boundary, '$out/${entry.key}.png');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
