import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/learning_modules/geld/geld_screen.dart';

/// Befund L8 der Fachprüfung Mathematik (17.11.2026): Falsche Beträge waren
/// mit den gezeigten Münzen nicht legbar (83 Cent), Beträge hießen
/// „1 Euro 50“.
void main() {
  test('Beträge in Schulschreibweise', () {
    expect(geldBetrag(50), '50 Cent');
    expect(geldBetrag(150), '1,50 €');
    expect(geldBetrag(200), '2,00 €');
    expect(geldBetrag(310), '3,10 €');
  });

  test('Ablenker sind legbar und enthalten typische Zählfehler', () {
    const coinValues = [10, 20, 50, 100, 200];
    final rng = math.Random(7);
    for (var round = 0; round < 500; round++) {
      final coins = [
        for (var i = 0; i <= rng.nextInt(4); i++)
          coinValues[rng.nextInt(coinValues.length)],
      ];
      final total = coins.reduce((a, b) => a + b);
      final wrong = geldAblenker(coins, rng);
      expect(wrong, hasLength(3), reason: '$coins');
      expect(wrong.toSet(), hasLength(3), reason: '$coins');
      for (final value in wrong) {
        expect(value, isNot(total), reason: '$coins');
        expect(value, greaterThan(0), reason: '$coins');
        // Mit 10-, 20- und 50-Cent-Münzen ist jeder Zehnerbetrag legbar.
        expect(value % 10, 0, reason: '$coins → $wrong');
      }
      final forgotOrDouble = {
        for (final c in coins) total - c,
        for (final c in coins) total + c,
      };
      expect(wrong.any(forgotOrDouble.contains), isTrue,
          reason: '$coins → $wrong');
    }
  });
}
