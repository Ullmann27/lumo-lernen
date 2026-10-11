// Captures the real existing module widgets. These are Flutter test-runtime
// frames, not concept art, an Android device recording or a performance claim.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/features/learning_modules/formen/formen_screen.dart';
import 'package:lumo_lernen/features/learning_modules/learning_module_registry.dart';
import 'package:lumo_lernen/features/learning_modules/minus_bis_10/minus_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/plus_bis_10/plus_bis_10_screen.dart';
import 'package:lumo_lernen/features/learning_modules/zahlen_bis_10/zahlen_bis_10_screen.dart';

const _boundary = ValueKey('learning-adventure-runtime-capture');
final _directory = Platform.environment['LUMO_LEARNING_CAPTURE_DIR'];
final _modules = <String, Widget Function(LumoAppState)>{
  'minus-bis-10': (app) => MinusBis10Screen(appState: app),
  'zahlen-bis-10': (app) => ZahlenBis10Screen(appState: app),
  'formen': (app) => FormenScreen(appState: app),
  'plus-bis-10-reference': (app) => PlusBis10Screen(appState: app),
  for (final entry in <String, String>{
    'uhr': 'm2_uhr',
    'geld': 'm2_geld',
    'zahlen-bis-100': 'm2_zahlen100',
    'einmaleins': 'm2_einmaleins',
    'grosses-einmaleins': 'm3_einmaleins_voll',
    'brueche': 'm4_bruch',
    'artikel': 'd2_artikel',
    'mehrzahl': 'd2_mehrzahl',
    'wortarten': 'd3_wortarten',
    'zeitformen': 'd3_zeitformen',
    'tiere': 's1_tiere',
    'farben': 's1_farben',
    'jahreszeiten': 's2_jahreszeiten',
    'wetter': 's2_wetter',
    'verkehr': 's2_verkehr',
    'wort-diktat': 'd1_woerter',
  }.entries)
    entry.key: (app) => LearningModuleRegistry.builderFor(entry.value, app)!,
};
const _sizes = <String, Size>{
  'phone-360x800': Size(360, 800),
  'landscape-640x360': Size(640, 360),
  'wide-1280x720': Size(1280, 720),
  // Logical size derived from the existing Android Fold QA configuration:
  // 2176 x 1812 physical pixels at device scale 2.25. Not a physical Samsung.
  'fold-2176x1812-density-225': Size(2176 / 2.25, 1812 / 2.25),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Nunito')
          ..addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  setUp(() {
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
  });

  for (final module in _modules.entries) {
    for (final size in _sizes.entries) {
      testWidgets('Real module capture ${module.key} ${size.key}',
          (tester) async {
        final density = size.key.contains('density-225') ? 2.25 : 1.0;
        tester.view.devicePixelRatio = density;
        tester.view.physicalSize = size.value * density;
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        await tester.binding.setSurfaceSize(size.value);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final app = LumoAppState();
        addTearDown(app.dispose);
        await tester.runAsync(() async {
          await app.hydrateFromWallet();
          await app.loadLearningProfile();
        });
        // A test profile, never an edit to a child's real data.
        app.state.settings = app.state.settings.copyWith(
          voiceEnabled: false,
          autoReadEnabled: false,
          reduceAnimations: true,
        );
        await tester.pumpWidget(MaterialApp(
          theme: LumoAppTheme.light(),
          home: RepaintBoundary(
            key: _boundary,
            child: module.value(app),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.runAsync(() async {
          await Future.wait(find.byType(Image).evaluate().map((element) {
            final widget = element.widget as Image;
            return precacheImage(widget.image, element);
          }));
        });
        await tester.pump();
        expect(tester.takeException(), isNull);
        final render = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(_boundary),
        );
        await tester.runAsync(() async {
          final image = await render.toImage(pixelRatio: 1);
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File('$_directory/${module.key}-${size.key}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(tester.takeException(), isNull);
      }, skip: _directory == null);
    }
  }
}
