import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/lumo3d/native_table_transport.dart';

/// Actual Flutter widget-test rendering of the Memory board (not a device
/// capture). Output: LUMO_MEMORY_FLUTTER_CAPTURE_DIR or .ci-results/memory.
class _NoTable implements NativeTableTransport {
  @override
  Future<void> open(String token, Map<String, Object?> state) async =>
      throw MissingPluginException('capture');
  @override
  Future<Map<String, dynamic>> poll(String token) async => {};
  @override
  Future<void> publish(String token, Map<String, Object?> state) async {}
  @override
  Future<void> close(String token) async {}
}

Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump(const Duration(milliseconds: 40));
  }
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('memory-visual-capture')));
  final folder = Platform.environment['LUMO_MEMORY_FLUTTER_CAPTURE_DIR'] ??
      '.ci-results/memory';
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Memory capture has no PNG bytes');
      await Directory(folder).create(recursive: true);
      await File('$folder/$name.png').writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true);
    } finally {
      image.dispose();
    }
  });
}

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

  for (final view in const [
    (name: 'phone', size: Size(412, 915)),
    (name: 'landscape', size: Size(915, 412)),
  ]) {
    testWidgets('Memory board visual capture ${view.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final app = LumoAppState();
      app.updateSettings(const AppSettings(
          voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
      await app.school.setActiveStudent('memory-visual-${view.name}');
      await tester.binding.setSurfaceSize(view.size);
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: const ValueKey('memory-visual-capture'),
          child: LumoMemoryScreen(
              appState: app, seed: 4, difficulty: MemoryDifficulty.mittel,
              nativeTransport: _NoTable()),
        ),
      ));
      await _settle(tester);
      expect(find.byKey(const ValueKey('memory-card-0')).hitTestable(), findsOneWidget);
      await _capture(tester, 'memory-flutter-${view.name}-start');
      final deck = MemoryBoard.deal(MemoryDifficulty.mittel, Random(4));
      final first = deck.first;
      for (var i = 0; i < deck.length; i++) {
        if (deck[i] != first) continue;
        await tester.tap(find.byKey(ValueKey('memory-card-$i')));
        await _settle(tester, 4);
      }
      await _settle(tester, 20);
      await _capture(tester, 'memory-flutter-${view.name}-pair');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      app.dispose();
      await tester.binding.setSurfaceSize(null);
    });
  }
}
