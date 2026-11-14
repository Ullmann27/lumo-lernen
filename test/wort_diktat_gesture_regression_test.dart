import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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

const _settings = AppSettings(
  voiceEnabled: false,
  autoReadEnabled: false,
  soundEnabled: false,
  reduceAnimations: true,
  calmMode: true,
);

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

Finder _row(int index) => find.descendant(
  of: find.byType(WortDiktatScreen),
  matching: find.byWidgetPredicate((widget) =>
      widget is CustomPaint &&
      widget.painter?.runtimeType.toString() == '_StrokesPainter'),
).at(index);

List<List<Offset>> _paintedStrokes(WidgetTester tester, int row) {
  final dynamic painter = tester.widget<CustomPaint>(_row(row)).painter;
  return [
    for (final List<Offset> stroke in painter.strokes as List<List<Offset>>)
      List<Offset>.of(stroke),
  ];
}

Future<void> _mount(WidgetTester tester, Size size) async {
  await tester.binding.setSurfaceSize(size);
  late LumoAppState app;
  await tester.runAsync(() async {
    app = LumoAppState(walletRepository: RewardWalletRepository());
    await app.hydrateFromWallet().timeout(const Duration(seconds: 15));
    await app.loadLearningProfile().timeout(const Duration(seconds: 15));
  });
  app.state.settings = _settings;
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
}

Future<TestGesture> _stroke(WidgetTester tester, int row, int pointer) async {
  await tester.ensureVisible(_row(row));
  await frames(tester, 8);
  final rect = tester.getRect(_row(row));
  final gesture = await tester.startGesture(
    rect.center - const Offset(45, 0), pointer: pointer,
  );
  for (var step = 0; step < 6; step++) {
    await gesture.moveBy(const Offset(15, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  return gesture;
}

Future<void> _finish(WidgetTester tester) async {
  final finish = find.text('Fertig ✓');
  await tester.ensureVisible(finish);
  await tester.tap(finish);
  await frames(tester, 10);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      'lumo_app_settings_v1': jsonEncode(_settings.toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    LumoSound.instance.muted = true;
  });

  for (final size in const [Size(430, 600), Size(640, 360)]) {
    testWidgets('actual WortDiktat vertical stroke stays stationary at $size',
        (tester) async {
      await _mount(tester, size);
      final area = _row(0);
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
      List<List<Offset>> strokes() =>
          (tester.widget<CustomPaint>(area).painter as dynamic).strokes
              as List<List<Offset>>;
      expect(strokes(), hasLength(1));
      final completedStroke = List<Offset>.of(strokes().single);
      expect(completedStroke.length, greaterThan(1));
      final interrupted =
          await tester.startGesture(before.center, pointer: 102);
      await interrupted.moveBy(const Offset(10, 15));
      await interrupted.cancel();
      await tester.pump();
      expect(strokes(), [completedStroke],
          reason: 'Cancelling another stroke must preserve the completed word');
      await _finish(tester);
      expect(find.text('Das richtige Wort war:'), findsOneWidget,
          reason: 'The stationary real stroke must still reach the existing comparison.');
    });
  }

  testWidgets('a WortDiktat tap alone is not a completed writing attempt',
      (tester) async {
    await _mount(tester, const Size(840, 1000));
    await tester.tap(_row(0));
    await tester.pump();
    await _finish(tester);
    expect(find.text('Das richtige Wort war:'), findsNothing);
    expect(find.text('Schreib zuerst das Wort - dann tippe Fertig!'), findsOneWidget);
  });

  testWidgets('a cancelled WortDiktat stroke is not a completed attempt',
      (tester) async {
    await _mount(tester, const Size(840, 1000));
    final gesture = await _stroke(tester, 0, 111);
    await gesture.cancel();
    await tester.pump();
    expect(_paintedStrokes(tester, 0), isEmpty,
        reason: 'A cancelled active stroke must leave no committed row ink.');
    await _finish(tester);
    expect(find.text('Das richtige Wort war:'), findsNothing);
  });

  testWidgets('WortDiktat cancel preserves completed strokes in other rows',
      (tester) async {
    await _mount(tester, const Size(840, 1000));
    final first = await _stroke(tester, 0, 121);
    await first.up();
    await tester.pump();
    final saved = _paintedStrokes(tester, 0);
    expect(saved, hasLength(1));
    expect(saved.single.length, greaterThan(1));
    final second = await _stroke(tester, 1, 122);
    await second.cancel();
    await tester.pump();
    expect(_paintedStrokes(tester, 0), saved,
        reason: 'Cancelling a later row cannot remove an earlier finished stroke.');
    expect(_paintedStrokes(tester, 1), isEmpty);
    await _finish(tester);
    expect(find.text('Das richtige Wort war:'), findsOneWidget);
  });
}
