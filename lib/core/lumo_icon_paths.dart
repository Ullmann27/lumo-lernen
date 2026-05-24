// ════════════════════════════════════════════════════════════════════════
// LUMO ICON PATHS — Registry fuer die 40 SVG-Icons aus assets/icons/
// ════════════════════════════════════════════════════════════════════════
// Tier-A-Foundation aus dem Asset-Integrations-Plan (Heinz 2026-05-23).
//
// Alle Icons sind currentColor-tintbar, viewBox 64x64, Stroke 3px, rund
// (linejoin=round). Verwendung kommt in PR E mit dem LumoSvgIcon-Widget
// (braucht flutter_svg-Dependency).
//
// Vorerst nur die String-Pfade - bestehender Code bleibt unangetastet.
// ════════════════════════════════════════════════════════════════════════

/// SVG-Icon-Pfade aus assets/icons/ — 40 Lumo-Brand-Icons fuer die UI.
class LumoIconPaths {
  LumoIconPaths._();

  // ── Playback / Media ──────────────────────────────────────────────────
  static const String pause = 'assets/icons/pause.svg';
  static const String play = 'assets/icons/play.svg';
  static const String stop = 'assets/icons/stop.svg';
  static const String volumeOn = 'assets/icons/volume_on.svg';
  static const String volumeOff = 'assets/icons/volume_off.svg';
  static const String musicOn = 'assets/icons/music_on.svg';
  static const String musicOff = 'assets/icons/music_off.svg';

  // ── Navigation ────────────────────────────────────────────────────────
  static const String home = 'assets/icons/home.svg';
  static const String back = 'assets/icons/back.svg';
  static const String forward = 'assets/icons/forward.svg';
  static const String close = 'assets/icons/close.svg';
  static const String settings = 'assets/icons/settings.svg';

  // ── Feedback ──────────────────────────────────────────────────────────
  static const String check = 'assets/icons/check.svg';
  static const String info = 'assets/icons/info.svg';
  static const String warning = 'assets/icons/warning.svg';
  static const String help = 'assets/icons/help.svg';

  // ── Belohnung / Status ────────────────────────────────────────────────
  static const String trophy = 'assets/icons/trophy.svg';
  static const String crown = 'assets/icons/crown.svg';
  static const String star = 'assets/icons/star.svg';
  static const String starFilled = 'assets/icons/star_filled.svg';
  static const String flame = 'assets/icons/flame.svg';
  static const String heart = 'assets/icons/heart.svg';
  static const String heartBroken = 'assets/icons/heart_broken.svg';
  static const String lightbulb = 'assets/icons/lightbulb.svg';

  // ── Lern-Werkzeuge ────────────────────────────────────────────────────
  static const String book = 'assets/icons/book.svg';
  static const String pencil = 'assets/icons/pencil.svg';
  static const String eraser = 'assets/icons/eraser.svg';
  static const String paintBrush = 'assets/icons/paint_brush.svg';

  // ── Lumo Cards ────────────────────────────────────────────────────────
  static const String cardBack = 'assets/icons/card_back.svg';
  static const String cardPlay = 'assets/icons/card_play.svg';
  static const String deck = 'assets/icons/deck.svg';
  static const String dice = 'assets/icons/dice.svg';
  static const String hourglass = 'assets/icons/hourglass.svg';
  static const String timer = 'assets/icons/timer.svg';

  // ── Privacy / Notifications ───────────────────────────────────────────
  static const String lock = 'assets/icons/lock.svg';
  static const String unlock = 'assets/icons/unlock.svg';
  static const String bell = 'assets/icons/bell.svg';
  static const String bellOff = 'assets/icons/bell_off.svg';

  // ── Personen (Eltern/Kind) ────────────────────────────────────────────
  static const String parent = 'assets/icons/parent.svg';
  static const String child = 'assets/icons/child.svg';

  /// Liste aller 40 Icon-Pfade fuer Smoke-Tests.
  static const List<String> all = <String>[
    pause, play, stop, volumeOn, volumeOff, musicOn, musicOff,
    home, back, forward, close, settings,
    check, info, warning, help,
    trophy, crown, star, starFilled, flame, heart, heartBroken, lightbulb,
    book, pencil, eraser, paintBrush,
    cardBack, cardPlay, deck, dice, hourglass, timer,
    lock, unlock, bell, bellOff,
    parent, child,
  ];
}
