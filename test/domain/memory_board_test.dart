import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/games/memory_board.dart';

void main() {
  test('Jedes Motiv kommt in jeder Stufe genau zweimal vor', () {
    for (final d in MemoryDifficulty.values) {
      final deck = MemoryBoard.deal(d, Random(3));
      expect(deck.length, d.cards, reason: d.label);
      final counts = <MemoryMotif, int>{};
      for (final m in deck) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
      expect(counts.length, d.pairs, reason: d.label);
      expect(counts.values.every((n) => n == 2), isTrue, reason: d.label);
    }
  });

  test('Es gibt genug Motive für die größte Stufe und alle Bilder existieren',
      () {
    expect(MemoryMotif.values.length,
        greaterThanOrEqualTo(MemoryDifficulty.profi.pairs));
    for (final m in MemoryMotif.values) {
      expect(File(m.path).existsSync(), isTrue, reason: m.path);
    }
  });

  test('Brettaufteilung ohne Lücken und passend zur Ausrichtung', () {
    for (final d in MemoryDifficulty.values) {
      final tall = MemoryBoard.bestGrid(d.cards, 340, 520);
      final wide = MemoryBoard.bestGrid(d.cards, 800, 340);
      expect(tall.cols * tall.rows, d.cards);
      expect(wide.cols * wide.rows, d.cards);
      expect(wide.cols, greaterThanOrEqualTo(tall.cols), reason: d.label);
    }
  });

  test('Belohnung wächst mit der Stufe und Sieg ist nie weniger wert', () {
    var last = 0;
    for (final d in MemoryDifficulty.values) {
      final win = d.starsFor(won: true, draw: false);
      expect(win, greaterThanOrEqualTo(last));
      expect(win, greaterThan(d.starsFor(won: false, draw: true) - 1));
      expect(d.starsFor(won: false, draw: false), greaterThanOrEqualTo(1));
      last = win;
    }
  });
}
