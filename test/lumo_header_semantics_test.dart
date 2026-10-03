import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lumo_lernen/app/app_shell.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/core/lumo_voice.dart';
import 'package:lumo_lernen/core/reward_wallet_repository.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_premium_effects.dart';

void main() {
  setUpAll(() async {
    final fonts =
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts';
    for (final entry in {
      'Nunito': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf'
    }.entries) {
      final file = File('$fonts/${entry.value}');
      if (!file.existsSync()) continue;
      final loader = FontLoader(entry.key);
      loader.addFont(
          Future.value(ByteData.sublistView(await file.readAsBytes())));
      await loader.load();
    }
  });

  Rect globalBounds(SemanticsNode node) {
    var rect = node.rect;
    for (SemanticsNode? current = node;
        current != null;
        current = current.parent) {
      if (current.transform != null) {
        rect = MatrixUtils.transformRect(current.transform!, rect);
      }
    }
    return rect;
  }

  testWidgets(
      'actual mobile header keeps touch and accessibility bounds stable',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(360, 740));
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              aiProxyEnabled: false)
          .toJson()),
    });
    LumoVoice.instance.isEnabled = false;
    await RewardWalletRepository.instance.reset();
    await tester.pumpWidget(
        MaterialApp(theme: LumoAppTheme.light(), home: const AppShell()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    final button = find.byKey(const ValueKey('mobile-lumo-button'));
    final accessibility =
        find.bySemanticsLabel('Lumo, dein Lernfuchs. Hilfe öffnen');
    final firstTouch = tester.getRect(button);
    final firstAccessible = globalBounds(tester.getSemantics(accessibility));
    expect(firstTouch.size, const Size(52, 52));
    expect(
        tester
            .getSemantics(accessibility)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue);
    expect(find.descendant(of: button, matching: find.byType(LumoFloating)),
        findsOneWidget);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.getRect(button), firstTouch);
      expect(globalBounds(tester.getSemantics(accessibility)), firstAccessible);
    }
    await tester.tap(button);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Mit Lumo sprechen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
    semantics.dispose();
  });

  testWidgets('reduced motion removes header floating and glow tickers',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    SharedPreferences.setMockInitialValues({
      'lumo_app_settings_v1': jsonEncode(const AppSettings(
              voiceEnabled: false,
              autoReadEnabled: false,
              aiProxyEnabled: false,
              reduceAnimations: true)
          .toJson()),
    });
    await tester.pumpWidget(
        MaterialApp(theme: LumoAppTheme.light(), home: const AppShell()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final button = find.byKey(const ValueKey('mobile-lumo-button'));
    expect(button, findsOneWidget);
    expect(find.descendant(of: button, matching: find.byType(LumoFloating)),
        findsNothing);
    expect(find.descendant(of: button, matching: find.byType(LumoGlowPulse)),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.binding.setSurfaceSize(null);
  });
}
