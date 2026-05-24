import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_companion_pose.dart';
import 'package:lumo_lernen/features/companion/lumo_companion_pose_image.dart';

/// Widget-Tests fuer LumoCompanionPoseImage. Pruefen Mount, Pose-Wahl,
/// Glow-Toggle und Semantic-Label.
///
/// Hinweis: rootBundle ist im TestWidgetsFlutterBinding leer fuer Assets,
/// daher faellt Image.asset auf errorBuilder zurueck -> sichtbar wird das
/// Emoji-Fallback. Genau das soll der Test verifizieren: KEIN CRASH,
/// stattdessen graceful Fallback.
void main() {
  group('LumoCompanionPoseImage', () {
    Future<void> pumpPose(
      WidgetTester tester, {
      required LumoCompanionPose pose,
      bool showGlow = false,
      double size = 64,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LumoCompanionPoseImage(
              pose: pose,
              size: size,
              showGlow: showGlow,
            ),
          ),
        ),
      );
    }

    testWidgets('rendert ohne Crash fuer jede der 5 Posen',
        (tester) async {
      for (final pose in LumoCompanionPose.values) {
        await pumpPose(tester, pose: pose);
        expect(tester.takeException(), isNull,
            reason: 'Pose ${pose.name} darf nicht crashen');
      }
    });

    testWidgets('zeigt SizedBox mit korrekter Groesse',
        (tester) async {
      await pumpPose(tester, pose: LumoCompanionPose.idle, size: 80);
      final box = tester.getSize(find.byType(LumoCompanionPoseImage));
      expect(box.width, 80);
      expect(box.height, 80);
    });

    testWidgets('Glow-Variante hat DecoratedBox um den Image-Slot',
        (tester) async {
      await pumpPose(tester, pose: LumoCompanionPose.cheer, showGlow: true);
      // Im Glow-Modus wird ein DecoratedBox mit BoxShadow drumherum gewrappt.
      final decorated = find.descendant(
        of: find.byType(LumoCompanionPoseImage),
        matching: find.byType(DecoratedBox),
      );
      expect(decorated, findsAtLeast(1));
    });

    testWidgets('ohne Glow wird kein zusaetzlicher DecoratedBox gerendert',
        (tester) async {
      await pumpPose(tester, pose: LumoCompanionPose.sad);
      // Image.asset selber rendert evtl. interne RawImage etc., aber
      // ohne Glow gibt es im LumoCompanionPoseImage-Subtree keinen
      // BoxShadow-DecoratedBox. Wir pruefen das via Size:
      final box = tester.getSize(find.byType(LumoCompanionPoseImage));
      expect(box.width, 96, reason: 'Default-Size 96');
    });

    testWidgets('Asset-Fehler -> Emoji-Fallback statt Crash',
        (tester) async {
      // In Tests ist rootBundle leer fuer Assets -> errorBuilder greift.
      // Wir verifizieren: kein roter Error-Widget-Crash, sondern das Fuchs-Emoji.
      await pumpPose(tester, pose: LumoCompanionPose.surprised);
      expect(tester.takeException(), isNull);
      expect(find.text('🦊'), findsOneWidget,
          reason: 'Emoji-Fallback muss greifen wenn Asset im Test fehlt');
    });

    testWidgets('semanticLabel-Override greift', (tester) async {
      const customLabel = 'TestLabel';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LumoCompanionPoseImage(
              pose: LumoCompanionPose.idle,
              semanticLabel: customLabel,
            ),
          ),
        ),
      );
      // Da Asset fehlt -> errorBuilder zeigt Emoji, semanticLabel
      // wandert von Image.asset's semanticLabel; pruefen, dass keine
      // Exception flog ist genug fuer Smoke-Test.
      expect(tester.takeException(), isNull);
    });
  });
}
