import 'dart:math' as math;
import 'dart:ui';

/// Reine Geometrie der Lernbühne: Wo darf Lumo stehen, wo seine Sprechblase?
///
/// Regel „nie im Weg“: Lumo und die Blase schneiden weder das Ziel noch ein
/// Hindernis (Aufgabe, Bild, Antworten). Alles in Bühnen-Koordinaten.
class LumoStageLayout {
  const LumoStageLayout({
    required this.stage,
    required this.figureHeight,
    this.margin = 8,
  });

  final Size stage;

  /// Sichtbare Figurhöhe in dp (mit Ohren).
  final double figureHeight;
  final double margin;

  /// Grundfläche der Figur um ihren Fußpunkt.
  Size get actorSize => Size(figureHeight * .78, figureHeight + 6);

  Rect actorRect(Offset foot) {
    final size = actorSize;
    return Rect.fromLTWH(foot.dx - size.width / 2, foot.dy - size.height,
        size.width, size.height);
  }

  /// Ungefähre Lage der zeigenden Hand (Streifen schauen nach rechts oben).
  Offset handPoint(Offset foot, {required bool facingRight}) => Offset(
      foot.dx + (facingRight ? 1 : -1) * actorSize.width * .48,
      foot.dy - figureHeight * .72);

  bool _inside(Rect rect) =>
      rect.left >= margin - .01 &&
      rect.top >= margin - .01 &&
      rect.right <= stage.width - margin + .01 &&
      rect.bottom <= stage.height - margin + .01;

  static bool _free(Rect rect, Iterable<Rect> obstacles) =>
      obstacles.every((o) => !o.deflate(.5).overlaps(rect));

  /// Fußpunkte für den Standardplatz: unten rechts, sonst unten links.
  List<Offset> homeCandidates() {
    final w = actorSize.width;
    final y = stage.height - margin;
    return [
      Offset(stage.width - margin - w / 2, y),
      Offset(margin + w / 2, y),
    ];
  }

  /// Erster freier Standardplatz oder null, wenn beide Ecken belegt sind.
  Offset? freeHome(Iterable<Rect> obstacles) {
    for (final foot in homeCandidates()) {
      if (_free(actorRect(foot), obstacles)) return foot;
    }
    return null;
  }

  /// Bester freier Platz neben [target], von dem aus Lumo hinzeigt.
  /// Null, wenn kein freier Platz existiert (dann hilft Lumo vom Platz aus).
  LumoStagePlacement? placeNear(Rect target, Iterable<Rect> obstacles,
      {Offset? from, bool preferEdges = false}) {
    final blocked = [target, ...obstacles];
    final size = actorSize;
    LumoStagePlacement? best;
    var bestScore = double.infinity;
    const step = 8.0;
    for (var x = margin + size.width / 2;
        x <= stage.width - margin - size.width / 2 + .01;
        x += step) {
      for (var y = margin + size.height;
          y <= stage.height - margin + .01;
          y += step) {
        final foot = Offset(x, y);
        final rect = actorRect(foot);
        if (!_inside(rect) || !_free(rect, blocked)) continue;
        final facingRight = target.center.dx >= x;
        final hand = handPoint(foot, facingRight: facingRight);
        final gap = _distanceToRect(hand, target);
        // Nahe ans Ziel, Hand eher unter/neben dem Ziel, kurzer Weg.
        final above = hand.dy < target.top ? 18.0 : 0.0;
        final travel = from == null ? 0.0 : (from - foot).distance * .04;
        // Zahlen stehen links bis mittig: nahe der Mitte, lieber links vom
        // Ziel mit Blick nach rechts (so wie die Streifen gezeichnet sind).
        final centre = (hand.dx - target.center.dx).abs() * .2;
        final side = facingRight ? 0.0 : 12.0;
        final edge = preferEdges
            ? math.min(rect.left, stage.width - rect.right) * 1.5
            : 0.0;
        final score =
            gap + above + travel + (preferEdges ? 0 : centre) + side + edge;
        if (score < bestScore) {
          bestScore = score;
          best = LumoStagePlacement(foot: foot, facingRight: facingRight);
        }
      }
    }
    return best;
  }

  /// Platz der Sprechblase bei Lumo, frei von Ziel, Hindernissen und Figur.
  Rect? placeBubble(Size bubble, Offset foot, Iterable<Rect> obstacles,
      {Rect? target}) {
    final actor = actorRect(foot);
    final blocked = [actor, if (target != null) target, ...obstacles];
    Rect? best;
    var bestScore = double.infinity;
    const step = 8.0;
    for (var x = margin;
        x <= stage.width - margin - bubble.width + .01;
        x += step) {
      for (var y = margin;
          y <= stage.height - margin - bubble.height + .01;
          y += step) {
        final rect = Rect.fromLTWH(x, y, bubble.width, bubble.height);
        if (!_free(rect, blocked)) continue;
        final score = _distanceRectRect(rect, actor.inflate(-4)) +
            // Lieber auf Kopfhöhe als unter den Füßen.
            (rect.top > actor.bottom ? 30 : 0);
        if (score < bestScore) {
          bestScore = score;
          best = rect;
        }
      }
    }
    return best;
  }

  static double _distanceToRect(Offset p, Rect r) {
    final dx = math.max(0.0, math.max(r.left - p.dx, p.dx - r.right));
    final dy = math.max(0.0, math.max(r.top - p.dy, p.dy - r.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _distanceRectRect(Rect a, Rect b) {
    final dx = math.max(0.0, math.max(a.left - b.right, b.left - a.right));
    final dy = math.max(0.0, math.max(a.top - b.bottom, b.top - a.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }
}

class LumoStagePlacement {
  const LumoStagePlacement({required this.foot, required this.facingRight});
  final Offset foot;
  final bool facingRight;
}
