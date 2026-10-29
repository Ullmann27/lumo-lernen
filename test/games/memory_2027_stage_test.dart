import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/app/app_state.dart';
import 'package:lumo_lernen/core/app_settings.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_game.dart';
import 'package:lumo_lernen/features/games/memory/lumo_memory_stage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in <Size>[
    const Size(344, 882),
    const Size(690, 829),
    const Size(850, 392),
  ]) {
    testWidgets('Premium Memory stage preserves playable cards at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final app = LumoAppState();
      app.updateSettings(const AppSettings(
        voiceEnabled: false,
        soundEnabled: false,
        reduceAnimations: true,
      ));
      await tester.pumpWidget(MaterialApp(
        home: LumoMemoryScreen(
          appState: app,
          seed: 4,
          difficulty: MemoryDifficulty.leicht,
        ),
      ));
      await tester.pump();

      expect(find.byType(LumoMemoryStage), findsOneWidget);
      final stage = find.byKey(const ValueKey('memory-2027-stage'));
      expect(stage, findsOneWidget);
      expect(
        find.ancestor(of: stage, matching: find.byType(IgnorePointer)),
        findsWidgets,
        reason: 'The painted backdrop cannot steal card taps.',
      );
      final card = find.byKey(const ValueKey('memory-card-0'));
      expect(card.hitTestable(), findsOneWidget);
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.bySemanticsLabel(RegExp('Memory Karte 1, .*')),
        findsWidgets,
        reason: 'The actual card remains accessible through semantics.',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    });
  }
}
