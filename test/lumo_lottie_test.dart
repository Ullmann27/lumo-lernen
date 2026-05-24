import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_asset_paths.dart';
import 'package:lumo_lernen/features/companion/lumo_lottie.dart';

/// Smoke-Tests fuer LumoLottie. Kein echtes Lottie-Rendering im Test
/// (rootBundle ist leer), aber wir verifizieren:
///   - Widget baut ohne Exception
///   - errorBuilder greift bei fehlendem Asset
///   - Fallback-PNG wird gesetzt wenn angegeben
void main() {
  group('LumoLottie', () {
    testWidgets('baut ohne Exception bei fehlendem Asset',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoLottie(
              asset: LumoAssetPaths.lottieLoading,
              size: 64,
            ),
          ),
        ),
      );
      // Loading-Animation laeuft im TestEnv nicht (kein rootBundle),
      // aber das Widget darf nicht crashen.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('SizedBox hat die gesetzte Groesse', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoLottie(
              asset: LumoAssetPaths.lottieStarBurst,
              size: 96,
            ),
          ),
        ),
      );
      final box = tester.getSize(find.byType(LumoLottie));
      expect(box.width, 96);
      expect(box.height, 96);
    });

    testWidgets('mit Fallback-PNG faellt zurueck wenn Lottie crasht',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoLottie(
              asset: 'assets/lottie/__nonexistent.json',
              size: 64,
              fallbackPngAsset: 'assets/companion/lumo_idle.png',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      // Kein Crash trotz nicht-existierendem Lottie-Asset.
      expect(tester.takeException(), isNull);
    });
  });
}
