/// Pixar-Farbpalette - exakt aus Heinz' Referenz-Bildern destilliert.
///
/// Quelle: docs/design_references/01_mathe_mit_lumo_target.png
///         docs/design_references/03_deutsch_mit_lumo_target.png
///         docs/design_references/02_pixar_scene_full.png
///
/// Die Farben sind so abgestimmt, dass sie zusammen die warme, kindgerechte
/// Atmosphaere der Pixar-Referenz erzeugen. Niemals einzelne Werte aendern
/// ohne den Vergleich zu den Referenzbildern - alles ist aufeinander
/// abgestimmt.

import 'package:flutter/material.dart';

abstract class PixarColors {
  PixarColors._();

  // ─────────────────── HIMMEL & ATMOSPHAERE ───────────────────

  /// Warmes Cremegelb - Standard-Hintergrund der Pixar-Szenen.
  static const Color skyWarm = Color(0xFFFFF4E0);

  /// Pfirsich-Ton - sanfter Uebergang zum Boden / Tisch.
  static const Color skyPeach = Color(0xFFFFE8C8);

  /// Morgendliche Waerme - obere Hero-Header-Section.
  static const Color skyMorning = Color(0xFFFFD9A8);

  /// Goldener Glow - hinter Sonnen-/Sternen-Akzenten.
  static const Color skyGlow = Color(0xFFFFE5B4);

  // ─────────────────── LUMO (der Fuchs) ───────────────────

  /// Orange Fellfarbe des Lumo-Fuchses.
  static const Color foxOrange = Color(0xFFFF8C42);

  /// Helle Bauch-/Wangenseite.
  static const Color foxBelly = Color(0xFFFFE5D0);

  /// Lila Hoodie des Maskottchens.
  static const Color foxHoodie = Color(0xFF9747FF);

  /// Lila Hoodie - dunkler Akzent (Schatten).
  static const Color foxHoodieDark = Color(0xFF7C3AED);

  /// Gelber Stern auf dem Hoodie.
  static const Color foxStar = Color(0xFFFFD700);

  /// Schwarze Akzente (Nase, Augen).
  static const Color foxAccent = Color(0xFF1F1B14);

  // ─────────────────── TEXT-AKZENTE ───────────────────

  /// Dunkelbraun fuer Headlines wie "Mathe" / "Deutsch".
  static const Color headlineDark = Color(0xFF3D2F26);

  /// Orange Akzent fuer "Lumo" und CTAs.
  static const Color headlineOrange = Color(0xFFFF7A2F);

  /// Sub-Titel-Farbe ("Rechnen macht Spass!").
  static const Color subtitleGray = Color(0xFF8B7355);

  /// Body-Text-Standard.
  static const Color bodyDark = Color(0xFF2D2419);

  // ─────────────────── KARTEN-SURFACES (PASTELL) ───────────────────

  /// Wörter-lesen-Karte (gelblich-warm).
  static const Color tileYellow = Color(0xFFFFF4D9);

  /// Buchstaben-finden-Karte (mintgruen).
  static const Color tileGreen = Color(0xFFDFF5E3);

  /// Reime-erkennen-Karte (rosa).
  static const Color tilePink = Color(0xFFFFE0EC);

  /// Satz-bilden-Karte (himmelblau).
  static const Color tileBlue = Color(0xFFDCEEFF);

  /// Mathe-Karte (cremig-orange).
  static const Color tileOrange = Color(0xFFFFEAD0);

  /// Sachunterricht-Karte (mint-tuerkis).
  static const Color tileMint = Color(0xFFE0F5F0);

  // ─────────────────── BUTTONS / CTAs ───────────────────

  /// Pill-Button Gradient Start.
  static const Color ctaGradStart = Color(0xFFFFB347);

  /// Pill-Button Gradient Ende.
  static const Color ctaGradEnd = Color(0xFFFF7A2F);

  /// CTA-Shadow-Color.
  static const Color ctaShadow = Color(0xFFFF7A2F);

  // ─────────────────── STATUS / FEEDBACK ───────────────────

  /// Grüner Check / korrekte Antwort - Outline.
  static const Color correctGreen = Color(0xFF6EE7B7);

  /// Grüner Check - dunkler Akzent (Border).
  static const Color correctGreenDark = Color(0xFF10B981);

  /// Pfirsich-Ton fuer "falsch aber freundlich".
  static const Color wrongPeach = Color(0xFFFEC89A);

  /// Roter Akzent fuer ernste Fehler (selten benutzt - Kinder!).
  static const Color wrongRed = Color(0xFFEF4444);

  // ─────────────────── MISSION / STREAK / XP ───────────────────

  /// Streak-Flamme.
  static const Color streakFire = Color(0xFFFF5722);

  /// XP-Badge Blau.
  static const Color xpBlue = Color(0xFF4A9EFF);

  /// Stern-Gold (Belohnungen).
  static const Color starGold = Color(0xFFFFB800);

  /// Stern-Gold heller.
  static const Color starGoldLight = Color(0xFFFFD700);

  // ─────────────────── HELFER ───────────────────

  /// Hero-Gradient von oben nach unten (Hintergrund-Atmosphaere).
  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[skyMorning, skyPeach, skyWarm],
    stops: <double>[0.0, 0.55, 1.0],
  );

  /// CTA-Pill-Button Gradient.
  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[ctaGradStart, ctaGradEnd],
  );

  /// Lumo-Hoodie Gradient.
  static const LinearGradient foxHoodieGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[foxHoodie, foxHoodieDark],
  );

  /// Pastell-Surface fuer eine bestimmte Fach-Karte.
  static Color tileForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathe':
      case 'mathematik':
        return tileOrange;
      case 'deutsch':
        return tileYellow;
      case 'lesen':
        return tilePink;
      case 'sachunterricht':
      case 'natur':
        return tileMint;
      case 'englisch':
        return tileBlue;
      default:
        return tileGreen;
    }
  }
}
