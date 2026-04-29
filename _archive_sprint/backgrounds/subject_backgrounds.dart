import 'package:flutter/material.dart';
import '../../../app/app_theme.dart';
import 'floating_symbols_background.dart';

/// Mathematik: Zahlen + Operatoren tanzen leise im Hintergrund.
class MathCardBackground extends StatelessWidget {
  const MathCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '−', '×', '='],
      color: LumoColors.math,
      density: 9,
      minSize: 22,
      maxSize: 52,
      opacity: 0.16,
      driftSeconds: 16,
    );
  }
}

/// Deutsch: Buchstaben & Sonderzeichen schweben.
class GermanCardBackground extends StatelessWidget {
  const GermanCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['A', 'B', 'a', 'b', 'ä', 'ö', 'ü', 'ß', 'sch', 'ie', 'eu'],
      color: LumoColors.german,
      density: 9,
      minSize: 22,
      maxSize: 50,
      opacity: 0.18,
      driftSeconds: 18,
    );
  }
}

/// Englisch: kleine Wörter & Begrüßungen.
class EnglishCardBackground extends StatelessWidget {
  const EnglishCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['Hi', 'Hello', 'Yes', 'No', 'A', 'a', 'b', 'c', 'cat', 'dog'],
      color: LumoColors.english,
      density: 8,
      minSize: 18,
      maxSize: 38,
      opacity: 0.20,
      driftSeconds: 17,
    );
  }
}

/// Übung: kleine Sterne & Häkchen — verspielt.
class PracticeCardBackground extends StatelessWidget {
  const PracticeCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['★', '✦', '✓', '♥', '●'],
      color: LumoColors.practice,
      density: 12,
      minSize: 14,
      maxSize: 30,
      opacity: 0.22,
      driftSeconds: 15,
    );
  }
}

/// Test: Häkchen + Kreuze + Ziffern — clean, ruhig.
class TestCardBackground extends StatelessWidget {
  const TestCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['✓', '?', '1', '2', '3', '○'],
      color: LumoColors.testColor,
      density: 9,
      minSize: 20,
      maxSize: 42,
      opacity: 0.18,
      driftSeconds: 19,
    );
  }
}

/// Schularbeit: Pokal + Sterne + A+ Symbole.
class SchoolworkCardBackground extends StatelessWidget {
  const SchoolworkCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['A+', 'A', '★', '✦', '1.'],
      color: LumoColors.schoolwork,
      density: 8,
      minSize: 22,
      maxSize: 48,
      opacity: 0.18,
      driftSeconds: 20,
    );
  }
}

/// Foto: Kamera-Symbole sanft, keine Hektik.
class ScannerCardBackground extends StatelessWidget {
  const ScannerCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['◉', '○', '◎', '✓'],
      color: LumoColors.scanner,
      density: 7,
      minSize: 22,
      maxSize: 50,
      opacity: 0.16,
      driftSeconds: 22,
    );
  }
}

/// Weiterlernen: Pfeile, Bücher, Lese-Hinweise.
class ContinueCardBackground extends StatelessWidget {
  const ContinueCardBackground({super.key});
  @override
  Widget build(BuildContext context) {
    return const FloatingSymbolsBackground(
      symbols: ['→', '▶', '►', '✓'],
      color: LumoColors.continueColor,
      density: 8,
      minSize: 20,
      maxSize: 44,
      opacity: 0.18,
      driftSeconds: 18,
    );
  }
}
