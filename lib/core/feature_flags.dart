// ════════════════════════════════════════════════════════════════════════
//                    FEATURE FLAGS
// ════════════════════════════════════════════════════════════════════════
//
// Zentrale Schalter fuer optionale Features. Werden zum Build-Zeitpunkt
// (const) gesetzt. Wenn ein Feature instabil ist: hier auf false stellen,
// dann verschwindet es vollstaendig aus der App.

class FeatureFlags {
  const FeatureFlags._();

  /// Schreibcoach MVP (Phase 1+2): Canvas, Stroke-Erfassung, einfache
  /// Buchstaben-Heuristiken fuer I/L/O/H, Lumo-Vorzeichnen.
  static const bool enableWritingCoach = true;

  /// ML Kit Digital Ink Recognition (Phase 7).
  /// MUSS false bleiben bis Plugin/Modell-Setup geprueft und stabil.
  static const bool enableDigitalInkRecognition = false;

  /// Diktatmodus mit Buchstabenfeldern (Phase 5).
  static const bool enableWritingWordMode = false;

  /// Fortschrittsbericht Schreibcoach (Phase 6).
  static const bool enableWritingProgressReport = false;
}
