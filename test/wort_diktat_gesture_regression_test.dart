import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_sound.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/learning_modules/wort_diktat/wort_diktat_screen.dart';

// Read the two actual decorative images from the checkout, without building
// the unrelated game asset bundle. A local sparse checkout can provide the
// same source-bound files through LUMO_GESTURE_ASSET_ROOT.
class _SourceAssetBundle extends CachingAssetBundle {
  static const images = [
    'assets/lumo_design/fox/fox_avatar.png',
    'assets/lumo_design/fox/fox_book_point.png',
  ];

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final image in images) image: [<String, Object>{'asset': image}],
      })!;
    }
    final root = Platform.environment['LUMO_GESTURE_ASSET_ROOT'] ?? Directory.current.path;
    return ByteData.sublistView(await File('$root/$key').readAsBytes());
  }
}

// The real WortDiktat screen creates its real LumoLearningModuleFrame. No
// artificial ScrollView is inserted around the production writing rows.
Future<void> frames(WidgetTester tester, [int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const settings = AppSettings(
    voiceEnabled: false,
    autoReadEnabled: false,
    soundEnabled: false,
    reduceAnimations: true,
    calmMode: true,
  );
  setUpAll(() async {
    // Use the real local font files without duplicating a large asset bundle.
    final loader = FontLoader('Nunito');
    for (final name in ['Regular', 'Bold', 'ExtraBold', 'Black']) {
      final font = File('assets/fonts/Nunito-$name.ttf');
      expect(font.existsSync(), isTrue, reason: 'Use the production font metrics.');
      loader.addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    }
    await loader.load();
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(settings.toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    LumoSound.instance.muted = true;
  });

  for (final size in const [Size(430, 600), Size(640, 360)]) {
    testWidgets('actual WortDiktat vertical stroke stays stationary at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      late LumoAppState app;
      await tester.runAsync(() async {
        app = LumoAppState(walletRepository: RewardWalletRepository());
        await app.hydrateFromWallet().timeout(const Duration(seconds: 15));
        await app.loadLearningProfile().timeout(const Duration(seconds: 15));
      });
      app.state.settings = settings;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        app.dispose();
        await tester.binding.setSurfaceSize(null);
      });
      await tester.pumpWidget(DefaultAssetBundle(
        bundle: _SourceAssetBundle(),
        child: MaterialApp(
          theme: LumoAppTheme.light(),
          home: WortDiktatScreen(appState: app),
        ),
      ));
      await frames(tester);
      final area = find.descendant(
        of: find.byType(WortDiktatScreen),
        matching: find.byWidgetPredicate((widget) =>
            widget is CustomPaint &&
            widget.painter?.runtimeType.toString() == '_StrokesPainter'),
      ).first;
      expect(area, findsOneWidget);
      await tester.ensureVisible(area);
      await frames(tester, 8);
      final positions = <ScrollPosition>[];
      tester.element(area).visitAncestorElements((element) {
        if (element is StatefulElement && element.state is ScrollableState) {
          final position = (element.state as ScrollableState).position;
          if (position.maxScrollExtent > 0) positions.add(position);
        }
        return true;
      });
      expect(positions, isNotEmpty,
          reason: 'Exercise the real compact/landscape scrolling fallback.');
      final before = tester.getRect(area);
      final initialOffsets = positions.map((position) => position.pixels).toList();
      final travel = math.min(50.0, before.height - 12);
      expect(travel, greaterThan(18),
          reason: 'The visible row must permit a meaningful vertical stroke.');
      final first = await tester.startGesture(
        before.center + Offset(0, travel / 2),
        pointer: 101,
      );
      final observations = <List<double>>[];
      final origins = <Offset>[];
      for (var step = 0; step < 8; step++) {
        await first.moveBy(Offset(0, -travel / 8));
        await tester.pump(const Duration(milliseconds: 16));
        observations.add(positions.map((position) => position.pixels).toList());
        origins.add(tester.getTopLeft(area));
      }
      await first.up();
      await tester.pump();
      debugPrint('[DiktatGesture] size=$size canvas=$before travel=$travel '
          'initial=$initialOffsets during=$observations origins=$origins');
      expect(tester.takeException(), isNull);
      for (final sample in observations) {
        for (var index = 0; index < initialOffsets.length; index++) {
          expect(sample[index], closeTo(initialOffsets[index], 0.001),
              reason: 'The real writing row must not scroll while drawing.');
        }
      }
      for (final origin in origins) {
        expect((origin - before.topLeft).distance, lessThan(0.001));
      }
      final finish = find.text('Fertig ✓');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await frames(tester, 10);
      expect(find.text('Das richtige Wort war:'), findsOneWidget,
          reason: 'The stationary real stroke must still reach the existing comparison.');
    });
  }
}
