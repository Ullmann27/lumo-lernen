// ════════════════════════════════════════════════════════════════════════
// WRITING FEATURE FLAGS
// ════════════════════════════════════════════════════════════════════════
// Heinz' Regel: neue Schreibcoach-Phasen sind hinter Flags versteckt,
// bis sie stabil sind. So bleibt die App auch dann sicher, wenn ein
// Phase-5/6-Build noch Macken hat.
// ════════════════════════════════════════════════════════════════════════

class WritingFeatureFlags {
  WritingFeatureFlags._();

  /// Phase 5: Wortmodus mit Buchstabenfeldern (Diktat).
  static const bool enableWordMode = true;

  /// Phase 6: Persistenter Progress (Buchstaben-Statistiken,
  /// schwache Buchstaben, abgeschlossene Woerter).
  /// Standardmaessig an, da Phase 6 jetzt fertig gebaut wird.
  static const bool enableProgressTracking = true;

  /// Phase 7: ML Kit Digital Ink Recognition.
  /// Bleibt false bis ML Kit getestet ist.
  static const bool enableDigitalInkRecognition = false;

  /// Phase 8: Foto-/OCR-Arbeitsblatt.
  /// Bleibt false bis dieser Pfad vorbereitet ist.
  static const bool enableSheetOcr = false;
}
