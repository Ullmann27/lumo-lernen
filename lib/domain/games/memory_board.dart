import 'dart:math' as math;

/// Gespeicherte Motive behalten ihren Namen bei einem Wechsel des Kartendesigns.
enum MemoryMotif {
  panda('Panda'),
  giraffe('Giraffe'),
  lumo('Lumo'),
  hase('Hase'),
  pinguin('Pinguin'),
  stern('Sternchen'),
  laterne('Laterne'),
  truhe('Schatztruhe'),
  note('Notenfreund'),
  fahne('Sternenfahne'),
  pilz('Pilz'),
  stein('Stachelstein');

  const MemoryMotif(this.label);
  final String label;
  String get path => 'assets/lumo_design/memory/collection/$name.webp';
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

/// Themed card packs. "Alle" keeps the historical shuffle of every motif.
/// Tiere / Weltall / Garten prefer matching art; leftover pairs are filled
/// from the remaining motifs so every difficulty still deals unique pairs.
enum MemoryThemePack {
  alle('Alle'),
  tiere('Tiere'),
  weltall('Weltall'),
  garten('Garten');

  const MemoryThemePack(this.label);
  final String label;

  List<MemoryMotif> get motifs => switch (this) {
        MemoryThemePack.alle => MemoryMotif.values,
        MemoryThemePack.tiere => const [
            MemoryMotif.panda,
            MemoryMotif.giraffe,
            MemoryMotif.lumo,
            MemoryMotif.hase,
            MemoryMotif.pinguin,
          ],
        MemoryThemePack.weltall => const [
            MemoryMotif.stern,
            MemoryMotif.laterne,
            MemoryMotif.fahne,
            MemoryMotif.note,
            MemoryMotif.lumo,
          ],
        MemoryThemePack.garten => const [
            MemoryMotif.pilz,
            MemoryMotif.stein,
            MemoryMotif.truhe,
            MemoryMotif.laterne,
            MemoryMotif.note,
          ],
      };
}

/// Mischt ein Brett: jedes gewählte Motiv genau zweimal.
class MemoryBoard {
  static List<MemoryMotif> deal(
    MemoryDifficulty difficulty,
    math.Random rng, {
    MemoryThemePack pack = MemoryThemePack.alle,
  }) {
    final List<MemoryMotif> motifs;
    if (pack == MemoryThemePack.alle) {
      motifs = [...MemoryMotif.values]..shuffle(rng);
    } else {
      final preferred = [...pack.motifs]..shuffle(rng);
      final extra = [
        for (final motif in MemoryMotif.values)
          if (!preferred.contains(motif)) motif
      ]..shuffle(rng);
      motifs = [...preferred, ...extra];
    }
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
