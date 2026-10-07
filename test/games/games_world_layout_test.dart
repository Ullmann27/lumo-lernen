import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/features/games/games_content.dart';

/// Spielewelt nach Bild 06: nur echte Spiele, Android-Prüftexte bleiben.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Spielewelt zeigt die vier Spiele und Lumo Kart', (tester) async {
    await tester.binding.setSurfaceSize(const Size(392, 2800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final handle = tester.ensureSemantics();
    final app = LumoAppState();
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 600));

    await tester.ensureVisible(find.text('Weitere Spielwelten entdecken'));
    await tester.tap(find.text('Weitere Spielwelten entdecken'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.bySemanticsLabel('Lumo Spielewelt'), findsOneWidget);
    for (final title in [
      'Memory',
      'Cards',
      'Puzzle',
      'Jump & Run',
      'Rhythm Party',
      'Schatzsuche',
      'Bauwelt',
      'Vier gewinnt',
      'Würfel-Wettlauf',
      'Lumo Kart',
    ]) {
      expect(find.text(title), findsWidgets, reason: title);
    }
    expect(find.byKey(const ValueKey('spielwelt-lumo')), findsOneWidget);
    expect(find.byKey(const ValueKey('spielwelt-adventure')), findsOneWidget);
    expect(find.text('Wortjagd'), findsNothing,
        reason: 'kein Spiel anzeigen, das es nicht gibt');
    expect(find.bySemanticsLabel(RegExp('Losfahren')), findsOneWidget,
        reason: 'Android-Prüfung tippt auf „Losfahren“');
    expect(find.byKey(const ValueKey('launch-lumo-kart')), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  testWidgets('Rhythm Party opens the real native rhythm scene', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const bridge = MethodChannel('lumo_lernen/bridge');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(bridge, (call) async {
      calls.add(call); return {'destination': 'games'};
    });
    try {
      await tester.binding.setSurfaceSize(const Size(1000, 2400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState(); addTearDown(app.dispose);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: GamesContent(appState: app))));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 600));
      final start = find.byKey(const ValueKey('launch-creative-rhythm'));
      await tester.ensureVisible(start); await tester.tap(start);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 600));
      expect(calls.where((c) => c.method == 'launch3D'), hasLength(1));
      expect((calls.firstWhere((c) => c.method == 'launch3D').arguments as Map)['scene'], 'rhythm');
      expect(find.text('Rhythm Party kommt bald!'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    } finally {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(bridge, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
