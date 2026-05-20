// ════════════════════════════════════════════════════════════════════════
//                    LUMO KART - TUNING-KONSTANTEN
// ════════════════════════════════════════════════════════════════════════
//
// Alle Physik- und Fahrgefuehl-Werte zentral. Wenn das Kart sich zu
// schwammig oder zu hektisch anfuehlt, hier anpassen, nicht ueberall im
// Code. Werte sind in Welt-Pixeln pro Sekunde, soweit nicht anders
// angegeben.

class KartTuning {
  const KartTuning._();

  // ── Geschwindigkeit ─────────────────────────────────────────────────
  /// Maximale Vorwaerts-Geschwindigkeit ohne Boost (Welt-Pixel/s).
  static const double maxSpeed = 360.0;

  /// Beschleunigung beim Anfahren (Welt-Pixel/s^2).
  static const double acceleration = 240.0;

  /// Verzoegerung beim manuellen Bremsen (Welt-Pixel/s^2).
  static const double brakeForce = 520.0;

  /// Passive Reibung wenn kein Input (Welt-Pixel/s^2).
  /// Sorgt dafuer dass das Kart natuerlich ausrollt.
  static const double friction = 90.0;

  // ── Lenkung ─────────────────────────────────────────────────────────
  /// Lenkrate bei voller Geschwindigkeit (lane-units pro Sekunde,
  /// wobei laneX zwischen -1 und +1 liegt).
  static const double turnRate = 1.45;

  /// Lenkdaempfung bei niedriger Geschwindigkeit. Bei speed=0 ist die
  /// Lenkung auf turnRate*minTurnFactor reduziert.
  static const double minTurnFactor = 0.55;

  /// Daempfung der visuellen Kart-Neigung pro Frame.
  static const double tiltDamping = 0.84;

  /// Wie stark die visuelle Neigung beim Lenken ausschlaegt.
  static const double tiltStrength = 0.22;

  // ── Boost ───────────────────────────────────────────────────────────
  /// Multiplikator fuer Max-Speed waehrend Boost.
  static const double boostMultiplier = 1.6;

  /// Dauer eines Boost-Pad-Triggers (Sekunden).
  static const double boostPadDuration = 1.6;

  /// Dauer eines manuellen Boost-Trigger (Sekunden).
  static const double manualBoostDuration = 1.1;

  /// Cooldown fuer manuellen Boost (Sekunden). Verhindert Spam.
  static const double manualBoostCooldown = 0.6;

  // ── Drift ───────────────────────────────────────────────────────────
  /// Lenkinput-Schwellwert ab dem Drift visuell ausgeloest wird (>0..1).
  static const double driftThreshold = 0.7;

  /// Mindest-Speed-Verhaeltnis (zu maxSpeed) damit Drift entsteht.
  static const double driftMinSpeedFactor = 0.55;

  /// Visueller Drift-Faktor: zusaetzliche Kart-Neigung waehrend Drift.
  static const double driftTiltBonus = 0.18;

  // ── Kollisionen ─────────────────────────────────────────────────────
  /// Geschwindigkeitsmultiplikator nach Kistenkollision (0..1).
  static const double crashSlowdown = 0.42;

  /// Dauer der Slow-Phase nach einer Kollision (Sekunden).
  static const double crashDuration = 0.55;

  /// Screen-Shake-Amplitude bei Crash (in Pixeln).
  static const double crashShakeAmplitude = 14.0;

  /// Wie schnell der Screen-Shake abklingt (pro Sekunde Faktor).
  static const double crashShakeDecay = 6.0;

  // ── Strecke ─────────────────────────────────────────────────────────
  /// Breite des fahrbaren Streckenbereichs (Welt-Pixel).
  static const double trackWidth = 360.0;

  /// Wie weit links/rechts laneX maximal gehen darf (clamp).
  static const double laneClamp = 0.95;

  /// Welt-Pixel die das Kart bis zum Ziel zuruecklegen muss.
  /// 7000 ergibt ca. 50-70 Sekunden Rennen bei normalem Fahren.
  static const double finishDistance = 7000.0;

  /// Wie stark die Strecke seitlich schwingt (Kurvenillusion).
  static const double trackSwayAmplitude = 0.18;

  /// Wellenlaenge der Streckenschwingung (Welt-Pixel).
  static const double trackSwayWavelength = 1800.0;

  // ── Kart-Sprite ─────────────────────────────────────────────────────
  static const double kartWidth = 96.0;
  static const double kartHeight = 124.0;

  // ── Sammelobjekte ───────────────────────────────────────────────────
  static const double starSize = 52.0;
  static const double crateSize = 58.0;
  static const double boostPadSize = 84.0;
  static const double questionBlockSize = 68.0;
}
