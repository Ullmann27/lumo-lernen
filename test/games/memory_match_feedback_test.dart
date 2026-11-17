import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/app/app_theme.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/lumo_capture.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(loadLumoCaptureFonts);
  testWidgets('Matched memory pair has a lasting shape cue and keeps the turn',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(412, 915));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final app = LumoAppState();
    app.updateSettings(const AppSettings(
        voiceEnabled: false, soundEnabled: false, reduceAnimations: true));
    const boundary = ValueKey('memory-feedback-capture');
    await tester.pumpWidget(MaterialApp(
        theme: LumoAppTheme.light(),
        home: RepaintBoundary(
            key: boundary,
            child: LumoMemoryScreen(
                appState: app, seed: 4, difficulty: MemoryDifficulty.leicht))));
    await tester.pump();
    final deck = MemoryBoard.deal(MemoryDifficulty.leicht, Random(4));
    final partner = deck.indexOf(deck[0], 1);
    await tester.tap(find.byKey(const ValueKey('memory-card-0')));
    await tester.tap(find.byKey(ValueKey('memory-card-$partner')));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Du bist dran! Tipp 2 Karten.'), findsOneWidget);
    final folder = Platform.environment['LUMO_MEMORY_CAPTURES'];
    if (folder != null) {
      await captureLumoBoundary(
          tester, boundary, '$folder/memory-match-phone.png',
          pixelRatio: 1.5);
    }
    expect(find.byKey(const ValueKey('memory-matched-mark')), findsNWidgets(2));
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel(RegExp('Memory Karte .*Paar gefunden')),
        findsNWidgets(2));
    semantics.dispose();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
  });
}
