// ════════════════════════════════════════════════════════════════════════
// LUMO ASSET PATHS — zentrale Asset-Pfad-Registry
// ════════════════════════════════════════════════════════════════════════
// Tier-A-Foundation aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
// Single Source of Truth fuer alle Asset-Pfade die in mehreren Stellen
// im Code referenziert werden.
//
// Regel: keine 'assets/...' Strings mehr direkt in Widgets verteilen -
// stattdessen LumoAssetPaths.companionIdle, LumoAssetPaths.sfxCardWhoosh,
// etc. So gibt's bei einem Pfad-Wechsel nur eine Aenderung im Repo.
//
// Companion-Posen + Lottie-Animationen haben zusaetzlich enum-basierte
// Convenience-Mapper in lumo_companion_pose.dart.
//
// SVG-Icons haben eine eigene Klasse LumoIconPaths in lumo_icon_paths.dart
// (40 Stueck, zu viel fuer diese Datei).
// ════════════════════════════════════════════════════════════════════════

/// Zentrale Asset-Pfade fuer Companion-Sprites, Lottie-Animationen, SFX,
/// Musik und Lernfragen-JSONs.
class LumoAssetPaths {
  LumoAssetPaths._();

  // ── Companion (Lumo-Fuchs Posen) ──────────────────────────────────────
  static const String companionIdle = 'assets/companion/lumo_idle.png';
  static const String companionCheer = 'assets/companion/lumo_cheer.png';
  static const String companionThink = 'assets/companion/lumo_think.png';
  static const String companionSad = 'assets/companion/lumo_sad.png';
  static const String companionSurprised =
      'assets/companion/lumo_surprised.png';

  // ── Lottie-Animationen ────────────────────────────────────────────────
  static const String lottieIdle = 'assets/lottie/lumo_idle.json';
  static const String lottieCheer = 'assets/lottie/lumo_cheer.json';
  static const String lottieSad = 'assets/lottie/lumo_sad.json';
  static const String lottieThink = 'assets/lottie/lumo_think.json';
  static const String lottieLoading = 'assets/lottie/loading_spinner.json';
  static const String lottieStarBurst = 'assets/lottie/star_burst.json';

  // ── SFX (8 Effekte, alle in LumoSound._assetPath verkabelt) ───────────
  static const String sfxCardWhoosh = 'assets/audio/sfx/card_whoosh.m4a';
  static const String sfxCardDraw = 'assets/audio/sfx/card_draw.m4a';
  static const String sfxPlus2Storm = 'assets/audio/sfx/plus2_storm.m4a';
  static const String sfxPlus4Thunder = 'assets/audio/sfx/plus4_thunder.m4a';
  static const String sfxWinFanfare = 'assets/audio/sfx/win_fanfare.m4a';
  static const String sfxLoseBuzz = 'assets/audio/sfx/lose_buzz.m4a';
  static const String sfxClick = 'assets/audio/sfx/click.m4a';
  static const String sfxError = 'assets/audio/sfx/error.m4a';

  // ── Hintergrund-Musik ─────────────────────────────────────────────────
  static const String musicChillLoop = 'assets/audio/music/chill_loop.m4a';
  static const String musicEnergeticLoop =
      'assets/audio/music/energetic_loop.m4a';
  static const String musicVictoryJingle =
      'assets/audio/music/victory_jingle.m4a';

  // ── Lernfragen (JSON, je 50 Items) ────────────────────────────────────
  static const String questionsGrade1Math =
      'assets/learning_questions/grade1_math.json';
  static const String questionsGrade1German =
      'assets/learning_questions/grade1_german.json';
  static const String questionsGrade2Math =
      'assets/learning_questions/grade2_math.json';
  static const String questionsGrade2German =
      'assets/learning_questions/grade2_german.json';

  /// Liste aller Frage-Bundle-Pfade fuer einfaches Iterate (Tests).
  static const List<String> allQuestionBundles = <String>[
    questionsGrade1Math,
    questionsGrade1German,
    questionsGrade2Math,
    questionsGrade2German,
  ];

  /// Liste aller Companion-Posen-Pfade fuer Smoke-Tests.
  static const List<String> allCompanionPoses = <String>[
    companionIdle,
    companionCheer,
    companionThink,
    companionSad,
    companionSurprised,
  ];

  /// Liste aller Lottie-Pfade fuer Smoke-Tests.
  static const List<String> allLottiePaths = <String>[
    lottieIdle,
    lottieCheer,
    lottieSad,
    lottieThink,
    lottieLoading,
    lottieStarBurst,
  ];
}
