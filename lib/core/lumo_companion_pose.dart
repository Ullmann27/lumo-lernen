// ════════════════════════════════════════════════════════════════════════
// LUMO COMPANION POSE — typsicheres Mapping Pose -> Asset
// ════════════════════════════════════════════════════════════════════════
// Statt 'idle.png' / 'cheer.png' als String durch den Code zu reichen,
// nutzen wir das Enum [LumoCompanionPose] und holen Asset-Pfade ueber
// die Extension. Spaeter (PR D Lottie-Integration) liefert dieselbe
// Pose-Variable Vector- ODER Bitmap-Pfad.
//
// Verwendung:
//   final pose = LumoCompanionPose.cheer;
//   Image.asset(pose.pngPath);
//   // ODER Lottie.asset(pose.lottiePath ?? pose.pngPath);
// ════════════════════════════════════════════════════════════════════════

import 'lumo_asset_paths.dart';

/// Verschiedene Emotions-Posen des Lumo-Fuchs-Maskottchens.
enum LumoCompanionPose {
  /// Neutral, freundlich - Default-Zustand.
  idle,

  /// Triumph, Sieg - z.B. nach gewonnener Runde oder richtiger Antwort.
  cheer,

  /// Denkend, Pfote am Kinn - z.B. Denkpause-Karte, Lernfrage laeuft.
  think,

  /// Niedergeschlagen, sanft - z.B. nach Niederlage oder falscher Antwort.
  sad,

  /// Erstaunt, ueberrascht - z.B. wenn der Gegner eine +4-Karte spielt.
  surprised,
}

extension LumoCompanionPosePaths on LumoCompanionPose {
  /// Bitmap-Pfad (PNG) - immer verfuegbar, alle 5 Posen.
  String get pngPath {
    switch (this) {
      case LumoCompanionPose.idle:
        return LumoAssetPaths.companionIdle;
      case LumoCompanionPose.cheer:
        return LumoAssetPaths.companionCheer;
      case LumoCompanionPose.think:
        return LumoAssetPaths.companionThink;
      case LumoCompanionPose.sad:
        return LumoAssetPaths.companionSad;
      case LumoCompanionPose.surprised:
        return LumoAssetPaths.companionSurprised;
    }
  }

  /// Lottie-Pfad (Vector-Animation) - nur fuer 4 von 5 Posen verfuegbar
  /// (idle/cheer/sad/think). 'surprised' hat noch keine Lottie-Variante.
  /// null = Caller soll auf [pngPath] zurueckfallen.
  String? get lottiePath {
    switch (this) {
      case LumoCompanionPose.idle:
        return LumoAssetPaths.lottieIdle;
      case LumoCompanionPose.cheer:
        return LumoAssetPaths.lottieCheer;
      case LumoCompanionPose.think:
        return LumoAssetPaths.lottieThink;
      case LumoCompanionPose.sad:
        return LumoAssetPaths.lottieSad;
      case LumoCompanionPose.surprised:
        return null;
    }
  }

  /// Kurzer semantischer Label-Text fuer Screen-Reader / Accessibility.
  String get semanticLabel {
    switch (this) {
      case LumoCompanionPose.idle:
        return 'Lumo schaut freundlich';
      case LumoCompanionPose.cheer:
        return 'Lumo jubelt';
      case LumoCompanionPose.think:
        return 'Lumo ueberlegt';
      case LumoCompanionPose.sad:
        return 'Lumo ist traurig';
      case LumoCompanionPose.surprised:
        return 'Lumo ist ueberrascht';
    }
  }
}
