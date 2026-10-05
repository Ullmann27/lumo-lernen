import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Bildmotive der Memory-Karten. Die fünf Tierkarten sind fertige Kartenbilder
/// (Panda, Giraffe, Lumo, Hase, Pinguin); alle anderen sind freigestellte
/// Figuren, die auf einem Farbverlauf der Karte sitzen.
enum MemoryMotif {
  panda('Panda', 'face_panda', false, Color(0xFF3FA8F5), Color(0xFF8FD3FF)),
  giraffe('Giraffe', 'face_giraffe', false, Color(0xFF58C985), Color(0xFFB4F0C8)),
  lumo('Lumo', 'face_fox', false, Color(0xFF2E9BEA), Color(0xFF7CCBFF)),
  hase('Hase', 'face_bunny', false, Color(0xFFB45CF0), Color(0xFFE2A8FF)),
  pinguin('Pinguin', 'face_penguin', false, Color(0xFF45B0F0), Color(0xFF9EDCFF)),
  stern('Sternchen', 'sticker_star', true, Color(0xFF2B6FE0), Color(0xFF7FB6FF)),
  laterne('Laterne', 'sticker_lantern', true, Color(0xFF3A4FC0), Color(0xFF8D9CF5)),
  truhe('Schatztruhe', 'sticker_chest', true, Color(0xFF2E8E9E), Color(0xFF8FE0E8)),
  note('Notenfreund', 'sticker_note', true, Color(0xFF8C4FE0), Color(0xFFD0A8FF)),
  fahne('Sternenfahne', 'sticker_flag', true, Color(0xFF2A7FE8), Color(0xFF9CCBFF)),
  pilz('Pilz', 'sticker_mushroom', true, Color(0xFF4FAE6A), Color(0xFFA8E8B8)),
  stein('Stachelstein', 'sticker_rock', true, Color(0xFF5A6FA0), Color(0xFFAEBBE0));

  const MemoryMotif(
      this.label, this.asset, this.sticker, this.tintDark, this.tintLight);

  final String label;
  final String asset;

  /// true: freigestellte Figur auf Farbverlauf; false: fertiges Kartenbild.
  final bool sticker;
  final Color tintDark;
  final Color tintLight;

  String get path => 'assets/lumo_design/memory/$asset.png';
}

/// Schwierigkeitsstufen. [cols]×[rows] ist die Spielfeldgröße im Querformat;
/// im Hochformat dreht das Brett sich passend (siehe [bestGrid]).
enum MemoryDifficulty {
  leicht(4, 2),
  mittel(4, 3),
  schwer(4, 4),
  knifflig(5, 4),
  profi(6, 4);

  const MemoryDifficulty(this.cols, this.rows);
  final int cols;
  final int rows;

  int get cards => cols * rows;
  int get pairs => cards ~/ 2;
  String get label => '$cols×$rows';

  /// Sterne für Sieg, Unentschieden und Niederlage. Wächst mit der Anzahl
  /// der Paare, damit kleine Bretter nicht dieselbe Belohnung geben wie das
  /// große (Werte nicht von Heinz freigegeben, hier zentral einstellbar).
  int starsFor({required bool won, required bool draw}) {
    final base = (5 * pairs / 12).round().clamp(2, 5);
    if (won) return base;
    return draw ? math.max(1, base - 2) : math.max(1, base - 3);
  }
}

class MemoryGrid {
  const MemoryGrid(this.cols, this.rows);
  final int cols;
  final int rows;
}

/// Mischt ein Brett: jedes gewählte Motiv genau zweimal.
class MemoryBoard {
  static List<MemoryMotif> deal(MemoryDifficulty difficulty, math.Random rng) {
    final motifs = [...MemoryMotif.values]..shuffle(rng);
    final chosen = motifs.take(difficulty.pairs).toList();
    return [...chosen, ...chosen]..shuffle(rng);
  }

  /// Beste Aufteilung der Karten für ein Feld der Größe [width]×[height]:
  /// nur Teiler der Kartenzahl, damit keine Lücken entstehen.
  static MemoryGrid bestGrid(
    int cards,
    double width,
    double height, {
    double cardAspect = .74,
    double gap = 8,
  }) {
    MemoryGrid? best;
    var bestArea = -1.0;
    for (var cols = 2; cols <= cards ~/ 2; cols++) {
      if (cards % cols != 0) continue;
      final rows = cards ~/ cols;
      final w = (width - gap * (cols - 1)) / cols;
      final h = (height - gap * (rows - 1)) / rows;
      if (w <= 0 || h <= 0) continue;
      final cardW = math.min(w, h * cardAspect);
      final area = cardW * cardW / cardAspect;
      if (area > bestArea) {
        bestArea = area;
        best = MemoryGrid(cols, rows);
      }
    }
    return best ?? MemoryGrid(math.max(1, cards ~/ 2), 2);
  }
}
