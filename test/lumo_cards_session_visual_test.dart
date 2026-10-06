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
import 'package:lumo_lernen/core/lumo_music.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/games/lumo_cards/lumo_cards_screen.dart';
import 'package:lumo_lernen/features/games/lumo_cards/widgets/lumo_intro_splash.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shots = <Map<String, Object?>>[];
  final loadedFonts = <String, String>{};
  setUpAll(() async {
    // Match the documented Android fallback; do not call this bundled Nunito.
    final folder =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File('$folder/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
      loadedFonts[entry.key] = entry.value;
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LumoSound.instance.muted = true;
    LumoMusic.instance.muted = true;
    LumoVoice.instance.isEnabled = false;
  });

  Future<void> capture(WidgetTester tester, GlobalKey key, Size size,
      String name) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = (await tester.runAsync(() => boundary.toImage(pixelRatio: 2)))!;
    try {
      final data = await tester
          .runAsync(() => image.toByteData(format: ui.ImageByteFormat.png));
      expect(data, isNotNull);
      expect(image.width, size.width.round() * 2);
      expect(image.height, size.height.round() * 2);
      final dir = Directory('ci-out/cards-visual')..createSync(recursive: true);
      final file = File('${dir.path}/$name.png');
      file.writeAsBytesSync(data!.buffer.asUint8List(), flush: true);
      expect(file.lengthSync(), greaterThan(10000));
      shots.add({
        'file': '$name.png',
        'logical_width': size.width,
        'logical_height': size.height,
        'pixel_width': image.width,
        'pixel_height': image.height,
      });
    } finally {
      image.dispose();
    }
  }

  for (final entry in <(String, Size)>[
    ('phone', const Size(360, 780)),
    ('fold', const Size(720, 840)),
    ('landscape', const Size(840, 400)),
    ('tablet', const Size(1024, 800)),
  ]) {
    testWidgets('render actual Cards and avatar dialog ${entry.$1}',
        (tester) async {
      await tester.binding.setSurfaceSize(entry.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(walletRepository: RewardWalletRepository());
      await app.hydrateFromWallet();
      final key = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LumoAppTheme.light(),
        builder: (context, child) => RepaintBoundary(key: key, child: child!),
        home: LumoCardsScreen(appState: app, seed: 10),
      ));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      if (find.byType(LumoIntroSplash).evaluate().isNotEmpty) {
        await tester.tap(find.byType(LumoIntroSplash));
      }
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      await capture(tester, key, entry.$2, 'cards-${entry.$1}');
      await tester.tap(find.byTooltip('Avatar wechseln'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
      await capture(tester, key, entry.$2, 'avatar-${entry.$1}');
      await tester.tap(find.byTooltip('Auswahl schließen'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Spiel pausiert'), findsOneWidget);
      await capture(tester, key, entry.$2, 'paused-${entry.$1}');
      await tester.pumpWidget(const SizedBox());
      app.dispose();
      expect(tester.takeException(), isNull);
    });
  }

  tearDownAll(() {
    final dirty = Process.runSync('git', ['diff', '--name-only']);
    final sha = Process.runSync('git', ['rev-parse', 'HEAD']);
    final dir = Directory('ci-out/cards-visual')..createSync(recursive: true);
    File('${dir.path}/capture-manifest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'source_commit': dirty.stdout.toString().trim().isEmpty
            ? sha.stdout.toString().trim()
            : null,
        'tracked_differences': dirty.stdout.toString().trim(),
        'renderer': 'Flutter test engine, real app widgets and theme',
        'emulator_test': false,
        'physical_device_test': false,
        'font_aliases': loadedFonts,
        'visual_acceptance': 'Manual review required; rendering is not approval.',
        'shots': shots,
      }),
      flush: true,
    );
  });
}
