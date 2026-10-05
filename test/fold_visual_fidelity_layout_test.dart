import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/widgets/design/lumo_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  Future<void> pumpWork(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 180));
    }
  }

  testWidgets(
      'Fold home keeps four compact main tiles, progress rail and floating Lumo',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(840, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(
      theme: LumoAppTheme.light(),
      home: const AppShell(),
    ));
    await pumpWork(tester);

    expect(find.byType(LumoFoldProgressPanel), findsOneWidget);
    expect(find.byKey(const ValueKey('home-learn')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-games')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-tests')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-rewards')), findsOneWidget);
    expect(find.text('SZENENBILD-PLATZHALTER'), findsNothing);

    final homeScroll =
        find.byKey(const PageStorageKey<String>('lumo-home-scroll'));
    final homeGrid =
        find.descendant(of: homeScroll, matching: find.byType(GridView));
    expect(homeGrid, findsWidgets);
    final grid = tester.widget<GridView>(homeGrid.first);
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 4);

    final floor = find.byKey(const ValueKey('lumo-companion-floor'));
    expect(floor, findsOneWidget);
    final floorSize = tester.getSize(floor);
    expect(floorSize.width, lessThanOrEqualTo(64));
    expect(floorSize.height, lessThanOrEqualTo(64));

    expect(tester.takeException(), isNull);
  });
}
