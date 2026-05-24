import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/lumo_asset_paths.dart';
import 'package:lumo_lernen/core/lumo_companion_pose.dart';
import 'package:lumo_lernen/core/lumo_icon_paths.dart';

/// Smoke-Test fuer die Asset-Registry. Verifiziert dass jeder
/// const-Pfad eine echte Datei im Repo trifft - faengt Tippfehler in
/// Pfad-Konstanten ab BEVOR sie als Runtime-Crash im APK landen.
///
/// Tests laufen mit Working-Dir = Repo-Root, daher funktioniert
/// File('assets/...').existsSync() direkt.
void main() {
  group('LumoAssetPaths', () {
    test('alle Companion-Posen-PNGs existieren im Repo', () {
      for (final path in LumoAssetPaths.allCompanionPoses) {
        expect(File(path).existsSync(), isTrue,
            reason: 'Companion-Asset fehlt: $path');
      }
    });

    test('alle Lottie-JSONs existieren im Repo', () {
      for (final path in LumoAssetPaths.allLottiePaths) {
        expect(File(path).existsSync(), isTrue,
            reason: 'Lottie-Asset fehlt: $path');
      }
    });

    test('alle 8 SFX-m4a-Files existieren im Repo', () {
      const sfxFiles = <String>[
        LumoAssetPaths.sfxCardWhoosh,
        LumoAssetPaths.sfxCardDraw,
        LumoAssetPaths.sfxPlus2Storm,
        LumoAssetPaths.sfxPlus4Thunder,
        LumoAssetPaths.sfxWinFanfare,
        LumoAssetPaths.sfxLoseBuzz,
        LumoAssetPaths.sfxClick,
        LumoAssetPaths.sfxError,
      ];
      for (final path in sfxFiles) {
        expect(File(path).existsSync(), isTrue,
            reason: 'SFX-Asset fehlt: $path');
      }
    });

    test('alle 3 Music-Loops existieren im Repo', () {
      const music = <String>[
        LumoAssetPaths.musicChillLoop,
        LumoAssetPaths.musicEnergeticLoop,
        LumoAssetPaths.musicVictoryJingle,
      ];
      for (final path in music) {
        expect(File(path).existsSync(), isTrue,
            reason: 'Music-Asset fehlt: $path');
      }
    });

    test('alle 4 Lernfragen-JSON-Bundles existieren im Repo', () {
      for (final path in LumoAssetPaths.allQuestionBundles) {
        expect(File(path).existsSync(), isTrue,
            reason: 'Question-Bundle fehlt: $path');
      }
    });
  });

  group('LumoIconPaths', () {
    test('alle 40 SVG-Icons existieren im Repo', () {
      expect(LumoIconPaths.all.length, 40,
          reason: 'Wir haben 40 Icons aus dem Asset-Pack importiert');
      for (final path in LumoIconPaths.all) {
        expect(File(path).existsSync(), isTrue,
            reason: 'Icon fehlt: $path');
      }
    });

    test('keine doppelten Icon-Pfade in der Liste', () {
      expect(LumoIconPaths.all.toSet().length, LumoIconPaths.all.length);
    });
  });

  group('LumoCompanionPose', () {
    test('jede Pose hat einen PNG-Pfad der existiert', () {
      for (final pose in LumoCompanionPose.values) {
        expect(File(pose.pngPath).existsSync(), isTrue,
            reason: 'Pose ${pose.name} PNG fehlt: ${pose.pngPath}');
      }
    });

    test('4 von 5 Posen haben Lottie-Pfade, surprised hat null', () {
      expect(LumoCompanionPose.idle.lottiePath, isNotNull);
      expect(LumoCompanionPose.cheer.lottiePath, isNotNull);
      expect(LumoCompanionPose.think.lottiePath, isNotNull);
      expect(LumoCompanionPose.sad.lottiePath, isNotNull);
      expect(LumoCompanionPose.surprised.lottiePath, isNull,
          reason: 'fuer surprised wurde keine Lottie generiert - PNG-Fallback');
    });

    test('jede Lottie-Datei die referenziert wird existiert', () {
      for (final pose in LumoCompanionPose.values) {
        final lottie = pose.lottiePath;
        if (lottie != null) {
          expect(File(lottie).existsSync(), isTrue,
              reason: 'Lottie fuer ${pose.name} fehlt: $lottie');
        }
      }
    });

    test('semanticLabel ist nicht leer fuer jede Pose', () {
      for (final pose in LumoCompanionPose.values) {
        expect(pose.semanticLabel.isNotEmpty, isTrue);
      }
    });
  });
}
