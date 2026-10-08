// Echte App-Screenshots der Hauptbereiche (kein Konzeptbild): rendert die
// vollständige AppShell mit Profil auf Telefon- und Fold-Größe.
// Läuft nur mit LUMO_TOUR_DIR=<ordner>, sonst übersprungen.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/core/user_profile.dart';

final String? _out = Platform.environment['LUMO_TOUR_DIR'];
const _boundary = ValueKey('lumo-app-tour');

const sizes = <String, Size>{
  'phone': Size(412, 915),
  'fold': Size(690, 829),
};
const sections = <LumoSection>[
  LumoSection.home,
  LumoSection.learn,
  LumoSection.games,
  LumoSection.tests,
  LumoSection.rewards,
  LumoSection.profile,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final font = FontLoader('Nunito')
      ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
    await font.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
        voiceEnabled: false,
        autoReadEnabled: false,
        microphoneEnabled: false,
        aiProxyEnabled: false,
        reduceAnimations: true,
      ).toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
  });

  Future<void> capture(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      await Future.wait(tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => precacheImage(
              image.image, tester.element(find.byWidget(image)))
              .catchError((_) {})));
    });
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final render =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(_boundary));
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_out/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final size in sizes.entries) {
    for (final section in sections) {
      testWidgets('Tour ${size.key} ${section.name}', (tester) async {
        await tester.binding.setSurfaceSize(size.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final date = DateTime(2026, 10, 8);
        await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: RepaintBoundary(
            key: _boundary,
            child: AppShell(
              profile: UserProfile(
                id: 'tour',
                name: 'Mia',
                age: 8,
                grade: 2,
                createdAt: date,
                lastActiveAt: date,
              ),
              initialSection: section,
            ),
          ),
        ));
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await capture(tester, '${size.key}_${section.name}');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }, skip: _out == null);
    }
  }
}
